import SwiftUI

// MARK: - Animation Constants
enum AnimationConstants {
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.85
    static let standardDuration: Double = 0.3
    static let fastDuration: Double = 0.15
    static let slowDuration: Double = 0.5
    
    static var spring: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }
    
    static var easeInOut: Animation {
        .easeInOut(duration: standardDuration)
    }
    
    static var easeOut: Animation {
        .easeOut(duration: standardDuration)
    }
    
    static var fast: Animation {
        .easeOut(duration: fastDuration)
    }
}

// MARK: - View Modifiers
struct FadeInModifier: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                withAnimation(AnimationConstants.easeOut.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(AnimationConstants.spring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct SlideInModifier: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0
    var direction: Edge = .leading
    
    private var offset: CGFloat {
        isVisible ? 0 : (direction == .leading || direction == .trailing ? 30 : 0)
    }
    
    private var yOffset: CGFloat {
        isVisible ? 0 : (direction == .top || direction == .bottom ? 30 : 0)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset, y: yOffset)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(AnimationConstants.spring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct HoverScaleModifier: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat = 1.02
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1)
            .animation(AnimationConstants.fast, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct PressScaleModifier: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.97
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .animation(AnimationConstants.fast, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            isAnimating = true
                        }
                    }
                }
                .mask(content)
            )
    }
}

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
}

// MARK: - View Extensions
extension View {
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
    
    func scaleIn(delay: Double = 0) -> some View {
        modifier(ScaleInModifier(delay: delay))
    }
    
    func slideIn(delay: Double = 0, from direction: Edge = .leading) -> some View {
        modifier(SlideInModifier(delay: delay, direction: direction))
    }
    
    func hoverScale(_ scale: CGFloat = 1.02) -> some View {
        modifier(HoverScaleModifier(scale: scale))
    }
    
    func pressScale(_ scale: CGFloat = 0.97) -> some View {
        modifier(PressScaleModifier(scale: scale))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
    
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Staggered Animation Helper
struct StaggeredContainer<Content: View>: View {
    let content: Content
    let staggerDelay: Double
    @State private var isVisible = false
    
    init(staggerDelay: Double = 0.05, @ViewBuilder content: () -> Content) {
        self.staggerDelay = staggerDelay
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(AnimationConstants.easeOut) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Animated Number
struct AnimatedNumber: View {
    let value: Int
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .onAppear {
                animateValue()
            }
            .onChange(of: value) { _, _ in
                animateValue()
            }
    }
    
    private func animateValue() {
        withAnimation(AnimationConstants.easeOut) {
            displayValue = value
        }
    }
}

// MARK: - Page Transition
enum PageTransition {
    case fade
    case slide(direction: Edge)
    case scale
    
    var transition: AnyTransition {
        switch self {
        case .fade:
            return .opacity
        case .slide(let direction):
            return .move(edge: direction).combined(with: .opacity)
        case .scale:
            return .scale.combined(with: .opacity)
        }
    }
}
