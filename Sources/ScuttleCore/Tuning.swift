import Foundation

public struct SpeciesTraits: Sendable, Equatable {
    public var weight: Double
    public var sizeRange: ClosedRange<Double>
    public var cruise: Double
    public var burst: ClosedRange<Double>
    public var pause: ClosedRange<Double>
    public var chainChance: Double
    public var turnRate: Double
    public var turnSpread: Double
    public var meander: Double
    public var dashChance: Double
    public var dashBoost: Double
    public var sinuosity: Double
    public var bendRate: Double
    public var fleeSpeed: Double

    public init(
        weight: Double,
        sizeRange: ClosedRange<Double>,
        cruise: Double,
        burst: ClosedRange<Double>,
        pause: ClosedRange<Double>,
        chainChance: Double,
        turnRate: Double,
        turnSpread: Double,
        meander: Double,
        dashChance: Double,
        dashBoost: Double,
        sinuosity: Double,
        bendRate: Double,
        fleeSpeed: Double
    ) {
        self.weight = weight
        self.sizeRange = sizeRange
        self.cruise = cruise
        self.burst = burst
        self.pause = pause
        self.chainChance = chainChance
        self.turnRate = turnRate
        self.turnSpread = turnSpread
        self.meander = meander
        self.dashChance = dashChance
        self.dashBoost = dashBoost
        self.sinuosity = sinuosity
        self.bendRate = bendRate
        self.fleeSpeed = fleeSpeed
    }
}

public struct Tuning: Sendable, Equatable {
    public static let figureScale: Double = 2.25

    public var darkAngle: Double = 15
    public var litAngle: Double = 85
    public var lightSmoothing: Double = 0.06
    public var lightRateSmoothing: Double = 0.08
    public var fullLight: Double = 0.995

    public var nerveRange: ClosedRange<Double> = 0.08...0.8
    public var nerveSkew: Double = 1.4
    public var nerveHysteresis: Double = 0.035

    public var growthSeconds: Double = 60
    public var growthStart: Int = 3
    public var growthCurve: Double = 1.3
    public var growthGrace: Double = 2

    public var weatherGuestShare: Double = 0.25

    public var forceRare: Bool? = nil
    public var rareChance: Double = 0.05
    public var ufoShare: Double = 0.12
    public var rareMinDark: Double = 20
    public var rareSummonDelay: ClosedRange<Double> = 0.6...1.4

    public var emergeDelay: ClosedRange<Double> = 0.25...6.5
    public var emergeMinGap: Double = 0.07
    public var reemergeCooldown: ClosedRange<Double> = 0.8...3.0
    public var bottomEntryWeight: Double = 0.4
    public var leftEntryWeight: Double = 0.2
    public var rightEntryWeight: Double = 0.2
    public var topEntryWeight: Double = 0.2
    public var entryCornerMargin: Double = 0.06
    public var peekChance: Double = 0.45
    public var peekPause: ClosedRange<Double> = 0.3...1.1

    public var maxVenture: Double = 0.78
    public var maxEdgeDistance: Double = 520
    public var ventureRange: ClosedRange<Double> = 0.3...1.0
    public var ventureDarknessCurve: Double = 0.75
    public var ceilingSlack: Double = 12
    public var goalSeeking: Double = 0.55
    public var wallAngle: Double = 0.06
    public var steerGain: Double = 6
    public var avoidance: Double = 0.9
    public var avoidRadius: Double = 0.6
    public var hurryBoost: Double = 1.4
    public var wiggleCycles: Double = 0.55
    public var strideLength: Double = 0.9
    public var airAvoidance: Double = 0.4

