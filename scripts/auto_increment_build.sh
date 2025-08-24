#!/bin/bash

# Auto-increment build number script for Xcode
# Add this as a "Run Script" phase in your Xcode target

# Get the current build number
CURRENT_BUILD=$(agvtool what-version -terse)

# Increment it
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update the build number
agvtool new-version -all $NEW_BUILD

echo "✅ Auto-incremented build number from $CURRENT_BUILD to $NEW_BUILD"

# Optional: Update version based on branch or tag
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
    # Only increment version on main branch
    CURRENT_VERSION=$(agvtool what-marketing-version -terse1)
    echo "📦 Current marketing version: $CURRENT_VERSION"
    
    # Uncomment to auto-increment marketing version
    # NEW_VERSION=$(echo $CURRENT_VERSION | awk -F. '{$NF = $NF + 0.1; print}' | sed 's/\./ /g' | xargs printf "%.1f")
    # agvtool new-marketing-version $NEW_VERSION
fi