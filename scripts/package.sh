#!/usr/bin/env bash
# Package the standup-tool Executa binary into an Anna-distributable tar.gz.
#
# Layout produced (per the Anna "releasable binary" guide):
#   tool-cubiczan-standup-tool-trj7594f-<platform>.tar.gz
#   ├── bin/
#   │   └── tool-cubiczan-standup-tool-trj7594f   (0o755)
#   └── manifest.json
#
# Usage: scripts/package.sh <platform>   e.g. darwin-arm64 | darwin-x86_64 | linux-x86_64
set -euo pipefail

TOOL_ID="tool-cubiczan-standup-tool-trj7594f"
VERSION="1.0.0"
PLATFORM="${1:?usage: package.sh <platform>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

BIN_SRC="$ROOT/dist/$TOOL_ID"
[ -f "$BIN_SRC" ] || { echo "missing built binary: $BIN_SRC (run pyinstaller first)"; exit 1; }

STAGE="$ROOT/dist/pkg-$PLATFORM"
rm -rf "$STAGE"
mkdir -p "$STAGE/bin"
cp "$BIN_SRC" "$STAGE/bin/$TOOL_ID"
chmod 0755 "$STAGE/bin/$TOOL_ID"

cat > "$STAGE/manifest.json" <<JSON
{
  "name": "$TOOL_ID",
  "display_name": "Standup Tool",
  "version": "$VERSION",
  "description": "Transforms raw developer activity (commits, PRs, issues, messages) into a structured daily standup with automatic blocker detection. Speaks stdio JSON-RPC.",
  "runtime": {
    "binary": {
      "entrypoint": {
        "default": "bin/$TOOL_ID"
      },
      "permissions": {
        "bin/$TOOL_ID": "0o755"
      }
    }
  }
}
JSON

ARCHIVE="$ROOT/dist/$TOOL_ID-$PLATFORM.tar.gz"
tar -C "$STAGE" -czf "$ARCHIVE" bin manifest.json
echo "built: $ARCHIVE"
tar -tzf "$ARCHIVE"