    public var startleRate: Double = 0.9
    public var startleLookahead: Double = 0.35
    public var flinchRate: Double = 2.2
    public var startleDelay: ClosedRange<Double> = 0.08...0.75
    public var startleSlowScale: Double = 1.25
    public var startleSnapScale: Double = 0.95
    public var rippleWeight: Double = 0.4
    public var catchEnabled: Bool = true
    public var catchWindow: Double = 0.5
    public var catchJitter: Double = 0.04
    public var catchReact: Double = 0.42
    public var catchHold: ClosedRange<Double> = 0.5...0.6
    public var catchWakeHold: Double = 0.45
    public var catchWakePanic: Double = 0.85
    public var catchCascade: Double = 0.6
    public var catchWindup: ClosedRange<Double> = 0.16...0.24
    public var catchSlipWindup: Double = 0.5
    public var catchSideBias: Double = 0.5
    public var catchTopBias: Double = 1.5
    public var catchDashDeadline: Double = 1.1
    public var catchLaunch: Double = 0.35
    public var catchGlanceRange: Double = 3.2
    public var catchGlanceChance: Double = 0.7
    public var catchNaturalChance: Double = 0.5
    public var catchLookChance: Double = 0.5
    public var catchWrongWayChance: Double = 0.35
    public var catchSlipChance: Double = 0.35
    public var forceCatchQuirk: CatchQuirk? = nil
    public var panicRateFloor: Double = 0.15
    public var panicRateFull: Double = 3.2
    public var panicMemory: Double = 0.5

    public var fleeSpeedRange: ClosedRange<Double> = 240...420
    public var fleeSizeExponent: Double = 0.3
    public var fleeSlowFactor: Double = 0.5
    public var fleeSnapFactor: Double = 0.9
    public var fleeSpeedCap: Double = 480
    public var fleeAccelTime: Double = 0.32
    public var fleeTurnRate: Double = 9
    public var fleeWobble: ClosedRange<Double> = 0.22...0.48
    public var fleeWobbleHz: ClosedRange<Double> = 2.2...4.0
    public var sideEdgeBias: Double = 1.0
    public var homeEdgeBias: Double = 0.8
    public var fleeAimSpread: Double = 0.4
    public var hesitantChance: Double = 0.06
    public var hesitation: ClosedRange<Double> = 0.25...0.5
    public var wrongWay: ClosedRange<Double> = 0.22...0.45
    public var clearTimeSnap: Double = 2.8
    public var clearTimeSlow: Double = 5.5

    public var forceStraggler: Bool? = nil
    public var confusedStragglerChance: Double = 0.25
    public var confusedMinPanic: Double = 0.35
    public var confusedMinDepth: Double = 110
    public var confusedDartWeight: Double = 0.25
    public var confusedDuration: ClosedRange<Double> = 3.8...6.6
    public var confusedRealiseDelay: Double = 0.25
    public var confusedMaxSeconds: Double = 12
    public var confusedRampTime: Double = 0.5
    public var confusedCalmTime: Double = 0.4
    public var confusedMargin: Double = 44
    public var confusedTopMargin: Double = 70
    public var confusedRunFactor: Double = 0.7
    public var confusedExitBoost: Double = 1.35
    public var confusedBolt: ClosedRange<Double> = 0.5...0.9
    public var confusedLook: ClosedRange<Double> = 1.0...1.6
    public var confusedLookSwing: ClosedRange<Double> = 0.8...1.3
    public var confusedDither: ClosedRange<Double> = 1.2...1.9
    public var confusedDoubleBack: ClosedRange<Double> = 0.4...0.65
    public var confusedEdgeRunMax: Double = 2.2
    public var confusedEdgeRunBoost: Double = 1.3
    public var confusedEdgePause: ClosedRange<Double> = 0.35...0.6
    public var confusedSpin: ClosedRange<Double> = 0.75...1.0
    public var confusedFreeze: ClosedRange<Double> = 0.7...1.1
    public var confusedSpot: ClosedRange<Double> = 0.45...0.6

    public var failsafeSeconds: Double = 5.5
    public var failsafeGrace: Double = 1.5
    public var fadeTime: Double = 0.25

    public var scatterEventLatency: Double = 0.05
    public var scatterQuietTime: Double = 0.6
    public var activityScale: Double = 36

    public var traitOverrides: [Species: SpeciesTraits] = [:]

    public var deepAngle: Double = 12
    public var deepGrace: Double = 1.5
    public var duskLight: Double = 0.36
    public var lidVelocitySmoothing: Double = 0.08
    public var arrivalProbeAngle: Double = 66
    public var slamRate: Double = 170
    public var slowRate: Double = 15
    public var slamBurst: Int = 3
    public var slamBurstSpacing: ClosedRange<Double> = 0.08...0.22
    public var carefulArrivals: Int = 2
    public var carefulPeekScale: Double = 2.4

