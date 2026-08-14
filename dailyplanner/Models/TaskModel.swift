import Foundation
import SwiftData
import CoreTransferable
import UniformTypeIdentifiers

@Model
class TaskModel: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var desc: String
    var color: String
    var icon: String?

    init(name: String, desc: String, color: String, icon: String?) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.color = color
        self.icon = icon
    }
}

extension TaskModel: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { task in
            TaskTransfer(id: task.id, name: task.name, desc: task.desc, color: task.color, icon: task.icon)
        }
    }
}

struct TaskTransfer: Codable, Transferable {
    let id: UUID
    let name: String
    let desc: String
    let color: String
    let icon: String?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}
