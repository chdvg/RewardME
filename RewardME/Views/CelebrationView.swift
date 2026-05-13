import SwiftUI

// MARK: - Particle Shape
private enum PShape { case rect, circle, star, streak }

// MARK: - Particle
private struct Particle {
    let startTime: Double   // seconds after animation begins
    let x0, y0:   CGFloat
    let vx, vy:   CGFloat
    let color:    Color
    let size:     CGFloat
    let aspect:   CGFloat   // width multiplier (rects only)
    let shape:    PShape
    let rot0, rotSpeed: Double
    let lifespan: Double    // seconds this particle is alive after startTime

    static let g: Double = 380  // gravity (px/s²)

    func alive(at t: Double) -> Bool {
        let lt = t - startTime; return lt >= 0 && lt <= lifespan
    }

    func pos(at t: Double) -> CGPoint {
        let lt = CGFloat(t - startTime)
        return CGPoint(x: x0 + vx * lt,
                       y: y0 + vy * lt + CGFloat(0.5 * Self.g) * lt * lt)
    }

    func alpha(at t: Double) -> Double {
        let lt = t - startTime
        guard lt >= 0 else { return 0 }
        if lt > lifespan { return 0 }
        let fadeIn  = lt < 0.06 ? lt / 0.06 : 1.0
        let fadeOut = lt > lifespan * 0.58
            ? max(0, 1 - (lt - lifespan * 0.58) / (lifespan * 0.42))
            : 1.0
        return fadeIn * fadeOut
    }

    func rot(at t: Double) -> Angle {
        .degrees(rot0 + rotSpeed * max(0, t - startTime))
    }
}

// MARK: - CelebrationView
struct CelebrationView: View {
    let level:      CelebrationLevel
    let difficulty: TaskDifficulty
    let onFinished: () -> Void

    @State private var startDate:     Date   = .now
    @State private var particles:     [Particle] = []
    @State private var flashColor:    Color  = .yellow
    @State private var flashOpacity:  Double = 0

