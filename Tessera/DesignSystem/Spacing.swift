import CoreGraphics

/// 4-point spacing scale and shared corner radii.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let pill: CGFloat = 999
    /// Corner radius applied to individual board/tile cells, as a fraction of cell size.
    static let cellFraction: CGFloat = 0.26
}
