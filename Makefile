.PHONY: help check run build clean test format lint deps setup pod-install

# Default target
help:
	@echo "WinZipper - Makefile Commands"
	@echo "=============================="
	@echo "make check       - Pre-flight check for common issues"
	@echo "make setup       - First-time setup (deps + pods)"
	@echo "make run         - Run app on macOS"
	@echo "make build       - Build release for macOS"
	@echo "make test        - Run all tests"
	@echo "make format      - Format Dart code"
	@echo "make lint        - Run linter"
	@echo "make clean       - Clean build artifacts"
	@echo "make deps        - Get Flutter dependencies"
	@echo "make pod-install - Install CocoaPods dependencies"

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

# Pre-flight check
check:
	@./scripts/preflight_check.sh

# First-time setup
setup: deps pod-install
	@echo ""
	@echo "✓ Setup complete! Run 'make check' to verify installation."

# Get dependencies
deps:
	flutter pub get

# Install CocoaPods dependencies
pod-install:
	cd macos && pod install && cd ..

# Clean build artifacts
clean:
	flutter clean
	rm -rf build/
	cd macos && rm -rf Pods Podfile.lock && cd ..
