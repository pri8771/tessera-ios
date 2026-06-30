import SwiftUI

/// The "stable board locks with a satisfying ripple" moment. A few concentric
/// rings expand and fade from the centre when a board is solved.
struct SolveRippleView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @State private var animate = false

    var body: some View {
        let colors = theme.colors(for: scheme)
        GeometryReader { geo in
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .strokeBorder(colors.success.opacity(0.5), lineWidth: 3)
                        .frame(width: animate ? geo.size.width * 1.6 : 40,
                               height: animate ? geo.size.width * 1.6 : 40)
                        .opacity(animate ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.1).delay(Double(index) * 0.16),
                            value: animate
                        )
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .onAppear { animate = true }
    }
}
