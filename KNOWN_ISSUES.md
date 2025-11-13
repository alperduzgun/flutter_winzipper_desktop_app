# Known Issues and Compatibility

This document lists known issues discovered through chaos engineering research and community reports for WinZipper on macOS.

## ✅ RESOLVED Issues (Already Fixed)

### 1. ~~macos_window_utils Ventura/Sonoma Incompatibility~~ ✅ FIXED
**Issue**: Version 1.0.0 had compatibility issues with macOS Ventura and Sonoma.
- **Error**: `value of type 'NSToolbar' has no member 'allowsDisplayModeCustomization'`
- **Cause**: Missing compile-time checks for macOS version-specific APIs
- **Fix**: Updated to version 1.8.1+ in pubspec.yaml (Jan 2025)
- **Status**: ✅ Resolved

### 2. ~~Missing macos_window_utils Package~~ ✅ FIXED
**Issue**: MainFlutterWindow.swift imports macos_window_utils but package was missing
- **Symptom**: Build failure with "No such module 'macos_window_utils'"
- **Fix**: Added macos_window_utils: ^1.8.1 to dependencies
- **Status**: ✅ Resolved

### 3. ~~Sandbox Prevents Process.run~~ ✅ FIXED
**Issue**: macOS sandbox blocked external process execution (7z, unrar)
- **Symptom**: RAR and 7-Zip operations fail 100% of the time
- **Fix**: Disabled sandbox in entitlements (not suitable for App Store)
- **Security**: Path traversal, archive bomb, timeouts still active
- **Status**: ✅ Resolved

### 4. ~~Window Initialization Race Condition~~ ✅ FIXED
**Issue**: Blank screen or crash due to initialization order
- **Fix**: Reordered Window.initialize() before doWhenWindowReady()
- **Fix**: Added try-catch for graceful degradation
- **Status**: ✅ Resolved

### 5. ~~Podfile Deployment Target Mismatch~~ ✅ FIXED
**Issue**: Platform version 10.14.6 in Podfile but 10.14 in build settings
- **Symptom**: CocoaPods warnings, potential build failures
- **Fix**: Standardized to 10.14.6 everywhere
- **Status**: ✅ Resolved

### 6. ~~Archive Package Memory Issues~~ ✅ MITIGATED
**Issue**: Dart archive package had memory problems with large files
- **Fix**: Updated to archive 3.6.1 (improved memory handling)
- **Fix**: Added 2GB file size limit
- **Status**: ✅ Mitigated with safeguards

---

## ⚠️ ACTIVE Issues (Workarounds Available)

### 1. bitsdojo_window Package Maintenance Status
**Issue**: bitsdojo_window v0.1.5 is from 2022, not actively maintained
- **Impact**: May have compatibility issues with future Flutter/macOS versions
- **Community**: Many users have switched to forks or alternative packages
- **Current Status**: Works but may break with Flutter 3.20+
- **Workaround**:
  - Current version works on Flutter 3.10-3.19
  - If issues arise, can override with fork: `bitsdojo/bitsdojo_window#main`
  - Alternative: Use window_manager package instead
- **Action Required**: None currently, monitor for Flutter upgrades

### 2. CocoaPods Installation on M1/M2 Macs
**Issue**: CocoaPods may not work properly on Apple Silicon
- **Symptoms**:
  - "pod install" fails with FFI errors
  - Ruby version incompatibilities
  - Architecture mismatch (arm64 vs x86_64)
- **Workarounds**:
  ```bash
  # Method 1: Force x86_64 architecture (Rosetta 2)
  sudo arch -x86_64 gem install cocoapods
  sudo arch -x86_64 gem install ffi
  cd macos && arch -x86_64 pod install

  # Method 2: Update Ruby to 2.6+
  brew install ruby
  # Restart terminal
  sudo gem install cocoapods

  # Method 3: Use Rosetta Terminal
  # Duplicate Terminal.app, enable "Open using Rosetta"
  # Install CocoaPods in that terminal
  ```
- **Pre-flight Check**: Run `make check` to detect this issue
- **Status**: Known limitation, workarounds available

### 3. Large Archive Memory Consumption
**Issue**: Processing very large archives (>1GB) uses significant memory
- **Cause**: Dart archive package loads data into memory
- **Mitigation**: 2GB file size limit enforced
- **Workaround**: For 2GB+ files, use command-line tools directly
- **Recommendation**: Close other apps when processing large archives
- **Status**: Acceptable tradeoff for security (prevents zip bombs)

---

## 📋 KNOWN LIMITATIONS

