#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset
IFS=$'\t\n'

FX_ARM="https://download2.gluonhq.com/openjfx/17.0.10/openjfx-17.0.10_osx-aarch64_bin-jmods.zip"
FX_X64=https://download2.gluonhq.com/openjfx/17.0.10/openjfx-17.0.10_osx-x64_bin-jmods.zip

if [ "$(uname -m)" = "arm64" ]; then
  FX=$FX_ARM
else
  FX=$FX_X64
fi

CURRENT_DIR=$(pwd)
echo "Current dir: $CURRENT_DIR"

VERSION="${1:?Missing version (1.2.3)}"
echo "Will build Conduktor $VERSION"

echo "Modules: ${CDK_JLINK_MODULES:?Missing modules}"
echo "Application: ${CDK_APP_NAME:?Missing application name}"
echo "Description: ${CDK_APP_DESCRIPTION:?Missing description}"
echo "Vendor: ${CDK_VENDOR:?Missing vendor}"
echo "Copyright: ${CDK_COPYRIGHT:?Missing copyright}"
echo "Options: ${CDK_JAVA_OPTIONS:?Missing Java Options}"

########################################################################################################################

CONDUKTOR_DISTRIBUTION_PATH="$(pwd)/conduktor-$VERSION"
DEPLOY_RESOURCES_PATH=".github/resources"
APP="$CDK_APP_NAME.app"

if [ ! -d "$CONDUKTOR_DISTRIBUTION_PATH" ]; then
  echo "Ensure $CONDUKTOR_DISTRIBUTION_PATH exists"
  exit 1
fi
if [ ! -d "$DEPLOY_RESOURCES_PATH" ]; then
  echo "Ensure $DEPLOY_RESOURCES_PATH exists"
  exit 1
fi

########################################################################################################################

echo "Downloading JavaFX Jmods..."
curl -sLO $FX
unzip -oq openjfx-17.0.10_osx-*-jmods.zip
# cleanup
rm -f openjfx-17.0.10_osx-*-jmods.zip
FX_MODS_PATH="./javafx-jmods-17.0.10"

echo "Building custom JRE..."
CUSTOM_JRE_NAME="runtime"

rm -rf "$CUSTOM_JRE_NAME"
jlink --module-path "$FX_MODS_PATH" \
    --add-modules "$CDK_JLINK_MODULES" \
    --bind-services --output "$CUSTOM_JRE_NAME" \
    --strip-debug --compress 2 --no-header-files --no-man-pages

###############################################################################
# Configure Keychain for signing
###############################################################################
# just to get insights
xcrun --version
#xcrun --show-sdk-version
#xcrun --show-sdk-build-version

MACOS_SIGNING_IDENTITY_PASSPHRASE=${MACOS_SIGNING_IDENTITY_PASSPHRASE:-}
MACOS_SIGNING_IDENTITY_B64=${MACOS_SIGNING_IDENTITY_B64:-}
MACOS_SIGNING_USERNAME=${MACOS_SIGNING_USERNAME:-}
MACOS_SIGNING_SPECIFIC_PWD=${MACOS_SIGNING_SPECIFIC_PWD:-}

