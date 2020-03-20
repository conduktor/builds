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
# --mac-sign --mac-signing-key-user-name "developer"  --mac-package-signing-prefix com.myapp

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
