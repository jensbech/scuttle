import Foundation
import CoreGraphics
import ScuttleCore

extension KawaiiArt {
    static func ghost(_ f: FigureFrame, _ k: KawaiiKit) {
        let bodies = [Tone(0xf1ecff), Tone(0xe2f7ec), Tone(0xfbfaff), Tone(0xffece4), Tone(0xe4eeff)]
        let base = f.pick(bodies)
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1 + 0.025 * f.swing2, tilt: CGFloat = 0
        var trail: CGFloat = 0, ripple: CGFloat = 2.4, drop: CGFloat = 0
        var arm = (lx: CGFloat(19), ly: CGFloat(38) + 2.5 * f.swing, rx: CGFloat(81), ry: CGFloat(41) - 2.5 * f.swing)
        var faceX: CGFloat = 50, faceY: CGFloat = 40
        switch f.mood {
        case .calm:
            arm.ry += 5 * max(0, f.twitch)
        case .sleepy:
            sx = 1.05
            sy = 0.93 + 0.01 * f.swing
            ripple = 0.8
            arm = (22, 29 + f.swing, 78, 29 - f.swing)
            faceY = 38
        case .startled:
            sx = 0.94
            sy = 1.08
            ripple = 1
            arm = (20, 61 + 2 * f.swing2, 80, 63 - 2 * f.swing2)
            faceY = 43
        case .fleeing:
            trail = 8
            ripple = 3.6
            drop = 4
            arm = (16, 46 + 3 * f.swing, 77, 31 - 2 * f.swing)
            faceX = 53
        case .dizzy:
            tilt = 0.13 * sin(t)
            arm = (20, 47 + 3 * f.swing, 80, 33 - 3 * f.swing)
        }
        k.with(about(50, 30, rot: tilt, sx: sx, sy: sy)) {
            k.nub(arm.lx, arm.ly, 6.5, 6.5, base)
            k.nub(arm.rx, arm.ry, 6.5, 6.5, base)
            let body = kawaiiGhostBody(trail: trail, ripple: ripple, drop: drop, t: t)
            k.body(body, base, depth: 0.3)
            k.shine(35, 71, 6, 3.4)
            kawaiiGhostHat(f, k)
            k.face(faceX, faceY, spread: 12, r: 2.7)
            k.marks(76, 82, 13)
        }
    }

    private static func kawaiiGhostBody(trail: CGFloat, ripple: CGFloat, drop: CGFloat, t: CGFloat) -> CGPath {
        let l: CGFloat = 21, r: CGFloat = 79, hem: CGFloat = 22, cy: CGFloat = 54
        let p = CGMutablePath()
        p.move(to: pt(l - trail, hem))
        p.addCurve(to: pt(l, cy), control1: pt(l - trail * 0.7, hem + 12), control2: pt(l, cy - 12))
        p.addArc(center: pt(50, cy), radius: 29, startAngle: .pi, endAngle: 0, clockwise: true)
        p.addCurve(to: pt(r - trail, hem), control1: pt(r, cy - 12), control2: pt(r - trail * 0.7, hem + 12))
        let xs = (0...3).map { r - trail - CGFloat($0) * (r - l) / 3 }
        for i in 0..<3 {
            let depth = 17 + drop + ripple * sin(t + CGFloat(i) * 2.1)
            let notch = i < 2 ? ripple * 0.5 * sin(t + CGFloat(i + 1) * 2.1) : 0
            p.addQuadCurve(to: pt(xs[i + 1], hem + notch), control: pt((xs[i] + xs[i + 1]) / 2 - trail * 0.35, hem - depth))
        }
        p.closeSubpath()
        return p
    }

    private static func kawaiiGhostHat(_ f: FigureFrame, _ k: KawaiiKit) {
        switch f.variant % 5 {
        case 0:
            k.bow(50, 86, 6.2, Tone(0xffb3c9))
        case 1:
            let leaf = Tone(0x9fdcae)
            k.stroke(arc(50, 82, 51, 91, dip: -1.5), leaf.dim(0.9), 2.2)
            k.nub(44.5, 92 + f.twitch, 6, 3.2, leaf, 0.45)
            k.nub(56.5, 93 - f.twitch, 6, 3.2, leaf, -0.45)
        case 2:
            let hat = Tone(0xc4b2f2), band = Tone(0xffc2a6)
            k.fill(smooth([37, 85, 63, 85, 57, 96, 66, 108, 49, 99], t: 0.55), hat)
            k.clip(smooth([37, 85, 63, 85, 57, 96, 66, 108, 49, 99], t: 0.55)) { k.fill(rrect(30, 87, 40, 4.5, 0), band) }
            k.fill(ell(50, 85, 21, 4.2), hat.dim(0.94))
        case 3:
            k.flower(70, 76, 5.4, Tone(0xffb8d0))
        default:
            k.fill(softStar(31, 77, 6.5, inner: 0.5, spin: .pi / 2 + 0.2), Tone(0xffe08a))
            k.fill(circ(31, 77, 1.6), Tone(0xffc95c))
        }
    }

