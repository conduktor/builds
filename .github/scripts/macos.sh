#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset
IFS=$'\t\n'

FX="https://gluonhq.com/download/javafx-14-jmods-mac"

CURRENT_DIR=$(pwd)
echo "Current dir: $CURRENT_DIR"

VERSION="$1"
echo "Will build Conduktor $VERSION"

########################################################################################################################

echo "Downloading JavaFX Jmods..."
curl -sLO $FX
unzip -oq javafx-*-jmods-mac
FX_MODS_PATH="./javafx-jmods-14"

CONDUKTOR_DISTRIBUTION_PATH="$(pwd)/conduktor-$VERSION"

echo "Building custom JRE..."
CUSTOM_JRE_NAME="runtime"
jlink --module-path "$FX_MODS_PATH" \
    --add-modules "$CDK_JLINK_MODULES" \
    --bind-services --output "$CUSTOM_JRE_NAME" \
    --strip-debug --compress 2 --no-header-files --no-man-pages --strip-native-commands

DEPLOY_RESOURCES_PATH=".github/resources"

###############################################################################
# Configure Keychain for signing
###############################################################################
# just to get insights
xcrun --version
xcrun --show-sdk-version
xcrun --show-sdk-build-version

IDENTITY_PASSPHRASE=${IDENTITY_PASSPHRASE:-""}
if  [ "$IDENTITY_PASSPHRASE" != "" ] && [ "$IDENTITY_P12_B64" != "" ]; then
  security create-keychain -p "$IDENTITY_PASSPHRASE" build.keychain
  security default-keychain -s build.keychain
  security unlock-keychain -p "$IDENTITY_PASSPHRASE" build.keychain

  # Put the base-64 encoded signing certificicate into a text file, decode it to binary form.
  echo "$IDENTITY_P12_B64" > DS_ID_App.p12.txt
  openssl base64 -d -in DS_ID_App.p12.txt -out DS_ID_App.p12

  # Install the decoded signing certificate into our unlocked build keychain.
  security import DS_ID_App.p12 -A -P "$IDENTITY_PASSPHRASE"

  # Set the keychain to allow use of the certificate without user interaction (we are headless!)
  security set-key-partition-list -S apple-tool:,apple: -s -k "$IDENTITY_PASSPHRASE" build.keychain

  # build raw-image
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
              --runtime-image "$CUSTOM_JRE_NAME"

  # let's sign it
  APP="$CDK_APP_NAME.app"
  IDENTITY="Developer ID Application: Conduktor"
  ENTITLEMENTS_PATH="$DEPLOY_RESOURCES_PATH/Conduktor.entitlements"

  echo "Signing all the content..."
  codesign --force --strict --timestamp --verbose=4 --prefix "io.conduktor." \
           --deep \
           --entitlements "$ENTITLEMENTS_PATH" \
           --options runtime \
           --sign "$IDENTITY"
           "$APP"

  codesign -dvvvv "$APP"

  APP_SIGNED_NAME="$APP_NAME-signed"
  echo "Finishing packaging with signed content..."
  jpackage --name "$APP_SIGNED_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type dmg \
              --vendor "$CDK_VENDOR" \
              --mac-package-identifier "io.conduktor.app.Conduktor" \
              --mac-package-name "$CDK_APP_NAME" \
              --copyright "$CDK_COPYRIGHT" \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest .

  echo "Signing the package..."
  DMG_NAME="$APP_SIGNED_NAME-$VERSION.dmg"
  codesign --strict --timestamp --verbose=4 --prefix "io.conduktor." \
            --entitlements "$ENTITLEMENTS_PATH" \
            --options runtime \
            --sign "$IDENTITY" \
            "$DMG_NAME"

  NOTORIZATION=false

  if $NOTORIZATION; then

    USER="user"
    PASSWD="pwd"

    xcrun altool \
      --notarize-app \
      --primary-bundle-id "io.conduktor" \
      --username "$USER" --password "$PASSWD" \
      --file "$DMG_NAME" \
      --output-format xml > upload_result.plist

      request_id=$(/usr/libexec/PlistBuddy -c "Print :notarization-upload:RequestUUID" upload_result.plist)

      # Wait until the request is done processing.
      while true; do
          sleep 20
          xcrun altool --notarization-info "$request_id" \
                --username "$USER" --password "$PASSWD" \
                --output-format xml > status.plist
          if [ "$(/usr/libexec/PlistBuddy -c "Print :notarization-info:Status" status.plist)" != "in progress" ]; then
              break;
          fi
          echo "$(date) ...still waiting for notarization to finish..."
      done

      # See if notarization succeeded, and if so, staple the ticket to the disk image.
      if [ "$(/usr/libexec/PlistBuddy -c "Print :notarization-info:Status" status.plist)" = "success" ]; then
          echo "Notarization succeeded, stapling receipt to disk image"
          xcrun stapler staple "$DMG_NAME"
      else
          false;
      fi
  fi

fi
###############################################################################


echo "Packaging .pkg"
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

DMG=true
if $DMG; then
    echo "Packaging .dmg"
    echo "The .dmg sucks because: https://github.com/andreyvit/create-dmg/issues/72"
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
