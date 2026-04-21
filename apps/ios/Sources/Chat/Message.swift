import Foundation

struct Message: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var content: String
    var isStreaming: Bool
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        isStreaming: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
        self.timestamp = timestamp
    }
}
