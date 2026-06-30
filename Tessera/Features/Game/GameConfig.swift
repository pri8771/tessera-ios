import Foundation
import TesseraCore

/// Everything the game screen needs to present and score one puzzle.
struct GameConfig: Identifiable, Equatable {
    let puzzle: Puzzle
    var isTodaysDaily: Bool
    var allowResume: Bool
    var title: String
    var subtitle: String

    var id: String { puzzle.id }

    init(
        puzzle: Puzzle,
        isTodaysDaily: Bool = false,
        allowResume: Bool = true,
        title: String,
        subtitle: String
    ) {
        self.puzzle = puzzle
        self.isTodaysDaily = isTodaysDaily
        self.allowResume = allowResume
        self.title = title
        self.subtitle = subtitle
    }
}
