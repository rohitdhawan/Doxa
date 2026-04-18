import TipKit

struct TryAIToolsTip: Tip {
    static let toolsTabVisited = Event(id: "toolsTabVisited")

    var title: Text {
        Text("Try the AI Tools")
    }
    var message: Text? {
        Text("Summarize PDFs, ask questions about documents, and translate content — powered by on-device AI.")
    }
    var image: Image? {
        Image(systemName: "brain")
    }

    var rules: [Rule] {
        #Rule(Self.toolsTabVisited) { event in
            event.donations.count == 1
        }
    }
}

struct ChatWelcomeTip: Tip {
    static let chatTabVisited = Event(id: "chatTabVisited")

    var title: Text {
        Text("Ask Me Anything")
    }
    var message: Text? {
        Text("I can scan documents, merge PDFs, extract text, and more. Just describe what you need.")
    }
    var image: Image? {
        Image(systemName: "bubble.left.and.bubble.right.fill")
    }

    var rules: [Rule] {
        #Rule(Self.chatTabVisited) { event in
            event.donations.count == 1
        }
    }
}

struct ScanCompleteTip: Tip {
    static let scanCompleted = Event(id: "scanCompleted")

    var title: Text {
        Text("Scan Saved!")
    }
    var message: Text? {
        Text("Your scanned PDF is now in the Files tab. Tap Files to view, share, or edit it.")
    }
    var image: Image? {
        Image(systemName: "doc.on.doc")
    }

    var rules: [Rule] {
        #Rule(Self.scanCompleted) { event in
            event.donations.count == 1
        }
    }
}
