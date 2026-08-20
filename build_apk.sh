#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

# Default values parsed from pubspec.yaml
DEFAULT_NAME=$(grep '^name:' pubspec.yaml | head -n 1 | awk '{print $2}' | tr -d '"'\''')
DEFAULT_VERSION=$(grep '^version:' pubspec.yaml | head -n 1 | awk '{print $2}' | tr -d '"'\''')

APK_NAME=$DEFAULT_NAME
APK_VERSION=$DEFAULT_VERSION

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -n, --name <name>       Specify the output APK name (default: $DEFAULT_NAME)"
    echo "  -v, --version <version> Specify the output APK version (default: $DEFAULT_VERSION)"
    echo "  -h, --help              Show this help message"
    echo ""
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--name) APK_NAME="$2"; shift ;;
        -v|--version) APK_VERSION="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

echo "==========================================="
echo "Building Universal APK for $DEFAULT_NAME"
echo "Target Name:    $APK_NAME"
echo "Target Version: $APK_VERSION"
echo "==========================================="

# Export variables for Gradle
export APK_NAME
export APK_VERSION

# Run flutter build
flutter build apk

# Locate the newly built APK file
echo "Locating built APK file..."
mkdir -p ./output
GRADLE_APK="build/app/outputs/apk/release/${APK_NAME}-v${APK_VERSION}.apk"
FLUTTER_APK="build/app/outputs/flutter-apk/app-release.apk"
STANDARD_GRADLE_APK="build/app/outputs/apk/release/app-release.apk"

if [ -f "$GRADLE_APK" ]; then
    UNIVERSAL_APK="$GRADLE_APK"
elif [ -f "$FLUTTER_APK" ]; then
    UNIVERSAL_APK="$FLUTTER_APK"
elif [ -f "$STANDARD_GRADLE_APK" ]; then
    UNIVERSAL_APK="$STANDARD_GRADLE_APK"
else
    # Fallback to the most recently modified APK in the build output directory
    UNIVERSAL_APK=$(find build/app/outputs/ -name "*.apk" -type f -exec stat -c "%Y %n" {} + 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)
fi

if [ -f "$UNIVERSAL_APK" ]; then
    FINAL_APK="./output/${APK_NAME}-v${APK_VERSION}.apk"
    cp "$UNIVERSAL_APK" "$FINAL_APK"

    echo "-------------------------------------------"
    echo "Success! Universal APK ready:"
    echo "👉 $FINAL_APK"
    echo "   Size: $(du -h "$FINAL_APK" | cut -f1)"
    echo "-------------------------------------------"
    echo "💡 You can share this single APK file with anyone."
    echo "   It works on all phones (ARM64, ARM32, x86_64)."
    echo ""
    echo "⚠️  NOTE: If you previously had a split-ABI version"
    echo "   installed, you MUST uninstall it first before"
    echo "   installing this universal APK."
    echo "-------------------------------------------"
else
    echo "Error: Could not locate the generated Universal APK."
    echo "Please check the build logs above."
    exit 1
fi
