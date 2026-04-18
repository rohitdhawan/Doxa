import Foundation

extension String {
    var fileExtension: String {
        (self as NSString).pathExtension.lowercased()
    }

    var fileNameWithoutExtension: String {
        (self as NSString).deletingPathExtension
    }
}
