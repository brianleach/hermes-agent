import SwiftUI

struct RootView: View {
    @Environment(HermesClient.self) private var client
    @State private var viewModel: ChatViewModel?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    ChatView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Hermes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel?.newConversation()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(viewModel == nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                if viewModel == nil {
                    viewModel = ChatViewModel(client: client)
                }
            }
        }
    }
}
