<!--
   FILE: README.md
   DESC: Explain lexer/parser fixtures, future contracts, and the test runner.
   AUTHOR: Andre Cavalcante with GPT Sol 6.1 AI Model partner
   DATE: November, 2026
   LICENSE: GPL-v3
-->

# Testes do XPRK

Esta pasta contém os testes necessários para a validação do compilador xprk

## Executar ou listar

O executor usa Bash (4 ou posterior), awk e coreutils. 

```sh
bash tests/run_tests.sh --suite lexer --list
bash tests/run_tests.sh --suite parser --list
bash tests/run_tests.sh --suite runtime --list
bash tests/run_tests.sh --suite all --list
bash tests/run_tests.sh --suite lexer
bash tests/run_tests.sh --suite parser
bash tests/run_tests.sh --suite parser --case subtract_left
bash tests/run_tests.sh --suite runtime
```

`--list` confere catálogos e arquivos, sem iniciar o XPR e sem criar temporários.
Uma expectativa negativa ausente do catálogo também faz a listagem falhar.
No estado atual, os seis casos do parser com `empty-program` ou
`wrong-assignment` impedem a execução/listagem completa de `parser` e `all`.
Eles não são ignorados nem substituídos por outros erros. Use `--case` para
selecionar um caso cuja definição já exista; somente o diagnóstico selecionado
é resolvido, mantendo as verificações de integridade dos arquivos da suíte.
A suíte padrão continua sendo lexer. Use `--binary /caminho/xpr` ou `XPR` para
selecionar o executável. O timeout padrão é cinco segundos por caso.

Os argumentos de modo têm os padrões da tabela. A primeira ocorrência de
`--lexer-arg` ou `--parser-arg` substitui o padrão da respectiva suíte; ocorrências
seguintes acrescentam argumentos. Um valor vazio remove todos os argumentos de
modo. Isso permite consultar um binário histórico que já faça dump sem flag:

```sh
bash tests/run_tests.sh --suite lexer --lexer-arg= --binary /caminho/xpr-antigo
```

Esse binário histórico pode ser útil para comparar positivos preservados; não
se espera que satisfaça o novo contrato de diagnósticos negativos.





## Layout dos casos (implementação do runner)

- `tests/<suíte>/<caso>.x` — entrada do caso.
- `tests/<suíte>/<caso>.expected` — golden: stdout esperado do modo da suíte;
  ausente ⇒ o caso é **pending**, não é falha (golden nasce com `--update`
  quando o xprk passa a produzir o dump).
- `tests/<suíte>/<caso>.diag` — caso negativo: uma linha com o id do diagnóstico
  esperado no stderr, na forma `[id]`. `--list` falha se o id não constar no
  catálogo (`src/xpr.h`).
- Temporários do runner moram em `tmp/` do projeto — nunca no `/tmp` do sistema.

## Formato do dump do lexer (golden)

Uma linha por token: `LINE:COL TYPE VALUE`.

- `LINE` e `COL` são 1-based; `COL` conta **pontos Unicode**, não bytes.
- `TYPE` ∈ `INTEGER`, `REAL`, `STRING`, `IDENT`, `KEYWORD`, `OP`, `EOF`.
- `VALUE` é a fatia exata do fonte (tokens `STRING` incluem as aspas tal como
  escritas); `EOF` não tem `VALUE`.
- Comentários não são tokens (o lexer os ignora).
- `EOF` é reportado na posição seguinte ao último caractere; com o `\n` final
  padrão dos arquivos, cai em `(última_linha+1):1`.

## Atualizando goldens

```sh
bash tests/run_tests.sh --suite lexer --update   # regenera .expected dos casos bem-sucedidos
```

`--update` só abençoa casos cujo processo sai com 0; falhas continuam falhando.
