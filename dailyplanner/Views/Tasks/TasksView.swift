//
//  TasksView.swift
//  dailyplanner
//
//  Created by vili on 22.01.2026.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var tasks: [TaskModel]
    @Binding var isVisible: Bool
    @State private var showAddSheet = false
    @State private var isEditMode = false
    @State private var taskToEdit: TaskModel?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(Color.dpPrimaryText)
                }
                .padding(.trailing, 8)

                if !tasks.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditMode.toggle()
                        }
                    }) {
                        Image(systemName: isEditMode ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver")
                            .font(.title2)
                            .foregroundStyle(isEditMode ? Color.cyan : Color.dpPrimaryText)
                    }
                }

                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isVisible.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.right")
                        .font(.title3)
                        .foregroundStyle(Color.dpPrimaryText)
                }
            }
            .padding()
            .background(Color.dpAppBackground)

            Divider()

            // Tasks List - Draggable items
            if tasks.isEmpty {
                VStack {
                    Spacer()
                    Text("tasks.empty.message".localized)
                        .foregroundStyle(Color.gray)
                        .padding(8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tasks) { task in
                            TaskItem(
                                task: task,
                                isEditMode: isEditMode,
                                onEdit: {
                                    taskToEdit = task
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            TaskAddSheetView()
                .environment(themeManager)
                .id(themeManager.language.rawValue)
        }
        .sheet(item: $taskToEdit) { task in
            TaskAddSheetView(taskToEdit: task)
                .environment(themeManager)
                .id(themeManager.language.rawValue)
        }
        .onChange(of: taskToEdit) { _, newValue in
            if newValue == nil {
                isEditMode = false
            }
        }
    }
}

struct TaskItem: View {
    let task: TaskModel
    let isEditMode: Bool
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Text(task.name)
                .font(.system(.body, design: .default))
                .fontWeight(.semibold)
                .foregroundStyle(.black.opacity(0.74))
            Spacer()
            if let icon = task.icon {
                Text(icon)
            }

            if isEditMode {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.black.opacity(0.5))
            }
        }
        .padding()
        .background(Color(hex: task.color))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditMode {
                onEdit()
            }
        }
        .draggable(TaskTransfer(
            id: task.id,
            name: task.name,
            desc: task.desc,
            color: task.color,
            icon: task.icon
        ))
    }
}

// #Preview {
//    TasksView()
// }
