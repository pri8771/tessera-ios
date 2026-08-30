import SwiftUI

/// First-run introduction. Three calm panels, then a gentle hand-off into the
/// tutorial. Skippable for returning players who reinstall.
struct OnboardingView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var onStart: () -> Void
    var onSkip: () -> Void

    @State private var page = 0

    private struct Panel: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let panels: [Panel] = [
        Panel(symbol: "square.grid.3x3.fill", title: "Fill the surface",
              body: "Place every piece so the pattern tessellates — no gaps, no overlaps."),
        Panel(symbol: "rotate.right", title: "Rotate to fit",
              body: "Select a piece and rotate it until it settles into the one place it belongs."),
        Panel(symbol: "calendar", title: "A new board each day",
              body: "Everyone gets the same daily puzzle. Build a streak, then share your solve.")
    ]

    var body: some View {
        let colors = theme.colors(for: scheme)
        ZStack {
            ThemedBackground()
            VStack(spacing: Spacing.lg) {
                HStack {
                    Spacer()
                    Button("Skip", action: onSkip)
                        .font(AppFont.callout())
                        .foregroundStyle(colors.inkSecondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

                TabView(selection: $page) {
                    ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                        VStack(spacing: Spacing.lg) {
                            Image(systemName: panel.symbol)
                                .font(.system(size: 72, weight: .light))
                                .foregroundStyle(colors.accent)
                            Text(panel.title)
                                .font(AppFont.title())
                                .foregroundStyle(colors.ink)
                            Text(panel.body)
                                .font(AppFont.body())
                                .foregroundStyle(colors.inkSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                PrimaryButton(page == panels.count - 1 ? "Start playing" : "Next") {
                    if page == panels.count - 1 {
                        onStart()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}
