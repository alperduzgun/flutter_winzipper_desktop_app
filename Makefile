.PHONY: help run build clean test format lint deps

# Default target
help:
	@echo "WinZipper - Makefile Commands"
	@echo "=============================="
	@echo "make run       - Run app on macOS"
	@echo "make build     - Build release for macOS"
	@echo "make test      - Run all tests"
	@echo "make format    - Format Dart code"
	@echo "make lint      - Run linter"
	@echo "make clean     - Clean build artifacts"
	@echo "make deps      - Get dependencies"

# Run the app
run:
	flutter run -d macos

# Build release
build:
	flutter build macos --release
	@echo "Build complete: build/macos/Build/Products/Release/winzipper.app"

# Run tests
test:
	flutter test

# Format code
format:
	dart format lib/ test/

# Lint code
lint:
	flutter analyze

# Get dependencies
deps:
	flutter pub get

# Clean build artifacts
clean:
	flutter clean
	rm -rf build/
