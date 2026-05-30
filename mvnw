#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -x "$DIR/.mvn/apache-maven/bin/mvn" ]; then
  "$DIR/.mvn/apache-maven/bin/mvn" "$@"
  exit $?
fi
echo "Maven not found locally; downloading Apache Maven 3.9.7..."
TMPZIP="$DIR/.mvn/apache-maven.zip"
mkdir -p "$DIR/.mvn"
curl -fSL "https://archive.apache.org/dist/maven/maven-3/3.9.7/binaries/apache-maven-3.9.7-bin.zip" -o "$TMPZIP"
unzip -q "$TMPZIP" -d "$DIR/.mvn"
rm "$TMPZIP"
mv "$DIR/.mvn/apache-maven-3.9.7" "$DIR/.mvn/apache-maven" || true
"$DIR/.mvn/apache-maven/bin/mvn" "$@"
exit $?
