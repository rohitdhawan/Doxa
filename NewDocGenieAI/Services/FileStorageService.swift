import Foundation

final class FileStorageService: Sendable {
    static let shared = FileStorageService()

    let appFilesDirectory: URL
    let documentsDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(AppConstants.appDocumentsSubdirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        documentsDirectory = docs
        appFilesDirectory = dir
    }

    func importFile(from sourceURL: URL) throws -> (url: URL, relativePath: String) {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let fileName = sourceURL.lastPathComponent
        var destinationURL = appFilesDirectory.appendingPathComponent(fileName)

        // Handle name collisions
        var counter = 1
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension

        while FileManager.default.fileExists(atPath: destinationURL.path) {
            let newName = "\(nameWithoutExt) (\(counter)).\(ext)"
            destinationURL = appFilesDirectory.appendingPathComponent(newName)
            counter += 1
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        let relativePath = AppConstants.appDocumentsSubdirectory + "/" + destinationURL.lastPathComponent
        return (destinationURL, relativePath)
    }

    func deleteFile(at relativePath: String) throws {
        let url = documentsDirectory.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func renameFile(at relativePath: String, to newName: String) throws -> String {
        let oldURL = documentsDirectory.appendingPathComponent(relativePath)
        let ext = oldURL.pathExtension
        let newFileName = "\(newName).\(ext)"
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(newFileName)

        guard !FileManager.default.fileExists(atPath: newURL.path) else {
            throw FileStorageError.nameAlreadyExists
        }

        try FileManager.default.moveItem(at: oldURL, to: newURL)
        return AppConstants.appDocumentsSubdirectory + "/" + newFileName
    }

    func fileExists(at relativePath: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: url.path)
    }
}

enum FileStorageError: LocalizedError {
    case nameAlreadyExists
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .nameAlreadyExists: return "A file with that name already exists."
        case .fileNotFound: return "File not found."
        }
    }
}
