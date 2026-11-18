# FILE: clean-tmp.sh
# DESC: Wipe the project-local tmp/ scratch directory and recreate it empty.
# AUTHOR: Andre Cavalcante with AI partner
# DATE: November, 2026
# LICENSE: GPL-v3
#
# Usage: tools/clean-tmp.sh [directory]   (run from anywhere)
#   directory  optional name of the scratch dir (default: tmp)
#
# All throwaway artifacts (validation builds, dumps, scratch files) belong in
# <project>/tmp/ — never in the system /tmp — so nothing leaks outside the
# tree and cleanup is always one command away.

#!/usr/bin/env bash
set -euo pipefail

TMP_NAME="${1:-tmp}"

# Resolve the project root: this script lives in <root>/tools
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR_PATH="$ROOT/$TMP_NAME"

# Safety: refuse to operate outside a recognizable project tree
if [[ ! -f "$ROOT/Makefile" ]]; then
    echo "error: project root not found (missing Makefile): $ROOT" >&2
    exit 2
fi

mkdir -p "$TMPDIR_PATH"

# Delete the contents but keep the directory and its .gitkeep placeholder;
# find (instead of rm -rf glob) avoids symlink and glob-expansion pitfalls.
find "$TMPDIR_PATH" -mindepth 1 ! -name '.gitkeep' -delete

echo "cleaned: $TMPDIR_PATH"
