#!/usr/bin/env bash
# update-plugin-version.sh — Update a plugin's version in marketplace.json.
#
# Usage: bash scripts/update-plugin-version.sh <plugin> <version>
#
#   plugin   — plugin name as it appears in marketplace.json (e.g. jfm, tmb)
#   version  — version string with or without leading v (e.g. 0.8.0 or v0.8.0)
#
# Exits non-zero on any error. Skips the commit if already at the target version.

set -euo pipefail

PLUGIN="${1:-}"
VERSION="${2:-}"

if [[ -z "$PLUGIN" || -z "$VERSION" ]]; then
  echo "Usage: $0 <plugin> <version>" >&2
  exit 1
fi

# Strip leading 'v' if present
VERSION="${VERSION#v}"

MARKETPLACE="$(dirname "$0")/../marketplace.json"

if [[ ! -f "$MARKETPLACE" ]]; then
  echo "Error: marketplace.json not found at $MARKETPLACE" >&2
  exit 1
fi

# Verify the plugin exists before touching anything
FOUND=$(jq --arg p "$PLUGIN" '[.plugins[] | select(.name == $p)] | length' "$MARKETPLACE")
if [[ "$FOUND" -eq 0 ]]; then
  echo "Error: plugin '$PLUGIN' not found in marketplace.json" >&2
  exit 1
fi

# Check current version — skip if already up to date
CURRENT=$(jq -r --arg p "$PLUGIN" '.plugins[] | select(.name == $p) | .version' "$MARKETPLACE")
if [[ "$CURRENT" == "$VERSION" ]]; then
  echo "Already at $PLUGIN $VERSION — nothing to do."
  exit 0
fi

# Update the version in place
jq --arg p "$PLUGIN" --arg v "$VERSION" \
  '(.plugins[] | select(.name == $p) | .version) = $v' \
  "$MARKETPLACE" > "$MARKETPLACE.tmp" && mv "$MARKETPLACE.tmp" "$MARKETPLACE"

echo "Updated $PLUGIN: $CURRENT → $VERSION"

# Commit and push
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add marketplace.json
git commit -m "Bump $PLUGIN to $VERSION"
git push
