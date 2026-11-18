#!/usr/bin/env bash
#
# FILE: run_tests.sh
# DESC: Fixture-driven test runner for xprk (lexer/parser/runtime suites), per tests/README.md.
# AUTHOR: Andre Cavalcante with AI partner
# DATE: November, 2026
# LICENSE: GPL-v3
#
# Layout: tests/<suite>/<case>.x (input), <case>.expected (golden stdout; a
# missing golden is PENDING, not failure), <case>.diag (negative case: expected
# diagnostic id, which must exist in the catalog src/xpr.h or --list fails).
# Temporaries go to <root>/tmp/ — never the system /tmp.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$ROOT/tmp"
CATALOG="$ROOT/src/xpr.h"
XPR="${XPR:-$ROOT/xprk}"

SUITE="lexer"
LIST=0
CASE=""
UPDATE=0
TIMEOUT=5

# Suite mode defaults; the first --lexer-arg/--parser-arg replaces the default,
# later ones append, an empty value clears all arguments.
LEX_ARGS=(--lex-dump)
PAR_ARGS=(--parse-dump)
_lex_done=0
_par_done=0

PASS=0; FAIL=0; PEND=0; UPD=0; LISTFAIL=0

usage() {
    cat <<'EOF'
usage: run_tests.sh [--suite lexer|parser|runtime|all] [--list] [--case NAME]
                    [--binary PATH | env XPR] [--timeout N] [--update]
                    [--lexer-arg ARG ...] [--parser-arg ARG ...]

  --list     check catalogs and files only (no binary, no temporaries)
  --case     select a single case by name
  --update   bless/regenerate .expected goldens from successful runs
EOF
}

die_usage() { echo "error: $*" >&2; usage >&2; exit 2; }

while [ $# -gt 0 ]; do
    case "$1" in
        --suite)      SUITE="$2"; shift 2 ;;
        --suite=*)    SUITE="${1#*=}"; shift ;;
        --list)       LIST=1; shift ;;
        --case)       CASE="$2"; shift 2 ;;
        --case=*)     CASE="${1#*=}"; shift ;;
        --binary)     XPR="$2"; shift 2 ;;
        --binary=*)   XPR="${1#*=}"; shift ;;
        --timeout)    TIMEOUT="$2"; shift 2 ;;
        --timeout=*)  TIMEOUT="${1#*=}"; shift ;;
        --update)     UPDATE=1; shift ;;
        --lexer-arg)
            [ "$_lex_done" -eq 0 ] && { LEX_ARGS=(); _lex_done=1; }
            [ -n "$2" ] && LEX_ARGS+=("$2"); shift 2 ;;
        --lexer-arg=*)
            [ "$_lex_done" -eq 0 ] && { LEX_ARGS=(); _lex_done=1; }
            [ -n "${1#*=}" ] && LEX_ARGS+=("${1#*=}"); shift ;;
        --parser-arg)
            [ "$_par_done" -eq 0 ] && { PAR_ARGS=(); _par_done=1; }
            [ -n "$2" ] && PAR_ARGS+=("$2"); shift 2 ;;
        --parser-arg=*)
            [ "$_par_done" -eq 0 ] && { PAR_ARGS=(); _par_done=1; }
            [ -n "${1#*=}" ] && PAR_ARGS+=("${1#*=}"); shift ;;
        -h|--help)    usage; exit 0 ;;
        *)            die_usage "unknown option: $1" ;;
    esac
done

case "$SUITE" in
    lexer|parser|runtime|all) ;;
    *) die_usage "unknown suite: $SUITE" ;;
esac

suites_of() {
    case "$SUITE" in
        all) echo "lexer parser runtime" ;;
        *)   echo "$SUITE" ;;
    esac
}

suite_args() { # echoes the mode args of a suite, one per line
    case "$1" in
        lexer)  printf '%s\n' ${LEX_ARGS[@]+"${LEX_ARGS[@]}"} ;;
        parser) printf '%s\n' ${PAR_ARGS[@]+"${PAR_ARGS[@]}"} ;;
        runtime) : ;;
    esac
}

diag_in_catalog() { # $1 = diagnostic id
    [ -f "$CATALOG" ] && grep -q -- "$1" "$CATALOG" 2>/dev/null
}

