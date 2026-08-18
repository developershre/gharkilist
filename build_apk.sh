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
echo "Building APK for $DEFAULT_NAME"
echo "Target Name:    $APK_NAME"
echo "Target Version: $APK_VERSION"
echo "==========================================="

# Export variables for Gradle
export APK_NAME
export APK_VERSION

# Run flutter build
flutter build apk

# Find and copy output to root project directory
echo "Locating built APK file..."
BUILT_APK=$(find build/app/outputs/apk/ -name "$APK_NAME-v$APK_VERSION*.apk" | head -n 1)

if [ -f "$BUILT_APK" ]; then
    DEST_APK="./output/$(basename "$BUILT_APK")"
    cp "$BUILT_APK" "$DEST_APK"
    echo "-------------------------------------------"
    echo "Success! APK copied to project root:"
    echo "👉 $(pwd)/$DEST_APK"
    echo "-------------------------------------------"
else
    echo "Error: Could not locate the generated APK."
    echo "Please check the build logs above."
    exit 1
fi
