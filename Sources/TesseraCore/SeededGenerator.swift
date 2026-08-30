import Foundation

/// A deterministic, seedable pseudo-random generator (SplitMix64).
///
/// The whole point of Tessera's daily puzzle is that every player on a given date
/// receives the *same* board. That requires randomness that is fully reproducible
/// from a seed and independent of platform `Hashable`/`Set` ordering. `SplitMix64`
/// is small, fast, and well-distributed — ideal for puzzle generation.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        // Avoid a zero state producing a degenerate first few outputs.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Returns an integer in `0..<bound` (deterministic, unbiased enough for puzzles).
    public mutating func int(below bound: Int) -> Int {
        precondition(bound > 0, "bound must be positive")
        return Int(next() % UInt64(bound))
    }

    /// Returns an integer in the inclusive range.
    public mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + int(below: range.count)
    }

    /// Picks a random element deterministically, or `nil` for an empty collection.
    public mutating func pick<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[int(below: array.count)]
    }
}
