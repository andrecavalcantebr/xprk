## 2026-11-22 — Normativos: parágrafos em uma linha

- `xpr-specs-pt.md` e `xpr-rationale.md` foram reflowed: cada parágrafo e item de
  lista agora ocupa uma linha só (quebra fica por conta do editor/visualizador, para
  celular). Conteúdo idêntico ao HEAD (verificado por sequência de palavras); blocos
  de código, títulos, tabelas e contagem de itens preservados.
- Arquivos `*.md.bak` untracked continuam fora do controle de versão; não tocados.
- Commit ainda não feito; aguardando autorização do usuário.

## 2026-11-22 — Normativos reconstruídos: conformidade e descarte de valor

- Acrescentadas as duas regras que faltavam e sustentavam o resto implicitamente:
  - §0 Conformidade + R1.2: programa conforme = aceito pela análise + comportamento
    definido + independência de implementação. Falha prevista é comportamento
    definido, não violação. Sem UB. Observável = stdout + stderr + exit.
    Não-terminação não é não-conformidade. Pontos em aberto não impõem requisito.
  - §4.11 Descarte de valor + R2.1: produzir valor não obriga a consumi-lo. C1 é
    sobre o construto; descarte é sobre o contexto. Não suprime falha, não é
    preguiça, não exige marcação. Sem ela, o açúcar de `for … else` (__a/__b por
    efeito), blocos com statements intermediários e o programa que só imprime
    seriam ilegais. Recusada sintaxe explícita de descarte (R15).
- Consolida a versão fechada nas sessões anteriores: Rec substitui Module (7 tipos);
  `:` definição / `=` atribuição; sombreamento por definição, delegação por alias;
  internos nus e biblioteca qualificada; import fechado; args e entry emergente;
  try local em Rec com else default (sem binder); for de contagem com else de vazio
  (açúcar sobre iif, não sobre try); bloco vazio é erro; sem unidade/zeros por tipo;
  overflow como falha capturável.
- Verificado: slugs do índice seguem a convenção ASCII-folded do check-docs.sh;
  todo R<n> citado na spec está definido no rationale.
- Pendências (§11): step-budget; fmt globais e seus padrões; upper/lower; input EOF;
  diretório da stdlib; rethrow preservando code; aridade estática; binder no else.
- Estado: implementação em stub; projeto pausado aguardando correção do keel.