    private static func kawaiiFestiveWitchHat(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ hat: Tone, _ band: Tone, _ rot: CGFloat = 0) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: s, y: s)) {
            let cone = smooth([-13, 0, 13, 0, 7, 11, 16, 23, -1, 14], t: 0.55)
            k.fill(cone, hat)
            k.clip(cone) { k.fill(rrect(-20, 2, 40, 4.5, 0), band) }
            k.fill(ell(0, 0, 21, 4.2), hat.dim(0.94))
        }
    }

    private static func kawaiiFestiveStar(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ rot: CGFloat = 0) {
        k.fill(softStar(x, y, r, inner: 0.5, spin: .pi / 2 + rot), Tone(0xffe08a))
        k.fill(circ(x, y, r * 0.25), Tone(0xffc95c))
    }

    private static func kawaiiFestiveCandyCane(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: s, y: s)) {
            let cane = CGMutablePath()
            cane.move(to: pt(0, -12))
            cane.addLine(to: pt(0, 4))
            cane.addCurve(to: pt(8, 4), control1: pt(0, 10), control2: pt(8, 10))
            let shape = cane.copy(strokingWithWidth: 4.4, lineCap: .round, lineJoin: .round, miterLimit: 2)
            k.fill(shape, Tone(0xfff8f4))
            k.clip(shape) {
                for i in 0..<6 {
                    let yy = CGFloat(i) * 4.6 - 14
                    k.stroke(line(-4, yy, 12, yy + 7), Tone(0xff8fa3), 1.9)
                }
            }
        }
    }

    private static func kawaiiFestiveGift(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ box: Tone, _ ribbon: Tone) {
        k.fill(rrect(x - s, y - s, s * 2, s * 1.7, s * 0.35), box)
        k.fill(rrect(x - s * 1.12, y + s * 0.45, s * 2.24, s * 0.6, s * 0.25), box.lift(0.15))
        k.fill(rrect(x - s * 0.22, y - s, s * 0.44, s * 2.05, 0), ribbon)
        k.bow(x, y + s * 1.15, s * 0.55, ribbon)
    }

    static func bat(_ f: FigureFrame, _ k: KawaiiKit) {
        let furs = [Tone(0xd8ccf3), Tone(0xffd2e2), Tone(0xcdeedf), Tone(0xe6dcea), Tone(0xcddcf8)]
        let base = f.pick(furs)
        let wingTone = base.dim(0.92).mix(Tone(0xa58fd8), 0.1)
        let t = f.t
        var spread: CGFloat = 0.12, beat: CGFloat = 0.5 * f.swing
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var faceX: CGFloat = 51, faceY: CGFloat = 45
        var earL: CGFloat = 0, earR: CGFloat = -0.14 * f.twitch
        var feetY: CGFloat = 27, feetRot: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            spread = -0.9
            beat = 0.05 * f.swing
            sx = 1.04
            sy = 0.94
            earL = 0.3
            earR = -0.3
            faceY = 43
            feetY = 30
        case .startled:
            spread = 0.7
            beat = 0.12 * f.swing2
            sx = 0.94
            sy = 1.08
            faceY = 47
            earL = -0.12
            earR = 0.12
            feetY = 24
        case .fleeing:
            spread = 0.05
            beat = 0.72 * f.swing
            faceX = 54
            earL = 0.42
            earR = 0.42
            tilt = -0.08
            feetRot = -0.5
        case .dizzy:
            tilt = 0.13 * sin(t)
            beat = 0.4 * sin(t)
        }
        k.with(about(50, 48, rot: tilt, sx: sx, sy: sy)) {
            k.both { s in
                var ang = spread + beat
                if f.mood == .dizzy { ang = spread + 0.42 * sin(t + (s > 0 ? 0 : 2.2)) }
                k.with(CGAffineTransform(translationX: 50 + s * 13, y: 51).rotated(by: s * ang).scaledBy(x: s, y: 1)) {
                    k.body(batWing(), wingTone, depth: 0.25)
                }
            }
            k.with(about(50, feetY + 4, rot: feetRot)) {
                k.nub(44, feetY, 3.6, 4.6, wingTone)
                k.nub(56, feetY, 3.6, 4.6, wingTone)
            }
            k.with(about(40, 63, rot: earL)) {
                k.fill(smooth([34, 60, 32, 81, 47, 66], t: 0.75), base)
                k.fill(smooth([37, 64, 35.5, 75, 43, 67], t: 0.75), Tone(0xffc2d6))
            }
            k.with(about(60, 63, rot: earR)) {
                k.fill(smooth([66, 60, 68, 81, 53, 66], t: 0.75), base)
                k.fill(smooth([63, 64, 64.5, 75, 57, 67], t: 0.75), Tone(0xffc2d6))
            }
            k.body(ell(50, 47, 23, 21), base)
            k.shine(39, 60, 4.6, 2.7)
            batAccessory(f, k)
            k.face(faceX, faceY, spread: 9.5, r: 2.6)
            if f.mood == .calm || f.mood == .sleepy || f.mood == .dizzy {
                k.fill(poly([faceX + 0.9, faceY - 2.3, faceX + 4.3, faceY - 2.3, faceX + 2.6, faceY - 5.9]), .white)
            }
            k.marks(70, 70, 12)
        }
    }

    private static func batWing() -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(0, 7))
        p.addQuadCurve(to: pt(31, 16), control: pt(13, 22))
        p.addQuadCurve(to: pt(37, 3), control: pt(40, 12))
        p.addQuadCurve(to: pt(25, -1), control: pt(33, -9))
        p.addQuadCurve(to: pt(13, -1), control: pt(19, -11))
        p.addQuadCurve(to: pt(0, -5), control: pt(5, -11))
        p.closeSubpath()
        return p
    }

    private static func batAccessory(_ f: FigureFrame, _ k: KawaiiKit) {
        switch f.variant % 5 {
        case 1:
            k.bow(63, 70, 6.6, Tone(0xb59cf0), -0.3)
        case 2:
            kawaiiFestiveWitchHat(k, 50, 66, 1.0, Tone(0xb9a2f0), Tone(0xffc2a6), 0.12)
        case 3:
            k.fill(ell(50, 21, 9.5, 7.8), Tone(0xffb979))
            k.fill(ell(50, 21, 3.8, 7.8), Tone(0xffca92))
            k.fill(rrect(48.6, 27.5, 2.8, 4.4, 1.4), Tone(0xa8d59c))
        case 4:
            kawaiiFestiveStar(k, 65, 73, 7.5, 0.25)
        default:
            break
        }
    }

    static func pumpkin(_ f: FigureFrame, _ k: KawaiiKit) {
        let skins = [Tone(0xffc690), Tone(0xfff3e6), Tone(0xffc59a), Tone(0xffe3a3), Tone(0xffc9d4)]
        let base = f.pick(skins)
        let rib = base.dim(0.96).mix(Tone(0xf0977c), 0.2)
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.06 * f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var tilt: CGFloat = 0
        var lh = (x: CGFloat(22), y: CGFloat(24) + 4 * f.stretch)
        var rh = (x: CGFloat(78), y: CGFloat(24) + 4 * f.stretch + 6 * max(0, f.twitch))
        var faceX: CGFloat = 50, faceY: CGFloat = 30
        var stemRot: CGFloat = 0.08 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.92
            sx *= 1.05
            lh = (25, 15)
            rh = (75, 15)
            stemRot = -0.4
            faceY = 28
        case .startled:
            sy *= 1.07
            sx *= 0.95
            lh = (15, 58 + f.swing2)
            rh = (85, 60 - f.swing2)
            stemRot = 0.15 * f.swing2
            faceY = 32
        case .fleeing:
            lh = (15, 36 + 3 * f.swing)
            rh = (81, 20 - 3 * f.swing)
            faceX = 53
            stemRot = 0.4
        case .dizzy:
            tilt = 0.13 * sin(f.t)
            lh = (19, 34 + 4 * f.swing)
            rh = (81, 34 - 4 * f.swing)
        }
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            k.nub(39, 6.5 + 3 * tuck, 6.5, 3.8, k.shade(rib))
            k.nub(61, 6.5 + 3 * tuck, 6.5, 3.8, k.shade(rib))
            let front = f.mood != .calm && f.mood != .sleepy
            if !front {
                k.nub(lh.x, lh.y, 5.6, 5.6, rib)
                k.nub(rh.x, rh.y, 5.6, 5.6, rib)
            }
            let hat = f.variant % 5 == 2
            if !hat {
                k.with(about(50, 58, rot: stemRot)) {
                    k.fill(rrect(46, 56, 8, 15, 4), Tone(0xb3d89b))
                    k.nub(59, 67, 7.5, 3.6, Tone(0xc8e9b2), 0.5 + 0.15 * f.twitch)
                }
            }
            k.body(ell(31, 34, 20, 25), rib, depth: 0.22)
            k.body(ell(69, 34, 20, 25), rib, depth: 0.22)
            k.body(ell(50, 35, 22, 28), base)
            if front {
                k.nub(lh.x, lh.y, 5.4, 5.4, base.lift(0.1))
                k.nub(rh.x, rh.y, 5.4, 5.4, base.lift(0.1))
            }
            k.shine(38, 52, 5, 3)
            k.face(faceX, faceY, spread: 11, r: 2.7)
            pumpkinAccessory(f, k, stemRot)
            k.marks(74, 66, 12)
        }
    }

    private static func pumpkinAccessory(_ f: FigureFrame, _ k: KawaiiKit, _ rot: CGFloat) {
        switch f.variant % 5 {
        case 1:
            k.with(about(50, 58, rot: rot)) { k.bow(58, 62, 6.8, Tone(0xffa0be), -0.2) }
        case 2:
            kawaiiFestiveWitchHat(k, 50, 60, 1.05, Tone(0xbda8f0), Tone(0xa8deb4), 0.08 + rot * 0.5)
        case 3:
            k.flower(64, 59, 7, Tone(0xffaecb))
        case 4:
            let ear = Tone(0xb59fd6)
            k.stroke(arc(30, 56, 70, 56, dip: -9), ear, 2.6)
            k.fill(smooth([32, 57, 31, 72, 42, 62], t: 0.7), ear)
            k.fill(smooth([68, 57, 69, 72, 58, 62], t: 0.7), ear)
        default:
            break
        }
    }

    static func spider(_ f: FigureFrame, _ k: KawaiiKit) {
        let furs = [Tone(0xdcd8ea), Tone(0xe4d5f8), Tone(0xcdeedd), Tone(0xffdccc), Tone(0xffd4e4)]
        let base = f.pick(furs)
        let legTone = k.shade(base).dim(0.95)
        let lw = k.width(5.8, minPt: 1.7)
        let t = f.t
        var bodyY: CGFloat = 34, sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var faceX: CGFloat = 50, faceY: CGFloat = 29
        var amp: CGFloat = 3 * f.energy, squeeze: CGFloat = 0.94, raise: [CGFloat] = [0, 0, 0, 0], lean: CGFloat = 0
        var wave = false
        switch f.mood {
        case .calm:
            wave = f.twitch > 0
        case .sleepy:
            bodyY = 30
            sx = 1.05
            sy = 0.92
            squeeze = 0.8
            faceY = 26
        case .startled:
            bodyY = 38
            sy = 1.06
            sx = 0.96
            raise = [20, 13, 4, 0]
            faceY = 34
        case .fleeing:
            lean = -5
            amp = 5
            faceX = 53
        case .dizzy:
            tilt = 0.13 * sin(t)
        }
        let hips: [[CGFloat]] = [[64, 40], [66, 34], [64, 27], [59, 21]]
        let knees: [[CGFloat]] = [[84, 52], [88, 40], [84, 27], [72, 18]]
        let feet: [[CGFloat]] = [[93, 39], [94, 23], [87, 7], [74, 4.5]]
        k.with(about(50, 4, rot: tilt)) {
            k.both { s in
                for i in 0..<4 {
                    let w = sin(2 * t + CGFloat(i) * 1.5 + (s > 0 ? 0.9 : 0))
                    var dy: CGFloat = w * amp
                    if i >= 2 { dy = max(0, w) * amp * 1.2 }
                    var up: CGFloat = raise[i]
                    if wave && s > 0 && i == 0 { up = 14 + 3 * f.twitch }
                    let hy: CGFloat = bodyY - 34 + hips[i][1]
                    let kx: CGFloat = 50 + s * (knees[i][0] - 50) * squeeze + lean * 0.5
                    let ky: CGFloat = knees[i][1] + (bodyY - 34) * 0.7 + dy * 0.6 + up * 0.7
                    let fx: CGFloat = 50 + s * (feet[i][0] - 50) * squeeze + lean
                    let fy: CGFloat = max(4.5, feet[i][1] + (bodyY - 34) * (i >= 2 ? 0 : 0.6) + dy + up)
                    let p = CGMutablePath()
                    p.move(to: pt(50 + s * (hips[i][0] - 50), hy))
                    p.addQuadCurve(to: pt(fx, fy), control: pt(kx, ky + 6))
                    k.stroke(p, legTone, lw)
                }
            }
            k.with(about(50, bodyY - 24, sx: sx, sy: sy)) {
                let body = ell(50, bodyY, 25, 23)
                k.body(body, base)
                if f.variant % 5 == 3 {
                    k.clip(body) {
                        for d in [[33, 46, 3.2], [67, 47, 3], [57, 54, 2.4], [28, 33, 2.2], [72, 33, 2.4], [42, 54, 2]] as [[CGFloat]] {
                            k.fill(circ(d[0], d[1] + bodyY - 34, d[2] * 1.35), Tone.white.alpha(0.75))
                        }
                    }
                }
                k.shine(39, bodyY + 13, 4.6, 2.7)
                k.face(faceX, faceY, spread: 10.5, r: 2.8)
                let eye = k.eyeTone
                if f.mood != .dizzy {
                    k.fill(circ(faceX - 4.6, faceY + 6.2, 1.5), eye.alpha(0.85))
                    k.fill(circ(faceX + 4.6, faceY + 6.2, 1.5), eye.alpha(0.85))
                }
                spiderAccessory(f, k, bodyY)
                k.marks(72, bodyY + 24, 12)
            }
        }
    }

    private static func spiderAccessory(_ f: FigureFrame, _ k: KawaiiKit, _ y: CGFloat) {
        let top = y + 23
        switch f.variant % 5 {
        case 1:
            kawaiiFestiveWitchHat(k, 52, top - 3, 0.9, Tone(0xbda8f0), Tone(0xffd36b), 0.15)
        case 2:
            k.flower(64, top - 5, 6.8, Tone(0xffaecb))
        case 3:
            k.bow(50, top + 1, 6.6, Tone(0xff98b8))
        case 4:
            kawaiiFestiveStar(k, 63, top - 4, 7.2, 0.2)
        default:
            let tuft = k.shade(f.pick([Tone(0xdcd8ea), Tone(0xe4d5f8), Tone(0xcdeedd), Tone(0xffdccc), Tone(0xffd4e4)])).dim(0.9)
            k.stroke(smooth([48, top - 1, 47, top + 5, 52, top + 7.5], closed: false), tuft, k.width(2.4, minPt: 0.9))
            k.stroke(smooth([52, top - 1, 54, top + 4, 58, top + 4.5], closed: false), tuft, k.width(2.4, minPt: 0.9))
        }
    }

    static func gingerbread(_ f: FigureFrame, _ k: KawaiiKit) {
        let cookies = [Tone(0xf2c9a0), Tone(0xf6d3ad), Tone(0xeec09c), Tone(0xf7dabb), Tone(0xefc4a8)]
        let base = f.pick(cookies)
        let icing = Tone(0xfffcf8)
        let e = f.energy
        let t = f.t
        let limbW = k.width(12, minPt: 3.4), armW = k.width(10.5, minPt: 3)
        var reach: CGFloat = 3.8 * e
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var faceX: CGFloat = 50, faceY: CGFloat = 59
        var lh = (x: CGFloat(25), y: CGFloat(34) - 3 * f.swing)
        var rh = (x: CGFloat(75), y: CGFloat(34) + 3 * f.swing)
        var stance: CGFloat = 0
        switch f.mood {
        case .calm:
            if f.twitch > 0 { rh = (79, 55 + 3 * f.twitch) }
        case .sleepy:
            lh = (31, 21)
            rh = (69, 21)
            sx = 1.04
            sy = 0.94
            reach = 1.5
            faceY = 58
        case .startled:
            lh = (23, 61 + f.swing2)
            rh = (77, 63 - f.swing2)
            sy = 1.05
            sx = 0.96
            stance = 4
            reach = 2
            faceY = 61
        case .fleeing:
            lh = (24 + 5 * f.swing, 46 + 5 * f.swing)
            rh = (75 - 5 * f.swing, 28 - 5 * f.swing)
            faceX = 53
        case .dizzy:
            tilt = 0.12 * sin(t)
            lh = (23, 42 + 4 * f.swing)
            rh = (77, 42 - 4 * f.swing)
        }
        let bob: CGFloat = 1.6 * f.bounce * e
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            for which in 0..<2 {
                let side: CGFloat = which == 0 ? -1 : 1
                let ph: CGFloat = which == 0 ? t : t + .pi
                let hx: CGFloat = 50 + side * (6.5 + stance)
                let fx: CGFloat = hx + side * stance * 0.6 + reach * cos(ph)
                let fy: CGFloat = 9.5 + max(0, -sin(ph)) * 4.5 * e
                k.stroke(line(hx, 24 + bob, fx, fy), base, limbW)
                k.stroke(wavy(fx - 4.2, fy + 2.4, fx + 4.2, fy + 2.4, waves: 1.5, amp: 0.9), icing, k.width(1.5, minPt: 0.55))
            }
            for (hand, side) in [(lh, CGFloat(-1)), (rh, CGFloat(1))] {
                let sxp: CGFloat = 50 + side * 10, syp: CGFloat = 39 + bob
                let hy: CGFloat = hand.y + bob
                k.stroke(line(sxp, syp, hand.x, hy), base, armW)
                let dx: CGFloat = hand.x - sxp, dy: CGFloat = hy - syp
                let l: CGFloat = max(0.01, hypot(dx, dy))
                let mx: CGFloat = sxp + dx * 0.8, my: CGFloat = syp + dy * 0.8
                let nx: CGFloat = -dy / l * 3.8, ny: CGFloat = dx / l * 3.8
                k.stroke(wavy(mx - nx, my - ny, mx + nx, my + ny, waves: 1.5, amp: 0.8), icing, k.width(1.5, minPt: 0.55))
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                if f.variant % 5 == 3 {
                    let tail: CGFloat = f.mood == .fleeing ? -10 : -2
                    k.fill(smooth([44, 42, 40, 30 + (f.mood == .fleeing ? 8 : 0), 44 + tail * 0.5, 26 + (f.mood == .fleeing ? 10 : 0), 48, 40], t: 0.8), Tone(0x9fdcc4))
                }
                k.body(ell(50, 31, 16.5, 15), base)
                var head: CGPath = circ(50, 62, 20)
                if f.variant % 5 == 4 { head = minus(head, uni([circ(67, 78, 5.5), circ(71, 72, 5), circ(64, 83, 4.6)])) }
                k.body(head, base, depth: 0.1)
                k.shine(39, 73, 4.8, 2.8)
                gingerbreadAccessory(f, k)
                k.face(faceX, faceY, spread: 10.5, r: 2.6)
                k.marks(70, 80, 12)
            }
        }
    }

    private static func gingerbreadAccessory(_ f: FigureFrame, _ k: KawaiiKit) {
        let pink = Tone(0xffa6c0), mint = Tone(0x9fdec4)
        switch f.variant % 5 {
        case 1:
            k.fill(circ(50, 34, 2.8), mint)
            k.fill(circ(50, 26, 2.8), mint)
            k.bow(50, 43.5, 6.4, Tone(0xff94ae))
        case 2:
            k.fill(heart(50, 34, 3.3), pink)
            k.fill(heart(50, 25.5, 3.3), pink)
            k.bow(63, 80, 7, Tone(0xff9fbc), -0.35)
        case 3:
            k.fill(circ(50, 31, 2.8), pink)
            k.fill(circ(50, 23.5, 2.8), pink)
            k.fill(rrect(36, 39.5, 28, 6.5, 3.25), Tone(0x9fdcc4))
            k.fill(rrect(36, 41, 28, 1.8, 0.9), Tone.white.alpha(0.7))
        default:
            k.fill(circ(50, 35, 2.8), pink)
            k.fill(circ(50, 26.5, 2.8), mint)
        }
    }

    static func present(_ f: FigureFrame, _ k: KawaiiKit) {
        let boxes = [Tone(0xffc6d8), Tone(0xc6eedb), Tone(0xdccdf7), Tone(0xffe6a4), Tone(0xc7dcfa)]
        let ribbons = [Tone(0x9fdfc3), Tone(0xff9fbd), Tone(0xffd36b), Tone(0xbea4f0), Tone(0xfffaf6)]
        let base = f.pick(boxes), ribbon = f.pick(ribbons)
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.06 * f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var lid: CGFloat = 3.5 * tuck, lidRot: CGFloat = 0, bowRot: CGFloat = 0.1 * f.twitch, tilt: CGFloat = 0
        var lh = (x: CGFloat(20), y: CGFloat(22) + 4 * f.stretch)
        var rh = (x: CGFloat(80), y: CGFloat(22) + 4 * f.stretch + 6 * max(0, f.twitch))
        var faceX: CGFloat = 50, faceY: CGFloat = 26
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.92
            sx *= 1.05
            lid = -1.5
            bowRot = -0.35
            lh = (22, 13)
            rh = (78, 13)
            faceY = 24
        case .startled:
            sy *= 1.05
            sx *= 0.96
            lid = 11 + f.swing2
            lidRot = 0.08 * f.swing2
            lh = (16, 48)
            rh = (84, 50)
            faceY = 28
        case .fleeing:
            lid = 2
            lidRot = 0.08
            bowRot = 0.45
            lh = (14, 34 + 3 * f.swing)
            rh = (82, 16 - 3 * f.swing)
            faceX = 53
        case .dizzy:
            tilt = 0.13 * sin(f.t)
            lidRot = -0.12 * sin(f.t)
            lid = 2
            lh = (18, 32 + 4 * f.swing)
            rh = (82, 32 - 4 * f.swing)
        }
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            k.nub(38, 6.5 + 3 * tuck, 6.5, 3.8, k.shade(base))
            k.nub(62, 6.5 + 3 * tuck, 6.5, 3.8, k.shade(base))
            k.nub(lh.x, lh.y, 5.2, 5.2, base.dim(0.97))
            k.nub(rh.x, rh.y, 5.2, 5.2, base.dim(0.97))
            let box = rrect(23, 7, 54, 40, 10)
            k.body(box, base, depth: 0.28)
            k.clip(box) {
                k.fill(rrect(45, 0, 10, 60, 0), ribbon)
                if f.variant % 5 == 1 {
                    for d in [[30, 41], [70, 40], [29, 14], [71, 14], [37, 34], [63, 34]] as [[CGFloat]] {
                        k.fill(circ(d[0], d[1], 2.6), Tone.white.alpha(0.65))
                    }
                }
            }
            k.shine(30, 40, 3.6, 2.2)
            k.face(faceX, faceY, spread: 13.5, r: 2.8)
            k.with(about(50, 46 + lid, rot: lidRot)) {
                let top = rrect(19, 44 + lid, 62, 14, 7)
                k.body(top, base.lift(0.18), shade: base.dim(0.97), depth: 0.22)
                k.clip(top) { k.fill(rrect(45, 40 + lid, 10, 22, 0), ribbon) }
                k.with(about(50, 58 + lid, rot: bowRot)) {
                    if f.variant % 5 == 2 { kawaiiFestiveCandyCane(k, 61, 66 + lid, 0.8, -0.35) }
                    k.fill(smooth([50, 58 + lid, 44, 52 + lid, 40, 50 + lid], closed: false), ribbon)
                    k.bow(50, 61 + lid, 8, ribbon)
                }
                if f.variant % 5 == 3 {
                    k.stroke(line(56, 60 + lid, 65, 51 + lid), Tone(0xc9a8e8), k.width(1.2, minPt: 0.5))
                    k.with(about(66, 47 + lid, rot: -0.25)) {
                        k.fill(rrect(61.5, 43 + lid, 9, 8, 2), Tone(0xfffaf4))
                        k.fill(heart(66, 47.4 + lid, 2.4), Tone(0xff9fbd))
                    }
                }
                if f.variant % 5 == 4 { kawaiiFestiveStar(k, 30, 51 + lid, 5, 0.2) }
            }
            k.marks(76, 64 + max(0, lid), 12)
        }
    }

    static func elf(_ f: FigureFrame, _ k: KawaiiKit) {
        let suits = [Tone(0xa6deb3), Tone(0xffb6b6), Tone(0xd5c3f6), Tone(0xb6d5fa), Tone(0x9fded4)]
        let trims = [Tone(0xffb0c2), Tone(0xa6deb3), Tone(0xffd36b), Tone(0xfff3e2), Tone(0xffc39c)]
        let suit = f.pick(suits), trim = f.pick(trims)
        let skin = Tone(0xffe5d3)
        let e = f.energy
        let t = f.t
        var reach: CGFloat = 3.6 * e
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var faceX: CGFloat = 51, faceY: CGFloat = 51
        var lh = (x: CGFloat(29), y: CGFloat(24) - 3 * f.swing)
        var rh = (x: CGFloat(71), y: CGFloat(24) + 3 * f.swing)
        var tip = (x: CGFloat(19) - 3 * f.twitch - 2 * f.swing, y: CGFloat(93))
        var earUp: CGFloat = 0.1 * f.twitch
        switch f.mood {
        case .calm:
            if f.twitch > 0 && f.variant % 5 != 2 && f.variant % 5 != 4 { rh = (76, 44 + 2 * f.twitch) }
        case .sleepy:
            sx = 1.04
            sy = 0.94
            reach = 1.5
            lh = (33, 17)
            rh = (67, 17)
            tip = (24, 72)
            earUp = -0.3
            faceY = 50
        case .startled:
            sy = 1.05
            sx = 0.96
            lh = (25, 46 + f.swing2)
            rh = (75, 48 - f.swing2)
            tip = (30, 100)
            earUp = 0.25
            faceY = 53
        case .fleeing:
            lh = (26 + 4 * f.swing, 34 + 4 * f.swing)
            rh = (73 - 4 * f.swing, 18 - 4 * f.swing)
            tip = (6, 84 + 2 * f.swing)
            earUp = -0.2
            faceX = 54
        case .dizzy:
            tilt = 0.12 * sin(t)
            tip = (19 + 6 * sin(t), 92)
            lh = (26, 30 + 4 * f.swing)
            rh = (74, 30 - 4 * f.swing)
        }
        let bob: CGFloat = 1.4 * f.bounce * e
        let legW = k.width(7, minPt: 2.2)
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            for which in 0..<2 {
                let side: CGFloat = which == 0 ? -1 : 1
                let ph: CGFloat = which == 0 ? t : t + .pi
                let hx: CGFloat = 50 + side * 6
                let fx: CGFloat = hx + reach * cos(ph)
                let fy: CGFloat = 8 + max(0, -sin(ph)) * 4.2 * e
                k.stroke(line(hx, 16 + bob, fx, fy), trim.mix(.white, 0.25), legW)
                k.nub(fx + 2.5, fy - 2.4, 6, 3.6, suit.dim(0.9), 0.12)
                k.fill(circ(fx + 8.2, fy - 0.6, 2), suit.dim(0.9))
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                let armW = k.width(7.5, minPt: 2.3)
                for (hand, side) in [(lh, CGFloat(-1)), (rh, CGFloat(1))] {
                    k.stroke(line(50 + side * 11, 32, hand.x, hand.y), suit.dim(0.97), armW)
                    k.fill(circ(hand.x, hand.y, 3.9), skin)
                }
                let tunic = ell(50, 25, 17.5, 15)
                k.body(tunic, suit)
                k.clip(tunic) { k.fill(rrect(30, 19, 40, 4.8, 0), trim) }
                k.fill(rrect(47, 18.4, 6, 6, 1.6), Tone(0xffd36b))
                k.with(about(34, 58, rot: earUp)) {
                    k.fill(smooth([35, 61, 34, 51, 17, 63], t: 0.6), skin)
                    k.fill(smooth([33, 59, 32.5, 54, 24, 61], t: 0.6), Tone(0xffc6cf))
                }
                k.with(about(66, 58, rot: -earUp)) {
                    k.fill(smooth([65, 61, 66, 51, 83, 63], t: 0.6), skin)
                    k.fill(smooth([67, 59, 67.5, 54, 76, 61], t: 0.6), Tone(0xffc6cf))
                }
                k.body(circ(50, 54, 19), skin, depth: 0.1)
                let cone = CGMutablePath()
                cone.move(to: pt(31, 69))
                cone.addQuadCurve(to: pt(tip.x, tip.y), control: pt(32, 90))
                cone.addQuadCurve(to: pt(69, 69), control: pt(64, 97))
                cone.closeSubpath()
                k.body(cone, suit, depth: 0.0)
                k.fill(rrect(29, 64, 42, 8.5, 4.25), trim)
                if f.variant % 5 == 1 {
                    k.fill(circ(tip.x, tip.y - 1, 4.6), Tone(0xffd36b))
                    k.fill(rrect(tip.x - 2.6, tip.y - 2.2, 5.2, 1.4, 0.7), Tone(0xd9a640))
                } else {
                    k.fill(circ(tip.x, tip.y, 5), trim)
                }
                k.shine(41, 64, 3.6, 2.1)
                k.face(faceX, faceY, spread: 9.5, r: 2.5)
                elfAccessory(f, k, rh)
                k.marks(70, 74, 11)
            }
        }
    }

    private static func elfAccessory(_ f: FigureFrame, _ k: KawaiiKit, _ rh: (x: CGFloat, y: CGFloat)) {
        switch f.variant % 5 {
        case 2:
            kawaiiFestiveCandyCane(k, rh.x + 1, rh.y + 4, 0.85, -0.15)
            k.fill(circ(rh.x, rh.y, 3.9), Tone(0xffe5d3))
        case 3:
            let red = Tone(0xff9fae)
            k.fill(rrect(35, 34, 30, 6.5, 3.25), Tone(0xfff6ee))
            k.clip(rrect(35, 34, 30, 6.5, 3.25)) {
                for i in 0..<4 { k.fill(rrect(37 + CGFloat(i) * 8, 30, 3.5, 14, 0), red) }
            }
            let tail: CGFloat = f.mood == .fleeing ? -9 : 0
            k.fill(rrect(36 + tail, 22 + (tail < 0 ? 6 : 0), 6, 13, 3), red)
        case 4:
            kawaiiFestiveGift(k, rh.x + 2, rh.y + 1, 7.2, Tone(0xffc0d4), Tone(0xa6deb3))
            k.fill(circ(rh.x + 8, rh.y + 1, 3.6), Tone(0xffe5d3))
        default:
            break
        }
    }

    static func reindeer(_ f: FigureFrame, _ k: KawaiiKit) {
        let furs = [Tone(0xe9c8a8), Tone(0xdec1a6), Tone(0xf8f1ea), Tone(0xeec7b6), Tone(0xe4cdb9)]
        let noses = [Tone(0xff7286), Tone(0xd99aa0), Tone(0xe39ba2), Tone(0xff9fbd), Tone(0xd6a0a4)]
        let base = f.pick(furs), nose = f.pick(noses)
        let muzzle = Tone(0xfff4e8)
        let antler = Tone(0xe6cba2)
        let hoof = base.mix(Tone(0x9b7f8f), 0.38)
        let e = f.energy
        let t = f.t
        var reach: CGFloat = 4.5 * e
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var faceX: CGFloat = 55, faceY: CGFloat = 40
        var earRot: CGFloat = 0, earTw: CGFloat = 0.25 * f.twitch
        var legs = true
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.06
            sy = 0.9
            earRot = -0.45
            reach = 0
            legs = false
            faceY = 37
        case .startled:
            sy = 1.07
            sx = 0.95
            earRot = 0.4
            reach = 2
            faceY = 42
        case .fleeing:
            earRot = -0.25
            earTw = 0
            faceX = 58
        case .dizzy:
            tilt = 0.12 * sin(t)
        }
        let bob: CGFloat = 1.5 * f.bounce * e
        let aw = k.width(4.4, minPt: 1.4)
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            if legs {
                for i in 0..<4 {
                    let back = i >= 2
                    let ph: CGFloat = t + (i % 2 == 0 ? 0 : .pi) + (back ? .pi * 0.5 : 0)
                    let hx: CGFloat = [41, 59, 32, 68][i]
                    let fx: CGFloat = hx + reach * cos(ph)
                    let fy: CGFloat = 6.5 + max(0, -sin(ph)) * 3 * e + (back ? 1.5 : 0)
                    k.nub(fx, fy, 5.6, 4.4, back ? hoof.dim(0.92) : hoof)
                }
            }
            k.fill(circ(22, 26, 5.6), muzzle)
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                k.both { s in
                    let cx: CGFloat = 50 + s * 13
                    let a = CGMutablePath()
                    a.move(to: pt(cx, 60))
                    a.addQuadCurve(to: pt(50 + s * 22, 89), control: pt(50 + s * 20, 72))
                    k.stroke(a, antler, aw)
                    k.stroke(arc(50 + s * 19, 76, 50 + s * 31, 82, dip: 2.5), antler, aw)
                    k.stroke(arc(50 + s * 21, 84, 50 + s * 13, 90, dip: -1.5), antler, aw)
                }
                for s in [CGFloat(-1), 1] {
                    let rot: CGFloat = s * (0.38 + earRot) + (s > 0 ? -earTw : 0)
                    let ex: CGFloat = 50 + s * 27
                    k.with(about(50 + s * 20, 58, rot: rot)) {
                        k.nub(ex, 58, 8.5, 4.2, base)
                        k.nub(ex + s * 1, 58, 5, 2.2, Tone(0xffc8cf))
                    }
                }
                let body = ell(50, 38, 28, 28)
                k.body(body, base)
                reindeerAccessory(f, k, faceX)
                k.fill(ell(faceX, 31, 12.5, 8.5), muzzle)
                k.shine(37, 55, 4.8, 2.8)
                k.face(faceX, faceY, spread: 11.5, r: 2.6, mouth: .none)
                k.mouth(faceX, 29.2, 5.2, kind: .cat)
                if f.variant % 5 == 0 { k.glow(faceX, 35, 9, Tone(0xff8fa0), 0.45) }
                k.fill(ell(faceX, 35, 4.4, 3.5), nose)
                k.fill(circ(faceX - 1.4, 36.2, 1.1), Tone.white.alpha(0.85))
                k.marks(74, 70, 12)
            }
        }
    }

    private static func reindeerAccessory(_ f: FigureFrame, _ k: KawaiiKit, _ fx: CGFloat) {
        switch f.variant % 5 {
        case 1:
            let scarf = Tone(0xa6deb3)
            k.clip(ell(50, 38, 28, 28)) {
                k.fill(rrect(18, 17, 64, 6.5, 3), scarf)
                k.fill(rrect(18, 19, 64, 1.6, 0.8), Tone.white.alpha(0.6))
            }
            let tail: CGFloat = f.mood == .fleeing ? -8 : 0
            k.fill(rrect(33 + tail, 6 + (tail < 0 ? 6 : 0), 6.5, 14, 3.2), scarf)
        case 2:
            k.stroke(arc(29, 21, 75, 21, dip: 4), Tone(0xff9fae), k.width(3.2, minPt: 1.1))
            k.fill(circ(fx, 16.5, 3.6), Tone(0xffd36b))
            k.fill(circ(fx, 15.4, 1), Tone(0xc99a3a))
        case 3:
            k.nub(28, 81, 6.4, 3.2, Tone(0x9fd8a8), 0.6)
            k.nub(37, 83.5, 6.4, 3.2, Tone(0x9fd8a8), -0.4)
            k.fill(circ(31.5, 79, 2.6), Tone(0xff8f9f))
            k.fill(circ(35.5, 78.2, 2.3), Tone(0xff8f9f))
        case 4:
            k.bow(67, 80, 6.4, Tone(0xff9fbc), 0.3)
        default:
            break
        }
    }

    static func blackCat(_ f: FigureFrame, _ k: KawaiiKit) {
        let furs = [Tone(0xb4a4cd), Tone(0xaab1cd), Tone(0xbda3ca), Tone(0xaaa2ba), Tone(0xa2abd6)]
        let base = f.pick(furs)
        let paw = base.lift(0.12)
        let e = f.energy
        let t = f.t
        var reach: CGFloat = 4.5 * e
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var faceX: CGFloat = 55, faceY: CGFloat = 37
        var earRot: CGFloat = 0
        let earTw: CGFloat = 0.22 * f.twitch
        var legs = true
        let sw: CGFloat = 3 * sin(t) + 3 * f.twitch
        var tail: [CGFloat] = [30, 18, 12, 24, 7 + sw * 0.4, 40, 11 + sw, 53, 19 + sw, 54]
        var tailW = k.width(7.2, minPt: 2.2)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.09
            sy = 0.88
            legs = false
            earRot = 0.1
            tail = [34, 10, 46, 5.5, 60, 5.5, 70, 8, 74 + 0.5 * f.swing, 13]
            faceY = 34
        case .startled:
            sy = 1.1
            sx = 0.93
            earRot = -0.08
            reach = 1.5
            tail = [30, 22, 22, 30, 19 + f.swing2, 46, 19 + 1.5 * f.swing2, 62, 20, 70]
            tailW = k.width(11, minPt: 3)
            faceY = 39
        case .fleeing:
            earRot = 0.45
            tail = [30, 24, 18, 30, 6, 33 + 3 * f.swing, -4, 34 + 4 * f.swing, -8, 38 + 3 * f.swing]
            faceX = 58
        case .dizzy:
            tilt = 0.12 * sin(t)
            tail = [30, 18, 14, 22, 8 + 4 * sin(t), 34, 14 + 6 * sin(t + 1), 46, 22, 44]
        }
        let bob: CGFloat = 1.4 * f.bounce * e
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            if f.mood != .sleepy { k.stroke(smooth(tail, closed: false, t: 0.9), base, tailW) }
            if legs {
                for i in 0..<4 {
                    let back = i >= 2
                    let ph: CGFloat = t + (i % 2 == 0 ? 0 : .pi) + (back ? .pi * 0.5 : 0)
                    let hx: CGFloat = [42, 60, 33, 68][i]
                    let fx: CGFloat = hx + reach * cos(ph)
                    let fy: CGFloat = 6.5 + max(0, -sin(ph)) * 3 * e + (back ? 1.2 : 0)
                    let pt0 = f.variant % 5 == 4 && !back ? Tone(0xfbf6ff) : (back ? k.shade(base) : paw)
                    k.nub(fx, fy, 5.6, 4.4, pt0)
                }
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                k.with(about(38, 58, rot: earRot)) {
                    k.fill(smooth([28, 54, 31, 78, 47, 62], t: 0.7), base)
                    k.fill(smooth([32, 59, 33.5, 71, 42, 63], t: 0.7), Tone(0xffbfd2))
                }
                k.with(about(64, 58, rot: earRot - earTw)) {
                    k.fill(smooth([74, 54, 72, 78, 55, 62], t: 0.7), base)
                    k.fill(smooth([70, 59, 69, 71, 60, 63], t: 0.7), Tone(0xffbfd2))
                }
                let body = ell(50, 36, 27, 27)
                k.body(body, base)
                if f.mood == .sleepy { k.stroke(smooth(tail, closed: false, t: 0.9), k.shade(base), tailW) }
                k.fill(ell(faceX, faceY - 4.4, 9.5, 6.2), base.lift(0.32))
                let wh = Tone.white.alpha(0.55)
                let ww = k.width(1.1, minPt: 0.45)
                k.stroke(line(faceX - 15, faceY - 3, faceX - 23, faceY - 1.5), wh, ww)
                k.stroke(line(faceX - 15, faceY - 5.5, faceX - 23, faceY - 6.5), wh, ww)
                k.stroke(line(faceX + 15, faceY - 3, faceX + 23, faceY - 1.5), wh, ww)
                k.stroke(line(faceX + 15, faceY - 5.5, faceX + 23, faceY - 6.5), wh, ww)
                k.shine(37, 52, 4.8, 2.8)
                blackCatAccessory(f, k, faceX)
                k.face(faceX, faceY, spread: 10.5, r: 2.7)
                k.fill(ell(faceX, faceY - 0.2, 1.5, 1.1), Tone(0xff9db8))
                k.marks(73, 70, 12)
            }
        }
    }

    private static func blackCatAccessory(_ f: FigureFrame, _ k: KawaiiKit, _ fx: CGFloat) {
        let cw = k.width(3.4, minPt: 1.2)
        switch f.variant % 5 {
        case 1:
            kawaiiFestiveWitchHat(k, 51, 61, 1.05, Tone(0x9e86d6), Tone(0xffc690), 0.12)
        case 2:
            k.bow(68, 70, 4.8, Tone(0xffa6c0), -0.4)
            k.stroke(arc(30, 21, 76, 21, dip: 4), Tone(0xffa6c0), cw)
        case 3:
            let band = Tone(0xffc690)
            k.fill(smooth([28, 24, 76, 24, fx + 4, 12, fx - 4, 12], t: 0.5), band)
            k.fill(circ(fx - 3, 17, 1.3), Tone.white.alpha(0.8))
            k.fill(circ(fx + 4, 19, 1.3), Tone.white.alpha(0.8))
        case 4:
            k.stroke(arc(30, 21, 76, 21, dip: 4), Tone(0xa6deb3), cw)
            kawaiiFestiveStar(k, fx, 15.5, 4.2)
        default:
            k.stroke(arc(30, 21, 76, 21, dip: 4), Tone(0xff9fb8), cw)
            k.fill(circ(fx, 16, 3.6), Tone(0xffd36b))
            k.fill(circ(fx, 15, 1), Tone(0xc99a3a))
        }
    }

    static func santa(_ f: FigureFrame, _ k: KawaiiKit) {
        let suits = [Tone(0xff9d9d), Tone(0xffa2a0), Tone(0xa6dcb6), Tone(0xa9c8f6), Tone(0xeaa2c6)]
        let suit = f.pick(suits)
        let fur = Tone(0xfffaf5), skin = Tone(0xffe2d0), dark = Tone(0x9c80a0), gold = Tone(0xffd36b)
        let e = f.energy
        let t = f.t
        var reach: CGFloat = 5 * e
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var hx: CGFloat = 52, hy: CGFloat = 59
        var lh = (x: CGFloat(25), y: CGFloat(26) - 3 * f.swing)
        var rh = (x: CGFloat(76), y: CGFloat(26) + 3 * f.swing)
        var tip = (x: CGFloat(24) - 2 * f.swing - 2 * f.twitch, y: CGFloat(89))
        var hatUp: CGFloat = 0, hatRot: CGFloat = 0
        switch f.mood {
        case .calm:
            if f.twitch > 0 && f.variant % 5 < 2 { rh = (80, 46 + 2 * f.twitch) }
        case .sleepy:
            sx = 1.05
            sy = 0.93
            reach = 1
            lh = (29, 17)
            rh = (71, 17)
            tip = (30, 66)
            hy = 57
        case .startled:
            sy = 1.05
            sx = 0.96
            reach = 2
            lh = (21, 50 + f.swing2)
            rh = (79, 52 - f.swing2)
            hatUp = 4.5 + f.swing2
            hatRot = 0.12
            tip = (28, 96)
        case .fleeing:
            lh = (22 + 5 * f.swing, 38 + 4 * f.swing)
            rh = (76 - 5 * f.swing, 20 - 4 * f.swing)
            tip = (8, 80 + 2 * f.swing)
            hx = 55
        case .dizzy:
            tilt = 0.12 * sin(t)
            hatRot = 0.15 * sin(t + 1)
            lh = (21, 34 + 4 * f.swing)
            rh = (79, 34 - 4 * f.swing)
        }
        let bob: CGFloat = 1.5 * f.bounce * e
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            if f.variant % 5 == 1 {
                let sack = Tone(0xe9d3b4)
                k.body(smooth([10, 30, 12, 52, 22, 64, 34, 58, 36, 34, 24, 24], t: 0.9), sack)
                k.fill(circ(26, 61, 3), Tone(0xc9a8e8))
            }
            for which in 0..<2 {
                let side: CGFloat = which == 0 ? -1 : 1
                let ph: CGFloat = which == 0 ? t : t + .pi
                let fx: CGFloat = 50 + side * 10 + reach * cos(ph)
                let fy: CGFloat = 6.5 + max(0, -sin(ph)) * 3.2 * e
                k.nub(fx + 1.5, fy, 7.2, 4.6, dark)
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                let armW = k.width(9.5, minPt: 2.8)
                for (hand, side) in [(lh, CGFloat(-1)), (rh, CGFloat(1))] {
                    k.stroke(line(50 + side * 15, 38, hand.x, hand.y), suit.dim(0.97), armW)
                    k.fill(circ(hand.x, hand.y, 4.8), dark)
                }
                let body = ell(50, 31, 26.5, 24)
                k.body(body, suit)
                k.clip(body) {
                    k.fill(rrect(46.5, 0, 7, 40, 0), fur)
                    k.fill(rrect(18, 20, 64, 6.5, 0), dark)
                }
                k.fill(rrect(44.5, 18.6, 11, 9.2, 2.4), gold)
                k.fill(rrect(47.4, 21, 5.2, 4.4, 1.2), dark)
                k.body(circ(hx, hy, 16), skin, depth: 0.1)
                for c in [[hx - 13, hy - 6, 7], [hx - 9, hy - 14, 8], [hx, hy - 18, 9], [hx + 9, hy - 14, 8], [hx + 13, hy - 6, 7], [hx, hy - 10, 8]] as [[CGFloat]] {
                    k.fill(circ(c[0], c[1], c[2]), fur)
                }
                k.fill(ell(hx, hy - 23, 14, 6), k.shade(fur).alpha(0.6))
                k.fill(ell(hx - 4.2, hy - 6.4, 4.8, 2.7, 0.3), Tone(0xf1ebf6))
                k.fill(ell(hx + 4.2, hy - 6.4, 4.8, 2.7, -0.3), Tone(0xf1ebf6))
                k.fill(circ(hx, hy - 3.6, 2.7), Tone(0xffb2a6))
                k.blush(hx - 10.5, hy - 2.5, 3.4, 2)
                k.blush(hx + 10.5, hy - 2.5, 3.4, 2)
                k.eye(hx - 7, hy + 1.5, 2.4, side: -1)
                k.eye(hx + 7, hy + 1.5, 2.4, side: 1)
                k.mouth(hx, hy - 10.5, 4.6, kind: .smile)
                k.with(about(hx, 72 + hatUp, rot: hatRot)) {
                    let cone = CGMutablePath()
                    cone.move(to: pt(hx - 16, 71 + hatUp))
                    cone.addQuadCurve(to: pt(tip.x, tip.y + hatUp), control: pt(hx - 14, 92 + hatUp))
                    cone.addQuadCurve(to: pt(hx + 16, 71 + hatUp), control: pt(hx + 12, 97 + hatUp))
                    cone.closeSubpath()
                    k.body(cone, suit, depth: 0.0)
                    k.fill(rrect(hx - 19, 66 + hatUp, 38, 9, 4.5), fur)
                    k.fill(circ(tip.x, tip.y + hatUp, 5.2), fur)
                    if f.variant % 5 == 3 {
                        let flake = Tone(0xffffff)
                        for i in 0..<3 {
                            let a = CGFloat(i) * .pi / 3
                            k.stroke(line(hx + 4 - cos(a) * 3.6, 81 + hatUp - sin(a) * 3.6, hx + 4 + cos(a) * 3.6, 81 + hatUp + sin(a) * 3.6), flake, k.width(1.5, minPt: 0.6))
                        }
                    }
                }
                santaAccessory(f, k, rh)
                k.marks(73, 78, 12)
            }
        }
    }

    private static func santaAccessory(_ f: FigureFrame, _ k: KawaiiKit, _ rh: (x: CGFloat, y: CGFloat)) {
        switch f.variant % 5 {
        case 2:
            kawaiiFestiveCandyCane(k, rh.x + 1, rh.y + 5, 0.95, -0.15)
            k.fill(circ(rh.x, rh.y, 4.8), Tone(0x9c80a0))
        case 4:
            kawaiiFestiveGift(k, rh.x + 3, rh.y + 1, 8, Tone(0xc6eedb), Tone(0xffa6c0))
            k.fill(circ(rh.x + 9.5, rh.y + 1, 4.4), Tone(0x9c80a0))
        default:
            break
        }
    }
}
