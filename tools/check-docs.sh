#!/usr/bin/env bash
#
# FILE: check-docs.sh
# DESC: Valida a integridade dos dois documentos normativos (spec e rationale).
# AUTHOR: Andre Cavalcante with AI partner
# DATE: November, 2026
# LICENSE: GPL-v3
#
# Verifica, sem compilar nada:
#   1. Todo link de índice "#slug" resolve para um heading do mesmo arquivo.
#   2. Todo heading de seção tem entrada no índice (índice completo).
#   3. Todo R<n> citado na spec está definido no rationale.
#   4. Todo link para o outro documento resolve.
#
# Convenção de âncora (a mesma dos dois índices): ASCII-folded — minúsculas,
# acentos removidos, TODO caractere que não seja letra/dígito/espaço é
# descartado (inclusive '—' e '.'), depois espaço -> hífen. Por isso
# "C1 — Tudo é expressão" vira "c1--tudo-e-expressao" (dois hífens: os dois
# espaços em volta do travessão sobrevivem, o travessão não).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/xpr-specs-pt.md"
RAT="$ROOT/xpr-rationale.md"

FAIL=0
err() { echo "ERRO: $*" >&2; FAIL=$((FAIL+1)); }

# Texto do heading -> slug. Sempre termina com newline.
slugify() {
    printf '%s\n' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/`//g' \
              -e 'y/áàâãäéèêëíìîïóòôõöúùûüçñ/aaaaaeeeeiiiiooooouuuucn/' \
              -e 's/[^a-z0-9 ]//g' \
              -e 's/ /-/g'
}

# Slugs dos headings que DEVEM estar no índice de um arquivo, um por linha.
# Inclui só títulos de seção: começam por dígito (§N ou N.M) ou por R<n>/C<n>.
# Exclui o próprio "Índice" e títulos de prosa sem numeração.
heading_slugs() {
    grep -E '^#{2,6} ' "$1" | sed -e 's/^#\{2,6\} //' \
        | grep -E '^([0-9]+(\.[0-9]+)?\..*|[RC][0-9]+(\.[0-9]+)?\b.*)' \
        | while IFS= read -r h; do slugify "$h"; done
}

# Slugs de TODOS os headings do arquivo (para validar alvos de link).
all_heading_slugs() {
    grep -E '^#{2,6} ' "$1" | sed -e 's/^#\{2,6\} //' | while IFS= read -r h; do
        slugify "$h"
    done
}

# "slug<TAB>texto" por entrada de índice.
toc_entries() {
    awk '
        /^[[:space:]]*- \[/ {
            line = $0
            text = line; sub(/^[[:space:]]*- \[/, "", text); sub(/\].*$/, "", text)
            slug = line; sub(/^.*\(#/, "", slug); sub(/\).*$/, "", slug)
            printf "%s\t%s\n", slug, text
        }
    ' "$1"
}

check_index() { # $1 = rótulo, $2 = caminho
    local label="$1" file="$2" slug text
    local heads n_entries=0 n_heads=0 missing=""
    heads="$(heading_slugs "$file")"
    local all_heads; all_heads="$(all_heading_slugs "$file")"
    n_heads="$(printf '%s\n' "$heads" | grep -c . || true)"

    while IFS=$'\t' read -r slug text; do
        [ -n "$slug" ] || continue
        n_entries=$((n_entries+1))
        printf '%s\n' "$all_heads" | grep -Fxq -- "$slug" \
            || err "$label: link de índice quebrado: [$text] -> #$slug"
    done < <(toc_entries "$file")

    while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        toc_entries "$file" | cut -f1 | grep -Fxq -- "$slug" \
            || missing="$missing $slug"
    done <<< "$heads"
    [ -n "$missing" ] && err "$label: heading sem entrada no índice:$missing"

    echo "  $label: $n_entries entradas no índice, $n_heads headings"
}

check_cross() { # $1 = rótulo, $2 = arquivo de origem, $3 = nome do outro doc, $4 = outro arquivo
    local label="$1" src="$2" other_name="$3" other="$4" slug
    local other_slugs; other_slugs="$(all_heading_slugs "$other")"
    local n=0
    while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        n=$((n+1))
        printf '%s\n' "$other_slugs" | grep -Fxq -- "$slug" \
            || err "$label: link quebrado para $other_name#$slug"
    done < <(grep -oE "\($other_name#[^)]+\)" "$src" | sed -e "s/^($other_name#//" -e 's/)$//')
    echo "  $label -> $other_name: $n link(s)"
}

echo "check-docs: integridade dos normativos"

check_index spec          "$SPEC"
check_index rationale     "$RAT"
check_cross spec      "$SPEC" xpr-rationale.md "$RAT"
check_cross rationale "$RAT"  xpr-specs-pt.md "$SPEC"

# R<n> citado na spec deve estar definido no rationale.
defined="$(grep -oE '^#{2,3} R[0-9]+(\.[0-9]+)?' "$RAT" | sed 's/^#* //' | sort -u)"
cited="$(grep -oE '\bR[0-9]+(\.[0-9]+)?\b' "$SPEC" | sort -u)"
for r in $cited; do
    printf '%s\n' "$defined" | grep -Fxq -- "$r" \
        || err "spec cita $r, que não está definido no rationale"
done
echo "  referências R: $(printf '%s\n' "$cited" | grep -c .) citadas na spec, $(printf '%s\n' "$defined" | grep -c .) definidas no rationale"

if [ "$FAIL" -ne 0 ]; then
    echo "check-docs: $FAIL problema(s)" >&2
    exit 1
fi
echo "check-docs: ok"
