import Foundation

struct Shake {
    var kind: Gesture
    var tossed = false
    var delay = 0.0
    var clock = 0.0
    var settle = -1.0
    var dizzy = 0.0
    var look = 0.0
    var vx = 0.0
    var vy = 0.0
    var swirl = 0.0

    var gesture: Gesture {
        if delay > 0 { return .none }
        if settle < 0 || settle < dizzy { return kind }
        return .look
    }
}

extension World {
    public var shakenCount: Int {
        var n = 0
        for b in bugs where b.shake != nil && b.mode != .hidden { n += 1 }
        return n
    }

    func beginShakes() {
        let t = tuning
        guard t.jiggleEnabled else { return }
        let level = lid.shakeLevel
        for i in bugs.indices {
            var b = bugs[i]
            guard b.peek == nil, b.sneak == nil, b.stray == nil, b.shake == nil, !b.retiring, !b.fading else { continue }
            let flinching = b.mode == .startled && b.flinchOnly
            guard b.calm || flinching, onScreen(b) else { continue }
            b.entrance = nil
            b.act = nil
            clearOwn(&b)
            b.restGesture = .none
            b.backward = false
            b.glide = false
            var k = Shake(kind: .shiver)
            if b.species.isAirborne {
                k.kind = .tumble
                k.tossed = true
                k.swirl = actRng.range(1.2...2.2) * (actRng.chance(0.5) ? 1 : -1)
            } else if actRng.chance(min(1, t.shakeTumbleShare + 0.3 * level)) {
                k.kind = .tumble
            }
            k.delay = actRng.range(t.shakeDelay)
            b.shake = k
            b.mode = .resting
            b.flinchOnly = false
            b.flinched = true
            bugs[i] = b
        }
    }

    func shakeStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var k = b.shake else { return 0 }
        let t = tuning
        b.mode = .resting
        k.clock += h
        if k.delay > 0 {
            k.delay -= h
            if k.delay <= 0 { k.delay = 0 }
            brake(&b, tau: 0.06, h: h)
            b.shake = k
            return 0
        }
        let shaking = isJiggling && k.clock < t.shakeMaxSeconds
        if shaking {
            k.settle = -1
        } else if k.settle < 0 {
            k.settle = 0
            k.dizzy = actRng.range(t.shakeDizzy) * (k.kind == .shiver ? 0.5 : 1)
            k.look = actRng.range(t.shakeRecover)
        } else {
            k.settle += h
        }
        b.speed = 0
        if k.kind == .tumble {
            if shaking && lid.pulse {
                let a = actRng.unit() * 2 * .pi
                let mag = actRng.range(t.shakeKick) * (0.5 + 0.5 * lid.shakeLevel) * (k.tossed ? 1.4 : 0.6)
                k.vx += cos(a) * mag
                k.vy += sin(a) * mag
            }
            if k.tossed {
                let r = k.swirl * h
                let c = cos(r), s = sin(r)
                let vx = k.vx * c - k.vy * s
                k.vy = k.vx * s + k.vy * c
                k.vx = vx
            }
            let damp = exp(-h / (k.tossed ? 0.9 : 0.35))
            k.vx *= damp
            k.vy *= damp
            b.x += k.vx * h
            b.y += k.vy * h
            let pad = b.size * 0.6
            if b.x < pad { b.x = pad; k.vx = abs(k.vx) * 0.5 }
            if b.x > width - pad { b.x = width - pad; k.vx = -abs(k.vx) * 0.5 }
            if b.y < pad { b.y = pad; k.vy = abs(k.vy) * 0.5 }
            if b.y > height - pad { b.y = height - pad; k.vy = -abs(k.vy) * 0.5 }
        }
        if !shaking && k.settle >= k.dizzy + k.look {
            b.shake = nil
            startBurst(&b, tr: tr)
            return 0
        }
        b.shake = k
        return 0
    }
}