    public var jiggleEnabled: Bool = true
    public var jiggleMinSwing: Double = 2
    public var jiggleTurns: Int = 3
    public var jiggleWindow: Double = 1.5
    public var jiggleMaxGap: Double = 0.7
    public var jiggleMaxSpan: Double = 30
    public var jiggleHold: Double = 0.5
    public var shakeTumbleShare: Double = 0.35
    public var shakeDelay: ClosedRange<Double> = 0...0.25
    public var shakeKick: ClosedRange<Double> = 50...130
    public var shakeDizzy: ClosedRange<Double> = 0.6...1.1
    public var shakeRecover: ClosedRange<Double> = 0.4...0.8
    public var shakeMaxSeconds: Double = 10

    public var peekEnabled: Bool = true
    public var peekLowAngle: Double = 62
    public var peekHighAngle: Double = 84
    public var peekDwell: Double = 1.0
    public var peekSteadyRate: Double = 3
    public var peekMax: Int = 3
    public var peekPool: Int = 4
    public var peekBottomWeight: Double = 0.6
    public var peekSideWeight: Double = 0.2
    public var peekGap: ClosedRange<Double> = 2.0...5.0
    public var peekScareGap: ClosedRange<Double> = 2.5...4.5
    public var peekRise: ClosedRange<Double> = 0.7...1.2
    public var peekWatch: ClosedRange<Double> = 3.5...8.0
    public var peekLook: ClosedRange<Double> = 1.2...2.6
    public var peekShallow: Double = -0.22
    public var peekDeep: Double = 0.25
    public var peekPatience: Double = 45
    public var peekBoredScale: Double = 3
    public var peekGiveUp: Double = 180
    public var peekDuckRise: Double = 2.5
    public var peekDuckRate: Double = 12
    public var peekDuckTime: Double = 0.22
    public var peekCooldown: ClosedRange<Double> = 4...9
    public var peekSlideChance: Double = 0.35
    public var forcePeekDare: Bool? = nil
    public var peekDareChance: Double = 0.15
    public var peekDareWave: ClosedRange<Double> = 1.2...1.7

    public var forceEntrance: EntranceStyle? = nil
    public var entranceGap: Double = 1.2
    public var entranceMaxSeconds: Double = 14
    public var popUpChance: Double = 0.3
    public var parachuteChance: Double = 0.45
    public var swoopChance: Double = 0.35
    public var shyChance: Double = 0.06
    public var congaChance: Double = 0.05
    public var popUpRise: ClosedRange<Double> = 0.28...0.4
    public var popUpLook: ClosedRange<Double> = 0.6...1.1
    public var moleChance: Double = 0.35
    public var moleShift: ClosedRange<Double> = 80...220
    public var parachuteSpeed: ClosedRange<Double> = 38...55
    public var parachuteLand: ClosedRange<Double> = 0.2...0.42
    public var parachuteMaxSeconds: Double = 6
    public var swoopTime: ClosedRange<Double> = 1.0...1.5
    public var swoopBoost: Double = 2.6
    public var tumbleSpeed: ClosedRange<Double> = 200...260
    public var tumbleTime: ClosedRange<Double> = 0.6...0.9
    public var shyDepth: ClosedRange<Double> = 1.3...2.0
    public var shyWait: ClosedRange<Double> = 1.0...2.5
    public var shyRetryChance: Double = 0.25
    public var congaSize: ClosedRange<Int> = 3...4
    public var congaLength: ClosedRange<Double> = 6...9
    public var congaCooldown: ClosedRange<Double> = 40...90
    public var congaMinDark: Double = 12
    public var congaBorrow: Int = 2

    public var gentleEnabled: Bool = true
    public var gentleRate: Double = 0.5
    public var sneakNotice: ClosedRange<Double> = 0.35...0.75
    public var sneakSpeed: Double = 0.24
    public var sneakDeadline: Double = 3.2
    public var sneakLitDeadline: Double = 1.8
    public var forceBackward: Bool? = nil
    public var backwardChance: Double = 0.4
    public var forceWaveBye: Bool? = nil
    public var waveByeChance: Double = 0.12
    public var waveByeLength: ClosedRange<Double> = 0.9...1.3
    public var waveByeGap: Double = 5
    public var lastLookLength: ClosedRange<Double> = 0.6...0.9

