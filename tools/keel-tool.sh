#!/usr/bin/env bash
#
# FILE: keel-tool.sh
# DESC: Guard and sync the vendored keel toolchain (tools/keel) against the official install.
# AUTHOR: Andre Cavalcante with AI partner
# DATE: November, 2026
# LICENSE: GPL-v3
#
# The project builds with the VENDORED copy (tools/keel/bin/cgen) for
# reproducibility — never with whatever cgen happens to be on PATH. The
# official install (0.3.0-dev) moves forward; this script keeps the vendored
# copy honest:
#
#   tools/keel-tool.sh version   vendored version key (commit)
#   tools/keel-tool.sh check     compare vendored x official (exit 2 on drift)
#   tools/keel-tool.sh sync      re-copy official -> tools/keel (run in a
#                                terminal that sees the official install)
#
# `check` passes silently when the official install is not visible (sandbox),
# so isolated environments never false-alarm. Override the official location
# with KEEL_OFFICIAL=<dir>.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDORED="$ROOT/tools/keel"
VENDORED_BIN="$VENDORED/bin/cgen"
STAMP="$VENDORED/VERSION"
OFFICIAL_DEFAULT="/home/andre/Apps/keel-0.3.0-dev"   # physical location; ~/code/... is a symlink to it

vendored_key() { "$VENDORED_BIN" --cgen-version | awk '/^commit/ {print $2}'; }

official_root() {
    if [ -n "${KEEL_OFFICIAL:-}" ] && [ -d "$KEEL_OFFICIAL" ]; then
        echo "$KEEL_OFFICIAL"; return 0
    fi
    if command -v cgen >/dev/null 2>&1; then
        local real root
        real="$(readlink -f "$(command -v cgen)")"
        root="$(dirname "$(dirname "$real")")"
        if [ -d "$root/lib" ]; then echo "$root"; return 0; fi
    fi
    if [ -d "$OFFICIAL_DEFAULT" ]; then echo "$OFFICIAL_DEFAULT"; return 0; fi
    return 1
}

official_key() { "$1/bin/cgen" --cgen-version | awk '/^commit/ {print $2}'; }

case "${1:-}" in
    version)
        vendored_key
        ;;
    check)
        [ -x "$VENDORED_BIN" ] || { echo "error: vendored cgen missing: $VENDORED_BIN" >&2; exit 1; }
        if ! root="$(official_root)"; then
            echo "keel-check: official install not visible here; skipping comparison" >&2
            exit 0
        fi
        v="$(vendored_key)"; o="$(official_key "$root")"
        if [ "$v" = "$o" ]; then
            echo "keel-check: ok (commit $v)"
        else
            echo "keel-check: DRIFT — vendored=$v official=$o" >&2
            echo "            fix with: make keel-sync   (in a terminal that sees the official)" >&2
            exit 2
        fi
        ;;
    sync)
        if ! root="$(official_root)"; then
            echo "error: official keel not found (PATH and $OFFICIAL_DEFAULT)" >&2
            echo "       run this in your normal terminal, or set KEEL_OFFICIAL=<dir>" >&2
            exit 1
        fi
        rm -rf "$VENDORED/bin" "$VENDORED/lib"
        cp -a "$root/bin" "$root/lib" "$VENDORED/"
        official_key "$root" > "$STAMP"
        echo "synced vendored keel from $root (commit $(cat "$STAMP"))"
        ;;
    *)
        echo "usage: keel-tool.sh {version|check|sync}" >&2
        exit 2
        ;;
esac
