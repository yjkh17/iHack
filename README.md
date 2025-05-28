# iHack

A powerful macOS application for browsing, editing, and analyzing app bundle contents. Perfect for developers who need to inspect and modify macOS and iOS application bundles.

## Features

### 🔍 Application Discovery
- Scans `/Applications`, `/System/Applications`, and user Applications folder
- Displays apps in a launchpad-style grid with real app icons
- Search functionality to filter applications
- Refresh button to rescan for new applications

### 📁 File System Browser
- Tree navigator similar to Xcode's file browser
- Hierarchical folder expansion/collapse with disclosure triangles
- Alphabetical sorting (directories first, then files)
- Real Finder icons for all files and folders
- File extension display for all file types

### ✏️ Multi-File Type Support
- **Plist files**: Full property list editor with key-value editing, add/delete functionality
- **JSON files**: Syntax-highlighted editor with multiple themes
- **Text files**: Support for .txt, .md, .swift, .h, .m, .cpp, .c, .py, .js, .html, .css, .xml, .strings, .scpt
- **Icon files**: Visual viewer for .icns, .png, .jpg, etc.
- **Provisioning profiles**: Display and analysis of .provisionprofile files
- **Binary files**: Specialized handling for PkgInfo, CodeResources, and other bundle files

### 🎨 Advanced Code Editor
- **Syntax Highlighting**: Support for Swift, JSON, JavaScript, Python, C/C++, Objective-C, XML/HTML, CSS
- **Multiple Themes**: Dark, Light, Monokai, GitHub, and Xcode themes
- **Line Numbers**: Professional code editor with line numbering
- **Live Editing**: Real-time syntax highlighting as you type
- **Theme Switching**: Instant theme changes while editing

### 🔧 Plist Editor Features
- **Visual Editing**: Table-based editor similar to Xcode's plist editor
- **Add New Keys**: Interactive form to add new key-value pairs
- **Multiple Value Types**: Support for String, Number, Boolean, Array, and Dictionary types
- **Smart Input**: Type-specific input fields and validation
- **Edit/Delete**: Modify or remove existing keys with confirmation

### 💾 File Management
- **Auto Backup**: Automatic backup creation before modifications
- **Save/Restore**: Save changes and restore from backups
- **Permission Handling**: Automatic permission fixing for system files
- **Multiple Encodings**: Support for UTF-8, UTF-16, and ASCII

### 🖥️ User Interface
- **Dark Theme**: Professional dark interface throughout
- **Three Views**: App list, App browser, and File editor
- **Navigation Breadcrumbs**: Clear navigation path
- **Status Messages**: Real-time feedback for user actions
- **Xcode-Inspired**: Familiar design language for developers

## System Requirements

- macOS 12.0 or later
- Apple Silicon or Intel Mac

## Installation

1. Download the latest release from the releases page
2. Drag iHack.app to your Applications folder
3. Launch iHack from Applications or Spotlight

**Note**: On first launch, you may need to right-click and select "Open" to bypass Gatekeeper, as the app is not notarized.

## Usage

### Getting Started
1. Launch iHack
2. Browse the grid of installed applications
3. Click on any app to explore its bundle contents
4. Navigate through folders using the tree view
5. Click on files to view and edit them

### Editing Plist Files
1. Navigate to any .plist file (like Info.plist)
2. The plist editor will open automatically
3. Click "Add Key" to add new entries
4. Edit existing values by clicking "Edit"
5. Save your changes with the "Save" button

### Editing Code Files
1. Click on any supported code file (.swift, .json, .js, etc.)
2. The syntax-highlighted editor will open
3. Choose your preferred theme from the dropdown
4. Edit the file directly in the editor
5. Save changes when finished

### File Management
- All modifications create automatic backups (.backup extension)
- Use "Restore Backup" to revert changes
- The app handles file permissions automatically

## Security & Permissions

iHack requires elevated permissions to modify app bundles, especially system applications. The app:
- Disables sandboxing for full file system access
- Includes entitlements for system file modification
- Handles read-only file permissions automatically
- Creates backups before any modifications

## Technical Details

### Built With
- SwiftUI for the user interface
- AppKit for system integration
- NSWorkspace APIs for file icons and metadata
- PropertyListSerialization for plist handling
- NSRegularExpression for syntax highlighting

### Architecture
- **Models**: AppBundle, AppContentItem for data representation
- **Views**: Modular SwiftUI views for different file types
- **Syntax Highlighting**: Custom regex-based highlighter with theme support
- **File Type Detection**: UTI-based with fallback parsing

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup
1. Clone the repository
2. Open `iHack.xcodeproj` in Xcode
3. Build and run the project
4. Make your changes and test thoroughly

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by developer tools like Xcode and various hex editors
- Thanks to the Swift and macOS development community
- Built with modern SwiftUI and macOS APIs

## Disclaimer

⚠️ **Important**: iHack allows modification of application bundles, including system applications. Always create backups before making changes. Modifying system applications may affect system stability and could potentially break applications or violate software licenses. Use at your own risk.

The developers of iHack are not responsible for any damage or issues caused by modifying application bundles.

---

**Version**: 1.0  
**Compatibility**: macOS 12.0+  
**Architecture**: Universal (Apple Silicon + Intel)