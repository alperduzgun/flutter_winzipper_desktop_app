# WinZipper - Archive Manager for macOS

A powerful and user-friendly archive management application built with Flutter for macOS. WinZipper allows you to easily extract and compress various archive formats.

## Features

- **Multiple Archive Format Support**
  - ZIP - Read and Write
  - RAR - Read (requires `unrar` installed)
  - 7-Zip - Read and Write (requires `7z` installed)
  - TAR - Read and Write
  - GZIP (.gz, .tar.gz) - Read and Write
  - BZIP2 (.bz2, .tar.bz2) - Read and Write

- **Easy to Use Interface**
  - Beautiful native macOS UI with custom window design
  - Drag and drop support for archive files
  - Preview archive contents before extraction
  - Batch compression support

- **Powerful Operations**
  - Extract archives to any location
  - Compress single or multiple files
  - Compress entire directories
  - View archive contents without extraction

## Requirements

- macOS 10.14 or later
- Flutter SDK (for development)

### Optional Dependencies for Full Format Support

For RAR and 7-Zip support, install the following command-line tools:

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install unrar for RAR support
brew install unrar

# Install p7zip for 7-Zip support
brew install p7zip
```

## Installation

### For Users

1. Download the latest release from the Releases page
2. Open the DMG file
3. Drag WinZipper to your Applications folder
4. Launch WinZipper from Applications

### For Developers

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/flutter_winzipper_desktop_app.git
   cd flutter_winzipper_desktop_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d macos
   ```

4. Build for release:
   ```bash
   flutter build macos --release
   ```

## Usage

### Opening and Extracting Archives

1. Click on "Open Archive" button
2. Select an archive file (ZIP, RAR, 7Z, TAR, etc.)
3. Browse the contents in the list view
4. Click "Extract" to choose a destination folder
5. Your files will be extracted to the selected location

### Compressing Files

**Single or Multiple Files:**
1. Click "Compress Files" button
2. Select one or more files to compress
3. Enter the archive name (e.g., `myfiles.zip`)
4. Choose where to save the archive
5. Your archive will be created

**Entire Folder:**
1. Click "Compress Folder" button
2. Select a directory to compress
3. Enter the archive name
4. Choose where to save the archive
5. The entire folder structure will be preserved in the archive

## Supported Archive Types

| Format | Extension | Extract | Create | Notes |
|--------|-----------|---------|--------|-------|
| ZIP    | .zip      | ✅      | ✅     | Native support |
| TAR    | .tar      | ✅      | ✅     | Native support |
| GZIP   | .gz, .tar.gz | ✅   | ✅     | Native support |
| BZIP2  | .bz2, .tar.bz2 | ✅ | ✅     | Native support |
| RAR    | .rar      | ✅      | ✅     | Requires `unrar` |
| 7-Zip  | .7z       | ✅      | ✅     | Requires `7z` |

## Architecture

The application is built using:
- **Flutter**: Cross-platform UI framework
- **Archive Package**: Native Dart library for ZIP, TAR, GZIP, BZIP2
- **File Picker**: macOS file selection dialogs
- **Platform Channels**: Integration with system tools for RAR and 7-Zip

## Development

### Project Structure

```
lib/
├── main.dart                 # Application entry point
├── screens/
│   └── home_screen.dart      # Main UI screen
├── services/
│   └── archive_service.dart  # Archive operations service
└── common/
    └── theme/
        └── theme.dart        # Theme configuration
```

### Key Components

- **ArchiveService**: Handles all archive operations (extract, compress, list)
- **HomeScreen**: Main user interface with file selection and operations
- **Custom Window**: Native-looking macOS window with custom title bar

## Troubleshooting

### "Command not found: unrar" or "Command not found: 7z"

Install the required tools using Homebrew:
```bash
brew install unrar p7zip
```

### Permission Denied Errors

The app requests file system access through macOS entitlements. Make sure to grant permission when prompted.

### Archive Won't Open

Ensure the file is a valid archive and not corrupted. Try opening it with another tool to verify.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is open source and available under the MIT License.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Archive handling powered by [archive](https://pub.dev/packages/archive)
- UI components from [bitsdojo_window](https://pub.dev/packages/bitsdojo_window)
- File selection via [file_picker](https://pub.dev/packages/file_picker)

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.
