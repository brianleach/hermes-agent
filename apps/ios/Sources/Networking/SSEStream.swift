import Foundation

enum SSEFrame: Sendable {
    case event(name: String?, data: String)
    case done
}

enum SSEParser {
    static func stream(
        from bytes: URLSession.AsyncBytes
    ) -> AsyncThrowingStream<SSEFrame, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var eventName: String?
                    var dataBuffer = ""

                    func flush() {
                        guard !dataBuffer.isEmpty else { return }
                        if dataBuffer == "[DONE]" {
                            continuation.yield(.done)
                        } else {
                            continuation.yield(.event(name: eventName, data: dataBuffer))
                        }
                        eventName = nil
                        dataBuffer = ""
                    }

                    for try await line in bytes.lines {
                        if line.isEmpty {
                            flush()
                            continue
                        }
                        if line.hasPrefix(":") { continue } // comment / keepalive
                        if line.hasPrefix("event:") {
                            eventName = line
                                .dropFirst("event:".count)
                                .trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let chunk = line.dropFirst("data:".count)
                            let trimmed = chunk.first == " " ? String(chunk.dropFirst()) : String(chunk)
                            if dataBuffer.isEmpty {
                                dataBuffer = trimmed
                            } else {
                                dataBuffer += "\n" + trimmed
                            }
                        }
                    }
                    flush()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
