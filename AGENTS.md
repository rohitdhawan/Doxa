# NewDocGenieAI

iOS document management app with AI-powered features (summarize, ask, translate PDFs), document scanning, PDF tools, and file conversion. Built entirely with SwiftUI + SwiftData using Apple-native frameworks only.

- **Deployment Target:** iOS 17.0
- **Swift:** 6.0 (concurrency: minimal strictness)
- **Device:** iPhone only
- **Bundle ID:** com.newdocgenieai.app

## Build & Run

Uses **XcodeGen** for project generation. No external dependencies.

```bash
# Generate project (only needed if project.yml changes)
xcodegen generate

# Open in Xcode
open NewDocGenieAI.xcodeproj

# Or build from CLI
xcodebuild -project NewDocGenieAI.xcodeproj -scheme NewDocGenieAI -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Architecture

**MVVM** with `@Observable` (not ObservableObject/StateObject).

```
NewDocGenieAI/
├── App/                        # Entry point (NewDocGenieAIApp.swift), Info.plist
├── Core/
│   ├── DesignSystem/
│   │   ├── Components/         # Reusable UI (AppCard, PrimaryButton, SkeletonView, etc.)
│   │   └── Theme/              # AppColors, AppTypography, AppSpacing, AppEffects, AppAnimations
│   ├── Navigation/             # NavigationRouter, AppTab, AppTabView
│   ├── Extensions/             # Date+Formatting, String+FileExtension, Int64+FileSize
│   ├── Tips/                   # TipKit definitions
│   └── Utilities/              # Constants, AppIconGenerator
├── Features/{Feature}/
│   ├── Views/
│   ├── ViewModels/
│   └── Services/               # Feature-specific services (e.g., Chat/Services/AIService)
├── Models/                     # SwiftData models + enums (DocumentFile, ChatMessage, Conversation)
├── Services/                   # Shared services (FileStorageService, OCRService, PDFToolsService, etc.)
└── Representables/             # UIKit bridges (PDFKitView, DocumentCameraView, SignatureCanvasView)
```

## Design System

All UI tokens are in `Core/DesignSystem/Theme/`. **Always use existing tokens — do not create new ones.**

| File | Key Tokens |
|------|-----------|
| `AppColors` | `.appPrimary`, `.appAccent`, `.appBGCard`, `.appText`, `.appTextMuted`, gradients |
| `AppTypography` | `.appH1` (28), `.appH2` (22), `.appH3` (17), `.appBody` (15), `.appCaption` (13) |
| `AppSpacing` | `.xs` (4), `.sm` (8), `.md` (16), `.lg` (24), `.xl` (32), `.xxl` (48) |
| `AppEffects` | `.glassCard()`, `.glow()`, `.shimmer()` view modifiers |
| `AppAnimations` | `.springBounce`, `.springSmooth`, `.springQuick`, `.staggeredAppear(index:)` |

Colors are adaptive (light/dark) via UIColor traitCollection with hex values.

## Navigation

- `NavigationRouter` (`@Observable`) is injected as an environment object
- Tabs: `.chat`, `.tools`, `.files`, `.transfer`, `.settings` (defined in `AppTab` enum)
- Each tab has its own `NavigationPath` in the router
- Tab re-tap calls `resetCurrentTab()` to pop the stack
- `HapticManager` provides feedback on tab switches

## Services

- **Pattern:** Singleton via `static let shared`, marked `Sendable`
- `FileStorageService` — File import/delete/rename, stores **relative paths** for SwiftData
- `AIService` — Protocol-based (`AIResponseProvider`), FoundationModels (iOS 26+) with KeywordMatching fallback
- `OCRService`, `PDFToolsService`, `ScannerService`, `ConverterService`, `ThumbnailService`

## SwiftData Models

- `DocumentFile` — `@Attribute(.unique)` on `id`, stores `relativeFilePath`, computed `fileURL` and `category`
- `ChatMessage` — role-based (user/assistant/system), supports messageType variants (documentCard, processing, toolResult)
- `Conversation` — title + timestamps, linked to messages via conversationId

## Concurrency Patterns

- `@MainActor` on all ViewModels and UI-facing services
- `Sendable` on shared services
- Async work: `Task { @MainActor [weak self] in ... }`
- Swift concurrency strictness is set to `minimal`

## Naming Conventions

- ViewModels: `{Feature}ViewModel` (e.g., `ChatViewModel`, `FilesViewModel`)
- Services: `{Feature}Service` (e.g., `FileStorageService`, `OCRService`)
- Views: `{Screen}View` or `{Component}View`
- Models: PascalCase, no suffix
- Constants: `AppConstants` enum with static lets

## Rules

- **No external dependencies** — use only Apple-native frameworks
- **Use existing design tokens** — don't add new colors, fonts, or spacing values
- **Always use the ViewModel layer** — views should not contain business logic
- **Use @Observable** — not ObservableObject/@StateObject/@Published
- **Relative paths** — FileStorageService stores relative paths, not absolute
- **Supported file types** are defined in `AppConstants.supportedExtensions`
- **Max file size:** 500 MB (`AppConstants.maxFileSizeBytes`)
- **Security-scoped resources** — always call `startAccessingSecurityScopedResource()` with deferred `stopAccessing` when handling external files
