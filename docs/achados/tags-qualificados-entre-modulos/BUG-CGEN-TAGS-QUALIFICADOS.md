<!--
   FILE: BUG-CGEN-TAGS-QUALIFICADOS.md
   DESC: achado reportado ao keel — alias.Set.VALOR entre módulos, import sem alias, types sobre tags
   AUTHOR: Andre Cavalcante with AI partner
   DATE: November, 2026
   LICENSE: GPL-v3
-->

# Achado: qualificador entre módulos, sobre `tags`

Três bugs do cgen (e uma lacuna da spec) achados ao escrever o catálogo de
diagnósticos do xprk (`tests/README.md`, caso "catálogo de diagnósticos vira
módulo keel") como módulo `xpr.diag`, consumido por `probe.k` e
`probe_full.k` em `tmp/diagprobe/`. Os três foram corrigidos no keel, branch
`0.3.0`, commits `868356b`, `a3c5da3`, `c561f08`.

## 1. `alias.Set.VALOR` de outro módulo

**Versão onde apareceu:** `cgen 0.2.0`, commit `v0.2.0-10-g38c5c2d-dirty`.

**Repro mínimo:**

```keel
// m/t.k
module m.t;
pub tags Color [RED = 0, GREEN = 1];

// main.k
module main;
import m.t as t types;
import_c <stdio.h>;
pub int main(void) {
    printf("%d\n", t.Color.GREEN);
    return 0;
}
```

**Comando:** `cgen --base-dir <base> -I . --main main main.k`

**Esperado:** `t.Color.GREEN` vira `m_t_Color_GREEN`.

**Observado:** o cgen resolvia só os três primeiros tokens (`t.Color`) para
o tipo `m_t_Color` e deixava `.GREEN` como texto, que o `cc` recusava:
`expected expression before 'm_t_Color'`.

**No xprk, caso real:** `probe_full.k`, `return outcome.fail(r,
xpr.diag.Diag.SIZE_MISMATCH);` (ver §3 abaixo, mesma causa, qualificador de
mais de um token).

**Corrigido em:** commit `868356b` (keel, branch `0.3.0`), golden `075`.

## 2. Import sem alias não resolve

**Versão onde apareceu:** `cgen 0.2.0`, commit `v0.2.0-17-g868356b-dirty`.

**Repro mínimo:**

```keel
// m/t.k
module m.t;
pub constexpr i32 BRIDGE = 7;
pub int square(int x) { return x * x; }

// main.k
module main;
import m.t;                 // sem `as`
import_c <stdio.h>;
pub int main(void) {
    printf("%d %d\n", m.t.BRIDGE, m.t.square(5));
    return 0;
}
```

**Esperado:** sem alias, o qualificador nos usos é o nome do módulo por
inteiro — `m.t.BRIDGE`, `m.t.square(5)`.

**Observado:** nenhuma forma resolvia. `m.t.BRIDGE` falhava com `'m'
undeclared`; só o último segmento (`t.BRIDGE`) também falhava, com `'t'
undeclared`. A spec não dizia qual forma deveria valer.

**No xprk, caso real:** o catálogo (`xpr/diag.k`) é consumido sem alias em
algum ponto do probe; a ponte adotada como contorno (`pub constexpr i32
ERR_X = X;`, padrão `coll.EMPTY`) deixa de ser necessária.

**Corrigido em:** commit `a3c5da3` (keel, branch `0.3.0`); spec §4.1 regra 5
*(desde 0.3.0)*: "Sem alias, o qualificador é o nome do módulo por inteiro,
com os pontos do caminho."; golden `077`.

## 3. `types` não injeta o nome de um conjunto `tags`

**Versão onde apareceu:** `cgen 0.2.0`, commit `v0.2.0-17-g868356b-dirty`.

**Repro mínimo:**

```keel
// m/t.k
module m.t;
pub tags Color [RED = 0, GREEN = 1];

// main.k
module main;
import m.t types;
import_c <stdio.h>;
pub int main(void) {
    Color c = Color.GREEN;
    printf("%d\n", c);
    return 0;
}
```

**Esperado:** `Color` é tipo e modificador, e a spec (confirmada pelo
rationale, seção "Constantes nomeadas") já previa `types` injetando nu o
nome de um conjunto `tags`: `Color c` e `Color.GREEN` resolvem sem o
qualificador do módulo.

**Observado:** `Color c` falhava com `unknown type name 'Color'`; o
`inject_types` do cgen só injetava tipo, modificador e protocolo, não
conjunto de tags, e a spec §4.1 regra 6 não citava `tags` na lista (era
lacuna da spec, não só bug do cgen).

**No xprk, caso real:** `probe.k` importa `xpr.diag as diag types;` e usaria
`Diag` sem o qualificador `diag.` se este bug não tivesse sido corrigido.

**Corrigido em:** commit `c561f08` (keel, branch `0.3.0`); spec §4.1 regra 6
*(desde 0.3.0)*: acrescenta "e conjuntos de tags" à lista do que `types`
injeta; golden `076`.

## Ambiente

Linux, `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`, `-std=c11` e `-std=c23`.
