import SwiftUI

struct CalendarScreenView: View {
    @EnvironmentObject var themeVM: ThemeViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = CalendarViewModel()
    @State private var viewMode: CalendarViewMode = .month

    enum CalendarViewMode: String, CaseIterable {
        case month = "Month"
        case week = "Week"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // View mode picker
                    Picker("View", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if viewMode == .month {
                        // Full month calendar
                        DatePicker(
                            "Select Date",
                            selection: $vm.selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                        .tint(.goPrimary)
                    } else {
                        // Week view - show just the current week
                        weekView
                    }

                    Divider()

                    // Events for selected date
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Schedule for \(vm.selectedDate, style: .date)")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        if vm.eventsForSelectedDate.isEmpty {
                            Text("No events for this date.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(vm.eventsForSelectedDate) { event in
                                        eventRow(event)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                }

                // FAB button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            vm.showAddEvent = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.goPrimary)
                                .clipShape(Circle())
                                .shadow(color: .goPrimary.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .goTopBar(showThemeToggle: false)
            .sheet(isPresented: $vm.showAddEvent) {
                addEventSheet
            }
            .task {
                vm.startListening()
            }
            .onAppear {
                Analytics.log(.calendarOpened)
            }
        }
    }

    @ViewBuilder
    private func eventRow(_ event: EventItem) -> some View {
        let category = event.resolvedCategory
        HStack(spacing: 10) {
            Image(systemName: category.iconName)
                .font(.subheadline)
                .foregroundColor(category.displayColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                HStack(spacing: 6) {
                    if event.source == "wizard" {
                        Text(category.displayLabel)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(category.displayColor.opacity(0.15))
                            .foregroundColor(category.displayColor)
                            .cornerRadius(4)
                    }
                    if event.notificationEnabled == true {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            // Wizard-emitted events are managed by re-running the wizard;
            // hide the delete button so users don't strand them.
            if event.source != "wizard" {
                Button {
                    vm.deleteEvent(event)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.goError)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var weekView: some View {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: vm.selectedDate)?.start ?? vm.selectedDate
        let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

        return VStack(spacing: 8) {
            HStack {
                Button {
                    if let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: vm.selectedDate) {
                        vm.selectedDate = prev
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.goPrimary)
                }

                Spacer()

                Text(vm.selectedDate, format: .dateTime.month(.wide).year())
                    .font(.headline)

                Spacer()

                Button {
                    if let next = calendar.date(byAdding: .weekOfYear, value: 1, to: vm.selectedDate) {
                        vm.selectedDate = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.goPrimary)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { day in
                    let isSelected = calendar.isDate(day, inSameDayAs: vm.selectedDate)
                    let hasEvents = vm.events.contains { calendar.isDate($0.date, inSameDayAs: day) }

                    Button {
                        vm.selectedDate = day
                    } label: {
                        VStack(spacing: 4) {
                            Text(day, format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(day, format: .dateTime.day())
                                .font(.subheadline.weight(isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : .primary)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? Color.goPrimary : Color.clear)
                                .clipShape(Circle())
                            if hasEvents {
                                Circle()
                                    .fill(Color.goPrimary)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var addEventSheet: some View {
        NavigationStack {
            Form {
                TextField("Event title", text: $vm.newEventTitle)
                DatePicker("Date", selection: $vm.selectedDate, displayedComponents: [.date])
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showAddEvent = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { vm.addEvent() }
                        .disabled(vm.newEventTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
