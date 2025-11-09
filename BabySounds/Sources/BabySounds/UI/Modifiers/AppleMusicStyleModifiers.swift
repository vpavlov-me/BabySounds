import SwiftUI

// MARK: - Apple Music Style Modifiers

extension View {
    /// Applies Apple Music-style press animation
    func appleMusicPressEffect() -> some View {
        modifier(AppleMusicPressEffect())
    }

    /// Applies Apple Music-style card styling
    func appleMusicCard(padding: CGFloat = 16) -> some View {
        modifier(AppleMusicCard(padding: padding))
    }

    /// Applies Apple Music-style blur background
    func appleMusicBlur() -> some View {
        modifier(AppleMusicBlur())
    }

    /// Adds Apple Music-style haptic feedback
    func appleMusicHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        onTapGesture {
            HapticManager.shared.impact(style)
        }
    }
}

// MARK: - AppleMusicPressEffect

struct AppleMusicPressEffect: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0) { pressing in
                isPressed = pressing
            } perform: {}
    }
}

// MARK: - AppleMusicCard

struct AppleMusicCard: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - AppleMusicBlur

struct AppleMusicBlur: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Symbol Effect Transition

extension Image {
    func appleMusicSymbolEffect() -> some View {
        contentTransition(.symbolEffect(.replace.downUp))
            .animation(.easeInOut(duration: 0.3), value: UUID())
    }
}

// MARK: - Navigation Bar Style

extension View {
    func appleMusicNavigationBar() -> some View {
        navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.regularMaterial, for: .navigationBar)
    }
}

// MARK: - Tab Bar Style

extension View {
    func appleMusicTabBar() -> some View {
        toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.regularMaterial, for: .tabBar)
    }
}

// MARK: - ScrollOffsetModifier

struct ScrollOffsetModifier: ViewModifier {
    @Binding var offset: CGFloat
    let coordinateSpace: String

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named(coordinateSpace)).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

extension View {
    func trackScrollOffset(_ offset: Binding<CGFloat>, in coordinateSpace: String = "scroll") -> some View {
        modifier(ScrollOffsetModifier(offset: offset, coordinateSpace: coordinateSpace))
    }
}

// MARK: - AnimatedGradientBackground

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    let colors: [Color]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - FloatingActionButton

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(.pink)
                        .shadow(color: .pink.opacity(0.3), radius: 12, x: 0, y: 6)
                )
        }
        .appleMusicPressEffect()
        .onTapGesture {
            HapticManager.shared.impact(.medium)
        }
    }
}

// MARK: - WaveAnimation

struct WaveAnimation: View {
    @State private var isAnimating = false
    let color: Color
    let count: Int

    init(color: Color = .pink, count: Int = 3) {
        self.color = color
        self.count = count
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 3)
                    .frame(height: isAnimating ? CGFloat.random(in: 8 ... 20) : 8)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - BreathingAnimation

struct BreathingAnimation: ViewModifier {
    @State private var isBreathing = false
    let duration: Double
    let scaleRange: ClosedRange<CGFloat>

    init(duration: Double = 2.0, scaleRange: ClosedRange<CGFloat> = 0.95 ... 1.05) {
        self.duration = duration
        self.scaleRange = scaleRange
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? scaleRange.upperBound : scaleRange.lowerBound)
            .animation(
                .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

extension View {
    func breathingAnimation(duration: Double = 2.0, scaleRange: ClosedRange<CGFloat> = 0.95 ... 1.05) -> some View {
        modifier(BreathingAnimation(duration: duration, scaleRange: scaleRange))
    }
}

// MARK: - SmartRefreshControl

struct SmartRefreshControl: View {
    let onRefresh: () async -> Void
    @State private var isRefreshing = false

    var body: some View {
        RefreshControl(
            coordinateSpace: "pullToRefresh"
        ) {
            await performRefresh()
        }
    }

    private func performRefresh() async {
        isRefreshing = true
        HapticManager.shared.impact(.light)
        await onRefresh()
        isRefreshing = false
    }
}

// MARK: - RefreshControl

struct RefreshControl: View {
    let coordinateSpace: String
    let onRefresh: () async -> Void

    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .named(coordinateSpace)).midY > 50 {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.pink)
                        .scaleEffect(0.8)
                    Spacer()
                }
                .task {
                    await onRefresh()
                }
            }
        }
        .frame(height: 0)
    }
}

// MARK: - Context Menu Helpers

extension View {
    func appleMusicContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        contextMenu {
            menuItems()
        } preview: {
            self
                .scaleEffect(1.1)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - LoadingView

struct LoadingView: View {
    let text: String

    init(_ text: String = "Loading...") {
        self.text = text
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.pink)
                .scaleEffect(1.2)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - ErrorView

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(_ message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                    HapticManager.shared.impact(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