    public var playEnabled: Bool = true
    public var actTick: ClosedRange<Double> = 1.5...3.5
    public var playAfter: Double = 8
    public var playChance: Double = 0.45
    public var playShare: Double = 0.1
    public var danceLength: ClosedRange<Double> = 2.5...4.5
    public var cheerLength: ClosedRange<Double> = 1.2...1.8
    public var sleepEnabled: Bool = true
    public var sleepAfter: Double = 40
    public var sleepRamp: Double = 60
    public var sleepShare: Double = 0.5
    public var sleepLength: ClosedRange<Double> = 25...70
    public var wakeLength: ClosedRange<Double> = 0.6...1.0
    public var wakeMargin: Double = 4
    public var wakeRate: Double = 6
    public var forceRipple: Bool? = nil
    public var rippleAfter: Double = 18
    public var rippleChance: Double = 0.06
    public var rippleCooldown: ClosedRange<Double> = 45...90
    public var rippleSpan: Double = 1.8
    public var forceGreeting: Bool? = nil
    public var greetAfter: Double = 6
    public var greetChance: Double = 0.12
    public var greetCooldown: ClosedRange<Double> = 25...50
    public var greetLength: ClosedRange<Double> = 1.6...2.4
    public var greetCentre: Double = 0.22
    public var duskLookChance: Double = 0.45
    public var duskHug: Double = 0.55
    public var duskReach: Double = 0.75

    public var socialEnabled: Bool = true
    public var forceSocial: SocialKind? = nil
    public var socialTick: ClosedRange<Double> = 1.5...3.5
    public var socialAfter: Double = 10
    public var socialChance: Double = 0.45
    public var socialShare: Double = 0.16
    public var socialMax: Int = 10
    public var socialCooldown: ClosedRange<Double> = 18...40
    public var socialMaxSeconds: Double = 24
    public var socialWeights: [SocialKind: Double] = [:]
    public var strollLength: ClosedRange<Double> = 7...12
    public var strollReach: Double = 240
    public var stringLength: ClosedRange<Double> = 8...14
    public var stringSize: ClosedRange<Int> = 3...4
    public var tagLength: ClosedRange<Double> = 10...16
    public var tagRadius: Double = 230
    public var tagTouches: Int = 5
    public var huddleSize: ClosedRange<Int> = 3...5
    public var huddleChat: ClosedRange<Double> = 5...9
    public var duetLength: ClosedRange<Double> = 3...4.5
    public var nudgeAfter: Double = 8
    public var visitLength: ClosedRange<Double> = 2.5...4
    public var shadeLength: ClosedRange<Double> = 4...7
    public var admireSize: ClosedRange<Int> = 2...4
    public var admireLength: ClosedRange<Double> = 7...11
    public var raceLength: ClosedRange<Double> = 8...12
    public var rollDistance: ClosedRange<Double> = 2...3.2
    public var bobHeight: ClosedRange<Double> = 1.2...2.0
    public var peekabooReach: Double = 280
    public var rainDanceLength: ClosedRange<Double> = 3...4.5
    public var watchLength: ClosedRange<Double> = 1.2...1.8
    public var flinchEnabled: Bool = true
    public var flinchRadius: Double = 150
    public var flinchMax: Int = 4

    public var pointerEnabled: Bool = true
    public var pointerShySpeed: Double = 70
    public var pointerShyRadius: Double = 110
    public var pointerScamperSpeed: Double = 380
    public var pointerSwipeSpeed: Double = 900
    public var pointerBowlRadius: Double = 50
    public var pointerCooldown: ClosedRange<Double> = 2.5...4
    public var pointerStillRadius: Double = 8
    public var pointerStillSpeed: Double = 15
    public var curiosityEnabled: Bool = true
    public var forceCuriosity: Bool? = nil
    public var curiosityDelay: Double = 2.5
    public var curiosityRange: Double = 380
    public var curiosityNerve: Double = 0.3
    public var curiosityTick: ClosedRange<Double> = 0.8...1.6
    public var curiosityChance: Double = 0.7
    public var curiousMax: Int = 2
    public var audienceDelay: Double = 7
    public var audienceMax: Int = 5
    public var curiosityBored: Double = 40
    public var curiosityCooldown: ClosedRange<Double> = 15...30
    public var curiousWaveChance: Double = 0.35
    public var followEnabled: Bool = true
    public var forceFollow: Bool? = nil
    public var followChance: Double = 0.2
    public var followSpeed: ClosedRange<Double> = 25...260
    public var followLength: ClosedRange<Double> = 8...14
    public var followLose: Double = 480
    public var followRange: Double = 320
    public var followCooldown: ClosedRange<Double> = 20...40
    public var followTrainChance: Double = 0.35

