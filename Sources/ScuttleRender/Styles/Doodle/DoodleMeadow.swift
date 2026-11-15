import Foundation
import CoreGraphics
import ScuttleCore

extension DoodleArt {
    static func ladybird(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xff3b30), Tone(0xc4122f), Tone(0x2a1f33)),
            (Tone(0xffd21f), Tone(0xff7a00), Tone(0x2a1f33)),
            (Tone(0xff6fae), Tone(0xe0246e), Tone(0x7a1450)),
            (Tone(0xff8a1f), Tone(0xd9480f), Tone(0x2a1f33)),
            (Tone(0x3fb0ff), Tone(0x1f62e0), Tone(0xffffff)),
        ]
        let (shell, mk, spot) = f.pick(looks)
        let head = Tone(0x2e2640), hk = Tone(0x8a6cff)
        let tw = meadowThin(k)
        var legH: CGFloat = 9, rot: CGFloat = 0, tilt: CGFloat = 0, faceX: CGFloat = 0, headDy: CGFloat = 0
        var ant: CGFloat = 0.35 + 0.22 * f.twitch
        var step: CGFloat = 5 * f.energy
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            legH = 1.5
            ant = 1.25
            step = 0
            headDy = -3
        case .startled:
            legH = 16
            ant = -0.1
            tilt = 0.12
            headDy = 2
        case .fleeing:
            legH = 10
            ant = -1.1 + 0.15 * f.swing
            faceX = 2.5
            step = 7
        case .dizzy:
            rot = 0.12 * sin(f.t)
            ant = 0.4 + 0.5 * f.swing
        }
        let base: CGFloat = 5 + legH + 0.8 * f.swing2 * min(1, f.energy)
        tilt += 0.03 * f.swing2 * min(1, f.energy)
        k.with(about(50, 5, rot: rot, sx: 1.08, sy: 1.08)) {
            if f.mood == .fleeing || f.mood == .startled {
                let flap: CGFloat = f.frameIndex % 2 == 0 ? 0 : 0.35
                meadowPart(k, ell(28, base + 38, 9, 20, 0.9 + flap), Tone(0xe6f6ff), Tone(0x5aa8ff), seed: 9, w: tw)
            }
            for i in 0..<3 {
                let lx: CGFloat = 32 + CGFloat(i) * 17
                let ph = f.t + CGFloat(i) * 2.1
                let dx = step * sin(ph)
                let up = max(0, cos(ph)) * 2.5 * min(1, f.energy)
                k.stick([lx, base + 4, lx + dx * 0.5 + 3, base - legH * 0.4 + up * 0.5 + 1, lx + dx + 1, 5 + up], hk, seed: 1 + i, w: tw)
            }
            let ax: CGFloat = 84, ay: CGFloat = base + 22 + headDy
            for i in 0..<2 {
                let a = ant + CGFloat(i) * 0.45
                let tx = ax + sin(a) * 16, ty = ay + cos(a) * 16
                k.stick([ax - 3 + CGFloat(i) * 5, ay, (ax + tx) / 2 - cos(a) * 2, (ay + ty) / 2 + sin(a) * 2, tx, ty], hk, seed: 5 + i, w: tw)
                k.dot(tx, ty, 3, 3, hk, seed: 7 + i)
            }
            k.with(about(76, base, rot: tilt)) {
                meadowPart(k, meadowDome(44, base, 33, 40), shell, mk, seed: 10)
                k.marker(smooth([44, base + 40, 54, base + 22, 58, base + 3], closed: false), mk, tw, seed: 11)
                let spots: [CGFloat] = [26, base + 13, 6.5, 37, base + 29, 6.5, 59, base + 25, 6, 50, base + 9, 5]
                for i in 0..<4 {
                    let x = spots[i * 3], y = spots[i * 3 + 1], r = spots[i * 3 + 2]
                    if f.variant % 5 == 2 {
                        k.fill(heart(x, y, r * 1.05), spot)
                    } else {
                        k.dot(x, y, r, r, spot, seed: 12 + i)
                    }
                }
                if f.variant % 5 == 3 {
                    meadowPart(k, smooth([30, base + 38, 42, base + 54, 56, base + 58, 48, base + 44], t: 0.8), Tone(0x6fd84a), Tone(0x1f9a3a), seed: 16, w: tw)
                    k.marker(line(32, base + 38, 50, base + 52), Tone(0x1f9a3a), tw, seed: 17)
                }
            }
            let hy: CGFloat = base + 11 + headDy
            meadowPart(k, circ(80 + faceX * 0.3, hy, 15), head, hk, seed: 18)
            meadowGoggle(k, 75.5 + faceX, hy + 4, 5, ring: nil, side: -1, seed: 20)
            meadowGoggle(k, 87 + faceX, hy + 4, 5, ring: nil, side: 1, seed: 23)
            k.mouth(81.5 + faceX, hy - 6, 8, ink: .white, seed: 26)
            switch f.variant % 5 {
            case 1:
                meadowFlower(k, 74, hy + 16, 7.5, Tone(0xff6fae), Tone(0xe0246e), seed: 30)
            case 2:
                meadowBow(k, 76, hy + 15, 6.5, Tone(0xffd21f), Tone(0xff8a00), seed: 30)
            case 4:
                meadowHat(k, 79, hy + 13, 8, Tone(0xffd21f), Tone(0xff7a00), rot: -0.25, seed: 30)
            default:
                break
            }
            k.marks(98, base + 36, 12, ink: hk, seed: 40)
        }
    }

    static func bumblebee(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xffd21f), Tone(0xff7a00), Tone(0x4a2a1a)),
            (Tone(0xffd21f), Tone(0xff7a00), Tone(0x4a2a1a)),
            (Tone(0xff7ab8), Tone(0xd61f7a), Tone(0x5a1f5a)),
            (Tone(0xffa23a), Tone(0xe0400a), Tone(0x4a2a1a)),
            (Tone(0x6fd8ff), Tone(0x1f7ae0), Tone(0x1f2a5a)),
        ]
        let (body, mk, stripe) = f.pick(looks)
        let tw = meadowThin(k)
        let buzz = f.frameIndex % 3
        var cy: CGFloat = 50, rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, faceX: CGFloat = 0
        var ant: CGFloat = 0.3 + 0.25 * f.twitch
        var wing: CGFloat = [-0.45, 0.0, 0.4][buzz]
        var legTrail: CGFloat = 0, legSpread: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            cy = 44
            sx = 1.05
            sy = 0.93
            wing = 0.75
            ant = 1.2
        case .startled:
            sx = 0.94
            sy = 1.08
            ant = -0.15
            wing = [-0.75, -0.3, 0.1][buzz]
            legSpread = 5
        case .fleeing:
            rot = -0.06
            faceX = 2.5
            ant = -0.95
            wing = [-0.2, 0.35, 0.85][buzz]
            legTrail = 8
        case .dizzy:
            rot = 0.13 * sin(f.t)
            ant = 0.4 + 0.5 * f.swing
        }
        k.with(about(46, cy, rot: rot, sx: sx, sy: sy)) {
            for i in 0..<3 {
                let lx: CGFloat = 34 + CGFloat(i) * 11
                let sw = 1.5 * sin(f.t + CGFloat(i))
                k.stick([lx, cy - 20, lx - 2 - legTrail + sw - legSpread * CGFloat(1 - i), cy - 30 + legTrail * 0.4], mk, seed: 1 + i, w: tw)
            }
            meadowPart(k, poly([19, cy + 4, 6, cy - 1, 19, cy - 7]), stripe, mk, seed: 19, w: tw)
            let ax: CGFloat = 64, ay: CGFloat = cy + 20
            for i in 0..<2 {
                let a = ant + CGFloat(i) * 0.5
                let tx = ax + sin(a) * 16, ty = ay + cos(a) * 16
                k.stick([ax - 3 + CGFloat(i) * 6, ay, tx, ty], mk, seed: 4 + i, w: tw)
                k.dot(tx, ty, 3.4, 3.4, mk, seed: 6 + i)
            }
            let shape = ell(46, cy, 30, 24)
            meadowFill(k, shape, body, seed: 8)
            k.clip(ell(46, cy, 29, 23)) {
                k.marker(line(27, cy - 30, 31, cy + 30), stripe, 7.5, seed: 9)
                k.marker(line(41, cy - 30, 44, cy + 30), stripe, 7.5, seed: 10)
            }
            k.marker(shape, mk, meadowW(k), seed: 11)
            for i in 0..<2 {
                let a = wing + CGFloat(i) * 0.8 - 0.25
                let rx: CGFloat = 36 + CGFloat(i) * 12, ry: CGFloat = cy + 18
                let wx = rx - sin(a) * 13, wy = ry + cos(a) * 13
                meadowPart(k, ell(wx, wy, 8.5, 14, a), Tone(0xdcf2ff), Tone(0x3f8cff), seed: 12 + i, w: tw)
            }
            k.eye(58 + faceX, cy + 4, 4, 5.2, side: -1, seed: 14)
            k.eye(70 + faceX, cy + 4, 4, 5.2, side: 1, seed: 15)
            meadowCheeks(k, 54 + faceX, 75 + faceX, cy - 6, 3.2, seed: 16)
            k.mouth(64.5 + faceX, cy - 7, 9, seed: 18)
            switch f.variant % 5 {
            case 1:
                meadowCrown(k, 63, cy + 22, 8, seed: 30)
            case 2:
                meadowBow(k, 64, cy + 21, 6, Tone(0x3fd0ff), Tone(0x1f7ae0), seed: 30)
            case 3:
                k.stick([74, cy - 14, 84, cy - 22, 86, cy - 34], Tone(0x1f9a3a), seed: 32, w: tw)
                meadowFlower(k, 86, cy - 34, 7.5, Tone(0xffffff), Tone(0xff4f8b), seed: 33)
            case 4:
                meadowHat(k, 65, cy + 20, 7, Tone(0xff4f8b), Tone(0xd61f6e), rot: -0.3, seed: 30)
            default:
                break
            }
            k.marks(84, cy + 26, 12, ink: mk, seed: 40)
        }
    }

    static func snail(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xffa23a), Tone(0xd94a0f), Tone(0x7fd84a), Tone(0x1f9a3a)),
            (Tone(0xb07bff), Tone(0x6a35e0), Tone(0xffc43a), Tone(0xe87a10)),
            (Tone(0xff6fae), Tone(0xd61f6e), Tone(0x5fc0ff), Tone(0x1f72d8)),
            (Tone(0x3fd0c0), Tone(0x10958a), Tone(0xff9a6a), Tone(0xd9502a)),
            (Tone(0x8fe04a), Tone(0x1f9a3a), Tone(0xb08aff), Tone(0x6a3fe0)),
        ]
        let (shell, sk, body, bk) = f.pick(looks)
        let tw = meadowThin(k)
        let s = sin(f.t) * f.energy
        var stretch: CGFloat = 4 * s, headY: CGFloat = 30, stalk: CGFloat = 1, stalkA: CGFloat = 0.25 + 0.22 * f.twitch
        var tilt: CGFloat = 0.03 * s, rot: CGFloat = 0, faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            stretch = -6
            headY = 20
            stalk = 0.45
            stalkA = 1.1
        case .startled:
            headY = 40
            stalk = 1.35
            stalkA = -0.05
            tilt = 0.08
        case .fleeing:
            stretch = 10 + 3 * s
            stalkA = -0.95
            tilt = 0.14
            faceX = 2
        case .dizzy:
            rot = 0.1 * sin(f.t)
        }
        let hx: CGFloat = 78 + stretch, hy = headY
        k.with(about(50, 5, rot: rot)) {
            for i in 0..<2 {
                let a = stalkA + CGFloat(i) * 0.4
                let bx = hx - 3 + CGFloat(i) * 7, by = hy + 9
                let tx = bx + sin(a) * 18 * stalk, ty = by + cos(a) * 18 * stalk
                k.stick([bx, by, tx, ty], bk, seed: 1 + i, w: tw)
                k.dot(tx, ty, 3.2, 3.2, bk, seed: 3 + i)
            }
            let foot = smooth([8, 7, 30, 5, 60, 5, hx + 8, 5, hx + 13, hy - 6, hx + 10, hy + 7, hx, hy + 12, hx - 11, hy + 4, hx - 14, 17, 40, 16, 16, 12], t: 0.9)
            meadowPart(k, foot, body, bk, seed: 5)
            k.with(about(42, 14, rot: tilt)) {
                let sh = circ(42, 39, 25)
                meadowPart(k, sh, shell, sk, seed: 6)
                k.marker(spiral(43, 40, 17, turns: 2.1, spin: -1, start: 0.6), sk, tw, seed: 7)
                switch f.variant % 5 {
                case 1:
                    meadowFlower(k, 46, 64, 8, Tone(0xff6fae), Tone(0xe0246e), seed: 30)
                case 2:
                    meadowBow(k, 40, 64, 7, Tone(0xffd21f), Tone(0xff8a00), seed: 30)
                case 3:
                    meadowHat(k, 44, 62, 9, Tone(0xff4f8b), Tone(0xd61f6e), rot: 0.15, seed: 30)
                case 4:
                    meadowCrown(k, 44, 62, 7, seed: 30)
                default:
                    break
                }
            }
            k.eye(hx - 2 + faceX, hy + 2, 3.4, 4.4, side: -1, seed: 10)
            k.eye(hx + 7 + faceX, hy + 2, 3.4, 4.4, side: 1, seed: 11)
            k.mouth(hx + 3 + faceX, hy - 6, 7, seed: 12)
            k.marks(hx + 14, hy + 24, 11, ink: bk, seed: 40)
        }
    }

    static func chick(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xffd21f), Tone(0xff7a00)),
            (Tone(0xffd21f), Tone(0xff7a00)),
            (Tone(0xffb03a), Tone(0xe0500a)),
            (Tone(0xfaf6ef), Tone(0x3f8cff)),
            (Tone(0xff9ad0), Tone(0xe0247a)),
        ]
        let (body, mk) = f.pick(looks)
        let tw = meadowThin(k)
        let beakFill = Tone(0xff8a1f), beakInk = Tone(0xe0500a)
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.1 * f.squat - 0.05 * f.stretch
        var rot: CGFloat = 0, faceX: CGFloat = 0, open: CGFloat = 0
        var wing: CGFloat = f.airborne ? -0.3 - 0.6 * sin(f.air * .pi) : 0.15
        var tuft: CGFloat = 0.35 * f.twitch
        let tuck: CGFloat = f.airborne ? 4 * sin(f.air * .pi) : 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.9
            sx *= 1.06
            wing = 0.35
            tuft = 0.5
        case .startled:
            sy *= 1.07
            sx *= 0.95
            wing = -1.3
            open = 5
            tuft = -0.1
        case .fleeing:
            rot = -0.1
            faceX = 2.5
            wing = f.frameIndex % 2 == 0 ? -1.0 : -0.2
            open = 3
            tuft = -0.6
        case .dizzy:
            rot = 0.12 * sin(f.t)
            tuft = 0.4 * f.swing
        }
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            for (i, x) in ([42, 58] as [CGFloat]).enumerated() {
                let fy: CGFloat = 5 + tuck
                k.stick([x, 13, x - 1, fy, x + 7, fy - 1], beakInk, seed: 1 + i, w: tw)
            }
            meadowPart(k, circ(50, 40, 30), body, mk, seed: 3)
            if f.variant % 5 != 1 {
                for i in 0..<3 {
                    let a = tuft + CGFloat(i - 1) * 0.45
                    let bx: CGFloat = 50 + CGFloat(i - 1) * 3
                    k.stick([bx, 68, bx + sin(a) * 6, 75 + cos(a) * 2, bx + sin(a) * 11 + 2, 79 + cos(a) * 3], mk, seed: 4 + i, w: tw)
                }
            }
            k.with(about(38, 46, rot: wing)) {
                meadowPart(k, smooth([38, 46, 30, 40, 26, 30, 34, 26, 42, 34], t: 0.9), body.mix(beakFill, 0.35), mk, seed: 7, w: tw)
            }
            k.eye(60 + faceX, 52, 3.8, 5, side: -1, seed: 8)
            k.eye(71.5 + faceX, 52, 3.8, 5, side: 1, seed: 9)
            meadowCheeks(k, 55 + faceX, 77 + faceX, 41, 3.3, seed: 10)
            let bx: CGFloat = 72 + faceX
            meadowPart(k, poly([bx, 45 + open * 0.3, bx + 13, 41.5, bx, 38.5]), beakFill, beakInk, seed: 12, w: tw)
            if open > 0 {
                meadowPart(k, poly([bx, 37.5, bx + 10, 37 - open, bx + 1, 34 - open * 0.5]), beakFill, beakInk, seed: 13, w: tw)
            }
            switch f.variant % 5 {
            case 1:
                let cap = CGMutablePath()
                cap.addLines(between: P([25, 56, 31, 64, 37, 55, 44, 65, 50, 56, 57, 65, 63, 55, 69, 64, 75, 56]))
                cap.addCurve(to: pt(25, 56), control1: pt(76, 96), control2: pt(24, 96))
                cap.closeSubpath()
                meadowPart(k, cap, Tone(0xfffaf0), Tone(0xd98a2a), seed: 30)
            case 2:
                meadowBow(k, 44, 70, 7, Tone(0xff4f8b), Tone(0xd61f6e), seed: 30)
            case 3:
                let c = smooth([30, 62, 34, 76, 50, 82, 66, 76, 70, 62], t: 0.9)
                meadowPart(k, c, Tone(0x3f8cff), Tone(0x1f5fd0), seed: 30)
                meadowPart(k, ell(76, 63, 11, 3.5, -0.1), Tone(0x3f8cff), Tone(0x1f5fd0), seed: 31, w: tw)
            case 4:
                meadowFlower(k, 40, 69, 8, Tone(0xffffff), Tone(0x3f8cff), seed: 30)
            default:
                break
            }
            k.marks(82, 72, 12, ink: mk, seed: 40)
        }
    }

    static func butterfly(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xffcf1f), Tone(0x3fc3ff), Tone(0xff3d7f), Tone(0x8a5cff)),
            (Tone(0xff8a1f), Tone(0xff4f6f), Tone(0x7a3cff), Tone(0xffd21f)),
            (Tone(0x5fb8ff), Tone(0xb07bff), Tone(0x2f5fe0), Tone(0xff6fae)),
            (Tone(0x8fe04a), Tone(0xffd21f), Tone(0x1fa04a), Tone(0xff8a1f)),
            (Tone(0xff7ab8), Tone(0xc79bff), Tone(0xd61f7a), Tone(0x6a3cff)),
        ]
        let (upper, lower, mk, body) = f.pick(looks)
        let tw = meadowThin(k)
        var open: CGFloat = 0.62 + 0.38 * f.swing
        var rot: CGFloat = 0, faceX: CGFloat = 0, sweep: CGFloat = 0
        var ant: CGFloat = 0.28 * f.twitch, antUp: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            open = 0.55 + 0.04 * f.swing
            antUp = -9
        case .startled:
            open = 0.88 + 0.12 * f.swing
            antUp = 4
        case .fleeing:
            open = 0.5 + 0.5 * f.swing
            sweep = 0.18
            ant = -0.5
            faceX = 2.5
        case .dizzy:
            rot = 0.12 * sin(f.t)
            ant = 0.3 * f.swing
        }
        k.with(about(50, 45, rot: rot)) {
            k.with(about(50, 48, rot: -sweep, sx: open)) {
                for side in [-1, 1] as [CGFloat] {
                    let m: ([CGFloat]) -> [CGFloat] = { side < 0 ? $0 : mirrorA($0) }
                    let o = side < 0 ? 0 : 10
                    meadowPart(k, smooth(m([47, 44, 42, 28, 30, 15, 15, 17, 12, 32, 26, 43])), lower, mk, seed: 3 + o)
                    meadowPart(k, smooth(m([47, 52, 38, 73, 22, 88, 7, 81, 5, 62, 19, 50, 36, 47])), upper, mk, seed: 4 + o)
                    let sx: CGFloat = side < 0 ? 22 : 78
                    switch f.variant % 5 {
                    case 1:
                        k.fill(heart(sx, 68, 6.5), mk)
                    case 2:
                        k.fill(star(sx, 68, 8, inner: 0.45), Tone(0xffffff))
                    default:
                        k.dot(sx, 68, 6, 6, mk, seed: 5 + o)
                    }
                }
            }
            for side in [-1, 1] as [CGFloat] {
                let m: ([CGFloat]) -> [CGFloat] = { side < 0 ? $0 : mirrorA($0) }
                let tip = m([46, 72, 44, 86, 39 - ant * 10, 95 + antUp, 33 - ant * 14, 94 + antUp, 33 - ant * 14, 88 + antUp])
                k.stick(tip, mk, seed: side < 0 ? 1 : 2, w: tw)
            }
            meadowPart(k, ell(50, 38, 7, 18), body, mk, seed: 30)
            meadowPart(k, circ(50, 63, 13), body.lift(0.45), mk, seed: 31)
            k.eye(45 + faceX, 64.5, 2.9, 3.8, side: -1, seed: 32)
            k.eye(55 + faceX, 64.5, 2.9, 3.8, side: 1, seed: 33)
            k.mouth(50 + faceX, 57.5, 7, seed: 34)
            switch f.variant % 5 {
            case 3:
                meadowBow(k, 41, 74, 6, Tone(0xff4f8b), Tone(0xd61f6e), seed: 40)
            case 4:
                meadowFlower(k, 58, 75, 6.5, Tone(0xffd21f), Tone(0xff8a00), seed: 40)
            default:
                break
            }
            k.marks(68, 80, 12, ink: mk, seed: 44)
        }
    }

    static func dragonfly(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x3fa9ff), Tone(0x1f5fe0)),
            (Tone(0xff4f4f), Tone(0xc4122f)),
            (Tone(0x3fd06a), Tone(0x139a48)),
            (Tone(0xb07bff), Tone(0x6a35e0)),
            (Tone(0xff9a2a), Tone(0xe0560a)),
        ]
        let (body, mk) = f.pick(looks)
        let tw = meadowThin(k)
        let wingFill = Tone(0xdcf4ff), wingInk = Tone(0x4aa6ff)
        let buzz: CGFloat = f.frameIndex % 2 == 0 ? 1 : -1
        var flap: CGFloat = 0.2 * buzz, spread: CGFloat = 0, curl: CGFloat = 2 * f.swing + 6 * f.twitch
        var rot: CGFloat = 0, faceX: CGFloat = 0, fold = false
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            fold = true
            curl = -7
        case .startled:
            curl = 12
            spread = 0.25
            flap = 0.12 * buzz
        case .fleeing:
            curl = 0
            flap = 0.32 * buzz
            faceX = 2
        case .dizzy:
            rot = 0.12 * sin(f.t)
            curl = 6 * f.swing
        }
        k.with(about(50, 50, rot: rot)) {
            let roots: [CGFloat] = [64, 58]
            for (i, base) in ([1.25, 1.85] as [CGFloat]).enumerated() {
                for side in [-1, 1] as [CGFloat] {
                    var a: CGFloat = side * (base - spread * (i == 0 ? 1 : -1)) + side * flap
                    if fold { a = side * (i == 0 ? 2.75 : 2.95) }
                    let len: CGFloat = 19
                    let rx = roots[i], ry: CGFloat = 52
                    let cx = rx + cos(a) * len, cy = ry + sin(a) * len
                    meadowPart(k, ell(cx, cy, 20, 6.5, a), wingFill, wingInk, seed: 1 + i * 2 + (side > 0 ? 1 : 0), w: tw)
                }
            }
            var top: [CGFloat] = []
            var bot: [CGFloat] = []
            for (x, h) in [(58, 5.6), (42, 4.8), (26, 4.2), (9, 3.8)] as [(CGFloat, CGFloat)] {
                let u = (58 - x) / 48
                let dy = curl * u * u
                top += [x, 52 + h + dy]
                bot = [x, 52 - h + dy] + bot
            }
            meadowPart(k, smooth(top + bot, t: 0.9), body, mk, seed: 6)
            for (i, x) in ([42, 26] as [CGFloat]).enumerated() {
                let u = (58 - x) / 48
                let dy = curl * u * u
                k.marker(line(x, 47 + dy, x - 1, 57 + dy), mk, tw * 0.8, seed: 7 + i)
            }
            meadowPart(k, ell(64, 52, 11, 9), body, mk, seed: 10)
            let hx: CGFloat = 80 + faceX * 0.3
            meadowPart(k, circ(hx, 54, 14), body.lift(0.35), mk, seed: 11)
            meadowGoggle(k, 74.5 + faceX, 58, 6.2, ring: mk, side: -1, seed: 12)
            meadowGoggle(k, 87 + faceX, 58, 6.2, ring: mk, side: 1, seed: 15)
            k.mouth(81 + faceX, 46.5, 7, seed: 18)
            switch f.variant % 5 {
            case 1:
                meadowFlower(k, 74, 69, 6.5, Tone(0xffd21f), Tone(0xff8a00), seed: 30)
            case 3:
                meadowCrown(k, 81, 66, 6, seed: 30)
            case 4:
                meadowHat(k, 83, 66, 7, Tone(0x3fd0ff), Tone(0x1f7ae0), rot: -0.3, seed: 30)
            default:
                break
            }
            k.marks(94, 70, 12, ink: mk, seed: 40)
        }
    }

    static func firefly(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xfff04a), Tone(0xff9a00)),
            (Tone(0xb6ff3a), Tone(0x3fae1f)),
            (Tone(0xff8ad8), Tone(0xe0247a)),
            (Tone(0x6fefff), Tone(0x1f9ae0)),
            (Tone(0xffb03a), Tone(0xe0560a)),
        ]
        let (lamp, lk) = f.pick(looks)
        let head = Tone(0x4a3fa0), hk = Tone(0x9a84ff)
        let tw = meadowThin(k)
        let buzz = f.frameIndex % 3
        var pulse: CGFloat = 0.8 + 0.2 * sin(f.t)
        var wing: CGFloat = [-0.4, 0.05, 0.45][buzz]
        var ant: CGFloat = 0.3 + 0.25 * f.twitch
        var rot: CGFloat = 0, faceX: CGFloat = 0, droop: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            pulse = 0.45
            wing = 0.8
            ant = 1.2
            droop = 4
        case .startled:
            pulse = 1.2
            ant = -0.15
            wing = [-0.8, -0.35, 0.1][buzz]
        case .fleeing:
            pulse = f.frameIndex % 2 == 0 ? 1.1 : 0.6
            ant = -0.95
            faceX = 2
            wing = [-0.2, 0.35, 0.85][buzz]
        case .dizzy:
            rot = 0.13 * sin(f.t)
            pulse = f.frameIndex % 4 < 2 ? 1 : 0.55
            ant = 0.4 + 0.5 * f.swing
        }
        k.with(about(50, 50, rot: rot)) {
            k.glow(34, 42 - droop, 36 * min(1.15, pulse), lamp, 0.8 * min(1, pulse))
            if pulse > 0.7 {
                for i in 0..<4 {
                    let a: CGFloat = 2.3 + CGFloat(i) * 0.6
                    let r0: CGFloat = 26, r1: CGFloat = 26 + 9 * min(1.3, pulse)
                    let ox: CGFloat = 35, oy: CGFloat = 43 - droop
                    k.marker(line(ox + cos(a) * r0, oy + sin(a) * r0, ox + cos(a) * r1, oy + sin(a) * r1), lk, meadowW(k), seed: 26 + i)
                }
            }
            let ax: CGFloat = 68, ay: CGFloat = 70
            for i in 0..<2 {
                let a = ant + CGFloat(i) * 0.5
                let tx = ax + sin(a) * 16, ty = ay + cos(a) * 16
                k.stick([ax - 3 + CGFloat(i) * 6, ay, tx, ty], hk, seed: 1 + i, w: tw)
                k.dot(tx, ty, 3.2, 3.2, hk, seed: 3 + i)
            }
            meadowPart(k, ell(35, 43 - droop, 21, 17, -0.3 - droop * 0.03), lamp.mix(.white, pulse > 1 ? 0.3 : 0).dim(0.75 + 0.25 * min(1, pulse)), lk, seed: 7)
            if pulse > 0.7 {
                k.dot(31, 46 - droop, 6, 4.5, Tone(0xffffff, 0.85), seed: 25)
            }
            meadowPart(k, ell(52, 50, 11, 10), head, hk, seed: 8)
            for i in 0..<2 {
                let a = wing + CGFloat(i) * 0.55
                let rx: CGFloat = 44 + CGFloat(i) * 8, ry: CGFloat = 58
                let wx = rx - sin(a) * 13, wy = ry + cos(a) * 13
                meadowPart(k, ell(wx, wy, 8.5, 14, a), Tone(0xe6f6ff), Tone(0x6ab8ff), seed: 9 + i, w: tw)
            }
            meadowPart(k, circ(68 + faceX * 0.3, 56, 16), head, hk, seed: 11)
            meadowGoggle(k, 63 + faceX, 59, 5.5, ring: nil, side: -1, seed: 12)
            meadowGoggle(k, 75 + faceX, 59, 5.5, ring: nil, side: 1, seed: 15)
            k.mouth(69.5 + faceX, 48, 8, ink: .white, seed: 18)
            switch f.variant % 5 {
            case 2:
                meadowBow(k, 60, 71, 6.5, Tone(0xff8ad8), Tone(0xe0247a), seed: 30)
            case 4:
                meadowHat(k, 70, 70, 8, Tone(0xffb03a), Tone(0xe0560a), rot: -0.3, seed: 30)
            default:
                break
            }
            k.marks(86, 76, 12, ink: hk, seed: 40)
        }
    }

    static func crab(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff5a3c), Tone(0xc81f2a)),
            (Tone(0xff9a2a), Tone(0xd9480f)),
            (Tone(0x4fa8ff), Tone(0x1f5fd0)),
            (Tone(0xff6fae), Tone(0xd61f6e)),
            (Tone(0xb07bff), Tone(0x6a35e0)),
        ]
        let (shell, mk) = f.pick(looks)
        let tw = meadowThin(k)
        let sway: CGFloat = 2.5 * sin(f.t) * f.energy
        var bodyY: CGFloat = 30 + 1.2 * f.swing2 * min(1, f.energy), rot: CGFloat = 0, faceX: CGFloat = 0
        var clawL = pt(14, 56), clawR = pt(86, 56)
        var snap: CGFloat = 0.28 + 0.2 * abs(sin(f.t))
        var stalkH: CGFloat = 16, stalkA: CGFloat = 0.12 + 0.08 * f.twitch
        var legAmp: CGFloat = 3, lean: CGFloat = 0
        switch f.mood {
        case .calm:
            clawR.y += 3 * max(0, f.twitch)
        case .sleepy:
            bodyY = 24
            clawL = pt(12, 16)
            clawR = pt(88, 16)
            snap = 0.06
            stalkH = 8
            stalkA = 0.5
            legAmp = 0
        case .startled:
            bodyY = 36
            clawL = pt(12, 78)
            clawR = pt(88, 78)
            snap = 0.55
            stalkH = 19
            stalkA = 0.05
        case .fleeing:
            clawL = pt(8, 62 + 3 * f.swing)
            clawR = pt(28, 84 - 3 * f.swing)
            faceX = 3
            legAmp = 6
            lean = -0.35
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let cx: CGFloat = 50 + sway
        k.with(about(50, 5, rot: rot)) {
            for side in [-1, 1] as [CGFloat] {
                for i in 0..<3 {
                    let ph = f.t + CGFloat(i) * 2.1 + (side > 0 ? 1 : 0)
                    let up = max(0, sin(ph)) * legAmp
                    let hx = cx + side * (20 + CGFloat(i) * 4)
                    let hy = bodyY - 6 - CGFloat(i) * 2
                    let fx = cx + side * (32 + CGFloat(i) * 7) + cos(ph) * legAmp * 0.6
                    k.stick([hx, hy, fx - side * 2, hy + 4 + up, fx, 5 + up], mk, seed: 1 + i + (side > 0 ? 3 : 0), w: tw)
                }
            }
            for side in [-1, 1] as [CGFloat] {
                let c = side < 0 ? clawL : clawR
                let sx = cx + side * 22, sy = bodyY + 6
                k.stick([sx, sy, (sx + c.x) / 2 + side * 4, (sy + c.y) / 2 - 2, c.x, c.y - 6], mk, seed: 8 + (side > 0 ? 1 : 0), w: meadowW(k))
                let d: CGFloat = .pi / 2 + side * 0.35
                let claw = CGMutablePath()
                claw.move(to: c)
                claw.addArc(center: c, radius: 10.5, startAngle: d + snap, endAngle: d - snap + 2 * .pi, clockwise: false)
                claw.closeSubpath()
                meadowPart(k, claw, shell, mk, seed: 10 + (side > 0 ? 1 : 0))
            }
            let eyeY = bodyY + 12 + stalkH
            for side in [-1, 1] as [CGFloat] {
                let bx = cx + side * 8
                let ex = bx + side * sin(stalkA) * stalkH + lean * stalkH + faceX, ey = bodyY + 12 + cos(stalkA) * stalkH
                k.stick([bx, bodyY + 10, ex, ey], mk, seed: 12 + (side > 0 ? 1 : 0), w: tw)
                meadowGoggle(k, ex, ey, 6, ring: mk, side: side, seed: side < 0 ? 14 : 17)
            }
            meadowPart(k, ell(cx, bodyY, 31, 17), shell, mk, seed: 20)
            meadowCheeks(k, cx - 17 + faceX, cx + 17 + faceX, bodyY - 1, 3.4, seed: 21)
            k.mouth(cx + faceX, bodyY - 1, 10, seed: 23)
            switch f.variant % 5 {
            case 1:
                let hy = eyeY + 7
                meadowPart(k, ell(cx, hy + 1, 22, 4.5), Tone(0xffe08a), Tone(0xd99a1a), seed: 30, w: tw)
                meadowPart(k, smooth([cx - 11, hy + 3, cx - 9, hy + 12, cx, hy + 15, cx + 9, hy + 12, cx + 11, hy + 3], t: 0.9), Tone(0xffe08a), Tone(0xd99a1a), seed: 31, w: tw)
                k.marker(line(cx - 11, hy + 5, cx + 11, hy + 5), Tone(0xff4f8b), tw, seed: 32)
            case 3:
                meadowBow(k, cx + 18, bodyY + 14, 6.5, Tone(0xffd21f), Tone(0xff8a00), seed: 30)
            case 4:
                meadowFlower(k, cx - 18, bodyY + 14, 7, Tone(0xffd21f), Tone(0xff8a00), seed: 30)
            default:
                break
            }
            k.marks(cx + 30, bodyY + 34, 12, ink: mk, seed: 40)
        }
    }

    static func frog(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x5fd04a), Tone(0x1f9a3a), Tone(0xd8f5a0)),
            (Tone(0x5fd04a), Tone(0x1f9a3a), Tone(0xd8f5a0)),
            (Tone(0x4fb0ff), Tone(0x1f62d0), Tone(0xcfeeff)),
            (Tone(0xff8a3a), Tone(0xd9480f), Tone(0xffe0a0)),
            (Tone(0xff7ab8), Tone(0xd61f6e), Tone(0xffe0ef)),
        ]
        let (body, mk, belly) = f.pick(looks)
        let tw = meadowThin(k)
        var sy: CGFloat = 1 - 0.18 * f.squat + 0.12 * f.stretch
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.06 * f.stretch
        var rot: CGFloat = 0, faceX: CGFloat = 1.5, arms: CGFloat = 0
        let leap = f.airborne && f.air < 0.7
        switch f.mood {
        case .calm:
            rot = -0.04 * min(0, f.twitch)
        case .sleepy:
            sy *= 0.88
            sx *= 1.06
        case .startled:
            sy *= 1.08
            sx *= 0.95
            arms = 1
        case .fleeing:
            rot = -0.08
            faceX = 4
            arms = -1
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            if f.variant % 5 == 2 {
                k.stick([74, 18, 76, 84], Tone(0xc98a4a), seed: 30, w: meadowW(k))
                let cap = CGMutablePath()
                cap.move(to: pt(50, 80))
                cap.addCurve(to: pt(104, 80), control1: pt(52, 112), control2: pt(102, 112))
                for q in P([95, 76, 86, 80, 77, 76, 68, 80, 59, 76]) { cap.addLine(to: q) }
                cap.closeSubpath()
                meadowPart(k, cap, Tone(0xff4f6f), Tone(0xd6163f), seed: 31)
                k.marker(smooth([77, 101, 70, 90, 68, 80], closed: false), Tone(0xffd21f), meadowThin(k), seed: 34)
            }
            for side in [-1, 1] as [CGFloat] {
                let s = side < 0 ? 0 : 1
                if leap {
                    k.stick([50 + side * 26, 16, 50 + side * 34, 6, 50 + side * 30, -2], mk, seed: 1 + s, w: meadowW(k))
                    meadowPart(k, ell(50 + side * 33, -3, 6, 2.6), body, mk, seed: 3 + s, w: tw)
                } else {
                    meadowPart(k, ell(50 + side * 30, 15, 11, 9, side * 0.3), body, mk, seed: 1 + s)
                    meadowPart(k, ell(50 + side * 38, 6, 7, 3), body, mk, seed: 3 + s, w: tw)
                }
            }
            let shape = smooth([22, 8, 50, 6, 78, 8, 84, 26, 80, 46, 78, 62, 70, 76, 58, 74, 51, 63, 44, 74, 32, 76, 23, 62, 20, 46, 16, 26], t: 0.95)
            meadowPart(k, shape, body, mk, seed: 5)
            meadowPart(k, ell(51, 22, 17, 12), belly, mk, seed: 6, w: tw)
            for side in [-1, 1] as [CGFloat] {
                let s = side < 0 ? 0 : 1
                let hx = 50 + side * 25
                if arms > 0 {
                    k.stick([hx, 32, hx + side * 9, 42, hx + side * 12, 54], mk, seed: 7 + s, w: meadowW(k))
                    k.dot(hx + side * 12, 55, 4, 4, body, seed: 20 + s)
                } else if arms < 0 {
                    let pump: CGFloat = 4 * f.swing
                    if side < 0 {
                        k.stick([hx, 30, hx - 9, 24 + pump, hx - 18, 22 + pump], mk, seed: 7 + s, w: meadowW(k))
                    } else {
                        k.stick([hx, 30, hx + 8, 36 - pump, hx + 14, 32 - pump], mk, seed: 7 + s, w: meadowW(k))
                    }
                } else {
                    let lift: CGFloat = leap ? 2 : 0
                    meadowPart(k, ell(50 + side * 11 + 1, 6 + lift, 7, 3.4), body, mk, seed: 7 + s, w: tw)
                }
            }
            switch f.variant % 5 {
            case 1:
                meadowCrown(k, 50, 69, 7, seed: 32)
            case 4:
                meadowFlower(k, 50, 74, 7.5, Tone(0xffffff), Tone(0xff4f8b), seed: 32)
            default:
                break
            }
            meadowGoggle(k, 36 + faceX, 64, 8.5, ring: mk, side: -1, seed: 10)
            meadowGoggle(k, 64 + faceX, 64, 8.5, ring: mk, side: 1, seed: 13)
            meadowCheeks(k, 28 + faceX, 74 + faceX, 41, 3.8, seed: 16)
            if f.mood == .calm {
                k.marker(arc(35 + faceX, 46, 67 + faceX, 46, dip: 7), k.felt, tw, seed: 18)
                if f.twitch > 0 {
                    k.stick([62 + faceX, 41, 70 + faceX, 36, 76 + faceX, 38, 74 + faceX, 42], Tone(0xff4f8b), seed: 24, w: meadowW(k))
                }
            } else {
                k.mouth(51 + faceX, 44, 14, seed: 18)
            }
            k.marks(82, 76, 12, ink: mk, seed: 40)
        }
    }

    static func sun(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xffd21f), Tone(0xff7a00), Tone(0xff9a1a)),
            (Tone(0xffd21f), Tone(0xff7a00), Tone(0xff9a1a)),
            (Tone(0xffb03a), Tone(0xe0500a), Tone(0xff6a3a)),
            (Tone(0xffe14a), Tone(0xff8a00), Tone(0xffb21a)),
            (Tone(0xff8a5c), Tone(0xe0304a), Tone(0xff5a6a)),
        ]
        let (face, mk, ray) = f.pick(looks)
        let tw = meadowThin(k)
        let rw = k.width(4.6, minPt: 1.7)
        var rayK: CGFloat = 1, sy: CGFloat = 1, sx: CGFloat = 1, rot: CGFloat = 0, faceX: CGFloat = 0, stream: CGFloat = 0
        switch f.mood {
        case .calm:
            rot = 0.07 * f.twitch
        case .sleepy:
            rayK = 0.55
            sy = 0.95
            sx = 1.03
        case .startled:
            rayK = 1.35
            sy = 1.05
            sx = 0.97
        case .fleeing:
            stream = 1
            faceX = 3
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let spin: CGFloat = f.phase * 2 * (2 * .pi / 10) * (f.mood == .dizzy ? 2 : 1)
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            for i in 0..<10 {
                let a: CGFloat = spin + CGFloat(i) * 2 * .pi / 10
                let long = i % 2 == 0
                var len: CGFloat = (long ? 15 : 9) * (1 + 0.15 * sin(f.t * 2 + CGFloat(i)))
                len *= rayK
                if stream > 0 { len *= 1 - 0.55 * cos(a) }
                let r0: CGFloat = 33
                let bend: CGFloat = stream > 0 ? -sin(a) * 0.25 : 0
                let x0 = 50 + cos(a) * r0, y0 = 50 + sin(a) * r0
                let x1 = 50 + cos(a + bend) * (r0 + len), y1 = 50 + sin(a + bend) * (r0 + len)
                k.marker(line(x0, y0, x1, y1), ray, rw, seed: 1 + i)
            }
            meadowPart(k, circ(50, 50, 28), face, mk, seed: 12)
            let glasses = f.variant % 5 == 1
            let glassesOn = glasses && (f.mood == .calm || f.mood == .fleeing || f.mood == .dizzy)
            if glassesOn {
                let gy: CGFloat = 55
                let tiltG: CGFloat = f.mood == .dizzy ? 0.12 * sin(f.t) : 0
                k.with(about(50 + faceX, gy, rot: tiltG)) {
                    let lens = CGMutablePath()
                    lens.addPath(rrect(33 + faceX, gy - 6, 14, 11, 4))
                    lens.addPath(rrect(53 + faceX, gy - 6, 14, 11, 4))
                    k.fill(lens, Tone(0x2a1f33))
                    k.marker(lens, Tone(0x2a1f33), tw, seed: 13)
                    k.marker(line(46 + faceX, gy + 2, 54 + faceX, gy + 2), Tone(0x2a1f33), tw, seed: 14)
                    k.marker(line(36 + faceX, gy + 2, 40 + faceX, gy - 2), Tone(0xffffff, 0.85), tw * 0.7, seed: 15)
                }
            } else {
                k.eye(41 + faceX, 55, 4, 5.4, side: -1, seed: 16)
                k.eye(59 + faceX, 55, 4, 5.4, side: 1, seed: 17)
                if glasses {
                    let lens = CGMutablePath()
                    lens.addPath(rrect(35, 66, 12, 7, 3))
                    lens.addPath(rrect(53, 66, 12, 7, 3))
                    k.fill(lens, Tone(0x2a1f33))
                    k.marker(line(47, 69, 53, 69), Tone(0x2a1f33), tw, seed: 14)
                }
            }
            meadowCheeks(k, 33 + faceX, 67 + faceX, 44, 4, seed: 18)
            k.mouth(50 + faceX, 42, 14, seed: 20)
            switch f.variant % 5 {
            case 2:
                meadowFlower(k, 30, 72, 8.5, Tone(0xff4f8b), Tone(0xd61f6e), seed: 30)
            case 3:
                meadowBow(k, 50, 80, 8, Tone(0x3fb0ff), Tone(0x1f62e0), seed: 30)
            case 4:
                meadowHat(k, 56, 76, 10, Tone(0x8a5cff), Tone(0x5a2fc0), rot: -0.25, seed: 30)
            default:
                break
            }
            k.marks(80, 82, 13, ink: mk, seed: 40)
        }
    }

    private static func meadowW(_ k: DoodleKit) -> CGFloat {
        k.width(3.4, minPt: 1.3)
    }

    private static func meadowThin(_ k: DoodleKit) -> CGFloat {
        k.width(2.5, minPt: 1.0)
    }

    private static func meadowFill(_ k: DoodleKit, _ shape: CGPath, _ tone: Tone, seed raw: Int) {
        let sd = k.seed(raw)
        var r = Noise(sd &+ 4242)
        let bb = shape.boundingBoxOfPath
        guard bb.width > 0.5, bb.height > 0.5 else { return }
        let s = max(0.84, 1 - 2.4 / max(bb.width, bb.height))
        let ox = r.range(-1.3, 1.3), oy = r.range(-1.3, 1.3)
        let t = CGAffineTransform(translationX: bb.midX + ox, y: bb.midY + oy).scaledBy(x: s, y: s).translatedBy(x: -bb.midX, y: -bb.midY)
        let region = CGMutablePath()
        for (i, sub) in DoodleKit.flatten(xf(shape, t), step: 2.6).enumerated() where sub.1 {
            region.addPath(DoodleKit.curve(DoodleKit.wobble(sub.0, closed: true, seed: sd &+ 7 &+ i, amp: 1.3), closed: true))
        }
        k.fill(region, tone.alpha(0.94))
        guard max(bb.width, bb.height) > 18 else { return }
        let gap = max(3.2, 1.8 * k.pt)
        let lw = max(1.1, 0.6 * k.pt)
        let ang = r.range(0.95, 1.2)
        let dx = cos(ang), dy = sin(ang)
        let half = hypot(bb.width, bb.height) / 2 + 3
        var off: CGFloat = -half
        let hatch = CGMutablePath()
        while off < half {
            let cx = bb.midX + dy * off, cy = bb.midY - dx * off
            hatch.move(to: CGPoint(x: cx - dx * half + r.range(-2, 2), y: cy - dy * half))
            hatch.addLine(to: CGPoint(x: cx + dx * half + r.range(-2, 2), y: cy + dy * half))
            off += gap * r.range(0.85, 1.3)
        }
        k.clip(region) {
            k.stroke(hatch, tone.dim(0.8).alpha(0.4), lw)
        }
    }

    private static func meadowPart(_ k: DoodleKit, _ p: CGPath, _ fill: Tone?, _ ink: Tone, seed: Int, w: CGFloat? = nil) {
        if let fill { meadowFill(k, p, fill, seed: seed) }
        k.marker(p, ink, w ?? meadowW(k), seed: seed)
    }

    private static func meadowCheeks(_ k: DoodleKit, _ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat, _ r: CGFloat, seed: Int) {
        k.dot(x0, y, r, r * 0.85, k.cheek.alpha(0.9), seed: seed)
        k.dot(x1, y, r, r * 0.85, k.cheek.alpha(0.9), seed: seed + 1)
    }

    private static func meadowDome(_ cx: CGFloat, _ base: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(cx - rx, base))
        p.addCurve(to: pt(cx, base + ry), control1: pt(cx - rx, base + ry * 0.6), control2: pt(cx - rx * 0.56, base + ry))
        p.addCurve(to: pt(cx + rx, base), control1: pt(cx + rx * 0.56, base + ry), control2: pt(cx + rx, base + ry * 0.6))
        p.addQuadCurve(to: pt(cx - rx, base), control: pt(cx, base - 4))
        p.closeSubpath()
        return p
    }

    private static func meadowGoggle(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, ring: Tone?, side: CGFloat, seed: Int) {
        let f = k.f
        let big: CGFloat = f.mood == .startled && !f.eyesShut ? 1.18 : 1
        k.dot(x, y, r * big, r * big, .white, seed: seed)
        if let ring { k.marker(circ(x, y, r * big), ring, meadowThin(k) * 0.8, seed: seed + 1) }
        if f.eyesShut || f.mood == .dizzy || f.mood == .fleeing {
            k.eye(x, y, r * 0.5, r * 0.62, side: side, seed: seed + 2)
        } else if f.mood == .startled {
            k.dot(x, y, r * 0.32, r * 0.32, k.felt, seed: seed + 2)
        } else {
            k.dot(x + r * 0.3, y - r * 0.05, r * 0.56, r * 0.62, k.felt, seed: seed + 2)
            k.fill(circ(x + r * 0.45, y + r * 0.2, r * 0.18), .white)
        }
    }

    private static func meadowFlower(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ petal: Tone, _ ink: Tone, seed: Int) {
        let s = size * 1.3
        meadowPart(k, softStar(x, y, s, points: 5, inner: 0.55, spin: .pi / 2 + 0.3, t: 1.4), petal, ink, seed: seed, w: meadowThin(k))
        k.dot(x, y, s * 0.38, s * 0.38, Tone(0xffc21a), seed: seed + 1)
    }

    private static func meadowBow(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ tone: Tone, _ ink: Tone, seed: Int) {
        let s = size * 1.3
        let p = CGMutablePath()
        p.addPath(smooth([x, y, x - s, y + s * 0.75, x - s, y - s * 0.75], t: 0.6))
        p.addPath(smooth([x, y, x + s, y + s * 0.75, x + s, y - s * 0.75], t: 0.6))
        meadowPart(k, p, tone, ink, seed: seed, w: meadowThin(k))
        k.dot(x, y, s * 0.32, s * 0.32, ink, seed: seed + 1)
    }

    private static func meadowHat(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ tone: Tone, _ ink: Tone, rot: CGFloat, seed: Int) {
        let s = size * 1.3
        k.with(about(x, y, rot: rot)) {
            meadowPart(k, poly([x - s * 0.72, y, x + s * 0.72, y, x, y + s * 1.6]), tone, ink, seed: seed, w: meadowThin(k))
            k.dot(x, y + s * 1.68, s * 0.34, s * 0.34, Tone(0xffffff), seed: seed + 1)
        }
    }

    private static func meadowCrown(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, seed: Int) {
        let s = size * 1.3
        let p = poly([x - s, y, x + s, y, x + s * 1.15, y + s * 1.15, x + s * 0.5, y + s * 0.55, x, y + s * 1.3, x - s * 0.5, y + s * 0.55, x - s * 1.15, y + s * 1.15])
        meadowPart(k, p, Tone(0xffd21f), Tone(0xff8a00), seed: seed, w: meadowThin(k))
    }
}
