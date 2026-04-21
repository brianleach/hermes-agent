import Foundation

struct ChatMessageDTO: Codable, Sendable {
    let role: String
    let content: String
}

struct ChatCompletionsRequest: Encodable, Sendable {
    let model: String
    let messages: [ChatMessageDTO]
    let stream: Bool
}

struct ChatCompletionsChunk: Decodable, Sendable {
    struct Choice: Decodable, Sendable {
        let index: Int?
        let delta: Delta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case delta
            case finishReason = "finish_reason"
        }
    }

    struct Delta: Decodable, Sendable {
        let role: String?
        let content: String?
    }

    let id: String?
    let choices: [Choice]
}

enum ChatStreamEvent: Sendable {
    case sessionId(String)
    case delta(String)
    case done
}

enum HermesClientError: LocalizedError {
    case invalidBaseURL
    case httpError(status: Int, body: String?)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Invalid base URL. Set it in Settings."
        case .httpError(let status, let body):
            if let body, !body.isEmpty {
                return "Server error \(status): \(body)"
            }
            return "Server error \(status)"
        case .invalidResponse:
            return "Invalid server response."
        }
    }
}
