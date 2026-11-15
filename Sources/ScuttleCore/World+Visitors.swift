import Foundation

extension World {
    public func summonRare(_ species: Species? = nil) {
        guard isDarkNow, !rareAnnounced else {
            summonPending = true
            summonSpecies = species
            return
        }
        darkEpisode = true
        summonPending = false
        summonSpecies = nil
        bugs.removeAll { $0.rare && $0.mode == .hidden }
        spawnRare(species ?? config.season.rareVisitor, fast: true)
    }

    func guestList(for config: WorldConfig) -> [Species] {
        if let weather = config.weather { return weather.guests(night: config.night) }
        return config.night ? [.owl] : []
    }

    func guestTarget(population: Int, guests: [Species]) -> Int {
        guard !guests.isEmpty, population > 0 else { return 0 }
        var n = Int((Double(population) * max(0, tuning.weatherGuestShare)).rounded())
        if population >= 4 { n = max(1, n) }
        return min(population, n)
    }

    func emergeAllowance(members: Int) -> Int {
        let t = tuning
        guard t.growthSeconds > 0, darkSeconds < t.growthSeconds else { return Int.max }
        let start = max(0, t.growthStart)
        if members <= start { return members }
        let u = max(0, darkSeconds / t.growthSeconds)
        return start + Int(Double(members - start) * pow(u, max(0.1, t.growthCurve)))
    }

    func beginDarkEpisode() {
        let t = tuning
        darkEpisode = true
        let roll = rareRng.unit()
        let ufo = rareRng.unit() < t.ufoShare
        if summonPending {
            summonPending = false
            spawnRare(summonSpecies ?? config.season.rareVisitor, fast: true)
            summonSpecies = nil
        } else if t.forceRare ?? (roll < t.rareChance) {
            spawnRare(ufo ? .ufo : config.season.rareVisitor, fast: false)
        }
    }

    func endDarkEpisode() {
        closeWork()
        darkEpisode = false
        rareAnnounced = false
        rareFast = false
        bugs.removeAll { $0.rare }
    }

    private func spawnRare(_ species: Species, fast: Bool) {
        var b = makeBug(serial: (1 << 20) + rareSerial, config: config, species: species)
        rareSerial += 1
        b.rare = true
        b.nerve = tuning.nerveRange.upperBound
        if fast { b.emergeTimer = rareRng.range(tuning.rareSummonDelay) }
        rareFast = fast
        bugs.append(b)
    }
}
