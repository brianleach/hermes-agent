# Hermes iOS

SwiftUI client for Hermes Agent. Phase 1: launch, chat, stream.

## Prerequisites

- macOS with Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- A running Hermes gateway exposing the OpenAI-compatible API (default port `8642`)

## Build & Run

```sh
cd apps/ios
xcodegen generate
open Hermes.xcodeproj
```

Pick a simulator and hit Run. The generated `Hermes.xcodeproj` is gitignored — regenerate anytime with `xcodegen generate`.

## Connecting to Hermes

On your host machine, start the API server:

```sh
hermes gateway start
# or run the API-only subcommand if available
```

Optional but recommended — set an API key before starting the gateway so the app can maintain a session across turns:

```sh
export API_SERVER_KEY="$(uuidgen)"
export API_SERVER_PORT=8642
hermes gateway start
```

In the iOS app, tap the gear icon and set:

- **Base URL**: `http://localhost:8642` (simulator) or `http://<your-mac-ip>:8642` (device on same LAN)
- **API Key**: the value you set for `API_SERVER_KEY` (leave blank if not using one)
- **Model**: `hermes-agent` (default)

> **Device builds on LAN**: iOS 14+ prompts for Local Network permission on first connection. The Info.plist already declares the required usage description.

## Architecture

- `Sources/HermesApp.swift` — `@main`; wires `SettingsStore` + `HermesClient` into the environment.
- `Sources/RootView.swift` — NavigationStack shell with Settings sheet + new-conversation button.
- `Sources/Chat/` — `ChatView`, `ChatViewModel` (@Observable, @MainActor), `Message`.
- `Sources/Networking/` — `HermesClient` (URLSession + `@MainActor`), `SSEParser`, OpenAI-compatible DTOs.
- `Sources/Settings/` — `SettingsStore` (UserDefaults + Keychain), `SettingsView`.

State lives in two `@Observable` classes owned by the `App`; views get them via `@Environment`.

## Phase 2 (planned)

- Model picker backed by `GET /v1/models`
- Markdown rendering (`swift-markdown-ui`)
- Tool-progress SSE events (`event: hermes.tool.progress`)
- Persistent conversation history (SwiftData)

## Phase 3 (planned)

- Share Extension (send URLs/photos to Hermes)
- Push notifications (APNs)
- Siri / App Intents
- TestFlight distribution (Fastlane)
