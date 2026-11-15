import Foundation
import CoreGraphics
import ScuttleCore

enum FigureArt {
    static func draw(_ f: FigureFrame, in ctx: CGContext) {
        switch f.style {
        case .kawaii: KawaiiArt.draw(f, KawaiiKit(ctx, f))
        case .sticker: StickerArt.draw(f, StickerKit(ctx, f))
        case .hose: HoseArt.draw(f, HoseKit(ctx, f))
        case .mascot: MascotArt.draw(f, MascotKit(ctx, f))
        case .doodle: DoodleArt.draw(f, DoodleKit(ctx, f))
        }
    }

    static func finish(for style: ArtStyle) -> SpriteFinish {
        switch style {
        case .kawaii: return KawaiiKit.finish
        case .sticker: return StickerKit.finish
        case .hose: return HoseKit.finish
        case .mascot: return MascotKit.finish
        case .doodle: return DoodleKit.finish
        }
    }
}

extension KawaiiArt {
    static func draw(_ f: FigureFrame, _ k: KawaiiKit) {
        switch f.species {
        case .ladybird: ladybird(f, k)
        case .bumblebee: bumblebee(f, k)
        case .snail: snail(f, k)
        case .chick: chick(f, k)
        case .butterfly: butterfly(f, k)
        case .dragonfly: dragonfly(f, k)
        case .firefly: firefly(f, k)
        case .crab: crab(f, k)
        case .frog: frog(f, k)
        case .sun: sun(f, k)
        case .hedgehog: hedgehog(f, k)
        case .acorn: acorn(f, k)
        case .toadstool: toadstool(f, k)
        case .leaf: leaf(f, k)
        case .penguin: penguin(f, k)
        case .snowman: snowman(f, k)
        case .snowflake: snowflake(f, k)
        case .robin: robin(f, k)
        case .cloud: cloud(f, k)
        case .owl: owl(f, k)
        case .ghost: ghost(f, k)
        case .bat: bat(f, k)
        case .pumpkin: pumpkin(f, k)
        case .spider: spider(f, k)
        case .gingerbread: gingerbread(f, k)
        case .present: present(f, k)
        case .elf: elf(f, k)
        case .reindeer: reindeer(f, k)
        case .blackCat: blackCat(f, k)
        case .santa: santa(f, k)
        case .balloon: balloon(f, k)
        case .star: star(f, k)
        case .sparkler: sparkler(f, k)
        case .rocket: rocket(f, k)
        case .bunny: bunny(f, k)
        case .turtle: turtle(f, k)
        case .fox: fox(f, k)
        case .polarBear: polarBear(f, k)
        case .comet: comet(f, k)
        case .ufo: ufo(f, k)
        }
    }
}

extension StickerArt {
    static func draw(_ f: FigureFrame, _ k: StickerKit) {
        switch f.species {
        case .ladybird: ladybird(f, k)
        case .bumblebee: bumblebee(f, k)
        case .snail: snail(f, k)
        case .chick: chick(f, k)
        case .butterfly: butterfly(f, k)
        case .dragonfly: dragonfly(f, k)
        case .firefly: firefly(f, k)
        case .crab: crab(f, k)
        case .frog: frog(f, k)
        case .sun: sun(f, k)
        case .hedgehog: hedgehog(f, k)
        case .acorn: acorn(f, k)
        case .toadstool: toadstool(f, k)
        case .leaf: leaf(f, k)
        case .penguin: penguin(f, k)
        case .snowman: snowman(f, k)
        case .snowflake: snowflake(f, k)
        case .robin: robin(f, k)
        case .cloud: cloud(f, k)
        case .owl: owl(f, k)
        case .ghost: ghost(f, k)
        case .bat: bat(f, k)
        case .pumpkin: pumpkin(f, k)
        case .spider: spider(f, k)
        case .gingerbread: gingerbread(f, k)
        case .present: present(f, k)
        case .elf: elf(f, k)
        case .reindeer: reindeer(f, k)
        case .blackCat: blackCat(f, k)
        case .santa: santa(f, k)
        case .balloon: balloon(f, k)
        case .star: star(f, k)
        case .sparkler: sparkler(f, k)
        case .rocket: rocket(f, k)
        case .bunny: bunny(f, k)
        case .turtle: turtle(f, k)
        case .fox: fox(f, k)
        case .polarBear: polarBear(f, k)
        case .comet: comet(f, k)
        case .ufo: ufo(f, k)
        }
    }
}

