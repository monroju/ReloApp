#if canImport(SwiftUI)
import SwiftUI

struct CalendarView: View {

    @State private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector
                    calendarGrid
                    selectedDateHeader
                    eventsList
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.isEditorPresented) {
                EventEditorSheet(viewModel: viewModel)
            }
            .overlay(alignment: .bottom) { toastOverlay }
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthYearLabel)
                .font(.title3.bold())
                .contentTransition(.numericText())

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 4) {
            weekdayHeaders

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading blank cells
                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                    Color.clear.frame(height: 48)
                }

                ForEach(viewModel.daysInMonth, id: \.self) { date in
                    dayCell(date)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weekdayHeaders: some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let cal = Calendar.current
        let isSelected = cal.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = cal.isDateInToday(date)
        let hasEvents = viewModel.hasEvents(on: date)
        let count = viewModel.eventCount(on: date)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: date))")
                    .font(isToday ? .callout.bold() : .callout)
                    .foregroundStyle(dayForeground(isSelected: isSelected, isToday: isToday))

                if hasEvents {
                    HStack(spacing: 2) {
                        ForEach(0..<min(count, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? .white : .accent)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Spacer().frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.accentColor)
                    : isToday
                        ? AnyShapeStyle(Color.accentColor.opacity(0.12))
                        : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }

    private func dayForeground(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        return .primary
    }

    // MARK: - Selected Date Header

    private var selectedDateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDateFormatted)
                    .font(.headline)
                Text("\(viewModel.eventsForSelectedDate.count) event\(viewModel.eventsForSelectedDate.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.presentNewEvent()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Events List

    private var eventsList: some View {
        Group {
            if viewModel.eventsForSelectedDate.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.eventsForSelectedDate) { event in
                        eventCard(event)
                    }
                }
            }
        }
    }

    private func eventCard(_ event: EventItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(formattedTime(millis: event.dateMillis))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Menu {
                Button {
                    viewModel.presentEditEvent(event)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    viewModel.deleteEvent(event)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding()
        .frame(minHeight: 56)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No events")
                .font(.subheadline.bold())
            Text("Tap + to add an event for this day.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            Text(message)
                .font(.subheadline.bold())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThickMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { viewModel.dismissToast() }
                    }
                }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    viewModel.selectedDate = Date()
                    viewModel.displayedMonth = Date()
                }
            } label: {
                Text("Today")
                    .font(.subheadline.bold())
            }
        }
    }

    // MARK: - Formatting

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: viewModel.selectedDate)
    }

    private func formattedTime(millis: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Event Editor Sheet

struct EventEditorSheet: View {

    @Bindable var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $viewModel.editorTitle)
                        .autocorrectionDisabled()

                    TextField("Notes (optional)", text: $viewModel.editorNote, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Reminder") {
                    Toggle("Enable Reminder", isOn: $viewModel.editorReminderEnabled)

                    if viewModel.editorReminderEnabled {
                        HStack {
                            Picker("Hour", selection: $viewModel.editorReminderHour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .clipped()

                            Text(":")
                                .font(.title3.bold())

                            Picker("Minute", selection: $viewModel.editorReminderMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .clipped()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(viewModel.editingEvent == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveEvent()
                    }
                    .bold()
                    .disabled(viewModel.editorTitle.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
}

#endif
