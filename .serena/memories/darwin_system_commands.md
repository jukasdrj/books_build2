# Darwin System Commands & Utilities

## Core Darwin/macOS Commands
### File System Operations
- `ls -la` - List files with details (supports color output)
- `cd` - Change directory  
- `pwd` - Print working directory
- `find . -name "*.swift"` - Find Swift files recursively
- `grep -r "pattern" .` - Search for patterns in files

### Git Operations  
- `git status` - Show working tree status
- `git diff` - Show changes
- `git log --oneline` - Compact commit history
- `git branch` - List branches
- `git add .` - Stage all changes

### Xcode Command Line Tools
- `xcodebuild -list` - List project schemes and configurations
- `xcodebuild -scheme books build` - Build from command line
- `xcodebuild test -scheme books` - Run tests from command line
- `xcrun simctl list` - List available simulators

### Darwin-Specific Considerations
- **Case Sensitivity**: macOS filesystem is typically case-insensitive
- **Hidden Files**: Files starting with `.` are hidden (use `ls -a`)
- **Permissions**: Use `chmod` and `chown` for file permissions
- **Spotlight**: `mdfind "search term"` for system-wide file search

### Development Workflow Commands
- `open books.xcodeproj` - Open Xcode project from terminal
- `open .` - Open current directory in Finder
- `pbcopy < file.txt` - Copy file contents to clipboard (Darwin-specific)
- `pbpaste > file.txt` - Paste clipboard to file (Darwin-specific)

### Useful Darwin Tools
- `system_profiler SPHardwareDataType` - System information
- `top` - Process monitor
- `ps aux` - List all processes
- `lsof -i :8080` - List processes using specific port

## Project-Specific Commands
### CSV Testing
```bash
cd test_csv_files
swift test_csv_import.swift
```

### Simulator Management
```bash
xcrun simctl boot "iPhone 16"
xcrun simctl shutdown all
```

### Build Cleanup
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/
```