list_suite() {
    local s="$1" dir="$ROOT/tests/$1" name id exp status x found_any=0
    echo "suite $s:"
    for x in "$dir"/*.x; do
        [ -e "$x" ] || { echo "  (no cases)"; return 0; }
        found_any=1
        name="$(basename "$x" .x)"
        [ -r "$x" ] || { echo "  $name  ERROR unreadable input"; LISTFAIL=1; continue; }
        [ -n "$CASE" ] && [ "$CASE" != "$name" ] && continue
        if [ -f "$dir/$name.diag" ]; then
            id="$(tr -d '[:space:]' < "$dir/$name.diag")"
            if [ -z "$id" ]; then
                echo "  $name  NEG  ERROR empty .diag"; LISTFAIL=1
            elif diag_in_catalog "$id"; then
                echo "  $name  NEG  $id  ok"
            else
                echo "  $name  NEG  $id  MISSING-IN-CATALOG"; LISTFAIL=1
            fi
        else
            exp="$dir/$name.expected"
            if [ -f "$exp" ]; then status="ok"; else status="pending-golden"; fi
            echo "  $name  POS  $status"
        fi
    done
    [ "$found_any" -eq 1 ] && [ -n "$CASE" ] && \
        [ ! -e "$dir/$CASE.x" ] && { echo "  ERROR case not found: $CASE"; LISTFAIL=1; }
    return 0
}

run_case() { # $1=suite $2=dir $3=name ; uses globals for counters
    local s="$1" dir="$2" name="$3"
    local x="$dir/$name.x" exp="$dir/$name.expected"
    local out="$TMP/test-$s-$name.out" err="$TMP/test-$s-$name.err"
    local rc=0 id

    if [ -f "$dir/$name.diag" ]; then                    # negative case
        id="$(tr -d '[:space:]' < "$dir/$name.diag")"
        timeout "$TIMEOUT" "$XPR" $(suite_args "$s") "$x" >"$out" 2>"$err"; rc=$?
        if [ "$rc" -eq 0 ]; then
            echo "FAIL $s/$name: expected nonzero exit ($id)"; head -3 "$err"; FAIL=$((FAIL+1))
        elif grep -q "\[$id\]" "$err"; then
            echo "pass $s/$name ($id)"; PASS=$((PASS+1))
        else
            echo "FAIL $s/$name: stderr lacks [$id]"; head -5 "$err"; FAIL=$((FAIL+1))
        fi
        return 0
    fi

    if [ ! -f "$exp" ]; then                              # positive, golden pending
        echo "pending $s/$name (no golden yet)"; PEND=$((PEND+1)); return 0
    fi

    timeout "$TIMEOUT" "$XPR" $(suite_args "$s") "$x" >"$out" 2>"$err"; rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "FAIL $s/$name: exit $rc"; head -3 "$err"; FAIL=$((FAIL+1)); return 0
    fi
    if [ "$UPDATE" -eq 1 ]; then
        cp "$out" "$exp"; echo "updated $s/$name"; UPD=$((UPD+1)); PASS=$((PASS+1)); return 0
    fi
    if diff -q "$exp" "$out" >/dev/null; then
        echo "pass $s/$name"; PASS=$((PASS+1))
    else
        echo "FAIL $s/$name: output mismatch"; diff -u "$exp" "$out" | head -15; FAIL=$((FAIL+1))
    fi
    return 0
}

run_suite() {
    local s="$1" dir="$ROOT/tests/$1" name x
    echo "suite $s:"
    [ -d "$dir" ] || { echo "  (no fixture dir)"; return 0; }
    for x in "$dir"/*.x; do
        [ -e "$x" ] || { echo "  (no cases)"; return 0; }
        name="$(basename "$x" .x)"
        [ -n "$CASE" ] && [ "$CASE" != "$name" ] && continue
        run_case "$s" "$dir" "$name"
    done
    if [ -n "$CASE" ] && [ ! -e "$dir/$CASE.x" ]; then
        echo "  note: case $CASE not in this suite"
    fi
    return 0
}

mkdir -p "$TMP"

if [ "$LIST" -eq 1 ]; then
    for s in $(suites_of); do list_suite "$s"; done
    if [ "$LISTFAIL" -ne 0 ]; then
        echo "listing FAILED: fix the entries above" >&2; exit 2
    fi
    echo "listing ok"; exit 0
fi

if [ ! -x "$XPR" ]; then
    echo "error: xpr binary not found or not executable: $XPR" >&2
    echo "       build it (make) or point --binary / env XPR" >&2
    exit 1
fi

for s in $(suites_of); do run_suite "$s"; done

awk -v p="$PASS" -v f="$FAIL" -v n="$PEND" -v u="$UPD" 'BEGIN {
    printf "== pass:%d fail:%d pending:%d updated:%d ==\n", p, f, n, u
    exit (f > 0) ? 1 : 0
}'
