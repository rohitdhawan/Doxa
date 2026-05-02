# NewDocGenieAI

NewDocGenieAI is an iPhone document management app built with SwiftUI, SwiftData, and Apple-native frameworks. The app helps users import, scan, organize, view, convert, and edit documents, with AI-powered document tools for summarizing, asking questions, and translation.

The app display name is **Doxa** and the bundle identifier is `com.newdocgenieai.app`.

## Features

- Document import and local file management
- PDF viewing, thumbnails, search, and page navigation
- Document scanning with review, filters, page management, and PDF export
- AI document workflows for asking questions, summarizing PDFs, and translating PDFs
- PDF tools including merge, split, compress, rotate, crop, reorder, extract pages, watermark, sign, lock, unlock, OCR, page numbers, metadata editing, and email
- File conversion tools for image-to-PDF, document-to-PDF, PDF-to-text, and PDF-to-image
- Chat interface with document cards, attachments, voice input, processing states, and tool results
- Nearby transfer workflow using local networking
- SwiftData-backed document, chat message, and conversation models

## Tech Stack

- iOS 17.0+
- Swift 6.0
- SwiftUI
- SwiftData
- PDFKit, VisionKit, UniformTypeIdentifiers, TipKit, and other Apple-native frameworks
- XcodeGen for project generation
- No external dependencies

## Requirements

- Xcode 26.0 or newer
- XcodeGen installed locally
- iPhone simulator or physical iPhone

## Build And Run

Generate the Xcode project after changing `project.yml`:

```bash
xcodegen generate
```

Open the project in Xcode:

```bash
open NewDocGenieAI.xcodeproj
```

Build from the command line:

```bash
xcodebuild -project NewDocGenieAI.xcodeproj -scheme NewDocGenieAI -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Project Structure

```text
NewDocGenieAI/
├── App/                        # App entry point, Info.plist, launch screen
├── Core/
│   ├── DesignSystem/           # Shared UI components and design tokens
│   ├── Navigation/             # Tab and navigation routing
│   ├── Extensions/             # Formatting and convenience extensions
│   ├── Tips/                   # TipKit definitions
│   └── Utilities/              # Constants and app utilities
├── Features/
│   ├── AITools/                # Ask, summarize, and translate PDF workflows
│   ├── Chat/                   # Chat UI, view model, and AI providers
│   ├── Converter/              # File conversion screens
│   ├── Files/                  # File list, categories, details, and actions
│   ├── Import/                 # File import UI
│   ├── PDFTools/               # PDF editing and processing tools
│   ├── PDFViewer/              # Advanced PDF viewer tools
│   ├── Scanner/                # Document scanning and review
│   ├── Settings/               # Settings and tip jar
│   ├── Tools/                  # Tool catalog
│   ├── Transfer/               # Nearby file transfer
│   └── Viewer/                 # Document viewer routing
├── Models/                     # SwiftData models and app enums
├── Services/                   # Shared document, OCR, PDF, conversion, and sharing services
└── Representables/             # UIKit and framework bridges
```

## Architecture

The app follows MVVM with Swift's `@Observable` macro. Views stay focused on presentation, while business logic belongs in view models and services.

- View models are marked `@MainActor`
- Shared services use singleton instances via `static let shared`
- Shared services are marked `Sendable`
- SwiftData stores `DocumentFile`, `ChatMessage`, and `Conversation`
- File storage keeps relative paths instead of absolute paths
- Each tab owns its own `NavigationPath` through `NavigationRouter`

## Design System

Use the existing design tokens in `NewDocGenieAI/Core/DesignSystem/Theme/`.

- `AppColors` for adaptive colors and gradients
- `AppTypography` for text styles
- `AppSpacing` for layout spacing
- `AppEffects` for glass, glow, and shimmer modifiers
- `AppAnimations` for spring and staggered animations

Do not add new colors, typography scales, spacing constants, or animation styles unless the design system itself is being intentionally updated.

## Supported Files

Supported extensions are defined in `AppConstants.supportedExtensions`:

```text
pdf, doc, docx, xls, xlsx, ppt, pptx,
txt, csv, xml, rtf,
jpg, jpeg, png, heic, webp, bmp, gif, tiff
```

The maximum supported file size is 500 MB.

## Development Rules

- Use Apple-native frameworks only.
- Keep UI code on the existing design system.
- Use `@Observable`, not `ObservableObject`, `@StateObject`, or `@Published`.
- Keep business logic in view models and services.
- Store relative file paths through `FileStorageService`.
- Use `AppConstants.supportedExtensions` for supported file checks.
- Always pair `startAccessingSecurityScopedResource()` with deferred `stopAccessingSecurityScopedResource()` when handling external files.
- Regenerate the Xcode project with XcodeGen after changing `project.yml`.

## App Store Assets

The repository includes App Store support files:

- `AppStorePrivacy/` for privacy policy documents
- `AppStoreScreenshots/` for screenshot assets
- `Configurations/Doxa.storekit` for StoreKit testing
