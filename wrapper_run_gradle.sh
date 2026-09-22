#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
GRADLE_VERSION=8.2.1
GRADLE_DIR="$ROOT_DIR/.gradle/gradle-$GRADLE_VERSION"
GRADLE_ZIP="$ROOT_DIR/.gradle/gradle-$GRADLE_VERSION-bin.zip"
GRADLE_URL="https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"

mkdir -p "$ROOT_DIR/.gradle"

if [ ! -d "$GRADLE_DIR" ]; then
  echo "Downloading Gradle $GRADLE_VERSION..."
  for attempt in 1 2; do
    if command -v curl >/dev/null 2>&1; then
      curl -L -o "$GRADLE_ZIP" "$GRADLE_URL" || { echo "Gradle download failed (attempt $attempt)"; continue; }
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$GRADLE_ZIP" "$GRADLE_URL" || { echo "Gradle download failed (attempt $attempt)"; continue; }
    else
      echo "Need curl or wget to download Gradle" >&2
      exit 1
    fi
    if unzip -q "$GRADLE_ZIP" -d "$ROOT_DIR/.gradle"; then
      break
    else
      echo "Gradle unzip failed (attempt $attempt)";
      rm -f "$GRADLE_ZIP";
    fi
  done
fi

export GRADLE_HOME="$GRADLE_DIR"
export PATH="$GRADLE_HOME/bin:$PATH"

exec gradle "$@"
