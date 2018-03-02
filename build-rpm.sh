#!/usr/bin/env bash

SIGNAL_VERSION=1.5.2
ALIEN_TARGET=amd64

wget https://github.com/signalapp/Signal-Desktop/archive/v${SIGNAL_VERSION}.zip && \
  unzip v${SIGNAL_VERSION}.zip && \
  pushd Signal-Desktop-${SIGNAL_VERSION} && \
  npm install -g yarn && \
  npm install -g grunt-cli && \
  yarn install && \
  grunt && \
  yarn icon-gen && \
  yarn test && \
  echo '{"serverUrl": "https://textsecure-service.whispersystems.org", "cdnUrl": "https://cdn.signal.org"}' > local-development.json && \
  yarn generate && \
  yarn build-release && \
  pushd release && \
  sudo alien --to-rpm --generate signal-desktop_${SIGNAL_VERSION}_${ALIEN_TARGET}.deb && \
  pushd signal-desktop-${SIGNAL_VERSION} && \
  sudo sed -i'' 's/^Summary: $/Summary: Signal Desktop Client/' signal-desktop-*.spec && \
  sudo rpmbuild signal-desktop-*.spec && \
  popd && \
  popd && \
  mv release/signal-desktop-${SIGNAL_VERSION}/*.rpm .
