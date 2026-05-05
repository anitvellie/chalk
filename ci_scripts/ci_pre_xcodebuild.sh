#!/bin/sh
# Xcode Cloud pre-build script.
# Generates the gitignored DevelopmentTeam.xcconfig so Xcode can resolve
# the base configuration reference on the build server.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCCONFIG="$REPO_ROOT/Config/DevelopmentTeam.xcconfig"

echo "DEVELOPMENT_TEAM = ${DEVELOPMENT_TEAM}" > "$XCCONFIG"
echo "ci_pre_xcodebuild: wrote $XCCONFIG"
