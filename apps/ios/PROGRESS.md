# Hermes iOS — Progress

Legend: ✅ done · 🟡 in progress · ⬜ not started

## Phase 1 — MVP (launch + chat)

_Goal: can launch the app and hold a streaming conversation with a local Hermes gateway._

- ✅ XcodeGen `project.yml` + iOS 18 / Swift 6 / SwiftUI baseline
- ✅ App shell: `HermesApp`, `RootView`, toolbar (new convo, settings sheet)
- ✅ `ChatView` + `MessageBubble` + `TypingIndicator` + composer
- ✅ `@Observable` `ChatViewModel` with streaming assistant message appending
- ✅ `HermesClient` targeting `POST /v1/chat/completions` (OpenAI-compatible)
- ✅ SSE parser (`SSEParser`) with `[DONE]` handling + multi-line `data:` support
- ✅ `X-Hermes-Session-Id` capture + replay for multi-turn continuity
- ✅ `SettingsStore` (UserDefaults for base URL + model, Keychain for API key)
- ✅ `SettingsView` form
- ✅ Info.plist: `NSAllowsLocalNetworking` + `NSLocalNetworkUsageDescription`
- ✅ Sim build + launch verified (iPhone 17 Pro, iOS 26.4)
- ⬜ End-to-end verified against a running `hermes gateway start` (user to confirm)

## Phase 2 — Quality-of-life

_Goal: feels like a real chat app, not a demo._

- ⬜ Model picker backed by `GET /v1/models`
- ⬜ Markdown rendering (likely `swift-markdown-ui`)
- ⬜ Tool-progress SSE events (`event: hermes.tool.progress`) surfaced inline
- ⬜ Conversation history persisted (SwiftData) with session list + resume
- ⬜ Swipe-to-delete / rename conversations
- ⬜ App icon + launch screen polish
- ⬜ Empty-state & error-state visual design pass
- ⬜ Migrate transport to @OutThisLife's WS + JSON-RPC (PR #12710) if it lands — evaluate once merged

## Phase 3 — Ambient-agent surfaces

_Goal: reasons to install the app instead of using Telegram._

- ⬜ **Share Extension** — send URL / text / image to Hermes from any app
- ⬜ **APNs push notifications** — proactive agent messages, cron deliveries
- ⬜ **Siri / App Intents** — "Hey Siri, ask Hermes to …"
- ⬜ Voice input (AVFoundation + streaming STT)
- ⬜ Live Activity for long-running agent runs
- ⬜ Lock-screen / home-screen widget (latest output, quick-glance status)
- ⬜ Fastlane + TestFlight distribution
- ⬜ Extract shared `HermesKit` Swift package under `apps/shared/` if code reuse appears

## Out of scope (for now)

- Android parity — Hermes's Telegram / Signal / Discord gateways already serve Android well
- Apple Watch companion
- mDNS / Bonjour gateway discovery (deferred until a real LAN-server use case appears)
- macOS catalyst build

## Decisions log

- **2026-04-20** — Native SwiftUI chosen over Expo / React Native. Rationale: two of three must-have features (Share Extension, Siri) are iOS-paradigm-heavy and punish RN; push notifications are easy on both; the cross-platform upside is muted because Hermes already has first-class Android surfaces via the messaging gateway.
- **2026-04-20** — MVP targets existing `/v1/chat/completions` SSE endpoint rather than @OutThisLife's in-flight WS + JSON-RPC transport (PR #12710). Rationale: stable now, migrate later if/when that lands. Protocol re-work is localized to `HermesClient` + `ChatTypes`.
- **2026-04-20** — Swift 6 with `SWIFT_STRICT_CONCURRENCY: minimal` for the first build. Will crank to `complete` once warnings are stable.

## Open questions

- Bundle ID — currently `com.brianleach.hermes`. Fine for now; revisit before TestFlight.
- Deployment target — iOS 18. Drop to 17 if broader device reach matters.
- Where does the gateway typically live for the primary user — localhost, LAN server, or cloud VPS? Affects whether mDNS discovery earns its keep.
