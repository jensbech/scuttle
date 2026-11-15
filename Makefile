APP := Scuttle.app
PREFIX ?= /Applications

DEMO_DIR ?= .build/demo
DEMO_FROM ?= 86.6
DEMO_TO ?= 95
DEMO_QUALITY ?= 78
SWIFT_FLAGS ?=

.PHONY: build install uninstall test clean demo

build:
	scripts/build-app.sh

install: build
	-osascript -e 'quit app "Scuttle"' 2>/dev/null
	rm -rf "$(PREFIX)/$(APP)"
	cp -R build/$(APP) "$(PREFIX)/$(APP)"
	open "$(PREFIX)/$(APP)"

uninstall:
	-osascript -e 'quit app "Scuttle"' 2>/dev/null
	rm -rf "$(PREFIX)/$(APP)"

test:
	swift test

demo:
	swift build -c release $(SWIFT_FLAGS) --product ScuttleSnap
	rm -rf $(DEMO_DIR)
	"$$(swift build -c release $(SWIFT_FLAGS) --show-bin-path)/ScuttleSnap" timeline scripts/timelines/catch-demo.json $(DEMO_DIR)/screen \
		--fps 30 --size 1100x715 --scale 2 --season winter --seed 4 --from $(DEMO_FROM) --to $(DEMO_TO) --plain true --style kawaii
	swiftc -O scripts/make-demo.swift -o $(DEMO_DIR)/make-demo
	$(DEMO_DIR)/make-demo scripts/timelines/catch-demo.json $(DEMO_DIR)/screen $(DEMO_DIR)/frames \
		--from $(DEMO_FROM) --subframes 3 --quality $(DEMO_QUALITY) --webp docs/demo-catch.webp
	img2webp $(DEMO_DIR)/frames/img2webp.args

clean:
	rm -rf .build .build-release build dist
