APP_NAME := PulseBar

.PHONY: build run demo test universal snapshot icon clean

build:
	./build.sh

run:
	swift run PulseBar

demo:
	PULSEBAR_DEMO=1 swift run PulseBar

test:
	swift test

universal:
	UNIVERSAL=1 ./build.sh

snapshot:
	swift run PulseBar --snapshot docs/images/dashboard.png

icon:
	./Scripts/make_icon.sh

clean:
	swift package clean
	rm -rf PulseBar.app .build/AppIcon.iconset
