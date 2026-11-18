<!--
   FILE: diretrizes-diagnosticos.md
   DESC: Implementation guidelines for the XPR diagnostic reporting flow (catalog module, format, exit codes).
   AUTHOR: Andre Cavalcante with AI partner
   DATE: November, 2026
   LICENSE: GPL-v3
-->

# Diretrizes de Implementação — Diagnósticos

Este documento descreve o **fluxo de relato de diagnósticos** do transpilador
xprk. A semântica normativa está em [xpr-specs-pt.md](../xpr-specs-pt.md),
Seção 10 — em caso de conflito, a especificação prevalece. O tratamento de
erros **capturáveis** em tempo de execução (`try`/`fail`/`last_error`) é assunto
de [diretrizes-erros.md](diretrizes-erros.md); este documento cobre o que é
**relatado**: tudo que passa pelo stderr e decide o status de saída.

## 1. Fonte única: o catálogo é um módulo keel

- O catálogo mora no módulo `xpr/diag.k` (`module xpr.diag;`), consumido por
  `import xpr.diag;`. Keel não tem cabeçalho escrito à mão: a interface de cada
  módulo (os `.h`) é gerada pelo `cgen`, e `pub`/`priv` decidem o que atravessa.
- O conjunto fechado de códigos é um `tags Diag` — um tag por linha das tabelas
  da Seção 10 da especificação, com valor explícito e estável. Um conjunto de
  tags gera um enum C **com identidade de tipo**: código de diagnóstico não se
  mistura com qualquer `i32` em silêncio — o mesmo argumento de `corot.Status`
  na base do keel contra `typedef i32`.
- A tabela é um `typedef struct DiagEntry` + `array DiagEntry table[N]`. **A
  linha é a fonte única**: cada linha liga a constante do conjunto, o
  identificador público (kebab-case, estável — é ele que aparece entre
  colchetes), a severidade (`error` | `warning` | `info`), o modelo de mensagem
  e a dica opcional. Não há macro X, nada é derivado por preprocessor, nada é
  duplicado em outro documento.
- Transporte: `outcome` carrega o código como `i32` (`outcome.fail(r, código)`);
  o tag é uma **leitura**, não o transporte — o precedente é `corot.tag`. O
  relato final resolve a linha por busca no código e formata.
- `match` sobre `tagged Diag void` dá despacho **exaustivo verificado pelo
  cgen** quando um tratamento por código for necessário. Severidade e mensagem,
  porém, vêm da linha da tabela — `match` não substitui o dado.
- **Nota de versão** (cgen v0.2.0, verificado em probe): constante de `tags`
  qualificado **entre módulos** (`diag.Diag.SIZE_MISMATCH`) ainda não é baixado
  ao nome C; dentro do próprio módulo, baixa correto. Até a correção no keel,
  pontes derivadas cruzam módulos com o padrão `pub constexpr i32 ERR_X = X;`
  (o caminho de `coll.EMPTY`, golden 007) — o conjunto continua sendo a fonte.
- **Runtime**: o programa gerado também precisa dos códigos em execução, e a
  especificação (Seção 9) manda a transpilação sair em **um único `.k`**. O
  gerador injeta no arquivo gerado os tags e a tabela que ele mesmo usa — a
  cópia nasce do mesmo módulo, nunca editada à mão. É a "biblioteca em código
  host" da terceira categoria de R12.
- As tabelas da Seção 10 nomeiam **condições semânticas**; o catálogo define o
  identificador público e a apresentação. Uma condição exigida e ausente do
  catálogo é tarefa de implementação pendente, não uma permissão.

## 2. Formato do relato

```
<arquivo>:<linha>:<coluna>: <severidade>: <mensagem> [<id>]
    hint: <dica>                 (apenas quando houver)
```

- **Linhas** contam a partir de 1; **colunas contam em pontos Unicode**, não em
  bytes — a mesma régua do lexer (especificação, Seção 10).
- Diagnósticos **sem** localização de origem (erro de invocação, arquivo
  ausente) relatam o arquivo, a operação ou o argumento relevante no lugar da
  posição.
- Trechos de origem citados na mensagem passam pela **sanitização de pontos de
  controle** (o mesmo caminho do texto de strings em `diagnostic.c`): nada de
  escapes crus vazando no terminal.
- Cada diagnóstico é relatado **uma única vez**, no stderr.

## 3. Fases e política de parada

- **Análise (lex, parse, resolução de `import`) é stop-the-world**: o primeiro
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

## 6. Localização através de `import`

- `import` não cola texto: cada arquivo importado é analisado como unidade
  própria, e um erro no seu corpo aponta para
  `arquivo-importado.x:linha:coluna` **naturalmente** — não há mapa de origem
  a manter, porque não há colagem que apague fronteiras.
- A pilha de importações em resolução continua necessária para detectar
  `recursive-import`: o ciclo é da análise (a dependência), não da posição.

## 7. Decisões abertas

- Cores no stderr quando terminal (seguir detecção do keel? sempre off com
  `NO_COLOR`?).
- Limites de truncamento de trechos de origem na mensagem.
- `-Wno-<id>` / `-Werror` na CLI do xpr.
- Tradução de mensagens (hoje: português na spec, inglês no código — catálogo
  define o idioma final das mensagens).
- Correção do cgen (baixa de constante `tags` entre módulos) versus pontes
  `constexpr` permanentes — reavaliar quando o keel upstream mudar.

## 8. Checklist mínimo

1. Módulo `xpr/diag.k`: `tags Diag` + `DiagEntry` + tabela (fonte única;
   pontes `constexpr` enquanto o cgen não corrigir a baixa entre módulos).
2. Ponto único de relato (stderr, formato da Seção 2, sanitização).
3. Colunas em pontos Unicode do lexer até o relato.
4. Pilha de importações com detecção de `recursive-import`.
5. Status de saída 0/1/2.
6. Injeção dos tags e da tabela no `.k` gerado (runtime, arquivo único).
7. Suíte de testes golden com saídas de diagnóstico literais (`tests/`).
