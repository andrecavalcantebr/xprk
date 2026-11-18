<!--
   FILE: diretrizes-erros.md
   DESC: Implementation guidelines for XPR runtime error handling (try/fail/last_error) mapped to keel outcome.
   AUTHOR: Andre Cavalcante with AI partner
   DATE: November, 2026
   LICENSE: GPL-v3
-->

# Diretrizes de Implementação — Erros em Tempo de Execução

Este documento descreve a **estratégia de implementação** do modelo de erros do
XPR (`try`/`fail`/`last_error`). A semântica normativa está em
[xpr-specs-pt.md](../xpr-specs-pt.md), seções 4.5, 4.7, 6.7 e 8 — em caso de conflito, a
especificação prevalece.

O transpilador é escrito em keel e gera código keel: o modelo abaixo vale para
o **código gerado** (semântica da linguagem) e pode ser usado também
internamente pelo transpilador para seus próprios erros de ferramenta.

## 1. Princípios

1. **Sem runtime de exceção próprio.** A propagação de falha usa `outcome T` e
   a cauda `else` do keel: a falha **sobe um nível por vez**, como retorno
   normal.
2. **`setjmp`/`longjmp` é proibido.** O keel injeta o corpo de cada `defer` em
   todo ponto de saída; um `longjmp` atravessa os frames intermediários sem
   executá-los — limpeza perdida, UB de `jmp_buf` órfão, `volatile` para cuidar.
   Nada disso existe na propagação por retorno.
3. **`abort()`/`exit()` só no relato final** de diagnósticos fatais (limites de
   recurso), nunca como mecanismo de erro da linguagem.
4. **Erro capturado não é diagnóstico.** Um erro capturado por `try` não passa
   pelo fluxo de stderr; um erro não capturado chega ao envoltório do `main` e
   vira diagnóstico único + status de saída ≠ 0.

## 2. Mapeamento XPR → keel gerado

| XPR | Keel gerado |
| --- | --- |
| `fail(msg)` | copia `msg` para o buffer de `last_error` **antes** de propagar; `outcome.fail(r, código)` |
| erro de interno (`a / b` com `b == 0`, `type-mismatch`, índice...) | idem: grava `last_error` (mensagem do catálogo) + `outcome.fail` |
| chamada com aridade incompatível | check no site da chamada → `outcome.fail` (`arity-mismatch`) |
| qualquer operando/combinador | `outcome xpr_Value t = sub(...) else return <propaga>;` — um check por nível |
| `and` / `or` curto-circuito | check após **cada** operando; a falha propaga antes de decidir o curto |
| `try(expr)` (sonda) | captura: falha → devolve `false`; sucesso → zera `last_error`, devolve `true` |
| `try(expr, default)` | `outcome ... = <expr> else <default>;` + zero de `last_error` no sucesso; `default` avaliado só na falha, sem proteção |
| `try(v = expr)` | sonda; no sucesso, aplica a atribuição **antes** de devolver `true` |
| programa inteiro | `try` implícito do gerador: falha → relata `last_error` uma vez no stderr, exit ≠ 0 |

Trecho ilustrativo (nomes de helper provisórios):

```keel
// xpr: num = try(a / b, 0.0);
outcome xpr_Value t0 = xpr_div(a, b) else xpr_real(0.0);
if (!outcome.failed(t0)) xpr_last_error_clear();
num = outcome.value(t0);
```

```keel
// xpr: iif(try(v = f(x)), print(v), print(last_error));
outcome xpr_Value t0 = xpr_call(f, x) else {
    // failure captured: last_error was set at raise time; assignment skipped
    return xpr_bool(false);
};
xpr_last_error_clear();        // success path clears the diagnostic
v = outcome.value(t0);         // assignment happens on success only
```

```keel
// xpr: fail("boom")  — builtin, always raises
xpr_Value xpr_builtin_fail(xpr_Value msg) {
    xpr_last_error_set(msg);   // copy payload to the stable buffer BEFORE raising
    outcome xpr_Value r = {0};
    return outcome.fail(r, XPR_ERR_FAIL);
}
```

## 3. `last_error`

