import Foundation

enum ScanContentType: String {
    case receipt
    case letter
    case form
    case textHeavy
    case imageHeavy
    case unknown

    static func classify(ocrText: String) -> ScanContentType {
        let lower = ocrText.lowercased()
        let wordCount = ocrText.split(separator: " ").count

        let receiptKeywords = ["total", "subtotal", "tax", "receipt", "invoice",
                               "payment", "amount due", "balance", "$", "price"]
        if receiptKeywords.filter({ lower.contains($0) }).count >= 3 { return .receipt }

        let formKeywords = ["name:", "date:", "address:", "signature", "phone:",
                            "email:", "[ ]", "[x]", "please fill", "form"]
        if formKeywords.filter({ lower.contains($0) }).count >= 3 { return .form }

        let letterKeywords = ["dear ", "sincerely", "regards", "to whom",
                              "re:", "subject:"]
        if letterKeywords.filter({ lower.contains($0) }).count >= 2 { return .letter }

        if wordCount > 50 { return .textHeavy }
        if wordCount < 10 { return .imageHeavy }

        return .unknown
    }

    var displayLabel: String {
        switch self {
        case .receipt: return "Receipt / Invoice"
        case .letter: return "Letter / Correspondence"
        case .form: return "Form / Application"
        case .textHeavy: return "Text Document"
        case .imageHeavy: return "Image / Photo"
        case .unknown: return "Document"
        }
    }

    var displayIcon: String {
        switch self {
        case .receipt: return "creditcard"
        case .letter: return "envelope"
        case .form: return "doc.text"
        case .textHeavy: return "doc.plaintext"
        case .imageHeavy: return "photo"
        case .unknown: return "doc"
        }
    }

    /// Generate a brief auto-summary from OCR text based on content type
    func generateAutoSummary(ocrText: String) -> String {
        let wordCount = ocrText.split(separator: " ").count
        let sentences = ocrText.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 10 }

        switch self {
        case .receipt:
            var summary = "This looks like a **\(displayLabel)**."
            // Try to find total amount
            if let amountRange = ocrText.range(of: #"\$[\d,]+\.?\d*"#, options: .regularExpression) {
                let amount = String(ocrText[amountRange])
                summary += " Amount found: **\(amount)**."
            }
            summary += " \(wordCount) words detected."
            if let firstLine = sentences.first {
                summary += "\n\n> \(String(firstLine.prefix(120)))..."
            }
            return summary

        case .letter:
            var summary = "This looks like a **\(displayLabel)** with ~\(wordCount) words."
            if let firstLine = sentences.first {
                summary += "\n\n> \(String(firstLine.prefix(150)))"
            }
            return summary

        case .form:
            var summary = "This looks like a **\(displayLabel)**."
            let fieldCount = ocrText.components(separatedBy: ":").count - 1
            if fieldCount > 1 {
                summary += " Found approximately \(fieldCount) fields."
            }
            summary += " \(wordCount) words detected."
            return summary

        case .textHeavy:
            var summary = "**\(displayLabel)** — ~\(wordCount) words detected."
            if sentences.count >= 2 {
                summary += "\n\nKey content:"
                for sentence in sentences.prefix(3) {
                    summary += "\n- \(String(sentence.prefix(120)))"
                }
            }
            return summary

        case .imageHeavy:
            return "This appears to be mostly an **image** with minimal text (\(wordCount) words)."

        case .unknown:
            var summary = "Scanned **document** — \(wordCount) words detected."
            if let firstLine = sentences.first {
                summary += "\n\n> \(String(firstLine.prefix(150)))"
            }
            return summary
        }
    }

    var suggestedActions: [(toolType: String, label: String, icon: String)] {
        switch self {
        case .receipt:
            return [
                ("ocr", "Extract Details", "text.viewfinder"),
                ("summarize", "Full Summary", "doc.text.magnifyingglass"),
                ("compress", "Compress PDF", "arrow.down.doc"),
            ]
        case .letter:
            return [
                ("ocr", "Extract Text", "text.viewfinder"),
                ("summarize", "Full Summary", "doc.text.magnifyingglass"),
                ("compress", "Compress PDF", "arrow.down.doc"),
            ]
        case .form:
            return [
                ("ocr", "Extract Fields", "text.viewfinder"),
                ("compress", "Compress PDF", "arrow.down.doc"),
                ("watermark", "Add Watermark", "drop.triangle"),
            ]
        case .textHeavy:
            return [
                ("ocr", "Extract Text", "text.viewfinder"),
                ("summarize", "Full Summary", "doc.text.magnifyingglass"),
                ("compress", "Compress PDF", "arrow.down.doc"),
            ]
        case .imageHeavy:
            return [
                ("compress", "Compress PDF", "arrow.down.doc"),
                ("watermark", "Add Watermark", "drop.triangle"),
            ]
        case .unknown:
            return [
                ("ocr", "Extract Text", "text.viewfinder"),
                ("summarize", "Full Summary", "doc.text.magnifyingglass"),
                ("compress", "Compress PDF", "arrow.down.doc"),
            ]
        }
    }
}
