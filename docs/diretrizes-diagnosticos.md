<!--
   FILE: diretrizes-diagnosticos.md
   DESC: Implementation guidelines for the XPR diagnostic reporting flow (catalog, format, exit codes).
   AUTHOR: Andre Cavalcante with AI partner
   DATE: November, 2026
   LICENSE: GPL-v3
-->

# Diretrizes de Implementação — Diagnósticos

Este documento descreve o **fluxo de relato de diagnósticos** do transpilador
xprk. A semântica normativa está em [xpr-specs-pt.md](../xpr-specs-pt.md),
Seção 7 — em caso de conflito, a especificação prevalece. O tratamento de
erros **capturáveis** em tempo de execução (`try`/`fail`/`last_error`) é assunto
de [diretrizes-erros.md](diretrizes-erros.md); este documento cobre o que é
**relatado**: tudo que passa pelo stderr e decide o status de saída.

## 1. Fonte única: o catálogo

- `XPR_DIAG_LIST` em `src/xpr.h` é a única definição de códigos de diagnóstico,
  identificadores públicos, severidades, modelos de mensagem e dicas.
  `XprErrorCode` e `XPR_DIAG_TABLE` são **derivados** do catálogo por macro —
  nunca escritos à mão, nunca duplicados em outro documento.
- Os nomes usados na especificação (`empty-block`, `builtin-redefinition`,
  `file-not-found`, `recursive-include`, `type-mismatch`,
  `undefined-identifier`, `lvalue-in-closure`, `syntax-error`) nomeiam
  **condições semânticas**; o catálogo define o identificador público e a
  apresentação. Uma condição exigida e ausente do catálogo é tarefa de
  implementação pendente, não uma permissão.
- Campos sugeridos por entrada do catálogo: código interno, identificador
  público (kebab-case, estável — é ele que aparece entre colchetes), severidade
  (`error` | `warning` | `info`), modelo de mensagem, dica opcional.

## 2. Formato do relato

```
<arquivo>:<linha>:<coluna>: <severidade>: <mensagem> [<id>]
    hint: <dica>                 (apenas quando houver)
```

- **Linhas** contam a partir de 1; **colunas contam em pontos Unicode**, não em
  bytes — a mesma régua do lexer (especificação, Seção 7).
- Diagnósticos **sem** localização de origem (erro de invocação, arquivo
  ausente) relatam o arquivo, a operação ou o argumento relevante no lugar da
  posição.
- Trechos de origem citados na mensagem passam pela **sanitização de pontos de
  controle** (o mesmo caminho do texto de strings em `diagnostic.c`): nada de
  escapes crus vazando no terminal.
- Cada diagnóstico é relatado **uma única vez**, no stderr.

## 3. Fases e política de parada

- **Análise (lex, parse, carga de `include`) é stop-the-world**: o primeiro
  `error` encerra a fase; não há acumulação, não há geração de `.k`. Erros de
  sintaxe são detectados até dentro de corpos de função nunca chamados.
- **Geração**: erros do gerador seguem o mesmo fluxo — primeiro `error` para
  tudo.
- **Execução**: apenas o erro **não capturado** chega aqui, via envoltório
  `try` do `main` (ver diretrizes-erros.md): relato único de `last_error` e
  status ≠ 0. Erro capturado por `try` nunca passa por este fluxo.
- `warning` não impede a continuação; `info` nunca impede. (Silenciamento
  `-Wno-<id>` / promoção `-Werror`, no estilo do keel, é decisão aberta.)

## 4. Status de saída

| Status | Condição |
| --- | --- |
| `0` | sucesso (inclui execução com erros capturados por `try`) |
| `1` | pelo menos um diagnóstico de severidade `error` |
| `2` | erro de invocação da ferramenta (opção inválida, arquivo-fonte ausente) |

Espelha a convenção do keel (manual, Seção de exit codes) e satisfaz a regra da
especificação ("status diferente de zero").

## 5. Propagação e limpeza (sem `abort()`)

- "Abortar" significa: propagar a falha por `outcome` (um nível por retorno) até
  o ponto de relato, executando os `defer`s no caminho — **nunca** `abort()` de
  C, `exit()` no meio do avaliador ou `longjmp`.
- Um único ponto do processo escreve no stderr e decide o status final.
- Efeitos já realizados (saída impressa, arquivos escritos) não são desfeitos.

## 6. Localização através de `include`

- A colagem textual apaga as fronteiras de arquivo; o carregador precisa manter
  um **mapa de origem** (pilha de inclusões) para que um erro em arquivo
  carregado aponte para `arquivo-incluído.x:linha:coluna` — não para a posição
  do `include`.
- A pilha de inclusões é a mesma que detecta `recursive-include`; um só
  mecanismo serve aos dois.

## 7. Decisões abertas

- Cores no stderr quando terminal (seguir detecção do keel? sempre off com
  `NO_COLOR`?).
- Limites de truncamento de trechos de origem na mensagem.
- `-Wno-<id>` / `-Werror` na CLI do xpr.
- Tradução de mensagens (hoje: português na spec, inglês no código — catálogo
  define o idioma final das mensagens).

## 8. Checklist mínimo

1. `XPR_DIAG_LIST` + derivações (`XprErrorCode`, `XPR_DIAG_TABLE`) em
   `src/xpr.h`.
2. Ponto único de relato (stderr, formato da Seção 2, sanitização).
3. Colunas em pontos Unicode do lexer até o relato.
4. Mapa de origem da pilha de `include`.
5. Status de saída 0/1/2.
6. Suíte de testes golden com saídas de diagnóstico literais (`tests/`).
