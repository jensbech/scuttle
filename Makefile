APP := Scuttle.app
PREFIX ?= /Applications

.PHONY: build install uninstall test clean

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

clean:
	rm -rf .build .build-release build dist
