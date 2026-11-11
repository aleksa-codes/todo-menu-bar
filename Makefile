.PHONY: check build run package icon

check:
	swift build
	swiftc -typecheck scripts/app-control.swift
	swift format lint --strict --recursive Sources scripts Package.swift
	bash -n scripts/build.sh
	plutil -lint Info.plist

build:
	bash scripts/build.sh

run:
	bash scripts/build.sh --restart

package:
	bash scripts/build.sh --package

icon:
	swift scripts/draw-icon.swift