if [ "$MACOS_SIGNING_IDENTITY_PASSPHRASE" != "" ] && [ "$MACOS_SIGNING_IDENTITY_B64" != "" ]; then
  if [ "$MACOS_SIGNING_USERNAME" = "" ] || [ "$MACOS_SIGNING_SPECIFIC_PWD" = "" ]; then
    echo "Missing auth to notarization service (MACOS_SIGNING_*) aborting..."
    exit 1
  fi

  security create-keychain -p "$MACOS_SIGNING_IDENTITY_PASSPHRASE" build.keychain
  security default-keychain -s build.keychain
  security unlock-keychain -p "$MACOS_SIGNING_IDENTITY_PASSPHRASE" build.keychain
  security set-keychain-settings -t 3600 -u build.keychain
  echo "$MACOS_SIGNING_IDENTITY_B64" > Conduktor.p12.txt
  openssl base64 -d -in Conduktor.p12.txt -out Conduktor.p12
  security import ./Conduktor.p12 -k build.keychain -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productsign -P "$MACOS_SIGNING_IDENTITY_PASSPHRASE"
  rm -f Conduktor.p12.txt Conduktor.p12
  # Set the keychain to allow use of the certificate without user interaction (we are headless!)
  security set-key-partition-list -S apple-tool:,apple: -s -k "$MACOS_SIGNING_IDENTITY_PASSPHRASE" build.keychain
  # check it's there
  security find-identity -v -p codesigning build.keychain

  # build raw image
  rm -rf "$APP"
  jpackage --name "$CDK_APP_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type app-image \
              --icon "$DEPLOY_RESOURCES_PATH/Conduktor.icns" \
              --vendor "$CDK_VENDOR" \
              --mac-package-identifier "io.conduktor.app.Conduktor" \
              --mac-package-name "$CDK_APP_NAME" \
              --main-class io.conduktor.app.ConduktorLauncher \
              --copyright "$CDK_COPYRIGHT" \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest . \
              --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
              --main-jar "desktop-$VERSION.jar" \
              --runtime-image "$CUSTOM_JRE_NAME" \
              --java-options "$CDK_JAVA_OPTIONS"

  # let's sign it
  IDENTITY="Developer ID Application: Conduktor LLC (572B6PF39A)"
  IDENTITY_INSTALLER="Developer ID Installer: Conduktor LLC (572B6PF39A)"
  ENTITLEMENTS_PATH="$DEPLOY_RESOURCES_PATH/Conduktor.entitlements"

  echo "Signing unsigned native libs..."
  CURRENT=$(pwd)
  for jar in $(find $APP/Contents/app -name "javafx*-mac.jar" -o -name "grpc-netty-shaded-*.jar" -o -name "conscrypt-openjdk-uber-*.jar" -o -name "netty-transport-native-*.jar"); do
    GOTO=$(mktemp -d)
    cd "$GOTO"
    jar xf "$CURRENT/$jar" >/dev/null
    for lib in $(find . -name "*.dylib" -o -name "*.jnilib"); do
      echo "Signing $lib..."
      codesign --strict --keychain build.keychain --force --timestamp --verbose=4 --prefix "io.conduktor." \
                --options runtime --sign "$IDENTITY" "$lib"
      echo "Repackaging $lib into $jar..."
      jar uf "$CURRENT/$jar" "$lib"
    done
  done

  cd "$CURRENT"

  echo "Signing our jars..."
  for jar in $(find $APP/Contents/app -name "*.jar"); do
    codesign --strict --keychain build.keychain --timestamp --verbose=4 --prefix "io.conduktor." \
              --options runtime --force --entitlements "$ENTITLEMENTS_PATH" --sign "$IDENTITY" \
              "$jar"
  done

  echo "Signing our runtime..."
  for runtime in $(find $APP/Contents/runtime/Contents/Home/lib -name "*.dylib") $APP/Contents/runtime/; do
    codesign --strict --keychain build.keychain --force --timestamp --verbose=4 --prefix "io.conduktor." \
              --deep --options runtime --sign "$IDENTITY" "$runtime"
  done

  echo "Signing the app itself"
  codesign --strict --keychain build.keychain --force --timestamp --verbose=4 --prefix "io.conduktor." \
           --deep --entitlements "$ENTITLEMENTS_PATH" --options runtime --sign "$IDENTITY" "$APP"

  echo "Finishing packaging with signed content..."
  jpackage --name "$CDK_APP_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type pkg \
              --app-image "$APP" \
              --vendor "$CDK_VENDOR" \
              --mac-package-identifier "io.conduktor.app.Conduktor" \
              --mac-package-name "$CDK_APP_NAME" \
              --copyright "$CDK_COPYRIGHT" \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest .

  # cleanup
  rm -rf "$APP"

  echo "Signing the package..."
  PKG="${CDK_APP_NAME}-${VERSION}.pkg"
  productsign --keychain build.keychain --sign "$IDENTITY_INSTALLER" "$PKG" "${CDK_APP_NAME}-${VERSION}-signed.pkg"
  mv "${CDK_APP_NAME}-${VERSION}-signed.pkg" "$PKG"

  # cleanup
  security delete-keychain build.keychain

  REQUEST_ID=$(xcrun altool \
    --notarize-app \
    --primary-bundle-id "io.conduktor" \
    --username "$MACOS_SIGNING_USERNAME" --password "$MACOS_SIGNING_SPECIFIC_PWD" \
    --file "$PKG" | grep RequestUUID | sed -e 's/RequestUUID = //')

  echo "Request: $REQUEST_ID"

  # sometimes, the check fails instantly because Apple can't find the ID they just gave us!
  # so we wait a long time here (it's slow anyway)
  sleep 60

  # Wait until the request is done processing.
  STATUS=""
  while true; do
      sleep 20
      STATUS=$(xcrun altool --notarization-info "$REQUEST_ID" \
            --username "$MACOS_SIGNING_USERNAME" --password "$MACOS_SIGNING_SPECIFIC_PWD" \
            | awk -F ': ' '/Status:/ { print $2; }')
      if [ "$STATUS" != "in progress" ]; then
          break;
      fi
      echo "$(date) ..."
  done

  echo

  # See if notarization succeeded, and if so, staple the ticket to the disk image.
  if [ "$STATUS" = "success" ]; then
      echo "Notarization succeeded, stapling receipt to disk image"
      xcrun stapler staple "$PKG"
  else
      echo "Notarization failed (status: $STATUS), aborting the build..."
      xcrun altool --notarization-info "$REQUEST_ID" \
          --username "$MACOS_SIGNING_USERNAME" --password "$MACOS_SIGNING_SPECIFIC_PWD" \
          | awk -F ': ' '/LogFileURL:/ { print $2; }'
      exit 1
  fi