extension HoseArt {
    static func draw(_ f: FigureFrame, _ k: HoseKit) {
        switch f.species {
        case .ladybird: ladybird(f, k)
        case .bumblebee: bumblebee(f, k)
        case .snail: snail(f, k)
        case .chick: chick(f, k)
        case .butterfly: butterfly(f, k)
        case .dragonfly: dragonfly(f, k)
        case .firefly: firefly(f, k)
        case .crab: crab(f, k)
        case .frog: frog(f, k)
        case .sun: sun(f, k)
        case .hedgehog: hedgehog(f, k)
        case .acorn: acorn(f, k)
        case .toadstool: toadstool(f, k)
        case .leaf: leaf(f, k)
        case .penguin: penguin(f, k)
        case .snowman: snowman(f, k)
        case .snowflake: snowflake(f, k)
        case .robin: robin(f, k)
        case .cloud: cloud(f, k)
        case .owl: owl(f, k)
        case .ghost: ghost(f, k)
        case .bat: bat(f, k)
        case .pumpkin: pumpkin(f, k)
        case .spider: spider(f, k)
        case .gingerbread: gingerbread(f, k)
        case .present: present(f, k)
        case .elf: elf(f, k)
        case .reindeer: reindeer(f, k)
        case .blackCat: blackCat(f, k)
        case .santa: santa(f, k)
        case .balloon: balloon(f, k)
        case .star: star(f, k)
        case .sparkler: sparkler(f, k)
        case .rocket: rocket(f, k)
        case .bunny: bunny(f, k)
        case .turtle: turtle(f, k)
        case .fox: fox(f, k)
        case .polarBear: polarBear(f, k)
        case .comet: comet(f, k)
        case .ufo: ufo(f, k)
        }
    }
}

extension MascotArt {
    static func draw(_ f: FigureFrame, _ k: MascotKit) {
        switch f.species {
        case .ladybird: ladybird(f, k)
        case .bumblebee: bumblebee(f, k)
        case .snail: snail(f, k)
        case .chick: chick(f, k)
        case .butterfly: butterfly(f, k)
        case .dragonfly: dragonfly(f, k)
        case .firefly: firefly(f, k)
        case .crab: crab(f, k)
        case .frog: frog(f, k)
        case .sun: sun(f, k)
        case .hedgehog: hedgehog(f, k)
        case .acorn: acorn(f, k)
        case .toadstool: toadstool(f, k)
        case .leaf: leaf(f, k)
        case .penguin: penguin(f, k)
        case .snowman: snowman(f, k)
        case .snowflake: snowflake(f, k)
        case .robin: robin(f, k)
        case .cloud: cloud(f, k)
        case .owl: owl(f, k)
        case .ghost: ghost(f, k)
        case .bat: bat(f, k)
        case .pumpkin: pumpkin(f, k)
        case .spider: spider(f, k)
        case .gingerbread: gingerbread(f, k)
        case .present: present(f, k)
        case .elf: elf(f, k)
        case .reindeer: reindeer(f, k)
        case .blackCat: blackCat(f, k)
        case .santa: santa(f, k)
        case .balloon: balloon(f, k)
        case .star: star(f, k)
        case .sparkler: sparkler(f, k)
        case .rocket: rocket(f, k)
        case .bunny: bunny(f, k)
        case .turtle: turtle(f, k)
        case .fox: fox(f, k)
        case .polarBear: polarBear(f, k)
        case .comet: comet(f, k)
        case .ufo: ufo(f, k)
        }
    }
}

extension DoodleArt {
    static func draw(_ f: FigureFrame, _ k: DoodleKit) {
        switch f.species {
        case .ladybird: ladybird(f, k)
        case .bumblebee: bumblebee(f, k)
        case .snail: snail(f, k)
        case .chick: chick(f, k)
        case .butterfly: butterfly(f, k)
        case .dragonfly: dragonfly(f, k)
        case .firefly: firefly(f, k)
        case .crab: crab(f, k)
        case .frog: frog(f, k)
        case .sun: sun(f, k)
        case .hedgehog: hedgehog(f, k)
        case .acorn: acorn(f, k)
        case .toadstool: toadstool(f, k)
        case .leaf: leaf(f, k)
        case .penguin: penguin(f, k)
        case .snowman: snowman(f, k)
        case .snowflake: snowflake(f, k)
        case .robin: robin(f, k)
        case .cloud: cloud(f, k)
        case .owl: owl(f, k)
        case .ghost: ghost(f, k)
        case .bat: bat(f, k)
        case .pumpkin: pumpkin(f, k)
        case .spider: spider(f, k)
        case .gingerbread: gingerbread(f, k)
        case .present: present(f, k)
        case .elf: elf(f, k)
        case .reindeer: reindeer(f, k)
        case .blackCat: blackCat(f, k)
        case .santa: santa(f, k)
        case .balloon: balloon(f, k)
        case .star: star(f, k)
        case .sparkler: sparkler(f, k)
        case .rocket: rocket(f, k)
        case .bunny: bunny(f, k)
        case .turtle: turtle(f, k)
        case .fox: fox(f, k)
        case .polarBear: polarBear(f, k)
        case .comet: comet(f, k)
        case .ufo: ufo(f, k)
        }
    }
}