    public var perchEnabled: Bool = true
    public var forcePerch: Bool? = nil
    public var perchTick: ClosedRange<Double> = 1.0...2.5
    public var perchChance: Double = 0.35
    public var perchShare: Double = 0.12
    public var perchMax: Int = 6
    public var perchRange: Double = 650
    public var perchStay: ClosedRange<Double> = 10...30
    public var perchSit: ClosedRange<Double> = 2.5...6
    public var perchTravelMax: Double = 9
    public var perchTrack: Double = 24
    public var perchFeet: Double = 0.46
    public var perchHopRange: Double = 320
    public var perchCooldown: ClosedRange<Double> = 12...25
    public var dockMax: Int = 1
    public var dockChance: Double = 0.25

    public var habitsEnabled: Bool = true
    public var forceHabit: HabitKind? = nil
    public var habitChance: Double = 0.16
    public var habitShare: Double = 0.15
    public var habitAfter: Double = 5

    public var propFadeRate: Double = 0.6
    public var propFadeFrom: Double = 0.55
    public var propLitMax: Double = 2.5
    public var propIdleLife: Double = 75
    public var propLooseMax: Int = 14
    public var propMax: Int = 90
    public var ballFriction: Double = 1.1
    public var ballBounce: Double = 0.7
    public var grabChance: Double = 0.3
    public var carryOffChance: Double = 0.65

    public var workEnabled: Bool = true
    public var workTick: ClosedRange<Double> = 1.2...2.6
    public var workChance: Double = 0.55
    public var workShare: Double = 0.25
    public var workMax: Int = 14
    public var jobMaxSeconds: Double = 160
    public var watchChance: Double = 0.3
    public var watchRange: Double = 360

    public var errandsEnabled: Bool = true
    public var forceErrand: ErrandKind? = nil
    public var errandAfter: Double = 6
    public var errandShare: Double = 0.08
    public var errandCooldown: ClosedRange<Double> = 6...16
    public var duskBand: Double = 150
    public var plantGrow: Double = 3
    public var flowerMax: Int = 8
    public var lanternWalk: ClosedRange<Double> = 10...16

    public var projectsEnabled: Bool = true
    public var forceProject: ProjectKind? = nil
    public var projectAfter: Double = 14
    public var projectMinVisible: Int = 6
    public var projectCrew: ClosedRange<Int> = 2...4
    public var projectCooldown: ClosedRange<Double> = 20...45
    public var projectTrips: ClosedRange<Int> = 3...5
    public var dropChance: Double = 0.12
    public var celebrateLength: ClosedRange<Double> = 4...6
    public var useLength: ClosedRange<Double> = 40...80
    public var workSpeed: Double = 1
    public var stealChance: Double = 0.06
    public var stealCooldown: ClosedRange<Double> = 40...80
    public var inspectChance: Double = 0.5
    public var inspectCooldown: ClosedRange<Double> = 25...50

    public var buildMemoryEnabled: Bool = true
    public var buildMemorySeconds: Double = 180
    public var memoryAfter: Double = 4

    public var gamesEnabled: Bool = true
    public var forceGame: GameKind? = nil
    public var gameAfter: Double = 8
    public var gameMinVisible: Int = 6
    public var gameCooldown: ClosedRange<Double> = 25...50
    public var ballKicks: ClosedRange<Int> = 10...16
    public var ballLength: ClosedRange<Double> = 25...40
    public var missChance: Double = 0.12
    public var tugLength: ClosedRange<Double> = 9...14
    public var fightLength: ClosedRange<Double> = 12...18
    public var hideCount: ClosedRange<Double> = 5...6.5
    public var hideLength: Double = 45

    public init() {}

    @available(*, deprecated, renamed: "hesitantChance")
    public var stragglerChance: Double {
        get { hesitantChance }
        set { hesitantChance = newValue }
    }

