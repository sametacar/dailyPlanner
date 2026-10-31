//
//  TaskScheduleSheet.swift
//  dailyplanner
//

import SwiftUI

/// Single place to edit a task's start/end time (15-minute steps) and to
/// delete it. Keeping all of this off the timeline card itself means short
/// tasks never need to squeeze resize handles + a delete button onto a card
/// too small to fit them.
struct TaskScheduleSheet: View {
    let taskName: String
    let isValidRange: (Int, Int, Int, Int) -> Bool
    let onSave: (Int, Int, Int, Int) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int

    private let minuteOptions = [0, 15, 30, 45]

    init(
        taskName: String,
        initialStartHour: Int,
        initialStartMinute: Int,
        initialEndHour: Int,
        initialEndMinute: Int,
        isValidRange: @escaping (Int, Int, Int, Int) -> Bool,
        onSave: @escaping (Int, Int, Int, Int) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.taskName = taskName
        self.isValidRange = isValidRange
        self.onSave = onSave
        self.onDelete = onDelete
        _startHour = State(initialValue: initialStartHour)
        _startMinute = State(initialValue: initialStartMinute)
        _endHour = State(initialValue: initialEndHour)
        _endMinute = State(initialValue: initialEndMinute)
    }

    private var isValid: Bool {
        isValidRange(startHour, startMinute, endHour, endMinute)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("taskresize.starttime.title".localized) {
                    hourMinuteWheel(hour: $startHour, minute: $startMinute)
                }

                Section {
                    hourMinuteWheel(hour: $endHour, minute: $endMinute)
                } header: {
                    Text("taskresize.endtime.title".localized)
                } footer: {
                    if !isValid {
                        Text("taskresize.picker.conflict".localized)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(action: onDelete) {
                        HStack {
                            Spacer()
                            Label("taskschedule.button.remove".localized, systemImage: "calendar.badge.minus")
                                .foregroundStyle(.indigo)
                            Spacer()
                        }
                    }
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle(taskName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("taskadd.button.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("taskedit.button.save".localized) {
                        onSave(startHour, startMinute, endHour, endMinute)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.fraction(0.6)])
    }

    /// Shared hour/minute wheel row, used identically for the start and end
    /// time sections. Factored out (rather than duplicated inline) to keep
    /// the Form body simple enough for the compiler to type-check quickly.
    private func hourMinuteWheel(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Picker("", selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .pickerStyle(.wheel)

            Picker("", selection: minute) {
                ForEach(minuteOptions, id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 120)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(.systemBackground))
    }
}
