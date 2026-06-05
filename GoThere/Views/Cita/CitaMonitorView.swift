import SwiftUI

/// User-guided cita previa helper. GoThere does NOT poll the government system
/// (that requires a persistent backend + accepts the portal's anti-bot/ToS
/// posture). Instead this saves the user's appointment targets, deep-links into
/// the correct official portal, and nudges them to check during weekday release
/// windows — meaningfully faster than navigating the portal maze cold.
struct CitaMonitorView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var monitors: [CitaMonitor] = CitaMonitorStore.load()
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                explainer

                if monitors.isEmpty {
                    emptyState
                } else {
                    ForEach(monitors) { monitor in
                        monitorCard(monitor)
                    }
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Add a cita target", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.goPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.goPrimary, lineWidth: 1.5)
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Cita Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            CitaMonitorEditor { monitor in
                monitors = CitaMonitorStore.upsert(monitor)
                if monitor.remindersEnabled {
                    NotificationManager.shared.requestPermissionIfNeeded()
                    NotificationManager.shared.scheduleCitaReminders(monitor)
                }
            }
        }
    }

    // MARK: - Sections

    private var explainer: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.badge")
                .foregroundColor(.goPrimary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Catch a slot the moment you can")
                    .font(.subheadline.weight(.semibold))
                Text("Spain's cita previa system books out fast. Save your targets here — we'll open the right official portal in one tap and remind you to check on weekday mornings, when slots are released.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.goPrimary.opacity(0.08))
        .cornerRadius(12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.goPrimary.opacity(0.4))
            Text("No cita targets yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Add the appointment you're chasing to get a one-tap portal link and check reminders.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func monitorCard(_ monitor: CitaMonitor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monitor.type.label)
                        .font(.subheadline.weight(.semibold))
                    if !monitor.area.isEmpty {
                        Text(monitor.area)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Menu {
                    Button(monitor.remindersEnabled ? "Pause reminders" : "Resume reminders") {
                        toggleReminders(monitor)
                    }
                    Button("Remove", role: .destructive) { remove(monitor) }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.goPrimary)
                }
            }

            // Status line
            HStack(spacing: 6) {
                Circle()
                    .fill(monitor.remindersEnabled ? Color.goSuccess : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(monitor.remindersEnabled ? "Reminders on · Mon–Fri 8:30" : "Reminders paused")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if let last = monitor.lastChecked {
                    Text("Checked \(relative(last))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(monitor.type.instruction)
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                openPortal(monitor)
            } label: {
                Label("Open booking portal", systemImage: "arrow.up.right.square")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.goPrimary)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.goSurfaceDark : Color.goSurfaceLight)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func openPortal(_ monitor: CitaMonitor) {
        UIApplication.shared.open(monitor.type.bookingURL(area: monitor.area))
        var updated = monitor
        updated.lastChecked = Date()
        monitors = CitaMonitorStore.upsert(updated)
    }

    private func toggleReminders(_ monitor: CitaMonitor) {
        var updated = monitor
        updated.remindersEnabled.toggle()
        monitors = CitaMonitorStore.upsert(updated)
        if updated.remindersEnabled {
            NotificationManager.shared.requestPermissionIfNeeded()
            NotificationManager.shared.scheduleCitaReminders(updated)
        } else {
            NotificationManager.shared.cancelCitaReminders(monitorId: updated.id)
        }
    }

    private func remove(_ monitor: CitaMonitor) {
        NotificationManager.shared.cancelCitaReminders(monitorId: monitor.id)
        monitors = CitaMonitorStore.remove(id: monitor.id)
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}

/// Add/edit sheet for a cita target.
private struct CitaMonitorEditor: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (CitaMonitor) -> Void

    @State private var type: CitaAppointmentType = .nieInitial
    @State private var province: String = "Madrid"
    @State private var consulateArea: String = ""
    @State private var remindersEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Appointment") {
                    Picker("Type", selection: $type) {
                        ForEach(CitaAppointmentType.allCases) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    Text(type.instruction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if type.usesProvince {
                    Section("Province") {
                        Picker("Province", selection: $province) {
                            ForEach(CitaProvinces.all, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                    }
                } else {
                    Section("Consulate location") {
                        TextField("City / country (e.g. New York)", text: $consulateArea)
                    }
                }

                Section {
                    Toggle("Remind me to check (Mon–Fri mornings)", isOn: $remindersEnabled)
                        .tint(.goPrimary)
                } footer: {
                    Text("GoThere opens the official portal and reminds you to check — it doesn't book or monitor the government system for you.")
                }
            }
            .navigationTitle("New Cita Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let area = type.usesProvince ? province : consulateArea
                        onSave(CitaMonitor(type: type, area: area, remindersEnabled: remindersEnabled))
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