    @available(*, deprecated, message: "Use bottomEntryWeight, leftEntryWeight, rightEntryWeight and topEntryWeight")
    public var bottomEntryChance: Double {
        get {
            let total = max(0, bottomEntryWeight) + max(0, leftEntryWeight) + max(0, rightEntryWeight) + max(0, topEntryWeight)
            return total > 0 ? max(0, bottomEntryWeight) / total : 0
        }
        set {
            let others = max(0, leftEntryWeight) + max(0, rightEntryWeight) + max(0, topEntryWeight)
            let v = min(max(newValue, 0), 1)
            bottomEntryWeight = others > 0 ? min(1e6, v * others / max(1e-6, 1 - v)) : v
        }
    }

    public func traits(for species: Species) -> SpeciesTraits {
        traitOverrides[species] ?? SpeciesTraits.standard(for: species)
    }
}

extension SpeciesTraits {
    public static func standard(for species: Species) -> SpeciesTraits {
        var t = base(for: species.locomotion)
        switch species {
        case .ladybird:
            t.sizeRange = 16...22
            t.cruise = 2.2
        case .snail:
            t.sizeRange = 22...30
            t.cruise = 0.45
            t.burst = 3.0...7.0
            t.pause = 1.0...2.6
            t.chainChance = 0.6
            t.turnRate = 1.2
            t.meander = 0.3
            t.dashChance = 0
            t.sinuosity = 0.01
            t.fleeSpeed = 300
        case .spider:
            t.sizeRange = 16...24
            t.cruise = 2.8
            t.burst = 0.6...2.0
            t.dashChance = 0.12
            t.dashBoost = 2.2
            t.fleeSpeed = 310
        case .crab:
            t.sizeRange = 22...30
            t.turnSpread = 1.0
            t.fleeSpeed = 300
        case .hedgehog:
            t.sizeRange = 30...38
            t.cruise = 1.3
        case .toadstool:
            t.sizeRange = 24...32
            t.cruise = 1.0
            t.sinuosity = 0.08
        case .penguin:
            t.sizeRange = 26...34
            t.cruise = 1.1
            t.sinuosity = 0.1
            t.fleeSpeed = 300
        case .snowman:
            t.weight = 0.8
            t.sizeRange = 32...40
            t.cruise = 0.55
            t.burst = 3.0...7.0
            t.pause = 1.0...2.5
            t.sinuosity = 0.04
            t.fleeSpeed = 300
        case .gingerbread:
            t.sizeRange = 24...32
            t.cruise = 1.6
            t.fleeSpeed = 300
        case .elf:
            t.sizeRange = 22...30
            t.cruise = 1.8
            t.fleeSpeed = 310
        case .reindeer:
            t.sizeRange = 32...40
            t.cruise = 1.5
            t.fleeSpeed = 310
        case .sparkler:
            t.sizeRange = 24...34
            t.cruise = 1.5
            t.fleeSpeed = 300
        case .chick:
            t.sizeRange = 20...28
            t.cruise = 1.6
        case .acorn:
            t.sizeRange = 20...26
            t.cruise = 1.5
        case .robin:
            t.sizeRange = 20...28
            t.cruise = 1.9
            t.pause = 0.3...1.0
        case .pumpkin:
            t.sizeRange = 26...34
            t.cruise = 1.3
        case .present:
            t.sizeRange = 24...32
            t.cruise = 1.4
        case .butterfly:
            t.sizeRange = 24...32
        case .bat:
            t.sizeRange = 24...32
            t.cruise = 2.6
            t.sinuosity = 0.7
            t.meander = 1.4
        case .bumblebee:
            t.sizeRange = 18...24
            t.cruise = 2.2
        case .firefly:
            t.sizeRange = 14...20
            t.cruise = 2.0
            t.pause = 0.4...1.0
        case .leaf:
            t.sizeRange = 22...30
            t.cruise = 1.0
            t.sinuosity = 0.4
        case .snowflake:
            t.sizeRange = 18...26
            t.cruise = 0.8
            t.sinuosity = 0.25
        case .ghost:
            t.sizeRange = 28...36
            t.sinuosity = 0.2
        case .balloon:
            t.weight = 0.9
            t.sizeRange = 30...38
            t.cruise = 0.7
            t.sinuosity = 0.15
        case .star:
            t.sizeRange = 22...30
            t.sinuosity = 0.25
        case .dragonfly:
            t.sizeRange = 26...34
            t.cruise = 6.5
        case .rocket:
            t.sizeRange = 26...36
            t.cruise = 6.0
        case .frog:
            t.sizeRange = 24...32
            t.cruise = 1.6
        case .cloud:
            t.sizeRange = 32...42
            t.cruise = 0.6
            t.sinuosity = 0.1
        case .sun:
            t.sizeRange = 28...36
            t.cruise = 0.7
            t.sinuosity = 0.15
        case .owl:
            t.sizeRange = 28...36
            t.cruise = 1.2
            t.pause = 0.8...2.4
        case .bunny:
            t.sizeRange = 34...40
            t.cruise = 1.8
        case .turtle:
            t.sizeRange = 36...42
            t.cruise = 0.5
            t.burst = 3.0...7.0
            t.fleeSpeed = 300
        case .fox:
            t.sizeRange = 38...44
            t.cruise = 1.6
            t.fleeSpeed = 310
        case .polarBear:
            t.sizeRange = 40...46
            t.cruise = 1.0
            t.fleeSpeed = 300
        case .blackCat:
            t.sizeRange = 34...40
            t.cruise = 1.7
            t.fleeSpeed = 310
        case .santa:
            t.sizeRange = 36...42
            t.cruise = 1.2
            t.fleeSpeed = 300
        case .comet:
            t.sizeRange = 34...40
            t.cruise = 6.0
        case .ufo:
            t.sizeRange = 38...46
            t.cruise = 1.6
            t.pause = 0.8...2.0
        }
        return t
    }