### 1. App Store Distribution Not Supported
**Limitation**: Cannot be distributed through Mac App Store
- **Reason**: Sandbox is disabled to allow Process.run()
- **Alternative**: Direct download, Homebrew, or enterprise distribution
- **Status**: By design

### 2. System Tools Required for RAR/7-Zip
**Limitation**: RAR and 7-Zip require external tools (unrar, 7z, rar)
- **Reason**: Proprietary formats without native Dart libraries
- **Workaround**: ZIP, TAR, GZIP, BZIP2 work without external tools
- **Installation**: `brew install unrar p7zip rar`
- **Detection**: Pre-flight script checks for missing tools
- **Status**: By design

### 3. macOS 10.14+ Required
**Limitation**: Does not support macOS versions older than Mojave (10.14)
- **Reason**:
  - flutter_acrylic requires 10.14+
  - bitsdojo_window requires 10.14+
  - Modern NSToolbar APIs
- **Status**: Acceptable (10.14 released in 2018)

### 4. Archive Size Limits (Security Feature)
**Limitation**: Maximum 2GB archive size, 10GB extraction limit
- **Reason**: Prevents zip bombs and memory exhaustion
- **Override**: Edit `lib/common/constants.dart` to increase limits
- **Risk**: Increasing limits may expose system to DoS attacks
- **Status**: Intentional security measure

---

## 🐛 UPSTREAM ISSUES (Not Our Bugs)

### 1. Flutter macOS Sandbox Support Limited
**Issue**: Flutter's Process.run() doesn't work in macOS sandbox
- **Source**: Flutter framework limitation
- **Tracking**: flutter/flutter#122796
- **Workaround**: Disable sandbox (what we do)
- **Future**: May be resolved in future Flutter versions
- **Status**: Waiting on Flutter team

### 2. bitsdojo_window Deprecated APIs
**Issue**: Package uses deprecated macOS APIs (targeting 10.14)
- **Symptom**: Xcode build warnings about deprecated methods
- **Impact**: None currently, may break in future macOS versions
- **Severity**: Low (warnings only, still functions)
- **Status**: Monitor for macOS updates

---

## 🔮 POTENTIAL FUTURE ISSUES

### 1. macOS 15 (Sequoia) Compatibility - UNKNOWN
**Status**: Not yet tested
- Flutter on Sequoia has reported issues with Xcode 16
- bitsdojo_window may have problems (not actively maintained)
- **Recommendation**: Wait for community reports before upgrading to Sequoia

### 2. Flutter 3.20+ Compatibility - UNKNOWN
**Status**: Not yet tested
- bitsdojo_window v0.1.5 may have breaking changes
- Archive package may have API changes
- **Recommendation**: Test in staging before upgrading Flutter

---

## 📊 Testing Matrix

### Tested and Working Configurations

| macOS Version | Flutter Version | Status | Notes |
|---------------|----------------|--------|-------|
| 13.x Ventura  | 3.10-3.19      | ✅ Works | After version updates |
| 14.x Sonoma   | 3.10-3.19      | ✅ Works | After version updates |
| 12.x Monterey | 3.10-3.19      | ✅ Expected | Not formally tested |
| 15.x Sequoia  | Any            | ❓ Unknown | Not tested |

### Known Broken Configurations

| macOS Version | Flutter Version | Status | Issue |
|---------------|----------------|--------|-------|
| < 10.14       | Any            | ❌ Broken | Minimum version not met |
| Any           | < 3.0          | ❌ Broken | Dart SDK incompatibility |

---

## 🆘 Getting Help

If you encounter an issue not listed here:

1. **Run pre-flight check**: `make check`
2. **Check verbose logs**: `flutter run -v`
3. **Search existing issues**: Check GitHub issues
4. **File a bug report** with:
   - Pre-flight check output
   - macOS version (`sw_vers -productVersion`)
   - Flutter version (`flutter --version`)
   - Full error message and stack trace
   - Steps to reproduce

---

## 📚 References

Research sources for these issues:

- Flutter GitHub Issues: https://github.com/flutter/flutter/issues
- bitsdojo_window Issues: https://github.com/bitsdojo/bitsdojo_window/issues
- macos_window_utils: https://pub.dev/packages/macos_window_utils/changelog
- Dart archive package: https://pub.dev/packages/archive/changelog
- CocoaPods M1 Issues: Multiple Stack Overflow threads
- macOS Sandbox Documentation: Apple Developer Docs

---

**Last Updated**: January 2025
**Version**: WinZipper 0.1.0
