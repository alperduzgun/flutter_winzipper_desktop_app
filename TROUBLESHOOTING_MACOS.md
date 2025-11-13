# macOS Troubleshooting Guide

This guide covers common issues when running WinZipper on macOS and their solutions.

## Before Running

### 1. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install CocoaPods dependencies
cd macos
pod install
cd ..
```

### 2. Install System Tools (Optional but Recommended)

For full RAR and 7-Zip support:

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install archive tools
brew install unrar p7zip
```

## Common Runtime Issues

### Issue: "Command not found: unrar" or "7z"

**Symptom**: RAR and 7-Zip archives fail to extract or compress.

**Solution**:
```bash
brew install unrar p7zip
```

**Workaround**: Use only ZIP, TAR, GZIP, or BZIP2 formats (native support, no tools needed).

---

### Issue: App Won't Launch - "MainFlutterWindow" Error

**Symptom**: App crashes on startup with Swift/Cocoa errors.

**Solution**:
```bash
# Clean build
flutter clean
cd macos
pod install
cd ..

# Rebuild
flutter build macos --debug
```

---

### Issue: Blank Window or Window Doesn't Appear

**Symptom**: App launches but shows no window or blank screen.

**Cause**: Window initialization race condition or acrylic effect compatibility issue.

**Solution**: The app now handles this gracefully. If you see warnings in console like:
```
Warning: Window.initialize failed: ...
```
This is expected on some macOS versions - the app will continue without visual effects.

**Manual Fix** (if needed):
Edit `lib/main.dart` and comment out flutter_acrylic:
```dart
// try {
//   await Window.initialize();
// } catch (e) {
//   print('Warning: Window.initialize failed: $e');
// }
```

---

### Issue: Permission Denied When Extracting Archives

**Symptom**: "Permission denied" errors when extracting to certain folders.

**Cause**: macOS Gatekeeper or file system permissions.

**Solution**:
1. Extract to your Downloads folder or Desktop (full access)
2. If extracting to other locations, grant Full Disk Access:
   - System Preferences → Privacy & Security → Full Disk Access
   - Add WinZipper to the list

---

### Issue: "Archive Too Large" Error for Small Files

**Symptom**: 2GB+ archives cannot be processed.

**Cause**: Memory protection (prevents zip bombs and memory exhaustion).

**This is intentional** - for files over 2GB:
1. Use command-line tools directly: `unrar x large.rar`
2. Or modify `lib/common/constants.dart`:
   ```dart
   static const int maxArchiveSizeBytes = 5 * 1024 * 1024 * 1024; // 5GB
   ```

---

### Issue: Build Fails with "Sandbox" Errors

**Symptom**: Build errors mentioning sandbox restrictions or Process.run.

**Solution**: This has been fixed. Sandbox is disabled in entitlements to allow system tool execution (7z, unrar).

**Note**: This app is for local use only - **not suitable for App Store submission** due to sandbox being disabled.

---

### Issue: Process Timeout During Large Archive Operations

**Symptom**: "Process timeout" errors on very large archives.

**Solution**: Increase timeout in `lib/common/constants.dart`:
```dart
static const Duration extractTimeout = Duration(minutes: 10); // was 5
static const Duration compressTimeout = Duration(minutes: 20); // was 10
```

---

### Issue: Zombie Processes After Crashes

**Symptom**: `7z` or `unrar` processes still running after app crash.

**Solution**:
```bash
# Kill zombie processes
pkill -9 7z
pkill -9 unrar
```

---

## Development Issues

### Issue: "macos_window_utils not found"

**Symptom**: Build fails with "No such module 'macos_window_utils'".

**Solution**: Already fixed in pubspec.yaml. If you still see this:
```bash
flutter pub get
cd macos && pod install && cd ..
flutter clean
flutter build macos
```

---

### Issue: Xcode Build Warnings

**Symptom**: Deprecation warnings during build.

**Common Warnings**:
- `bitsdojo_window` uses deprecated APIs (macOS 10.14 targeting)
- This is expected and safe to ignore
- App still works on modern macOS (tested up to Sonoma)

---

## Performance Tips

### For Large Archives (500MB+)

1. **Close other apps** - archive operations use significant memory
2. **Use SSD storage** - extraction is I/O intensive
3. **Monitor Activity Monitor** - watch for memory pressure
4. **Extract to local disk** - avoid network drives

### For Many Small Files (10k+ files)

1. **Expect slower performance** - archive bomb protection checks each file
2. **Use ZIP over 7z** - faster for many small files
3. **Archive contents preview may be slow** - this is intentional (security)

---

## Security Notes

### Why is Sandbox Disabled?

**Reason**: macOS sandbox prevents `Process.run()`, which is required for:
- `unrar` - RAR extraction
- `7z` - 7-Zip operations
- `rar` - RAR compression

**Security Measures Still Active**:
- ✅ Path traversal protection (Zip Slip)
- ✅ Archive bomb protection (file count/size limits)
- ✅ File size limits (prevents memory exhaustion)
- ✅ Disk space validation
- ✅ Process timeouts

**Not Recommended For**:
- ❌ App Store distribution
- ❌ Processing untrusted archives from internet (use with caution)

**Safe For**:
- ✅ Local development and personal use
- ✅ Processing your own archives
- ✅ Enterprise/internal distribution

---

## Getting Help

If you encounter issues not covered here:

1. Check console output: `flutter run -v`
2. Check macOS Console app for crash logs
3. File an issue on GitHub with:
   - macOS version (e.g., Sonoma 14.2)
   - Flutter version (`flutter --version`)
   - Error message and stack trace
   - Steps to reproduce

---

## Quick Reference

### Supported Formats
| Format | Extract | Create | Requires Tool |
|--------|---------|--------|---------------|
| ZIP    | ✅      | ✅     | No (native)   |
| TAR    | ✅      | ✅     | No (native)   |
| GZIP   | ✅      | ✅     | No (native)   |
| BZIP2  | ✅      | ✅     | No (native)   |
| RAR    | ✅      | ✅     | Yes (unrar/rar) |
| 7-Zip  | ✅      | ✅     | Yes (7z)      |

### System Requirements
- macOS 10.14 (Mojave) or later
- 4GB+ RAM recommended for large archives
- Homebrew (optional, for RAR/7z support)

### Build Commands
```bash
# Development
flutter run -d macos

# Release Build
flutter build macos --release

# Output Location
# build/macos/Build/Products/Release/winzipper.app
```
