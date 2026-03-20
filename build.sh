#!/bin/bash
set -e

APP_NAME="DuckBar"
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
RELEASES_DIR=".build/releases"

echo "=== DuckBar Build ==="

# 1. Build Swift Package
echo "[1/4] Compiling..."
if [[ "$1" == "--release" ]]; then
    # Release: Universal Binary (arm64 + x86_64)
    swift build -c release --arch arm64 --arch x86_64 2>&1
else
    # Development: native architecture only
    swift build -c release 2>&1
fi

# 2. Create app bundle structure
echo "[2/4] Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
if [[ "$1" == "--release" ]]; then
    cp .build/apple/Products/Release/DuckBar "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
else
    cp .build/release/DuckBar "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
fi

# Copy Info.plist
cp Resources/Info.plist "$APP_BUNDLE/Contents/"

# Copy icon
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/"

# Copy Sparkle.framework
mkdir -p "$APP_BUNDLE/Contents/Frameworks"
ARCH=$(uname -m)
[[ "$ARCH" == "x86_64" ]] && TRIPLE="x86_64-apple-macosx" || TRIPLE="arm64-apple-macosx"
cp -R ".build/${TRIPLE}/release/Sparkle.framework" "$APP_BUNDLE/Contents/Frameworks/"

# Add rpath for Sparkle.framework
install_name_tool -add_rpath "@loader_path/../Frameworks" "$APP_BUNDLE/Contents/MacOS/$APP_NAME" 2>/dev/null || true

# 3. Code sign
echo "[3/4] Signing..."
if [[ "$1" == "--release" ]]; then
    # Release: sign with Developer ID (required for notarization)
    codesign --force --deep --options runtime \
        --sign "Developer ID Application: TakeOut Co., Ltd. (7P9CL644X3)" \
        "$APP_BUNDLE"
else
    # Development: ad-hoc signing
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

# 4. Package release (only when --release flag is provided)
if [[ "$1" == "--release" ]]; then
    VERSION=$(defaults read "$(pwd)/$APP_BUNDLE/Contents/Info.plist" CFBundleShortVersionString)
    echo "[4/4] Packaging & Notarizing release v$VERSION..."

    mkdir -p "$RELEASES_DIR"
    ZIP_PATH="$RELEASES_DIR/${APP_NAME}-${VERSION}.zip"

    # Create zip preserving symlinks
    ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

    # Submit for notarization
    echo "Notarizing..."
    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "duckbar-notary" \
        --wait

    # Staple notarization ticket
    echo "Stapling..."
    xcrun stapler staple "$APP_BUNDLE"

    # Repackage with stapled ticket
    ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

    # Generate appcast
    SPARKLE_BIN=$(find .build/artifacts/sparkle -name "generate_appcast" 2>/dev/null | head -1)
    if [[ -n "$SPARKLE_BIN" ]]; then
        "$SPARKLE_BIN" "$RELEASES_DIR"
        echo "appcast.xml generated: $RELEASES_DIR/appcast.xml"
    else
        echo "generate_appcast not found. Run manually:"
        echo "  <sparkle_bin>/generate_appcast $RELEASES_DIR"
    fi

    echo ""
    echo "Release file: $ZIP_PATH"
    echo "Next steps:"
    echo "  1. Upload $RELEASES_DIR/appcast.xml to GitHub Pages"
    echo "  2. Upload $ZIP_PATH to GitHub Releases (tag: v$VERSION)"
else
    echo "[4/4] Skipped (use --release flag for release packaging)"
fi

echo ""
echo "=== Build Complete ==="
echo "App: $APP_BUNDLE"
echo ""
echo "Run: open $APP_BUNDLE"
echo "Install: cp -r $APP_BUNDLE /Applications/"
