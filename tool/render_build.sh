#!/usr/bin/env bash
# Builds the example app for Render's static site.
# Render dashboard -> Settings -> Build Command:  bash tool/render_build.sh
# Publish directory:                              example/build/web
set -euo pipefail

FLUTTER_VERSION="3.41.7"
# Commit the 3.41.7 tag points to; bump both together.
FLUTTER_REVISION="cc0734ac716fbb8b90f3f9db8020958b1553afa7"
FLUTTER_HOME="$HOME/flutter"

# Render keeps $HOME in its build cache: reuse the SDK when it is the right
# version, otherwise (missing, broken or another version) fetch it again.
if [ -x "$FLUTTER_HOME/bin/flutter" ] &&
  [ "$(git -C "$FLUTTER_HOME" rev-parse HEAD 2>/dev/null)" = "$FLUTTER_REVISION" ]; then
  echo "Using cached Flutter $FLUTTER_VERSION"
else
  rm -rf "$FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git \
    --depth 1 --branch "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter config --no-analytics
flutter --version

cd "$(dirname "$0")/../example"
flutter pub get
flutter build web --release
