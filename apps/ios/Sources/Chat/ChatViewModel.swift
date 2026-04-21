import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var errorMessage: String?
    private(set) var sessionId: String?

    private let client: HermesClient
    private var currentTask: Task<Void, Never>?

    init(client: HermesClient) {
        self.client = client
    }

    func send() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        inputText = ""
        errorMessage = nil

        messages.append(Message(role: .user, content: trimmed))
        messages.append(Message(role: .assistant, content: "", isStreaming: true))
        let assistantIndex = messages.count - 1

        let outbound = messages
            .dropLast()
            .map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) }
        let priorSessionId = sessionId

        isStreaming = true

        currentTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isStreaming = false }

            do {
                let stream = try await self.client.streamChatCompletion(
                    messages: outbound,
                    sessionId: priorSessionId
                )
                for try await event in stream {
                    switch event {
                    case .sessionId(let id):
                        self.sessionId = id
                    case .delta(let text):
                        guard assistantIndex < self.messages.count else { continue }
                        self.messages[assistantIndex].content += text
                    case .done:
                        if assistantIndex < self.messages.count {
                            self.messages[assistantIndex].isStreaming = false
                        }
                        return
                    }
                }
                if assistantIndex < self.messages.count {
                    self.messages[assistantIndex].isStreaming = false
                }
            } catch is CancellationError {
                if assistantIndex < self.messages.count {
                    self.messages[assistantIndex].isStreaming = false
                }
            } catch {
                if assistantIndex < self.messages.count {
                    self.messages[assistantIndex].isStreaming = false
                    if self.messages[assistantIndex].content.isEmpty {
                        self.messages.remove(at: assistantIndex)
                    }
                }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func cancelStreaming() {
        currentTask?.cancel()
    }

    func newConversation() {
        cancelStreaming()
        messages.removeAll()
        sessionId = nil
        errorMessage = nil
    }
}
