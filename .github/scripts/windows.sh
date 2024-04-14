#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -x
IFS=$'\t\n'

FX="https://download2.gluonhq.com/openjfx/17.0.10/openjfx-17.0.10_windows-x64_bin-jmods.zip"

CURRENT_DIR=$(pwd)
echo "Current dir: $CURRENT_DIR"

VERSION="$1"
echo "Will build Conduktor $VERSION"

########################################################################################################################

echo "Downloading JavaFX Jmods..."
curl -sLO $FX
unzip -oq openjfx-17.0.10_windows-x64_bin-jmods.zip
FX_MODS_PATH="./javafx-jmods-17.0.10"

CONDUKTOR_DISTRIBUTION_PATH="$(pwd)/conduktor-$VERSION"

echo "Building custom JRE..."
CUSTOM_JRE_NAME="runtime"
jlink --module-path "$FX_MODS_PATH" \
    --add-modules "$CDK_JLINK_MODULES" \
    --bind-services --output "$CUSTOM_JRE_NAME" \
    --strip-debug --compress 2 --no-header-files --no-man-pages

DEPLOY_RESOURCES_PATH=".github/resources"

###############################################################################

function cdk_jpackage() {
  TYPE=$1
  echo "Packaging ${TYPE}."
  jpackage --name "$CDK_APP_NAME" \
          --app-version "$VERSION" \
          --description "$CDK_APP_NAME" \
          --type "$TYPE" \
          --icon "$DEPLOY_RESOURCES_PATH/Conduktor.ico" \
          --vendor "$CDK_VENDOR" \
          --main-class io.conduktor.app.ConduktorLauncher \
          --copyright "$CDK_COPYRIGHT" \
          --resource-dir "$DEPLOY_RESOURCES_PATH" \
          --verbose \
          --dest . \
          --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
          --main-jar "desktop-$VERSION.jar" \
          --runtime-image "$CUSTOM_JRE_NAME" \
          --win-dir-chooser \
          --win-menu \
          --win-shortcut \
          --win-upgrade-uuid 3a60b525-6f18-4c22-8070-d08efcc89b95 \
          --java-options "$CDK_JAVA_OPTIONS"
}

# adding --win-per-user-install
function cdk_jpackage_single_user() {
  TYPE=$1
  echo "Packaging ${TYPE} Single User."
  jpackage --name "$CDK_APP_NAME" \
          --app-version "$VERSION" \
          --description "$CDK_APP_DESCRIPTION" \
          --type "$TYPE" \
          --icon "$DEPLOY_RESOURCES_PATH/Conduktor.ico" \
          --vendor "$CDK_VENDOR" \
          --main-class io.conduktor.app.ConduktorLauncher \
          --copyright "$CDK_COPYRIGHT" \
          --resource-dir "$DEPLOY_RESOURCES_PATH" \
          --verbose \
          --dest . \
          --input "$CONDUKTOR_DISTRIBUTION_PATH/lib" \
          --main-jar "desktop-$VERSION.jar" \
          --runtime-image "$CUSTOM_JRE_NAME" \
          --win-dir-chooser \
          --win-menu \
          --win-shortcut \
          --win-per-user-install \
          --win-upgrade-uuid 3a60b525-6f18-4c22-8070-d08efcc89b95 \
          --java-options "$CDK_JAVA_OPTIONS"
}

cdk_jpackage_single_user msi
mv "${CDK_APP_NAME}-${VERSION}.msi" "${CDK_APP_NAME}-${VERSION}-single-user.msi"

for TYPE in msi exe ; do
  cdk_jpackage $TYPE
done

