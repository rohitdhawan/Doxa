import SwiftUI
import SwiftData

@Observable
final class FilesViewModel {
    var searchText = ""
    var selectedCategory: FileCategory = .all
    var sortOption: FileSortOption = .dateDesc

    private var cachedCounts: [FileCategory: Int] = [:]
    private var cachedCountsFileCount = -1

    func filteredAndSorted(_ files: [DocumentFile]) -> [DocumentFile] {
        var result = files

        // Filter by category
        if selectedCategory != .all {
            result = result.filter { selectedCategory.extensions.contains($0.fileExtension.lowercased()) }
        }

        // Filter by search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) || $0.fileExtension.lowercased().contains(query) }
        }

        // Sort
        switch sortOption {
        case .dateDesc:
            result.sort { ($0.importedAt) > ($1.importedAt) }
        case .dateAsc:
            result.sort { ($0.importedAt) < ($1.importedAt) }
        case .nameAsc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .sizeDesc:
            result.sort { $0.fileSize > $1.fileSize }
        case .sizeAsc:
            result.sort { $0.fileSize < $1.fileSize }
        case .typeAsc:
            result.sort { $0.fileExtension < $1.fileExtension }
        }

        return result
    }

    func categoryCount(_ category: FileCategory, in files: [DocumentFile]) -> Int {
        // Recompute all counts when file count changes (single pass)
        if files.count != cachedCountsFileCount {
            rebuildCategoryCounts(files)
        }
        return cachedCounts[category] ?? 0
    }

    private func rebuildCategoryCounts(_ files: [DocumentFile]) {
        var counts: [FileCategory: Int] = [.all: files.count]
        for file in files {
            let ext = file.fileExtension.lowercased()
            for category in FileCategory.allCases where category != .all {
                if category.extensions.contains(ext) {
                    counts[category, default: 0] += 1
                }
            }
        }
        cachedCounts = counts
        cachedCountsFileCount = files.count
    }

    func recentFiles(_ files: [DocumentFile], limit: Int = 5) -> [DocumentFile] {
        files
            .filter { $0.lastOpenedAt != nil }
            .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}
