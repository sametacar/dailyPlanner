import Foundation
import Combine
import SwiftUI

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
}
