import Foundation

extension Date {
    var relativeDisplay: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today, " + formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday, " + formatted(date: .omitted, time: .shortened)
        } else if calendar.dateComponents([.day], from: self, to: .now).day ?? 7 < 7 {
            return formatted(.dateTime.weekday(.wide)) + ", " + formatted(date: .omitted, time: .shortened)
        } else {
            return formatted(.dateTime.month(.abbreviated).day().year())
        }
    }
}
