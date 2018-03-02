#!/usr/bin/env bash

SIGNAL_VERSION=1.5.2
ALIEN_TARGET=amd64

function fail() {
  echo
  echo
  echo "ERROR: $@"
  exit 1
}

if [ "$1" == "--clone" ]; then
wget https://github.com/signalapp/Signal-Desktop/archive/v${SIGNAL_VERSION}.zip || fail "Failed to download zip archive."
unzip v${SIGNAL_VERSION}.zip || fail "Failed to extract zip archive."
fi

pushd Signal-Desktop-${SIGNAL_VERSION} || fail "Signal-Desktop-${SIGNAL_VERSION} does not exist."

if [ "$1" == "--clone" ]; then
npm install -g yarn || fail "Failed to install yarn."
npm install -g grunt-cli || fail "Failed to install grunt-cli."
yarn install || fail "Error during 'yarn install'."
grunt || fail "Error during 'grunt'."
yarn icon-gen || fail "Error during 'yarn icon-gen'."
yarn test || fail "Test failure."
echo '{"serverUrl": "https://textsecure-service.whispersystems.org", "cdnUrl": "https://cdn.signal.org"}' > local-development.json || fail "Failed to create local-development.json."
yarn generate || fail "Error during 'yarn generate'."
yarn build-release || fail "Error during 'yarn build-release'."
fi

pushd release || fail "release/ does not exist."
sudo rm -rf signal-desktop-${SIGNAL_VERSION} || fail "Couldn't remove signal-desktop-${SIGNAL_VERSION}."
sudo alien --to-rpm --generate signal-desktop_${SIGNAL_VERSION}_${ALIEN_TARGET}.deb || fail "Failed to create RPM source directory."
pushd signal-desktop-${SIGNAL_VERSION} || fail "signal-desktop-${SIGNAL_VERSION} does not exist."
sudo sed -i'' 's/^Summary: $/Summary: Signal Desktop Client/' signal-desktop-*.spec || fail "Failed to run sed on signal-desktop-*.spec."
sudo sed -i'' 's/Group: Converted\/default/\0\nAutoReqProv: no/' signal-desktop-*.spec || fail "Failed to run sed on signal-desktop-*.spec (#2)."
sudo cp signal-desktop-*.spec{,.bak}
cat signal-desktop-*.spec.bak | grep -v '%dir "/usr' | grep -v '%dir "/"' | sudo tee signal-desktop-*.spec

sudo rpmbuild --nodeps -bb --buildroot $(pwd) signal-desktop-*.spec || fail "Failed to run rpmbuild."

popd || fail "popd failed (#1)"
popd || fail "popd failed (#2)"
popd || fail "popd failed (#3)"
mv Signal-Desktop-${SIGNAL_VERSION}/release/*.rpm . || fail "Failed to move RPM file."