    // MARK: - Palettes
    private static let confettiColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .indigo, .white
    ]
    private static let fireworkFamilies: [[Color]] = [
        [.red,    .orange, .yellow],
        [.cyan,   .blue,   .white ],
        [.purple, .pink,   .indigo],
        [.green,  .mint,   .yellow],
        [.white,  .yellow, .orange],
        [.pink,   .red,    .white ],
    ]

    // MARK: - Timing
    private var totalDuration: Double {
        switch level {
        case .off:                return 0
        case .mild:               return 2.5
        case .medium:             return 3.5
        case .wild:               return 5.0
        case .absolutelyUnhinged: return 7.0
        }
    }

    private var diffMult: Double {
        switch difficulty {
        case .easy:   return 0.6
        case .medium: return 0.85
        case .hard:   return 1.0
        case .epic:   return 1.4
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
                    let t = ctx.date.timeIntervalSince(startDate)
                    Canvas { context, size in
                        for p in particles {
                            guard p.alive(at: t) else { continue }
                            let pos = p.pos(at: t)
                            guard pos.y < size.height + 130,
                                  pos.x > -70, pos.x < size.width + 70 else { continue }
                            let a = p.alpha(at: t)
                            guard a > 0.01 else { continue }
                            var ctx2 = context
                            ctx2.opacity = a
                            ctx2.translateBy(x: pos.x, y: pos.y)
                            ctx2.rotate(by: p.rot(at: t))
                            ctx2.translateBy(x: -pos.x, y: -pos.y)
                            let fill = GraphicsContext.Shading.color(p.color)
                            switch p.shape {
                            case .rect:
                                let r = CGRect(x: pos.x - p.size * p.aspect / 2,
                                               y: pos.y - p.size / 2,
                                               width: p.size * p.aspect, height: p.size)
                                ctx2.fill(Path(r), with: fill)
                            case .circle:
                                let r = CGRect(x: pos.x - p.size / 2, y: pos.y - p.size / 2,
                                               width: p.size, height: p.size)
                                ctx2.fill(Path(ellipseIn: r), with: fill)
                            case .star:
                                ctx2.fill(starPath(at: pos, size: p.size), with: fill)
                            case .streak:
                                let r = CGRect(x: pos.x - p.size * 0.14 / 2,
                                               y: pos.y - p.size / 2,
                                               width: p.size * 0.14, height: p.size)
                                ctx2.fill(Path(r), with: fill)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .onAppear {
                    startDate = .now
                    spawnAll(in: geo.size)
                    fireHaptics()
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { onFinished() }
                }
            }

            // Screen flash for Wild / Unhinged
            if level == .wild || level == .absolutelyUnhinged {
                flashColor
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.45), value: flashOpacity)
            }
        }
    }

    // MARK: - Star path
    private func starPath(at center: CGPoint, size: CGFloat, points: Int = 5) -> Path {
        Path { p in
            let outer = size / 2
            let inner = outer * 0.42
            for i in 0 ..< (points * 2) {
                let theta = Double(i) * .pi / Double(points) - .pi / 2
                let r = CGFloat(i.isMultiple(of: 2) ? outer : inner)
                let pt = CGPoint(x: center.x + CGFloat(cos(theta)) * r,
                                 y: center.y + CGFloat(sin(theta)) * r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }

    // MARK: - Spawn
    private func spawnAll(in size: CGSize) {
        var all: [Particle] = []
        all += confettiRain(in: size)
        for (fi, xFrac, delay) in shellSchedule() {
            let peakY   = CGFloat.random(in: size.height * 0.08 ... size.height * 0.44)
            let palette = Self.fireworkFamilies[fi % Self.fireworkFamilies.count]
            all += firework(launchX:  size.width * CGFloat(xFrac),
                            peakY:    peakY,
                            bottomY:  size.height + 10,
                            palette:  palette,
                            delay:    delay)
        }
        particles = all
    }

    private func shellSchedule() -> [(Int, Double, Double)] {
        switch level {
        case .off, .mild: return []
        case .medium:
            return [(0, 0.28, 0.25), (1, 0.72, 0.9)]
        case .wild:
            return (0 ..< 5).map { i in
                (i, Double.random(in: 0.15 ... 0.85),
                 Double(i) * 0.55 + Double.random(in: 0 ... 0.2))
            }
        case .absolutelyUnhinged:
            var r: [(Int, Double, Double)] = []
            for i in 0 ..< 7 {   // wave 1
                r.append((i,
                           Double.random(in: 0.10 ... 0.90),
                           Double(i) * 0.38 + Double.random(in: 0 ... 0.15)))
            }
            for i in 0 ..< 5 {   // wave 2
                r.append((i + 2,
                           Double.random(in: 0.10 ... 0.90),
                           2.6 + Double(i) * 0.32 + Double.random(in: 0 ... 0.12)))
            }
            return r
        }
    }

    private func confettiRain(in size: CGSize) -> [Particle] {
        let base: Int
        switch level {
        case .off:                return []
        case .mild:               base = 50
        case .medium:             base = 100
        case .wild:               base = 160
        case .absolutelyUnhinged: base = 250
        }
        let n = Int(Double(base) * diffMult)
        return (0 ..< n).map { _ in
            let shape: PShape = [.rect, .rect, .circle, .star].randomElement()!
            return Particle(
                startTime: Double.random(in: 0 ... totalDuration * 0.28),
                x0:       CGFloat.random(in: -20 ... size.width + 20),
                y0:       CGFloat.random(in: -180 ... -10),
                vx:       CGFloat.random(in: -80 ... 80),
                vy:       CGFloat.random(in: 60 ... 260),
                color:    Self.confettiColors.randomElement()!,
                size:     CGFloat.random(in: 7 ... 18),
                aspect:   CGFloat.random(in: 0.4 ... 2.2),
                shape:    shape,
                rot0:     Double.random(in: 0 ... 360),
                rotSpeed: Double.random(in: -420 ... 420),
                lifespan: Double.random(in: totalDuration * 0.55 ... totalDuration * 0.92)
            )
        }
    }

    private func firework(launchX: CGFloat, peakY: CGFloat, bottomY: CGFloat,
                          palette: [Color], delay: Double) -> [Particle] {
        let g      = Particle.g
        let dist   = Double(bottomY - peakY)       // upward distance
        let lvY    = -CGFloat(sqrt(2 * g * dist))  // launch velocity Y (upward, negative)
        let tPeak  = Double(-lvY) / g              // seconds to reach peak

        var result: [Particle] = []

        // — Rocket trail (dots along the ascent path)
        for j in 0 ..< 14 {
            let tFrac = Double(j) / 14.0
            let tAt   = tFrac * tPeak
            let ty    = bottomY + lvY * CGFloat(tAt) + CGFloat(0.5 * g * tAt * tAt)
            result.append(Particle(
                startTime: delay + tAt,
                x0:       launchX + CGFloat.random(in: -4 ... 4),
                y0:       ty,
                vx:       CGFloat.random(in: -12 ... 12),
                vy:       CGFloat.random(in: 0 ... 35),
                color:    palette.randomElement()!,
                size:     CGFloat.random(in: 3 ... 8),
                aspect:   1, shape: .circle,
                rot0: 0, rotSpeed: 0,
                lifespan: Double.random(in: 0.22 ... 0.48)
            ))
        }

        // — Burst at peak
        let burstN: Int
        switch level {
        case .off, .mild: burstN = 0
        case .medium:     burstN = 52
        case .wild:       burstN = 72
        case .absolutelyUnhinged: burstN = 90
        }
        let burstT = delay + tPeak
        for _ in 0 ..< burstN {
            let speed  = CGFloat.random(in: 100 ... 520)
            let angle  = Double.random(in: 0 ... 2 * .pi)
            let shape: PShape = [.star, .circle, .rect].randomElement()!
            result.append(Particle(
                startTime: burstT + Double.random(in: 0 ... 0.04),
                x0:    launchX + CGFloat.random(in: -8 ... 8),
                y0:    peakY   + CGFloat.random(in: -8 ... 8),
                vx:    CGFloat(cos(angle)) * speed,
                vy:    CGFloat(sin(angle)) * speed * 0.80,
                color: palette.randomElement()!,
                size:  CGFloat.random(in: 6 ... 22),
                aspect: 1, shape: shape,
                rot0:  Double.random(in: 0 ... 360),
                rotSpeed: Double.random(in: -520 ... 520),
                lifespan: Double.random(in: 0.85 ... 2.2)
            ))
        }

        // — Sparkle streaks radiating out
        let streakN = level == .absolutelyUnhinged ? 18 : 10
        for _ in 0 ..< streakN {
            let speed = CGFloat.random(in: 180 ... 460)
            let angle = Double.random(in: 0 ... 2 * .pi)
            result.append(Particle(
                startTime: burstT,
                x0: launchX, y0: peakY,
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed,
                color: [Color.white, .yellow, .orange].randomElement()!,
                size:  CGFloat.random(in: 14 ... 34),
                aspect: 1, shape: .streak,
                rot0:  angle * 180 / .pi + 90, rotSpeed: 0,
                lifespan: Double.random(in: 0.3 ... 0.72)
            ))
        }

        return result
    }

    // MARK: - Haptics + Screen Flash
    private func fireHaptics() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let notif = UINotificationFeedbackGenerator()

        switch level {
        case .off: break

        case .mild:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                notif.notificationOccurred(.success)
            }

        case .wild:
            heavy.impactOccurred()
            for d in [0.55, 1.1, 1.9] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) { heavy.impactOccurred() }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                notif.notificationOccurred(.success)
            }
            flashScreen(color: .orange, at: 0.25)
            flashScreen(color: .yellow, at: 1.6)

        case .absolutelyUnhinged:
            heavy.impactOccurred()
            let bursts: [(Double, UIImpactFeedbackGenerator.FeedbackStyle)] = [
                (0.32, .heavy), (0.58, .rigid), (0.88, .heavy),
                (1.25, .heavy), (1.65, .rigid), (2.05, .heavy),
                (2.55, .heavy), (3.05, .rigid), (3.55, .heavy),
                (4.20, .heavy), (5.10, .heavy)
            ]
            for (d, style) in bursts {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    UIImpactFeedbackGenerator(style: style).impactOccurred()
                }
            }
            for d in [0.7, 1.5, 2.4, 3.3, 4.6] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    notif.notificationOccurred(.success)
                }
            }
            flashScreen(color: .yellow, at: 0.12)
            flashScreen(color: .orange, at: 0.88)
            flashScreen(color: .cyan,   at: 1.75)
            flashScreen(color: .purple, at: 2.65)
            flashScreen(color: .yellow, at: 3.45)
            flashScreen(color: .white,  at: 4.55)
        }
    }

    private func flashScreen(color: Color, at delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.linear(duration: 0.04)) {
                flashColor   = color
                flashOpacity = 0.22
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.easeOut(duration: 0.46)) { flashOpacity = 0 }
            }
        }
    }
}
