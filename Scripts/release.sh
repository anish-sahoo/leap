#!/usr/bin/env bash
# Cut a release by triggering the admin-only GitHub Actions release workflow.
#
#   Scripts/release.sh patch|minor|major
#
# The workflow computes the next version from the latest tag, builds + tests,
# bundles Leap.app, tags the release commit, and publishes the GitHub Release.
# Releasing is admin-only and happens entirely in CI — nothing is tagged or
# pushed from your machine here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUMP="${1:-}"
case "$BUMP" in
    patch | minor | major) ;;
    *)
        echo "usage: Scripts/release.sh patch|minor|major   (got: '${BUMP}')" >&2
        exit 1
        ;;
esac

if ! command -v gh >/dev/null 2>&1; then
    echo "error: GitHub CLI (gh) is required. See https://cli.github.com" >&2
    exit 1
fi

echo "==> Dispatching release workflow (bump: $BUMP)"
gh workflow run release.yml -f bump="$BUMP"

echo "==> Triggered. Watch it:"
echo "    gh run watch \$(gh run list --workflow=release.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
echo "    or: gh run list --workflow=release.yml"
