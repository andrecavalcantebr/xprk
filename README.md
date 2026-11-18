# Interpretador XPR

XPR é uma linguagem orientada a expressões onde cada construto devolve um valor. Ela oferece carregamento dinâmico de expressões externas e funções de primeira classe.

## Compilar e testar
- `make`: compila o binário `xpr`.
- `make test`: compila primeiro, depois executa a suíte de lexer através de `tests/run_tests.sh`.
- `bash tests/run_tests.sh`: verifica o binário existente sem compilar.
- `bash tests/run_tests.sh --suite runtime --list`: lista e valida as futuras fixtures de tempo de execução.
- `bash tests/run_tests.sh --suite runtime`: executa contratos de tempo de execução positivos e negativos; estes exigem que o parser e o avaliador estejam implementados.
- `make clean`: remove `obj/` e o binário.

## Uso
- `xpr arquivo.x`: Avalia o script XPR contido no arquivo especificado e gera gen/arquivo.k que será compilado e executado.

## Estrutura do Projeto
- `src/`: Código-fonte e cabeçalhos.
- `tests/`: Conjuntos de testes — `lexer/` (dump de tokens), `parser/` (futuras fixtures `--ast`/de sintaxe) e `runtime/` (contratos de execução).
- `/`: `xpr-specs.md` (especificação da linguagem), `MEMORY.md` (memória do projeto), `keel-llm-context.md` e `keel-manual.md` (a linguagem de programação).
- `Makefile`: Sistema de construção.

Veja [tests/README.md](tests/README.md) para verificações de saída exata, diagnósticos negativos e a distinção entre fixtures de lexer e contratos de runtime.

## Licença
GPL-v3
