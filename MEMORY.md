# MEMORY of the project

## 2026-11-16 — Remoção de listas da especificação

- Decisões confirmadas em `xpr-specs-pt.md`:
  - Removido o tipo lista e todas as suas referências (gramática `binding_pattern`/`list_pattern`/`list_expr`, `any`, `all`, `cat`, regras recursivas de operadores e `size-mismatch`), mantendo `indexed` (`s[i]`) para indexação somente leitura de strings.
  - `fmt` substituído por duas variáveis globais predefinidas: `fmt_decimals` (padrão `2`) e `fmt_sigdigits` (padrão `15`).
  - `at([v, i])` substituído por aplicação parcial/currying estilo Haskell: `at(s)(i)` (com `s[i]` como açúcar sintático).
  - `Number` quebrado em `Integer` e `Real` (gramática, literais, operadores e conversões `integer(val)` / `real(val)`).
  - Única conversão implícita da linguagem: promoção de `Integer` para `Real`; nenhuma outra conversão implícita existe.
  - Sem tipo `char`: um caractere é uma `String` de comprimento 1 (ex.: `{ s = "Hello"; s[0]; }` devolve `"H"`).
  - Builtins atualizados: adicionado `println(x)` (insere e contabiliza `\n`); removido `bool(val)` (usar `(s == "true")`); `integer(s)` e `real(s)` fazem parse apenas de `String` (ex.: `integer(3.9)` é `type-mismatch` com dica para usar `int`/`round`/`floor`/`ceil`); `int(r)` retorna a parte inteira de `r` (truncamento).
- Nenhuma compilação ou teste foi executado (ainda na fase de revisão da especificação).

## 2026-11-17 — Pivô para transpilador, modelo de erros e base de desenvolvimento

- **Transpilador, não interpretador**: sem modo interativo, sem código via stdin/pipe; CLI = `xpr arquivo.x` (compila para **um único `.k`** na pasta atual — sem módulos), `--lex-dump`/`--parse-dump`/`--gen-dump` (param no estágio), `-h`. Seções renumeradas 4.1–4.11.
- **Carregamento estático** via `include("arquivo.x")` (colagem textual, `#include` do C; resolvido em análise; `file-not-found`/`recursive-include` = erros de análise; busca só no diretório do script). `input(prompt)` voltou a ser builtin de leitura de stdin (EOF: a especificar).
- **Blocos vazios são erro** (`empty-block`); referências a `null-block` removidas.
- **Internos somente leitura**: atribuir a builtin/`last_error`/constante é `builtin-redefinition`. Bibliotecas/stdlib futuras podem ser redefinidas.
- **Modelo de erros (4.11)**: `try` é construto (`try(expr)` sonda→bool; `try(v=expr)` captura; `try(expr,default)` valor-ou-default, default preguiçoso e desprotegido, tipos compatíveis sob promoção Int→Real); `fail(msg)` é builtin que levanta; `last_error` variável global String readonly (zerada no try bem-sucedido, gravada no levantamento); mensagens livres; profundidade (10.000) e orçamento de passos **não-capturáveis**; gerador envolve o programa num try implícito.
- **Aridade 0 ou 1**: `fn()`/`f()` liberados (thunk); `f(a,b)` segue syntax-error; `arity-mismatch` em runtime (aridade fora do tipo estático).
- **Formatação**: `fmt_decimals`=casas decimais da notação fixa; `fmt_sigdigits`=dígitos significativos da científica (**padrão 5**); 1º dígito da mantissa conta (`1234567890123456789.0` → `1.2346e+18`).
- **`upper`/`lower`** como builtins (só ASCII A–Z↔a–z); comparação sem caixa = `upper(s1)==upper(s2)` (nota em 5.2; sem builtin dedicado).
- **Implementação**: propagação de falha **um-nível** com `outcome`+`else` do keel (setjmp/longjmp proibidos — defer); arenas via defer+watermark; payload copiado no levantamento. Documentado em `docs/diretrizes-erros.md` e `docs/diretrizes-diagnosticos.md` (catálogo `XPR_DIAG_LIST` em `src/xpr.h` = fonte única; formato `arquivo:linha:col: sev: msg [id]`; exit 0/1/2; source-map de include).
- **Base de desenvolvimento**: Makefile estilo keel (`tools/keel/bin/cgen` vendored — oficial em `~/Apps/keel-0.3.0-dev`, com guarda `make keel-check`/`keel-sync` contra drift); `tmp/` para temporários (`make cleantmp`); `src/main.k` compila verde (module decl + help atualizado); `tests/run_tests.sh` (suites lexer/parser/runtime, `--list/--case/--binary/--update`, timeout 5s, temporários em tmp/); `tests/lexer/` com 8 goldens manuais (formato `LINE:COL TYPE VALUE`, col em pontos Unicode); `tests/parser/` com `subtract_left` (golden pendente) + 6 negativos (`empty-program`×3, `wrong-assignment`×3) que falham listagem até o catálogo existir. Estado TDD: `make test` vermelho (pass:0 fail:8) — correto pré-implementação.
