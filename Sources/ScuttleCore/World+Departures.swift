import Foundation

enum SneakStage: Equatable {
    case notice
    case wave
    case exit
    case glance
}

struct Sneak {
    var stage = SneakStage.notice
    var clock = 0.0
    var length = 0.0
    var glanced = false
    var hurried = false

    var gesture: Gesture {
        switch stage {
        case .notice, .glance: return .look
        case .wave: return .wave
        case .exit: return .tiptoe
        }
    }
}

extension World {
    public var sneakerCount: Int {
        var n = 0
        for b in bugs where b.sneak != nil && b.mode != .hidden { n += 1 }
        return n
    }

    func depart(_ b: inout Bug, tr: SpeciesTraits) {
        if isGentle(b) {
            beginSneak(&b)
        } else {
            startle(&b, flinch: false)
        }
    }

    func isGentle(_ b: Bug) -> Bool {
        let t = tuning
        guard t.gentleEnabled, !b.retiring, b.stray == nil else { return false }
        return max(lightRate, peakRate) < t.gentleRate
    }

    func beginSneak(_ b: inout Bug) {
        let t = tuning
        keepOnSneak(&b)
        clearScripts(&b)
        var s = Sneak()
        s.length = actRng.range(t.sneakNotice)
        b.sneak = s
        b.mode = .resting
        b.flinchOnly = false
        b.wrongWay = 0
        b.panic = 0
        startledThisStep += 1
    }

    func sneakStep(_ b: inout Bug, tr: SpeciesTraits, h: Double, safe: Bool) -> Double {
        guard var s = b.sneak else { return 0 }
        let t = tuning
        if b.retiring || max(lightRate, peakRate) >= t.gentleRate * 2 {
            b.sneak = nil
            b.backward = false
            if b.mode == .fleeing { b.mode = .resting }
            startle(&b, flinch: false)
            return 0
        }
        if safe && lightRate <= 0 && onScreen(b) {
            b.sneak = nil
            settle(&b)
            return 0
        }
        s.clock += h
        if light >= t.fullLight && !s.hurried {
            s.hurried = true
            if s.stage == .exit {
                let remaining = depth(b.x, b.y, from: b.fleeEdge) + b.size * 0.6
                b.fleeDeadline = min(b.fleeDeadline, b.fleeElapsed + max(t.sneakLitDeadline, remaining * 1.1 / 220))
            } else {
                s.length = min(s.length, s.clock + 0.15)
            }
        }
        switch s.stage {
        case .notice:
            settleIn(&b, tr: tr, h: h)
            if s.clock >= s.length {
                if !s.hurried && waves(b) {
                    s.stage = .wave
                    s.clock = 0
                    s.length = actRng.range(t.waveByeLength)
                    stage.waveByeGap = t.waveByeGap
                } else {
                    beginSneakExit(&b, &s, tr: tr)
                }
            }
        case .wave:
            settleIn(&b, tr: tr, h: h)
            if s.clock >= s.length || s.hurried { beginSneakExit(&b, &s, tr: tr) }
        case .exit:
            flee(&b, h: h)
            let left = depth(b.x, b.y, from: b.fleeEdge)
            if !s.glanced && !s.hurried && stage.visible <= 1 && left < b.size * 1.1 && left > b.size * 0.45 {
                s.stage = .glance
                s.clock = 0
                s.length = actRng.range(t.lastLookLength)
                b.mode = .resting
            }
        case .glance:
            settleIn(&b, tr: tr, h: h)
            if s.clock >= s.length || s.hurried {
                s.glanced = true
                s.stage = .exit
                b.fleeDeadline += s.clock
                b.mode = .fleeing
            }
        }
        b.sneak = s
        return 0
    }

    private func waves(_ b: Bug) -> Bool {
        let t = tuning
        guard !b.species.isAirborne, b.species.stance == .upright, stage.waveByeGap <= 0 else { return false }
        return t.forceWaveBye ?? actRng.chance(t.waveByeChance)
    }

    private func settleIn(_ b: inout Bug, tr: SpeciesTraits, h: Double) {
        if b.species.isAirborne {
            hover(&b, tr: tr, h: h)
        } else {
            brake(&b, tau: 0.08, h: h)
        }
    }

    private func beginSneakExit(_ b: inout Bug, _ s: inout Sneak, tr: SpeciesTraits) {
        let t = tuning
        s.stage = .exit
        s.clock = 0
        b.fleeEdge = exitEdge(for: b)
        b.fleeAim = actRng.signed() * 0.25
        let mid = (tr.sizeRange.lowerBound + tr.sizeRange.upperBound) / 2
        let base = min(max(tr.fleeSpeed * pow(b.size / max(1, mid), t.fleeSizeExponent), t.fleeSpeedRange.lowerBound), t.fleeSpeedRange.upperBound)
        b.fleeTop = min(t.fleeSpeedCap, base * max(0.05, t.sneakSpeed) * b.fleeVariance)
        b.fleeDeadline = s.hurried ? t.sneakLitDeadline : t.sneakDeadline
        b.wobbleAmp = 0.06
        b.wobbleRate = 2 * .pi * 1.2
        b.wobblePhase = 0
        b.wrongWay = 0
        b.flinchOnly = false
        b.fleeElapsed = 0
        b.mode = .fleeing
        b.backward = !b.species.isAirborne && (t.forceBackward ?? actRng.chance(t.backwardChance))
    }
}
