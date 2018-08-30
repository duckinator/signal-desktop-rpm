#!/usr/bin/env bash

SIGNAL_VERSION=1.16.0-beta.1
ALIEN_TARGET=amd64

DIR="$(readlink -e $(dirname $0))"
SIGNAL_DIR="$DIR/Signal-Desktop-${SIGNAL_VERSION}"
RELEASE_DIR="$SIGNAL_DIR/release/"
RELEASE_SIGNAL_DIR="$RELEASE_DIR/signal-desktop-${SIGNAL_VERSION}"

DEB_FILE="signal-desktop_${SIGNAL_VERSION}_${ALIEN_TARGET}.deb"

function fail() {
  echo
  echo
  echo "ERROR: $@"
  exit 1
}

function checkdir() {
  [ -d "$1" ] || fail "$1 does not exist or is not a directory."
}

function checkfile() {
  [ -f "$1" ] || fail "$1 does not exist or is not a file."
}

if [ ! -f "v${SIGNAL_VERSION}.zip" ]; then
  wget https://github.com/signalapp/Signal-Desktop/archive/v${SIGNAL_VERSION}.zip || fail "Failed to download zip archive."
  unzip v${SIGNAL_VERSION}.zip || fail "Failed to extract zip archive."
fi

checkdir "$SIGNAL_DIR"
pushd "$SIGNAL_DIR"

if [ ! -d "$RELEASE_DIR" ]; then
  npm install -g yarn || fail "Failed to install yarn."
  npm install -g grunt-cli || fail "Failed to install grunt-cli."
  yarn install || fail "Error during 'yarn install'."
  grunt || fail "Error during 'grunt'."
  yarn icon-gen || fail "Error during 'yarn icon-gen'."
  #yarn test || fail "Test failure."
  echo '{"serverUrl": "https://textsecure-service.whispersystems.org", "cdnUrl": "https://cdn.signal.org"}' > local-development.json || fail "Failed to create local-development.json."
  yarn generate || fail "Error during 'yarn generate'."
  yarn build-release || fail "Error during 'yarn build-release'."
fi

checkdir "$RELEASE_DIR"
pushd "$RELEASE_DIR"
    sudo rm -rf "$RELEASE_SIGNAL_DIR"
    sudo alien --to-rpm --generate "$DEB_FILE" || fail "Failed to create RPM source directory."
    sudo chown -R $USER "$RELEASE_SIGNAL_DIR" || fail "Couldn't shown $RELEASE_SIGNAL_DIR."

checkdir "$RELEASE_SIGNAL_DIR"
pushd "$RELEASE_SIGNAL_DIR"
    sudo sed -i'' 's/^Summary: $/Summary: Signal Desktop Client/' signal-desktop-*.spec || exit 1
    sudo sed -i'' 's/Group: Converted\/default/\0\nAutoReqProv: no/' signal-desktop-*.spec || exit 1
    sudo cp signal-desktop-*.spec{,.bak} || exit 1
    cat signal-desktop-*.spec.bak | grep -v '%dir "/usr' | grep -v '%dir "/"' | sudo tee signal-desktop-*.spec
    sudo chmod -R 755 . || fail "Couldn't chmod -R 755 $RELEASE_SIGNAL_DIR."
    sudo rpmbuild --nodeps -bb --buildroot $(pwd) signal-desktop-*.spec || fail "Failed to run rpmbuild."

popd || fail
popd || fail
popd || fail

mv Signal-Desktop-${SIGNAL_VERSION}/release/*.rpm . || fail "Failed to move RPM file."
