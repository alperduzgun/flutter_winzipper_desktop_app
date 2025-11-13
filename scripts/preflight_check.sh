#!/bin/bash

# WinZipper macOS Pre-flight Check Script
# This script checks for common issues before running the app

set -e

echo "🔍 WinZipper Pre-flight Check"
echo "=============================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

WARNINGS=0
ERRORS=0

# Check 1: Flutter installation
echo "1. Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓${NC} Flutter found: $FLUTTER_VERSION"
else
    echo -e "${RED}✗${NC} Flutter not found in PATH"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: CocoaPods installation
echo "2. Checking CocoaPods installation..."
if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    echo -e "${GREEN}✓${NC} CocoaPods found: $POD_VERSION"

    # Check for M1/M2 compatibility
    if [[ $(uname -m) == "arm64" ]]; then
        echo -e "${YELLOW}ℹ${NC}  Running on Apple Silicon (M1/M2)"
        echo "   If pod install fails, try: arch -x86_64 pod install"
    fi
else
    echo -e "${RED}✗${NC} CocoaPods not found"
    echo "   Install with: sudo gem install cocoapods"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Optional system tools (unrar, 7z)
echo "3. Checking optional archive tools..."
TOOL_MISSING=0

if command -v unrar &> /dev/null; then
    echo -e "${GREEN}✓${NC} unrar found (RAR extraction supported)"
else
    echo -e "${YELLOW}⚠${NC} unrar not found (RAR extraction will fail)"
    echo "   Install with: brew install unrar"
    WARNINGS=$((WARNINGS + 1))
    TOOL_MISSING=1
fi

if command -v 7z &> /dev/null; then
    echo -e "${GREEN}✓${NC} 7z found (7-Zip supported)"
else
    echo -e "${YELLOW}⚠${NC} 7z not found (7-Zip will fail)"
    echo "   Install with: brew install p7zip"
    WARNINGS=$((WARNINGS + 1))
    TOOL_MISSING=1
fi

if command -v rar &> /dev/null; then
    echo -e "${GREEN}✓${NC} rar found (RAR compression supported)"
else
    echo -e "${YELLOW}⚠${NC} rar not found (RAR compression will fail)"
    echo "   Install with: brew install rar"
    WARNINGS=$((WARNINGS + 1))
fi

if [ $TOOL_MISSING -eq 1 ]; then
    echo ""
    echo "   Note: ZIP, TAR, GZIP, BZIP2 work without these tools (native support)"
fi
echo ""

# Check 4: Xcode Command Line Tools
echo "4. Checking Xcode Command Line Tools..."
if xcode-select -p &> /dev/null; then
    XCODE_PATH=$(xcode-select -p)
    echo -e "${GREEN}✓${NC} Xcode CLI tools found: $XCODE_PATH"
else
    echo -e "${RED}✗${NC} Xcode Command Line Tools not found"
    echo "   Install with: xcode-select --install"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 5: Flutter dependencies
echo "5. Checking Flutter dependencies..."
if [ -f "pubspec.yaml" ]; then
    if [ -d ".dart_tool" ]; then
        echo -e "${GREEN}✓${NC} Flutter dependencies appear to be installed"
    else
        echo -e "${YELLOW}⚠${NC} Flutter dependencies may not be installed"
        echo "   Run: flutter pub get"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}✗${NC} Not in a Flutter project directory"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 6: CocoaPods dependencies
echo "6. Checking CocoaPods dependencies..."
if [ -d "macos/Pods" ]; then
    echo -e "${GREEN}✓${NC} CocoaPods dependencies installed"
else
    echo -e "${YELLOW}⚠${NC} CocoaPods dependencies may not be installed"
    echo "   Run: cd macos && pod install && cd .."
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 7: macOS version
echo "7. Checking macOS version..."
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
MACOS_MINOR=$(echo $MACOS_VERSION | cut -d. -f2)

echo "   macOS version: $MACOS_VERSION"
if [ "$MACOS_MAJOR" -ge 10 ] && [ "$MACOS_MINOR" -ge 14 ]; then
    echo -e "${GREEN}✓${NC} macOS version is compatible (requires 10.14+)"
else
    echo -e "${RED}✗${NC} macOS version too old (requires 10.14 Mojave or later)"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 8: Disk space
echo "8. Checking available disk space..."
AVAILABLE_GB=$(df -H / | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$AVAILABLE_GB > 5" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Sufficient disk space (${AVAILABLE_GB}GB available)"
else
    echo -e "${YELLOW}⚠${NC} Low disk space (${AVAILABLE_GB}GB available)"
    echo "   Recommend at least 5GB free for archive operations"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo "=============================="
echo "Summary:"
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You can now run:"
    echo "  flutter run -d macos"
    echo ""
    echo "Or build for release:"
    echo "  flutter build macos --release"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "The app will run, but some features may not work."
    echo "See warnings above for installation instructions."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Please fix the errors above before running the app."
    exit 1
fi
