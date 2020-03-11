#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset
IFS=$'\t\n'

FX=https://gluonhq.com/download/javafx-14-jmods-linux # Linux !


CURRENT_DIR=$(pwd)
echo "Current dir: $CURRENT_DIR"

VERSION="$CDK_VERSION"
echo "Will build Conduktor $VERSION"

########################################################################################################################

echo "Downloading JavaFX Jmods..."
curl -sLO $FX
unzip -oq javafx-*-jmods-*
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

DEPLOY_RESOURCES_PATH=".github/resources"
echo "Packaging .deb"
jpackage --name "$CDK_APP_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type deb \
              --icon "$DEPLOY_RESOURCES_PATH/Conduktor.png" \
              --vendor "$CDK_VENDOR" \
              --main-class io.conduktor.app.ConduktorLauncher \
              --copyright "$CDK_COPYRIGHT" \
              --linux-package-name "${CDK_APP_NAME,,}" \
              --linux-deb-maintainer "contact@conduktor.io" \
              --linux-shortcut \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest . \
              --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
              --main-jar "desktop-$VERSION.jar" \
              --runtime-image "$CUSTOM_JRE_PATH"
mv conduktor_$VERSION*.deb "Conduktor-$VERSION.deb"

echo "Packaging .rpm"
jpackage --name "$CDK_APP_NAME" \
              --app-version "$VERSION" \
              --description "$CDK_APP_DESCRIPTION" \
              --type rpm \
              --icon "$DEPLOY_RESOURCES_PATH/Conduktor.png" \
              --vendor "$CDK_VENDOR" \
              --main-class io.conduktor.app.ConduktorLauncher \
              --copyright "$CDK_COPYRIGHT" \
              --linux-package-name "${CDK_APP_NAME,,}" \
              --linux-shortcut \
              --resource-dir "$DEPLOY_RESOURCES_PATH" \
              --verbose \
              --dest . \
              --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
              --main-jar "desktop-$VERSION.jar" \
              --runtime-image "$CUSTOM_JRE_PATH"
mv conduktor-$VERSION*.rpm "Conduktor-$VERSION.rpm"
