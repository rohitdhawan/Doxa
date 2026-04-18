import SwiftUI

enum ToolItem: String, CaseIterable, Identifiable {
    // Scanner
    case scanner = "Scanner"
    // PDF Tools
    case mergePDF = "Merge PDF"
    case splitPDF = "Split PDF"
    case compressPDF = "Compress"
    case lockPDF = "Lock PDF"
    case unlockPDF = "Unlock PDF"
    case extractPages = "Extract Pages"
    case rotatePDF = "Rotate PDF"
    case reorderPDF = "Reorder Pages"
    case pageNumbers = "Page Numbers"
    case watermark = "Watermark"
    case ocrText = "OCR Text"
    case signPDF = "Sign PDF"
    case cropPDF = "Crop PDF"
    case metadataEditor = "PDF Metadata"
    // Converters
    case imageToPDF = "Image to PDF"
    case docToPDF = "Doc to PDF"
    case pdfToImage = "PDF to Image"
    case pdfToText = "PDF to Text"
    // AI Tools
    case summarizePDF = "Summarize PDF"
    case askPDF = "Ask PDF"
    case translatePDF = "Translate PDF"
    // Viewer
    case pdfViewer = "PDF Viewer"
    // Utilities
    case emailPDF = "Email PDF"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .scanner: return "doc.viewfinder"
        case .mergePDF: return "doc.on.doc.fill"
        case .splitPDF: return "scissors"
        case .compressPDF: return "arrow.down.doc"
        case .lockPDF: return "lock.doc"
        case .unlockPDF: return "lock.open"
        case .extractPages: return "doc.badge.plus"
        case .rotatePDF: return "rotate.right"
        case .reorderPDF: return "arrow.up.arrow.down.square"
        case .pageNumbers: return "number.square"
        case .watermark: return "drop.triangle"
        case .ocrText: return "text.viewfinder"
        case .imageToPDF: return "photo.on.rectangle"
        case .docToPDF: return "doc.text.fill"
        case .pdfToImage: return "photo"
        case .pdfToText: return "doc.plaintext"
        case .signPDF: return "signature"
        case .cropPDF: return "crop"
        case .metadataEditor: return "info.circle"
        case .summarizePDF: return "text.badge.star"
        case .askPDF: return "questionmark.bubble"
        case .translatePDF: return "textformat.abc"
        case .pdfViewer: return "doc.richtext"
        case .emailPDF: return "envelope"
        }
    }

    var description: String {
        switch self {
        case .scanner: return "Scan documents"
        case .mergePDF: return "Combine multiple PDFs"
        case .splitPDF: return "Split PDF by pages"
        case .compressPDF: return "Reduce PDF file size"
        case .lockPDF: return "Password protect PDF"
        case .unlockPDF: return "Remove PDF password"
        case .extractPages: return "Extract specific pages"
        case .rotatePDF: return "Rotate PDF pages"
        case .reorderPDF: return "Rearrange PDF pages"
        case .pageNumbers: return "Add page numbers"
        case .watermark: return "Add text watermark"
        case .ocrText: return "Extract text from images"
        case .imageToPDF: return "Convert images to PDF"
        case .docToPDF: return "Convert documents to PDF"
        case .pdfToImage: return "Export PDF pages as images"
        case .pdfToText: return "Extract text from PDF"
        case .signPDF: return "Add signature to PDF"
        case .cropPDF: return "Crop PDF page margins"
        case .metadataEditor: return "Edit PDF properties"
        case .summarizePDF: return "AI-powered PDF summary"
        case .askPDF: return "Ask questions about PDF"
        case .translatePDF: return "Translate PDF content"
        case .pdfViewer: return "View & manage PDFs"
        case .emailPDF: return "Email PDF as attachment"
        }
    }

    var section: String {
        switch self {
        case .scanner:
            return "Scanner"
        case .mergePDF, .splitPDF, .compressPDF, .lockPDF, .unlockPDF,
             .extractPages, .rotatePDF, .reorderPDF, .pageNumbers, .watermark, .ocrText,
             .signPDF, .cropPDF, .metadataEditor:
            return "PDF Tools"
        case .pdfViewer:
            return "Viewer"
        case .imageToPDF, .docToPDF, .pdfToImage, .pdfToText:
            return "Converters"
        case .summarizePDF, .askPDF, .translatePDF:
            return "AI Tools"
        case .emailPDF:
            return "Utilities"
        }
    }

    var color: Color {
        switch self {
        case .scanner: return .appAccent
        case .mergePDF: return .appPrimary
        case .splitPDF: return .appWarning
        case .compressPDF: return .appSuccess
        case .lockPDF: return .appDanger
        case .unlockPDF: return .appAccent
        case .extractPages: return .appPrimary
        case .rotatePDF: return .appWarning
        case .reorderPDF: return .appSuccess
        case .pageNumbers: return .appAccent
        case .watermark: return .appPrimary
        case .ocrText: return .appSuccess
        case .imageToPDF: return .appWarning
        case .docToPDF: return .appPrimary
        case .pdfToImage: return .appAccent
        case .pdfToText: return .appSuccess
        case .signPDF: return .appDanger
        case .cropPDF: return .appWarning
        case .metadataEditor: return .appAccent
        case .summarizePDF: return .appPrimary
        case .askPDF: return .appAccent
        case .translatePDF: return .appSuccess
        case .pdfViewer: return .appPrimary
        case .emailPDF: return .appWarning
        }
    }
}
