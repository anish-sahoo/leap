#!/usr/bin/env bash
# Cut a SemVer release: validate, update CHANGELOG, tag, and push.
#
#   Scripts/release.sh 1.2.3
#
# The pushed tag (v1.2.3) triggers .github/workflows/release.yml, which builds
# and publishes the GitHub Release with the bundled app.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "usage: Scripts/release.sh X.Y.Z   (got: '${VERSION}')" >&2
    exit 1
fi
TAG="v$VERSION"

if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree not clean; commit or stash first." >&2
    exit 1
fi
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "error: tag $TAG already exists." >&2
    exit 1
fi

# Refresh CHANGELOG for this version if git-cliff is available.
if command -v git-cliff >/dev/null 2>&1; then
    echo "==> Updating CHANGELOG.md"
    git-cliff --tag "$TAG" --output CHANGELOG.md
    git add CHANGELOG.md
    git commit -m "chore(release): $TAG"
fi

echo "==> Tagging $TAG"
git tag -a "$TAG" -m "$TAG"

echo "==> Pushing"
git push origin HEAD
git push origin "$TAG"

echo "==> Done. The release workflow will build and publish $TAG."
