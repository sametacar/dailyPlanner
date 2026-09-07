//
//  TaskAddSheetView.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI
import SwiftData

struct TaskAddSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let taskToEdit: TaskModel?

    @State private var name: String = ""
    @State private var color: String = "#4A90E2"
    @State private var icon: String?
    @State private var showDeleteConfirmation = false

    init(taskToEdit: TaskModel? = nil) {
        self.taskToEdit = taskToEdit
        _name = State(initialValue: taskToEdit?.name ?? "")
        _color = State(initialValue: taskToEdit?.color ?? "#4A90E2")
        _icon = State(initialValue: taskToEdit?.icon)
    }

    let availableColors = [
        "#85B8FF", // Pastel Blue
        "#80DB9E", // Pastel Green (mint)
        "#FF9EB3", // Pastel Pink
        "#FFC7AD", // Pastel Peach
        "#CC9EFF", // Pastel Purple (lavender)
        "#FFB3D9", // Pastel Rose
        "#80E5F0", // Pastel Cyan
        "#FFE699", // Pastel Yellow
        "#B5E7A0", // Pastel Lime
        "#B0C4DE", // Pastel Periwinkle
        "#FFA587", // Pastel Coral
        "#7FD9CC"  // Pastel Teal
    ]

    let availableIcons = [
        // Spor
        "dumbbell.fill", "bicycle", "figure.run", "figure.pool.swim",
        // Çalışma
        "book.fill", "laptopcomputer", "briefcase.fill", "brain.head.profile.fill",
        // Dinlenme
        "cup.and.saucer.fill", "pawprint.fill", "leaf.fill", "music.note",
        "gamecontroller.fill", "film.fill", "tv.fill", "person.2.fill",
        // Diğer
        "moon.stars.fill", "fork.knife", "cart.fill", "shower.fill", "frying.pan.fill",
        "figure.mind.and.body", "hands.and.sparkles.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("taskadd.section.details".localized) {
                    TextField("taskadd.field.name".localized, text: $name)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > 30 {
                                name = String(newValue.prefix(30))
                            }
                        }
                }

                Section("taskadd.section.appearance".localized) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("taskadd.label.color".localized)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableColors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: color == colorHex ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        color = colorHex
                                    }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("taskadd.field.icon".localized)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                            IconPickerCell(systemName: "circle.slash", isSelected: icon == nil, selectedColor: color) {
                                icon = nil
                            }

                            ForEach(availableIcons, id: \.self) { iconName in
                                IconPickerCell(systemName: iconName, isSelected: icon == iconName, selectedColor: color) {
                                    icon = iconName
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                if taskToEdit != nil {
                    Section {
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Label("taskedit.button.delete".localized, systemImage: "trash")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(taskToEdit == nil ? "taskadd.title".localized : "taskedit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("taskadd.button.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(taskToEdit == nil ? "taskadd.button.add".localized : "taskedit.button.save".localized) {
                        saveTask()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                if let task = taskToEdit {
                    DeleteConfirmationSheet(
                        taskName: task.name,
                        onConfirm: {
                            modelContext.delete(task)
                            dismiss()
                        },
                        onCancel: {
                            showDeleteConfirmation = false
                        }
                    )
                    .presentationDetents([.height(260)])
                }
            }
        }
    }

    private func saveTask() {
        if let task = taskToEdit {
            // Edit existing task
            task.name = name
            task.color = color
            task.icon = icon

            // Save TaskModel changes first
            do {
                try modelContext.save()
            } catch {
                print("Failed to save TaskModel: \(error)")
            }

            // Update all related DayTasks asynchronously
            Task { @MainActor in
                await updateRelatedDayTasks(taskId: task.id, newName: name, newColor: color, newIcon: icon)
                dismiss()
            }
        } else {
            // Add new task
            let task = TaskModel(
                name: name,
                desc: "",
                color: color,
                icon: icon
            )
            modelContext.insert(task)
            dismiss()
        }
    }

    @MainActor
    private func updateRelatedDayTasks(taskId: UUID, newName: String, newColor: String, newIcon: String?) async {
        // Fetch all DayTasks that were created from this TaskModel
        let descriptor = FetchDescriptor<DayTaskModel>(
            predicate: #Predicate { $0.taskId == taskId }
        )

        do {
            let relatedDayTasks = try modelContext.fetch(descriptor)

            print("Found \(relatedDayTasks.count) related DayTasks to update")

            // Update each related DayTask
            for dayTask in relatedDayTasks {
                dayTask.name = newName
                dayTask.color = newColor
                dayTask.icon = newIcon
            }

            try modelContext.save()
            print("Successfully updated related DayTasks")
        } catch {
            print("Failed to update related DayTasks: \(error)")
        }
    }
}

struct IconPickerCell: View {
    let systemName: String
    let isSelected: Bool
    let selectedColor: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let cellSize: CGFloat = 60

    private var unselectedBackground: Color {
        colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.91)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isSelected ? 26 : 22, weight: .semibold))
                .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.9))
                .frame(width: cellSize, height: cellSize)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color(hex: selectedColor) : unselectedBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isSelected ? 0.5 : 0), lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.06 : 1.0)
                .shadow(
                    color: isSelected ? Color(hex: selectedColor).opacity(0.5) : .clear,
                    radius: 8, x: 0, y: 4
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

struct DeleteConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let taskName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)

                Text("delete.confirmation.title".localized(with: taskName))
                    .font(.headline)
                    .foregroundStyle(Color.dpPrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal)
            }
            .padding(.top)

            HStack(spacing: 12) {
                Button(action: {
                    onCancel()
                    dismiss()
                }) {
                    Text("delete.button.cancel".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.dpCardBackground)
                        .foregroundStyle(Color.dpPrimaryText)
                        .cornerRadius(10)
                }

                Button(action: {
                    onConfirm()
                    dismiss()
                }) {
                    Text("delete.button.delete".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.dpAppBackground)
    }
}