- Buffer global **fixo e estável** (memória estática, nunca arena).
- Gravado **no levantamento**, com cópia do payload: a `String` do argumento
  pode morar em arena liberada durante a propagação — copiar antes de subir.
- `try` bem-sucedido zera (`""`) **ao fim** da avaliação da forma.
- Conteúdo livre: `fail` grava a mensagem do usuário; internos gravam a
  mensagem do diagnóstico do catálogo.

## 4. Limites fatais (não-capturáveis)

- Profundidade de chamada (10.000) e orçamento de passos **não** entram no
  fluxo comum de `outcome`: usam uma **flag fatal global** (ou marcador distinto
  no `outcome`), verificada nos sites de `try` **antes** da conversão para
  `false` — se fatal, segue propagando até o envoltório/relato.
- Consequência: ninguém captura limite por acidente (spec 4.7).

## 5. Arenas e limpeza

- O código gerado usa `defer` para liberar arenas de escopo; como a propagação
  é retorno normal, os defers correm em ordem reversa em todos os caminhos.
- **Watermark**: o site de `try` salva o watermark da arena no início; restaura
  **apenas no caminho de falha** (libera tudo alocado na região protegida). No
  sucesso, não restaurar — o valor precisa escapar (spec 8).
- A cópia do payload (seção 3) é o que permite restaurar a arena sem perder a
  mensagem.

## 6. Curto-circuito

`and`/`or` avaliam o operando esquerdo, **checam falha**, e só então decidem o
curto. A falha tem precedência sobre a decisão lógica: um `false or <falha>`
propaga a falha, não devolve `false`.

## 7. Diagnósticos e o catálogo

- O catálogo é o módulo keel `xpr/diag.k` (`import xpr.diag;`): conjunto
  `tags Diag` + tabela `DiagEntry`, a fonte única de códigos, identificadores
  públicos, severidades, mensagens e dicas (spec 10; Seção 1 de
  diretrizes-diagnosticos.md).
- As tabelas da spec 10 nomeiam **condições**; o identificador público vem da
  linha do catálogo.
- Erros capturáveis entram no catálogo com sua mensagem — é ela que vira
  `last_error` quando um interno falha.
- O fluxo completo de relato (stderr único, arquivo:linha:coluna em pontos,
  status de saída) está descrito em
  [diretrizes-diagnosticos.md](diretrizes-diagnosticos.md).

## 8. Fases da compilação e dumps

- Pipeline: **lex → parse → gen**; a geração produz **um único `.k`** na pasta
  atual — todo `include` já foi colado textualmente antes da análise (um
  `#include` do C; sem módulos).
- `--lex-dump` / `--parse-dump` / `--gen-dump` interrompem no estágio
  correspondente (spec 8).
- Erros de análise são **stop-the-world**: primeiro diagnóstico, relato, exit
  ≠ 0. Não há `try` em tempo de compilação.

## 9. Decisões abertas

- Tamanho do buffer de `last_error` (proposta: 256 bytes, truncando com `...`).
- ~~Numeração do código de `outcome.fail`~~ resolvida pelo catálogo: o `i32`
  do `outcome` carrega o valor do tag (`Diag`), como `corot.tag` lê.
- Representação de `xpr_Value` (união etiquetada) — merece documento próprio
  quando o codegen começar.

## 10. Ordem sugerida de implementação

1. Catálogo: módulo `xpr/diag.k` — `tags Diag`, `DiagEntry` e tabela (fonte
   única; diretrizes-diagnosticos.md, Seção 1).
2. Lexer + `--lex-dump` (suíte `tests/` lexer).
3. Parser/AST + `--parse-dump`; rejeições de análise: bloco vazio, sobra de
   origem, alvos de
   argumento em chamada.
4. Carregamento estático de `include` com detecção de `recursive-include` e
   `file-not-found`.
5. Núcleo do runtime gerado: `xpr_Value`, helpers `outcome`, buffer de
   `last_error`, `fail`.
6. Gerador: sites das duas formas de `try`, propagação `else return` em todo
   combinador, curto-circuito, checagem de aridade nos sites de chamada, envoltório `main`.
7. Limites fatais (profundidade, orçamento) com flag fatal.
8. Suíte runtime golden (`tests/`).
