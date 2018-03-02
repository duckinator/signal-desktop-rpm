#!/usr/bin/env bash

SIGNAL_VERSION=1.5.2
ALIEN_TARGET=amd64

function fail() {
  echo
  echo
  echo "ERROR: $@"
  exit 1
}

wget https://github.com/signalapp/Signal-Desktop/archive/v${SIGNAL_VERSION}.zip || fail "Failed to download zip archive."
unzip v${SIGNAL_VERSION}.zip || fail "Failed to extract zip archive."
pushd Signal-Desktop-${SIGNAL_VERSION} || fail "Signal-Desktop-${SIGNAL_VERSION} does not exist."
npm install -g yarn || fail "Failed to install yarn."
npm install -g grunt-cli || fail "Failed to install grunt-cli."
yarn install || fail "Error during 'yarn install'."
grunt || fail "Error during 'grunt'."
yarn icon-gen || fail "Error during 'yarn icon-gen'."
yarn test || fail "Test failure."
echo '{"serverUrl": "https://textsecure-service.whispersystems.org", "cdnUrl": "https://cdn.signal.org"}' > local-development.json || fail "Failed to create local-development.json."
yarn generate || fail "Error during 'yarn generate'."
yarn build-release || fail "Error during 'yarn build-release'."
pushd release || fail "release/ does not exist."
sudo alien --to-rpm --generate signal-desktop_${SIGNAL_VERSION}_${ALIEN_TARGET}.deb || fail "Failed to create RPM source directory."
pushd signal-desktop-${SIGNAL_VERSION} || fail "signal-desktop-${SIGNAL_VERSION} does not exist."
sudo sed -i'' 's/^Summary: $/Summary: Signal Desktop Client/' signal-desktop-*.spec || fail "Failed to run sed on signal-desktop-*.spec."
sudo rpmbuild signal-desktop-*.spec || fail "Failed to run rpmbuild."
popd || fail "popd failed (#1)"
popd || fail "popd failed (#2)"
mv release/signal-desktop-${SIGNAL_VERSION}/*.rpm . || fail "Failed to move RPM file."
