import Foundation

enum FileSortOption: String, CaseIterable, Identifiable {
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case sizeDesc = "Largest First"
    case sizeAsc = "Smallest First"
    case typeAsc = "Type (A-Z)"

    var id: String { rawValue }
}