    static func base(for locomotion: Locomotion) -> SpeciesTraits {
        switch locomotion {
        case .crawl:
            return SpeciesTraits(
                weight: 1, sizeRange: 18...26, cruise: 2.0, burst: 1.2...3.6, pause: 0.4...1.6,
                chainChance: 0.5, turnRate: 2.6, turnSpread: 0.7, meander: 0.5,
                dashChance: 0.03, dashBoost: 1.8, sinuosity: 0.03, bendRate: 3, fleeSpeed: 290)
        case .walk:
            return SpeciesTraits(
                weight: 1, sizeRange: 24...34, cruise: 1.4, burst: 2.0...5.0, pause: 0.5...1.6,
                chainChance: 0.55, turnRate: 2.0, turnSpread: 0.5, meander: 0.3,
                dashChance: 0, dashBoost: 1, sinuosity: 0.05, bendRate: 3, fleeSpeed: 290)
        case .hop:
            return SpeciesTraits(
                weight: 1, sizeRange: 22...30, cruise: 1.7, burst: 1.0...2.6, pause: 0.4...1.4,
                chainChance: 0.45, turnRate: 3.0, turnSpread: 0.8, meander: 0.4,
                dashChance: 0.06, dashBoost: 1.6, sinuosity: 0, bendRate: 3, fleeSpeed: 300)
        case .flutter:
            return SpeciesTraits(
                weight: 1, sizeRange: 24...32, cruise: 2.2, burst: 2.0...5.0, pause: 0.6...1.8,
                chainChance: 0.65, turnRate: 3.0, turnSpread: 1.0, meander: 1.1,
                dashChance: 0.04, dashBoost: 1.5, sinuosity: 0.55, bendRate: 3, fleeSpeed: 300)
        case .hover:
            return SpeciesTraits(
                weight: 1, sizeRange: 18...24, cruise: 2.4, burst: 1.0...2.8, pause: 0.25...0.8,
                chainChance: 0.45, turnRate: 3.6, turnSpread: 1.0, meander: 0.6,
                dashChance: 0.08, dashBoost: 1.8, sinuosity: 0.08, bendRate: 3, fleeSpeed: 310)
        case .float:
            return SpeciesTraits(
                weight: 1, sizeRange: 24...32, cruise: 0.9, burst: 3.0...7.0, pause: 0.6...1.6,
                chainChance: 0.75, turnRate: 1.2, turnSpread: 0.6, meander: 0.5,
                dashChance: 0, dashBoost: 1, sinuosity: 0.3, bendRate: 3, fleeSpeed: 290)
        case .dart:
            return SpeciesTraits(
                weight: 0.7, sizeRange: 26...34, cruise: 6.0, burst: 0.25...0.55, pause: 1.2...3.2,
                chainChance: 0.15, turnRate: 9, turnSpread: 1.4, meander: 0.1,
                dashChance: 0, dashBoost: 1, sinuosity: 0, bendRate: 5, fleeSpeed: 320)
        }
    }
}
