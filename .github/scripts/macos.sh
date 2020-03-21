#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset
IFS=$'\t\n'

FX=https://gluonhq.com/download/javafx-14-jmods-mac


CURRENT_DIR=$(pwd)
echo "Current dir: $CURRENT_DIR"

VERSION="$CDK_VERSION"
echo "Will build Conduktor $VERSION"

########################################################################################################################

echo "Downloading JavaFX Jmods..."
curl -sLO $FX
unzip -oq javafx-*-jmods-mac
FX_NAME=$(ls -d javafx-jmods-*)
FX_MODS_PATH="$(pwd)/$FX_NAME/"

CONDUKTOR_DISTRIBUTION_PATH="$(pwd)/desktop-$VERSION"

echo "Building custom JRE..."
CUSTOM_JRE_NAME=runtime
jlink --module-path "$FX_MODS_PATH" \
    --add-modules "$CDK_JLINK_MODULES" \
    --bind-services --output $CUSTOM_JRE_NAME \
    --strip-debug --compress 2 --no-header-files --no-man-pages --strip-native-commands
CUSTOM_JRE_PATH="$(pwd)/$CUSTOM_JRE_NAME"

###############################################################################
# Configure Keychain for signing
###############################################################################
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
fi
###############################################################################


# needs the original source here
DEPLOY_RESOURCES_PATH=".github/resources"
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
              --runtime-image "$CUSTOM_JRE_PATH"

DMG=false
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
              --runtime-image "$CUSTOM_JRE_PATH"
fi
