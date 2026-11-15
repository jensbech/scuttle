import Foundation

extension World {
    static let squatShare = 0.25

    func locomote(_ b: inout Bug, tr: SpeciesTraits, h: Double) {
        let t = tuning
        let size = max(1, b.size)
        let fleeing = b.mode == .fleeing
        let alarmed = fleeing || b.mode == .startled
        let pace = b.speed / size
        let vary = 0.5 + 0.5 * b.tempo
        var heading = b.course
        var speed = b.speed
        var dx = 0.0
        var dy = 0.0
        var gait = 0.0
        b.lift = 0

        switch b.species.locomotion {
        case .crawl, .walk:
            if b.glide {
                heading = b.course
            } else {
                heading = b.course + tr.sinuosity * sin(b.gaitPhase * t.wiggleCycles * 2 * .pi)
                gait = speed * h / (size * max(0.1, t.strideLength))
            }
        case .hop:
            if b.glide {
                b.lift = 0
            } else {
                speed = hop(&b, h: h)
            }
        case .flutter:
            let old = b.sway
            b.sway += 2 * .pi * (fleeing ? 1.3 : 0.75) * vary * h
            let amp = tr.sinuosity * (fleeing ? 0.4 : 1)
            heading = b.course + amp * (sin(b.sway) + 0.35 * sin(2.3 * b.sway + 1.1)) / 1.35
            let lateral = size * (fleeing ? 0.08 : 0.2) * (sin(1.7 * b.sway) - sin(1.7 * old))
            dx -= sin(b.course) * lateral
            dy += cos(b.course) * lateral
            if fleeing {
                gait = 7.8
            } else if b.mode == .startled {
                gait = 6
            } else {
                gait = 3.3 + 0.1 * min(5, pace)
            }
        case .hover:
            let old = b.sway
            b.sway += 2 * .pi * vary * h
            let j = size * (fleeing ? 0.02 : 0.06)
            dx += j * (sin(2.3 * b.sway) - sin(2.3 * old) + 0.5 * (sin(3.7 * b.sway + 0.6) - sin(3.7 * old + 0.6)))
            dy += j * (sin(1.9 * b.sway + 1.3) - sin(1.9 * old + 1.3) + 0.5 * (sin(4.1 * b.sway + 2.2) - sin(4.1 * old + 2.2)))
            heading = b.course + tr.sinuosity * sin(1.3 * b.sway)
            gait = alarmed ? 9.5 : 6.5 + 0.3 * min(3, pace)
        case .float:
            let old = b.sway
            b.sway += 2 * .pi * (fleeing ? 0.9 : 0.4) * vary * h
            let lateral = size * (fleeing ? 0.12 : 0.35) * (sin(b.sway) - sin(old))
            dx -= sin(b.course) * lateral
            dy += cos(b.course) * lateral
            heading = b.course + tr.sinuosity * (fleeing ? 0.35 : 1) * sin(b.sway + 0.8)
            if fleeing {
                gait = 1.4
            } else if b.mode == .startled {
                gait = 0.9
            } else {
                gait = 0.5 + 0.03 * min(5, pace)
            }
        case .dart:
            let old = b.sway
            b.sway += 2 * .pi * vary * h
            let still = max(0, 1 - pace / 1.5)
            let j = size * 0.03 * still
            dx += j * (sin(2.9 * b.sway) - sin(2.9 * old))
            dy += j * (sin(2.1 * b.sway + 0.7) - sin(2.1 * old + 0.7))
            if fleeing {
                gait = 10
            } else {
                gait = pace > 2 ? 7.4 : 6.8
            }
        }

        if b.species.isAirborne { gait *= vary * h }
        b.heading = wrap(heading)
        if b.pinned {
            speed = 0
        } else {
            let dist = speed * h
            b.x += cos(b.heading) * dist + dx
            b.y += sin(b.heading) * dist + dy
        }
        if b.backward { b.heading = wrap(b.heading + .pi) }
        b.gaitPhase += gait
        b.pace = speed
        updateFacing(&b, h: h)
    }

    private func hop(_ b: inout Bug, h: Double) -> Double {
        let share = World.squatShare
        let size = max(1, b.size)
        let fleeing = b.mode == .fleeing
        let wants = b.speed > size * 0.15
        var whole = b.gaitPhase.rounded(.down)
        var p = b.gaitPhase - whole
        var remaining = h
        var travelled = 0.0
        while remaining > 1e-9 {
            if p < share {
                if !wants {
                    p = 0
                    break
                }
                let rate = share / (fleeing ? 0.05 : 0.14)
                let need = (share - p) / rate
                if need > remaining {
                    p += remaining * rate
                    remaining = 0
                } else {
                    p = share
                    remaining -= need
                    takeOff(&b)
                }
            } else {
                let rate = (1 - share) / max(0.05, b.hopAir)
                let need = (1 - p) / rate
                let used = min(need, remaining)
                travelled += b.hopSpeed * used
                remaining -= used
                if used >= need {
                    whole += 1
                    p = 0
                } else {
                    p += used * rate
                }
            }
        }
        b.gaitPhase = whole + p
        if p >= share {
            let q = (p - share) / (1 - share)
            b.lift = min(1, max(0, 4 * q * (1 - q)))
        }
        return travelled / h
    }

    private func takeOff(_ b: inout Bug) {
        let size = max(1, b.size)
        let fleeing = b.mode == .fleeing
        let v = max(b.speed, size * 0.15)
        let squat = fleeing ? 0.05 : 0.14
        let reach = size * (fleeing ? 2.6 : 1.0)
        let air = min(max(reach / v - squat, 0.2), fleeing ? 0.3 : 0.42)
        b.hopAir = air
        b.hopSpeed = min(tuning.fleeSpeedCap, v * (squat + air) / air)
    }

    private func updateFacing(_ b: inout Bug, h: Double) {
        b.facingHold -= h
        let moving = max(b.speed, b.pace) > b.size * 0.1 || b.lift > 0 || (b.stray?.started ?? false)
        guard moving, b.facingHold <= 0 else { return }
        let c = cos(b.course) * (b.backward ? -1 : 1)
        if c > 0.3 && b.facing < 0 {
            b.facing = 1
            b.facingHold = 0.3
        } else if c < -0.3 && b.facing > 0 {
            b.facing = -1
            b.facingHold = 0.3
        }
    }
}
