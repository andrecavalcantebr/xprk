# Transpilador XPR

XPR é uma linguagem orientada a expressões: cada construto devolve um valor e um
programa inteiro é uma única expressão. Não há comandos, não há construto sem
valor. O transpilador `xprk` traduz XPR para [keel](keel-manual.md) e aciona a
compilação final.

Dois documentos normativos, com divisão obrigatória:

- [`xpr-specs-pt.md`](xpr-specs-pt.md) — **definições**: o que a linguagem é.
- [`xpr-rationale.md`](xpr-rationale.md) — **razões**: por que cada regra existe,
  o que foi recusado. Normativo para admissão de mudanças (critérios em R1,
  recusas em R15). Uma recusa só é reativada refutando a razão registrada.

## Compilar e testar

- `make`: compila o binário `xprk`.
- `make test`: roda `check-docs` (ver abaixo) e depois `tests/run_tests.sh`.
- `make check-docs`: valida a integridade dos dois normativos — todo link de
  índice resolve, todo heading de seção está no índice, todo `R<n>` citado na
  spec existe no rationale, e os links entre os dois documentos resolvem.
  Não compila nada.
- `bash tests/run_tests.sh`: verifica o binário existente sem compilar.
- `bash tests/run_tests.sh --suite lexer --list`: lista e valida as fixtures.
- `bash tests/run_tests.sh --suite lexer --update`: regenera goldens.
- `make clean`: remove `obj/`, `gen/` e o binário.

## Uso

- `xprk arquivo.x`: transpila, compila e executa.
- `xprk --lex-dump arquivo.x` / `--parse-dump` / `--gen-dump`: param no estágio
  e despejam o resultado.
- `xprk -h`: ajuda e versão.

## Estrutura

- `src/` — fonte do transpilador, em **keel** (`src/main.k`).
- `tests/` — suites `lexer/`, `parser/`, `runtime/`, dirigidas por
  `tests/run_tests.sh` (ver [`tests/README.md`](tests/README.md)).
- `tools/` — `check-docs.sh` (integridade dos normativos), `keel-tool.sh`
  (guarda da cópia vendorizada do toolchain) e `clean-tmp.sh`.
- `docs/` — diretrizes de implementação para diagnósticos e erros. Não são
  normativos: em conflito, a especificação prevalece.
- `MEMORY.md` — memória cronológica do projeto, decisão por decisão.
