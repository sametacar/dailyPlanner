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
    @State private var showDeleteConfirmation = false

    init(taskToEdit: TaskModel? = nil) {
        self.taskToEdit = taskToEdit
        _name = State(initialValue: taskToEdit?.name ?? "")
        _color = State(initialValue: taskToEdit?.color ?? "#4A90E2")
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
        "#B0C4DE"  // Pastel Periwinkle
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

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ForEach(availableColors.prefix(5), id: \.self) { colorHex in
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

                            HStack(spacing: 12) {
                                ForEach(availableColors.suffix(5), id: \.self) { colorHex in
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
                    }
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

            // Save TaskModel changes first
            do {
                try modelContext.save()
            } catch {
                print("Failed to save TaskModel: \(error)")
            }

            // Update all related DayTasks asynchronously
            Task { @MainActor in
                await updateRelatedDayTasks(taskId: task.id, newName: name, newColor: color)
                dismiss()
            }
        } else {
            // Add new task
            let task = TaskModel(
                name: name,
                desc: "",
                color: color,
                icon: nil
            )
            modelContext.insert(task)
            dismiss()
        }
    }

    @MainActor
    private func updateRelatedDayTasks(taskId: UUID, newName: String, newColor: String) async {
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
            }

            try modelContext.save()
            print("Successfully updated related DayTasks")
        } catch {
            print("Failed to update related DayTasks: \(error)")
        }
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
