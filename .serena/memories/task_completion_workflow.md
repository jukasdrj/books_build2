# Task Completion Workflow

## When a Development Task is Completed

### 1. Code Quality Checks
Since this is a pure SwiftUI/SwiftData project with no external linting tools:
- **Xcode Build**: Ensure project builds without warnings (⌘+B)
- **Xcode Analyze**: Run static analyzer (Product → Analyze)
- **Manual Code Review**: Check for Material Design 3 compliance, proper spacing usage

### 2. Testing Requirements
**Unit Tests**: Run `booksTests` target (⌘+U)
- Model tests for SwiftData operations
- Service tests for API integration and import workflows
- Utility tests for CSV parsing and duplicate detection

**UI Tests**: Run `booksUITests` target  
- Navigation flow testing
- Theme switching validation
- Critical user workflow verification

### 3. Build Verification
- **Debug Build**: Verify app runs on simulator
- **Release Build**: Test release configuration builds successfully
- **Device Testing**: Test on physical device when possible

### 4. Documentation Updates
- Update `CLAUDE.md` if architecture changes
- Update relevant memory files if patterns change
- No automatic documentation generation - manual updates only

### 5. Git Workflow (When Ready)
- Review changes with `git diff`
- Stage files with `git add`
- Commit with descriptive message
- **DO NOT PUSH** unless explicitly requested by user

## No External Tooling
This project intentionally has no:
- Linting tools (SwiftLint, etc.)
- Code formatters
- Package managers (CocoaPods, SPM dependencies)
- CI/CD pipelines
- External build scripts

All quality assurance relies on Xcode's built-in tools and manual verification.

## Quality Gates
- ✅ Builds without warnings
- ✅ Unit tests pass
- ✅ UI tests pass for modified workflows
- ✅ Material Design 3 compliance maintained
- ✅ Theme system works across all changed views
- ✅ SwiftData migration compatibility preserved