import Foundation
import Observation

@MainActor
@Observable
final class HermesClient {
    private let settings: SettingsStore
    private let session: URLSession

    init(settings: SettingsStore, session: URLSession = .shared) {
        self.settings = settings
        self.session = session
    }

    func streamChatCompletion(
        messages: [ChatMessageDTO],
        sessionId: String?
    ) async throws -> AsyncThrowingStream<ChatStreamEvent, Error> {
        guard let base = settings.baseURL,
              var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else {
            throw HermesClientError.invalidBaseURL
        }
        let trimmedPath = components.path.hasSuffix("/")
            ? String(components.path.dropLast())
            : components.path
        components.path = trimmedPath + "/v1/chat/completions"
        guard let url = components.url else { throw HermesClientError.invalidBaseURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let key = settings.apiKey, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        if let sessionId, !sessionId.isEmpty {
            request.setValue(sessionId, forHTTPHeaderField: "X-Hermes-Session-Id")
        }

        let body = ChatCompletionsRequest(
            model: settings.model,
            messages: messages,
            stream: true
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HermesClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            var errBody = ""
            for try await line in bytes.lines {
                errBody += line
                if errBody.count > 2000 { break }
            }
            throw HermesClientError.httpError(
                status: http.statusCode,
                body: errBody.isEmpty ? nil : errBody
            )
        }

        let returnedSessionId = http.value(forHTTPHeaderField: "X-Hermes-Session-Id")
        let sseStream = SSEParser.stream(from: bytes)

        return AsyncThrowingStream<ChatStreamEvent, Error> { continuation in
            let task = Task {
                do {
                    if let returnedSessionId, !returnedSessionId.isEmpty {
                        continuation.yield(.sessionId(returnedSessionId))
                    }
                    for try await frame in sseStream {
                        switch frame {
                        case .done:
                            continuation.yield(.done)
                        case .event(_, let data):
                            guard let jsonData = data.data(using: .utf8) else { continue }
                            do {
                                let chunk = try JSONDecoder().decode(
                                    ChatCompletionsChunk.self,
                                    from: jsonData
                                )
                                if let text = chunk.choices.first?.delta.content, !text.isEmpty {
                                    continuation.yield(.delta(text))
                                }
                                if chunk.choices.first?.finishReason != nil {
                                    continuation.yield(.done)
                                }
                            } catch {
                                // Ignore unrecognized chunks (tool-progress events, pings, etc.)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
