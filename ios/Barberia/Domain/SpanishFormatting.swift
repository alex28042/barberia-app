import Foundation

let spanishLocale = Locale(identifier: "es_ES")

func makeSpanishCalendar(timeZone: TimeZone = .current) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = spanishLocale
    calendar.timeZone = timeZone
    calendar.firstWeekday = 2
    return calendar
}

/// "5 €", "22 €", "12,50 €".
func euros(_ cents: Int) -> String {
    (Decimal(cents) / 100).formatted(.currency(code: "EUR").locale(spanishLocale).precision(.fractionLength(0...2)))
}

/// "17:30".
func clockTime(_ date: Date) -> String {
    date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(spanishLocale))
}

/// "17:30" from minutes after midnight.
func clockTime(minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
}

/// "jue".
func weekdayShort(_ date: Date) -> String {
    date.formatted(.dateTime.weekday(.abbreviated).locale(spanishLocale)).replacingOccurrences(of: ".", with: "")
}

/// "jueves".
func weekdayLong(_ date: Date) -> String {
    date.formatted(.dateTime.weekday(.wide).locale(spanishLocale))
}

/// "16".
func dayNumber(_ date: Date) -> String {
    date.formatted(.dateTime.day().locale(spanishLocale))
}

/// "Martes, 14 de octubre".
func longDate(_ date: Date) -> String {
    capitalizedFirst(date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(spanishLocale)))
}

/// "Jue 16 oct".
func shortDate(_ date: Date) -> String {
    let month = date.formatted(.dateTime.month(.abbreviated).locale(spanishLocale)).replacingOccurrences(of: ".", with: "")
    return capitalizedFirst("\(weekdayShort(date)) \(dayNumber(date)) \(month)")
}

func capitalizedFirst(_ text: String) -> String {
    text.prefix(1).uppercased() + text.dropFirst()
}

/// "hoy a las 17:30", "mañana a las 10:00", "el lunes a las 10:00".
func relativeTimePhrase(_ date: Date, now: Date, calendar: Calendar) -> String {
    let time = "a las \(clockTime(date))"
    if calendar.isDate(date, inSameDayAs: now) { return "hoy \(time)" }
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
        return "mañana \(time)"
    }
    return "el \(weekdayLong(date)) \(time)"
}

/// "L", "M", "X"…
func weekdayInitial(_ date: Date) -> String {
    date.formatted(.dateTime.weekday(.narrow).locale(spanishLocale))
}
