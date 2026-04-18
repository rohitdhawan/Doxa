import SwiftUI
import SwiftData
import TipKit

@main
struct NewDocGenieAIApp: App {
    @AppStorage("themeMode") private var themeModeRaw = "system"

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(
                    red: 13.0 / 255.0,
                    green: 17.0 / 255.0,
                    blue: 23.0 / 255.0
                )
                    .ignoresSafeArea()

                AppTabView()
            }
            .preferredColorScheme(themeMode.colorScheme)
            .task {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
        }
        .modelContainer(for: [DocumentFile.self, ChatMessage.self, Conversation.self])
    }
}
