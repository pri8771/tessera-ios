import Foundation

/// A deterministic seed derived from a calendar date.
///
/// The daily puzzle key is the UTC `YYYY-MM-DD` string so every player worldwide
/// gets the same board for a given date. The numeric `value` is an FNV-1a hash of
/// that key, suitable for feeding `SeededGenerator`.
public struct DailySeed: Equatable, Codable, Sendable {
    public let dateKey: String
    public let value: UInt64

    public init(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        var calendar = calendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.dateKey = String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
        self.value = DailySeed.fnv1a64(dateKey)
    }

    /// Construct directly from a known date key (e.g. when replaying archive days).
    public init(dateKey: String) {
        self.dateKey = dateKey
        self.value = DailySeed.fnv1a64(dateKey)
    }

    /// FNV-1a 64-bit hash of a string — used to derive reproducible seeds from ids.
    public static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}
