import Foundation

enum OpenStatus: Equatable {
    case open(closesAt: Date)
    /// `opensAt` is nil only if the shop never opens in the coming week.
    case closed(opensAt: Date?)
}

extension OpeningHours {
    func status(at date: Date, calendar: Calendar) -> OpenStatus {
        let dayStart = calendar.startOfDay(for: date)
        for block in blocks(on: date, calendar: calendar) {
            guard let start = calendar.date(byAdding: .minute, value: block.startMinute, to: dayStart),
                  let end = calendar.date(byAdding: .minute, value: block.endMinute, to: dayStart) else { continue }
            if date < start { return .closed(opensAt: start) }
            if date < end { return .open(closesAt: end) }
        }
        for offset in 1...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: dayStart),
                  let firstBlock = blocks(on: day, calendar: calendar).first else { continue }
            return .closed(opensAt: calendar.date(byAdding: .minute, value: firstBlock.startMinute, to: day))
        }
        return .closed(opensAt: nil)
    }
}
