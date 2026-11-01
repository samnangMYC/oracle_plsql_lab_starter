#!/usr/bin/env sh
set -eu
if ! command -v mvn >/dev/null 2>&1; then
  echo "Maven was not found. Install Maven and add it to PATH." >&2
  exit 1
fi
mvn clean package
echo "Build complete: target/stdcifd-weblogic.war"