else

  echo "Packaging unsigned .pkg"
  jpackage --name "$CDK_APP_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type pkg \
              --icon "$DEPLOY_RESOURCES_PATH/Conduktor.icns" \
              --vendor "$CDK_VENDOR" \
              --mac-package-identifier "io.conduktor.app.Conduktor" \
              --mac-package-name "$CDK_APP_NAME" \
              --main-class io.conduktor.app.ConduktorLauncher \
              --copyright "$CDK_COPYRIGHT" \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest . \
              --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
              --main-jar "desktop-$VERSION.jar" \
              --runtime-image "$CUSTOM_JRE_NAME" \
              --java-options "$CDK_JAVA_OPTIONS"
fi

DMG=false
if $DMG; then
    cd "$CURRENT_DIR"
    echo "Packaging .dmg"
    jpackage --name "$CDK_APP_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type dmg \
              --icon "$DEPLOY_RESOURCES_PATH/Conduktor.icns" \
              --vendor "$CDK_VENDOR" \
              --mac-package-identifier "io.conduktor.app.Conduktor" \
              --mac-package-name "$CDK_APP_NAME" \
              --main-class io.conduktor.app.ConduktorLauncher \
              --copyright "$CDK_COPYRIGHT" \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest . \
              --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
              --main-jar "desktop-$VERSION.jar" \
              --runtime-image "$CUSTOM_JRE_NAME" \
              --java-options "$CDK_JAVA_OPTIONS"
fi


# cleanup
rm -rf "$CUSTOM_JRE_NAME" "$FX_MODS_PATH"

# From Conduktor-2.0.0.pkg to
# -> Conduktor-2.0.0-intel.pkg
# -> Conduktor-2.0.0-apple-silicon.pkg
if [ "$(uname -m)" = "arm64" ]; then
  mv "$PKG" "${CDK_APP_NAME}-${VERSION}-apple-silicon.pkg"
else
  mv "$PKG" "${CDK_APP_NAME}-${VERSION}-intel.pkg"
fi
