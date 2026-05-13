import SwiftUI

// MARK: - Confetti Particle

private struct ConfettiParticle {
    let x0:        CGFloat   // initial x (pixels)
    let y0:        CGFloat   // initial y (pixels, negative = above screen)
    let vx:        CGFloat   // horizontal velocity (px/s)
    let vy:        CGFloat   // vertical velocity   (px/s, negative = upward)
    let color:     Color
    let width:     CGFloat
    let height:    CGFloat
    let rot0:      Double    // initial rotation (degrees)
    let rotSpeed:  Double    // rotation speed   (degrees/s)
    let isCircle:  Bool

    private static let gravity: Double = 500   // px/s²

    func pos(t: Double) -> CGPoint {
        CGPoint(
            x: x0 + vx * CGFloat(t),
            y: y0 + vy * CGFloat(t) + CGFloat(0.5 * Self.gravity * t * t)
        )
    }

    func angle(t: Double) -> Angle { .degrees(rot0 + rotSpeed * t) }
}

// MARK: - Celebration View

/// Renders a confetti/fireworks overlay when a task is completed.
/// Call `onFinished` when the animation completes to dismiss the overlay.
struct CelebrationView: View {
    let level:      CelebrationLevel
    let difficulty: TaskDifficulty
    let onFinished: () -> Void

    @State private var startDate = Date.now
    @State private var particles: [ConfettiParticle] = []

    private static let palette: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .indigo
    ]

    // MARK: - Intensity

    private var baseParticleCount: Int {
        switch level {
        case .off:                return 0
        case .mild:               return 35
        case .medium:             return 90
        case .wild:               return 180
        case .absolutelyUnhinged: return 320
        }
    }

    private var difficultyMultiplier: Double {
        switch difficulty {
        case .easy:   return 0.6
        case .medium: return 0.85
        case .hard:   return 1.0
        case .epic:   return 1.5
        }
    }

    private var particleCount: Int { Int(Double(baseParticleCount) * difficultyMultiplier) }

    private var totalDuration: Double {
        switch level {
        case .off:                return 0
        case .mild:               return 1.8
        case .medium:             return 2.5
        case .wild:               return 3.5
        case .absolutelyUnhinged: return 5.0
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
                let elapsed   = ctx.date.timeIntervalSince(startDate)
                let fadeStart = totalDuration * 0.65
                let opacity: Double = elapsed > fadeStart
                    ? max(0, 1.0 - (elapsed - fadeStart) / (totalDuration - fadeStart))
                    : 1.0

                Canvas { context, size in
                    for p in particles {
                        let pos = p.pos(t: elapsed)
                        // Skip particles that have fallen below the screen.
                        guard pos.y < size.height + 80, pos.x > -80, pos.x < size.width + 80 else { continue }

                        let rect = CGRect(
                            x: pos.x - p.width  / 2,
                            y: pos.y - p.height / 2,
                            width:  p.width,
                            height: p.height
                        )
                        var ctx2 = context
                        ctx2.opacity = opacity
                        ctx2.translateBy(x: pos.x, y: pos.y)
                        ctx2.rotate(by: p.angle(t: elapsed))
                        ctx2.translateBy(x: -pos.x, y: -pos.y)

                        if p.isCircle {
                            ctx2.fill(Path(ellipseIn: rect), with: .color(p.color))
                        } else {
                            ctx2.fill(Path(rect), with: .color(p.color))
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                startDate = .now
                spawnParticles(in: geo.size)
                triggerHaptic()
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                    onFinished()
                }
            }
        }
    }

    // MARK: - Spawn

    private func spawnParticles(in size: CGSize) {
        var result: [ConfettiParticle] = []

        // Rain from top — all levels
        result += (0 ..< particleCount).map { _ in
            ConfettiParticle(
                x0:       CGFloat.random(in: -20 ... size.width + 20),
                y0:       CGFloat.random(in: -120 ... -10),
                vx:       CGFloat.random(in: -120 ... 120),
                vy:       CGFloat.random(in: 60 ... 260),
                color:    Self.palette.randomElement()!,
                width:    CGFloat.random(in: 6 ... 18),
                height:   CGFloat.random(in: 4 ... 12),
                rot0:     Double.random(in: 0 ... 360),
                rotSpeed: Double.random(in: -360 ... 360),
                isCircle: Bool.random()
            )
        }

        // Upward burst from bottom — Wild and Unhinged only
        if level == .wild || level == .absolutelyUnhinged {
            let burstCount = level == .absolutelyUnhinged ? 100 : 50
            result += (0 ..< burstCount).map { _ in
                let speed = CGFloat.random(in: 400 ... 900)
                let angle = Double.random(in: 220 ... 320) // upward arc (degrees)
                let rad   = angle * .pi / 180
                return ConfettiParticle(
                    x0:       CGFloat.random(in: size.width * 0.2 ... size.width * 0.8),
                    y0:       size.height + 20,
                    vx:       cos(rad) * speed,
                    vy:       sin(rad) * speed,   // negative → upward
                    color:    Self.palette.randomElement()!,
                    width:    CGFloat.random(in: 8 ... 20),
                    height:   CGFloat.random(in: 5 ... 14),
                    rot0:     Double.random(in: 0 ... 360),
                    rotSpeed: Double.random(in: -600 ... 600),
                    isCircle: Bool.random()
                )
            }
        }

        particles = result
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        switch level {
        case .off, .mild:
            break
        case .medium:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .wild:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .absolutelyUnhinged:
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { gen.impactOccurred() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { gen.impactOccurred() }
        }
    }
}
