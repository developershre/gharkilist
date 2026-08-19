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
flutter build apk --split-per-abi

# Find and copy output to output directory
echo "Locating built APK files..."
mkdir -p ./output

ARM64_APK=$(find build/app/outputs/apk/ -name "*arm64-v8a.apk" | head -n 1)
ARM32_APK=$(find build/app/outputs/apk/ -name "*armeabi-v7a.apk" | head -n 1)
X86_APK=$(find build/app/outputs/apk/ -name "*x86_64.apk" | head -n 1)

if [ -f "$ARM64_APK" ] || [ -f "$ARM32_APK" ] || [ -f "$X86_APK" ]; then
    echo "-------------------------------------------"
    echo "Success! Split APKs copied to output folder:"
    
    if [ -f "$ARM64_APK" ]; then
        cp "$ARM64_APK" "./output/${APK_NAME}-v${APK_VERSION}-Modern_Phones-64bit.apk"
        echo "👉 Modern Phones (64-bit ARM): ./output/${APK_NAME}-v${APK_VERSION}-Modern_Phones-64bit.apk"
    fi
    if [ -f "$ARM32_APK" ]; then
        cp "$ARM32_APK" "./output/${APK_NAME}-v${APK_VERSION}-Older_Phones-32bit.apk"
        echo "👉 Older Phones (32-bit ARM):  ./output/${APK_NAME}-v${APK_VERSION}-Older_Phones-32bit.apk"
    fi
    if [ -f "$X86_APK" ]; then
        cp "$X86_APK" "./output/${APK_NAME}-v${APK_VERSION}-PC_Emulators-x86_64.apk"
        echo "👉 PC Emulators / ChromeOS:    ./output/${APK_NAME}-v${APK_VERSION}-PC_Emulators-x86_64.apk"
    fi
    echo "-------------------------------------------"
    echo "💡 HELP: WHICH APK SHOULD I INSTALL?"
    echo "• If your phone is modern (bought in the last 6-8 years), install the 'Modern_Phones-64bit.apk'."
    echo "• If it is an older or budget device, install the 'Older_Phones-32bit.apk'."
    echo "• If you are running on an emulator on your PC, install the 'PC_Emulators-x86_64.apk'."
    echo "-------------------------------------------"
else
    echo "Error: Could not locate the generated APKs."
    echo "Please check the build logs above."
    exit 1
fi
