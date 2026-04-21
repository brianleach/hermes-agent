import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            if let err = viewModel.errorMessage {
                errorBanner(err)
            }
            composer
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        Text("Say hi to Hermes.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.last?.id) { _, newId in
                guard let newId else { return }
                withAnimation { proxy.scrollTo(newId, anchor: .bottom) }
            }
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                guard let id = viewModel.messages.last?.id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .bottom) }
            }
        }
    }

    private func errorBanner(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.85))
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message Hermes…", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .submitLabel(.send)

            Button {
                if viewModel.isStreaming {
                    viewModel.cancelStreaming()
                } else {
                    viewModel.send()
                }
            } label: {
                Image(systemName: viewModel.isStreaming ? "stop.fill" : "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(sendButtonColor)
                    .clipShape(Circle())
            }
            .disabled(sendButtonDisabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var sendButtonColor: Color {
        if viewModel.isStreaming { return .red }
        return sendButtonDisabled ? .gray : .accentColor
    }

    private var sendButtonDisabled: Bool {
        !viewModel.isStreaming &&
            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            bubbleBody
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if message.role != .user { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var bubbleBody: some View {
        if message.content.isEmpty && message.isStreaming {
            TypingIndicator()
        } else {
            Text(message.content)
                .textSelection(.enabled)
                .foregroundStyle(message.role == .user ? .white : .primary)
        }
    }

    private var background: Color {
        switch message.role {
        case .user: return .accentColor
        case .assistant: return Color(.secondarySystemBackground)
        case .system: return Color(.tertiarySystemBackground)
        }
    }
}

struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let dots = 3

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dots, id: \.self) { i in
                Circle()
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1.0 : 0.3)
            }
        }
        .foregroundStyle(.secondary)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                phase = (phase + 1) % dots
            }
        }
    }
}
