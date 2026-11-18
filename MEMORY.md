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

- **Transpilador, não interpretador**: sem modo interativo, sem código via stdin/pipe; CLI = `xpr arquivo.x` (compila para **um único `.k`** na pasta atual — sem módulos), `--lex-dump`/`--parse-dump`/`--gen-dump` (param no estágio), `-h`. Seções renumeradas (hoje a spec vai de 1 a 10).
- **Carregamento estático** via `include("arquivo.x")` (colagem textual, `#include` do C; resolvido em análise; `file-not-found`/`recursive-include` = erros de análise; busca só no diretório do script). `input(prompt)` voltou a ser builtin de leitura de stdin (EOF: a especificar).
- **Blocos vazios são erro** (`empty-block`); referências a `null-block` removidas.
- **Internos somente leitura**: atribuir a builtin/`last_error`/constante é `builtin-redefinition`. Bibliotecas/stdlib futuras podem ser redefinidas.
- **Modelo de erros**: `try` é construto (`try(expr)` sonda→bool; `try(v=expr)` captura; `try(expr,default)` valor-ou-default, default preguiçoso e desprotegido, tipos compatíveis sob promoção Int→Real); `fail(msg)` é builtin que levanta; `last_error` variável global String readonly (zerada no try bem-sucedido, gravada no levantamento); mensagens livres; profundidade (10.000) e orçamento de passos **não-capturáveis**; gerador envolve o programa num try implícito.
- **Aridade 0 ou 1**: `fn()`/`f()` liberados (thunk); `f(a,b)` segue syntax-error; `arity-mismatch` em runtime (aridade fora do tipo estático).
- **Formatação**: `fmt_decimals`=casas decimais da notação fixa; `fmt_sigdigits`=dígitos significativos da científica (**padrão 5**); 1º dígito da mantissa conta (`1234567890123456789.0` → `1.2346e+18`).
- **`upper`/`lower`** como builtins (só ASCII A–Z↔a–z); comparação sem caixa = `upper(s1)==upper(s2)` (nota em 5.2; sem builtin dedicado).
- **Implementação**: propagação de falha **um-nível** com `outcome`+`else` do keel (setjmp/longjmp proibidos — defer); arenas via defer+watermark; payload copiado no levantamento. Documentado em `docs/diretrizes-erros.md` e `docs/diretrizes-diagnosticos.md` (catálogo `XPR_DIAG_LIST` em `src/xpr.h` = fonte única; formato `arquivo:linha:col: sev: msg [id]`; exit 0/1/2; source-map de include).
- **Base de desenvolvimento**: Makefile estilo keel (`tools/keel/bin/cgen` vendored — oficial em `~/Apps/keel-0.3.0-dev`, com guarda `make keel-check`/`keel-sync` contra drift); `tmp/` para temporários (`make cleantmp`); `src/main.k` compila verde (module decl + help atualizado); `tests/run_tests.sh` (suites lexer/parser/runtime, `--list/--case/--binary/--update`, timeout 5s, temporários em tmp/); `tests/lexer/` com goldens manuais (hoje 12 casos) (formato `LINE:COL TYPE VALUE`, col em pontos Unicode); `tests/parser/` com positivos de golden pendente + negativos que falham a listagem até `src/xpr.h` existir (hoje 14 casos; ver entrada de 2026-11-18 parte 2 para o estado atual). Estado TDD: `make test` vermelho (pass:0 fail:8) — correto pré-implementação.

## 2026-11-18 — Chamadas encadeadas, currying e `pow`

- **Gramática (Seção 3)**: `primary`/`fn_call`/`indexed` substituídos por `postfix = atom { call_suffix | index_suffix }`. Aplicação e indexação agora são sufixos repetíveis que aninham à esquerda, então `f(x)(y)`, `at(s)(i)`, `s[i]` e `f()[0]` derivam da mesma regra. Corrige a inconsistência em que a prosa de 4.7 e a menção a `at(s)(i)` afirmavam ser válido algo que o EBNF anterior não produzia (`indexed` só repetia `[`, e `fn_call` exigia identificador).
- **Nova 5.3 "Currying e operações de duas entradas"**: com aridade ≤ 1 e congelamento de variáveis livres por cópia, **toda operação de duas entradas é curried** — é a única forma; variável global não serve como segundo operando (seria congelada na definição). Mesmo fundamento que já produzia `at(s)(i)`.
- **Ordem dos argumentos de `pow`**: `pow(x)(y)` = x^y, fixada pela operação e não por convenção de chamada (x é a base entregue a `log`, y multiplica o logaritmo). `pow(2)(3)` = 8, `pow(3)(2)` = 9. Recomendado nomear `fn(base){ fn(exponent){...}; }`.
- **Resolvida a questão do `x` livre no aninhamento**: o parâmetro da função externa conta como definido em todo o corpo (4.7), então a função interna o captura sem providência de ordem; o valor é congelado quando a definição interna é *avaliada*, isto é, durante a invocação da externa. Não há "quem vem primeiro" a decidir. A recíproca (livre que não é parâmetro nem vínculo prévio) segue `undefined-identifier` na definição. Documentado como item novo em 4.7.
- **Conflito de nome resolvido**: a constante de Euler era `exp`/`EXP` (Seção 6), colidindo com a função exponencial. Constante agora é `e`/`E`; `exp(x)` e `log(x)` passaram a ser internos (promoção Int→Real, resultado Real, domínio IEEE-754 sem erro: `log(0)` = `-INF`, `log(-1)` = `NaN`). Nota registrada: `2e3` continua sendo o literal `2000.0` (o lexer consome o expoente), então `e` só é lido onde se espera identificador.
- **`pow` é interno, não a fórmula log/exp**: a forma `exp(y*log(x))` fica na 5.3 apenas como ilustração do mecanismo de captura, com as divergências listadas (base negativa, `pow(0)(0)`, precisão). O interno acompanha `pow` do `math.h`.
- **Pendências criadas**: conjunto mais amplo de funções matemáticas (`sqrt`, trigonométricas, `abs`) segue a especificar; `pow(0)(0)` e sinal em base negativa estão definidos por delegação ao `math.h`, sem tabela própria na spec.
- **Teste adicionado**: `tests/parser/call_chain.x` (positivo, golden pendente) exercita cadeia de chamadas + currying. `make test` continua vermelho por design (`pass:0`, catálogo `src/xpr.h` e lexer ainda não implementados).
- Nenhuma compilação executada nesta rodada — alterações são apenas de especificação e fixtures.

## 2026-11-18 (parte 2) — Consolidação documental: spec/racional, léxico e despacho

Sessão longa de revisão. O eixo foi separar **definição** de **razão**, tornar a razão
normativa, e corrigir uma série de imprecisões que a revisão expôs. Nada foi compilado;
todas as mudanças são normativas ou de fixtures.

### 1. Dois documentos normativos

- **`xpr-rationale.md` criado** e depois promovido a **segundo documento normativo** —
  não é mais "explicitamente não normativo". Motivo do usuário: *o que justifica a norma
  acaba sendo norma*, e a justificativa é a base para negar/aceitar coisas futuras sem
  reanalisar. Normativo em dois sentidos: (a) **critério de admissão** — toda proposta se
  mede contra R1, e reativar item de R15 exige **refutar explicitamente** a razão
  registrada; (b) **fonte de intenção** — desempata leitura ambígua da spec, mas **nunca
  acrescenta regra ausente**.
- **Regra de sincronia** (em `AGENTS.md`): razão sem regra na spec ⇒ **a spec está
  incompleta** — corrija a spec, não o rationale. Ao mudar uma regra, atualize os dois.
- **Numeração R1..R15** com subseções R3.1–R3.4, R4.1, R7.1–R7.4. Cada seção abre com
  "Justifica: <seções da spec>". **Índice com 24 entradas**, âncoras ASCII-folded (mesma
  convenção da spec), 0 links quebrados. Regenerar **derivando dos headings**, nunca
  editando à mão.
- **R15 é o artefato anti-reanálise**: tabela de ~28 recusas com razão e origem.
- **Referências cruzadas `R<n>` na spec** (10+ inserções): tipos→R3, aridade→R4,
  recursão→R6, `import` literal→R7.2, escopo do módulo→R7.1, `%`→R5, internos→R12,
  `is_*`→R11, `print`→R13, memória→R14, léxico→R3.1–R3.3, anotação→R3.4, despacho→R4.1.
- **Reestruturação da spec**: de 917 → ~790 linhas, ordem 1 Tipos … 10 Diagnósticos;
  léxico virou §2 própria; tabela de diagnósticos passou a ser normativa em §10.

### 2. Léxico: três correções, uma delas um bug meu

- **Taxonomia (R3.1)** — `not`/`and`/`or` **não** são palavras-chave (são operadores
  alfabéticos) e `true`/`false` **não** são palavras-chave (são constantes). Critério:
  **ter ou não valor**. Palavra-chave = `fn iif for try import` (formas sintáticas).
  §2 agora separa operadores simbólicos / alfabéticos / pontuação, que antes eram uma
  lista só.
- **BUG meu**: a produção `boolean = "true" | "false"` foi **perdida** na reescrita —
  `literal` a referenciava sem definição. Restaurada em §3.
- **Consequência**: `true = 1` é `wrong-assignment` (forma), **não**
  `builtin-redefinition` (permissão). §7 virou "Constantes predefinidas" (booleanas +
  matemáticas); §6 distingue **três** classes de interno.
- **Terminadores (R3.2, R3.3)** — pergunta do usuário: `"/*" { chars } "*/"` deveria
  aceitar EOF? **Não**: `/*` sem `*/` tolerado até o EOF faz o **resto do arquivo virar
  comentário silencioso** — o programa compila e roda sem as expressões seguintes. A
  assimetria é do construto: comentário de **linha** termina em `\n` **ou EOF** porque
  **não tem delimitador de fechamento**; bloco e string têm ⇒ `unterminated-comment` /
  `unterminated-string` (dois ids novos em §10, fase de análise).
- **BUG de notação**: `chars` era "exceto aspas e `\`" e depois **reusado nos
  comentários**, proibindo `\` em `// C:\path`. Substituído por `any` e `any_not(P)` com
  **um predicado por construto**; `any_not` consome um ponto e o predicado decide se ele
  pode ser consumido — a menção a **sequência** é o que faz `/* a * b */` válido.

### 3. Sem anotação de tipo (R3.4)

- **Decisão: não haver anotação de tipo em nenhuma posição** (`fn(x: Integer)`,
  `fn: Boolean(s)`, `x: T = e`, `import` tipado) — anotação é `syntax-error`. §1 e §4.4
  explicitam.
- **Argumento decisivo**: `iif` **não exige ramos do mesmo tipo** (§4.5), então uma
  função pode ter retorno polimórfico em runtime (`describe = fn(x){ iif(is_real(x),
  "real", 0); }` devolve `String` **ou** `Integer`). Anotar exigiria **união de tipos** —
  feature estruturalmente maior que listas/registros. Aceitar `fn: Boolean(s)` obriga a
  aceitar `fn: Integer|String(x)`.
- **Segundo argumento**: com tipagem dinâmica, anotação só é verificável onde a
  inferência já sabe (ganho zero) ou vira checagem em runtime que produz o mesmo
  `type-mismatch` (ganho = mensagem mais cedo, custo = anotação em toda função).
- **Terceiro**: contrato de chamada = `arity-mismatch`; inspeção = `is_*` + `iif` (R11);
  documentação = corpo de **1 expressão a 1 parâmetro**.
- **Se um dia entrar**, o caminho é opcional e verificável (o `:` já está livre, R8) —
  mas exige decidir união de tipos antes.

### 4. Despacho por valor de função (R4.1)

- **Observação do usuário**: `iif(x=="myfunc", myfunc, otherfunc)("hello")` funciona e é
  poderoso. **Confirmado, registrado e corrigido no vocabulário**: não é polimorfismo; são
  **três mecanismos ortogonais** — (a) **união dinâmica** do tipo em runtime; (b)
  **seleção de valor** (`f = iif(c,g,h)`); (c) **despacho** (`iif(c,g,h)(x)`).
- **Por que é estrutural (custo zero em regras)**: depende de três decisões já tomadas
  por outros motivos — (1) `iif` devolve qualquer tipo e **não unifica ramos** (§4.5);
  (2) `Function` é valor e **a aridade não faz parte do tipo** (§1) — sem isso
  `iif(c,f0,f1)` exigiria mesma aridade; (3) `call_suffix` se aplica a **qualquer `atom`**
  (§3), inclusive `iif`. É o caso mais forte da tabela de R1.
- **Ligação com R3.4**: a união dinâmica é o que permite `iif(c,1,"a")` **e** o que torna
  anotação de tipo cara — mesma decisão, dois ângulos.
- **Limite honesto**: é *despacho dinâmico com closure*, não polimorfismo paramétrico. O
  erro de escolha só aparece na chamada; recomenda-se `fail` no ramo final do `iif`
  aninhado para gerar diagnóstico nominal.
- **ERRO MEU corrigido**: eu havia escrito uma "tabela de despacho" acumulando `ops`
  dentro de um `for`. **Impossível** — `for` devolve a contagem e o corpo é descartado
  (§4.6, R2). Substituído por **`iif` aninhado** + parágrafo "Limite registrado: `for` não
  acumula" com o contraexemplo. Mesma limitação que motiva `list(n)(f)` (R9).

### 5. Estado dos artefatos

- **Spec**: §3 documenta que `iif`/`for`/`try`/bloco/`import` são `atom` e aceitam
  `postfix` direto. §4.4 ganhou "Seleção de função e despacho" e "Tabela de despacho".
- **Rationale**: R3.1, R32–R3.4, R4.1, R14 (arena explica o que §4.9 garante: §4.9 é
  independência *observável*; R14 é como a implementação a obtém sem copiar tudo). R8/R9
  distinguem **recusa** (structs) de **adiamento** (listas).
- **Referências de `docs/` corrigidas** para a numeração atual: `diretrizes-erros.md`
  (§§4.5, 4.7, 6.7 e 8) e `diretrizes-diagnosticos.md` (§§10).
- **Fixtures** — lexer 12 casos: `keywords` reduzido às 5 palavras-chave,
  `operators_words` novo (OP vs KEYWORD), `unterminated_{comment,string}` novos (NEG),
  `modulo` (pending). Parser 14: `dispatch_call`, `call_chain`, `module_value`,
  `subtract_left` (POS pending) e negativos `annotated_{param,return}` (`syntax-error`),
  `wrong_assignment_*`, `empty_program_*`.
- **`MISSING-IN-CATALOG` é o estado esperado**: `src/xpr.h` ainda não existe, então todo
  `.diag` falha a listagem. `make test` segue vermelho por construção (fase TDD).
- **Pendência sugerida, não feita**: `tools/check-docs.sh` rodando as duas verificações
  (índice↔headings; `R<n>` citado na spec existe no rationale) junto de `make tests`.

## 2026-11-19 — C1 "tudo é expressão" é o critério PRIMÁRIO de admissão

- **Ponto do usuário**: nos critérios de admissão, o primeiro é **TUDO É EXPRESSÃO** — uma feature que entra como construto especial **não é XPR**. R1 estava com "regra da simplicidade" como critério primário, o que é a ordem errada: um construto pode **reduzir** o número de regras e ainda assim ser recusado, porque custo de construto não se mede em regras.
- **R1 reescrito com critérios em ORDEM (filtros, não trade-off)**: **C1** Tudo é expressão (categórico) → **C2** regra da simplicidade → **C3** mecanismos existentes → **C4** falha cedo. Uma proposta que falha em C1 não passa para C2.
- **O que C1 enumera**: um construto cria de uma vez (a) posição sintática nova, (b) segunda gramática, a de "instruções", que §3 não tem, (c) a pergunta recorrente "que valor devolve?", (d) exceções de composição (não compõe com `iif`, não vira argumento/campo/retorno).
- **Teste operacional que C1 fixa**: *que valor a feature produz?* Se "nenhum, é só efeito/declaração", está mal enquadrada — provavelmente existe um valor por trás. Ache o valor e vira expressão; não ache, não entra.
- **Nova R1.1 documenta `import` como caso-escola**: enquanto foi construto, exigiu **três remendos** — segundo argumento de alias, `qualified_name` como classe de literal, e semântica "colado no ambiente léxico do chamador". Nenhum era problema de módulos: os três eram sintomas de C1 violado (construto sem valor precisa que a linguagem lhe dê nome, acesso e escopo, um a um). Reconhecido que `import` produz uma **referência ao módulo**, os três caíram **juntos, sem substituição**. Lição registrada: o construto não era mais simples, era mais caro disfarçado.
- **Sinal de alarme em R1.1**: proposta que pede 2+ de {nome próprio, forma de acesso, regra de escopo, posição sintática} ao mesmo tempo ⇒ a causa provável é que o **valor da feature não foi identificado**.
- **Novo bloco em R2**: "R2 é o alicerce e C1 é o guardião" — R2 descreve o resultado, C1 é o filtro que o mantém.
- **Spec**: novo parágrafo no topo ("**Não existe construto sem valor**", com link para C1). TOC do rationale: 29 entradas (C1–C4 agora entram no índice), 0 quebradas.
- **`tools/check-docs.sh` (novo)** + alvo `make check-docs` (ligado a `make test`): valida (1) todo link de índice resolve, (2) todo heading de seção está no índice, só títulos numerados `N.`/`N.M`/`R<n>`/`C<n>`; ignora "Índice" e prosa, (3) todo `R<n>` citado na spec existe no rationale, (4) links cruzados entre os dois docs. **Testado com falhas plantadas** (link quebrado + heading órfão + R inexistente): acusa as três e sai 1; restaurado, sai 0.
- **Bug de convenção que o checker expôs**: âncora tem de ser ASCII-folded **descartando** pontuação, não convertendo em hífen — `C1 — Tudo é expressão` → `c1--tudo-e-expressao` (dois hífens), não `c1---tudo-...`. O checker pegou isso na primeira execução.
- **`README.md` reescrito**: estava desatualizado desde o pivô (dizia "Interpretador", "carregamento dinâmico de expressões", `xpr-specs.md`, e não mencionava o rationale). Agora: transpilador, dois normativos com a divisão, `make check-docs`, estrutura real.

## 2026-11-19 (b) — Lista passa em C1: "nada impede um construtor de listas"

- **Confirmação do usuário**: "tudo é expressão" é a característica **primária** de XPR — é o que a torna extremamente simples. Qualquer tipo de dado que entrar segue essa regra, **inclusive list**. E "nada impede um construtor de listas".
- **Nova R9.1 — `Lista passa em C1: é valor, logo é expressão`**: lista é **tipo de dado**, não construto: produz valor (a própria lista), entra como `atom`, não cria posição sintática nova, compõe com `iif`/`fn`/bloco. Tabela comparando construto (recusado) × lista (aceita) em quatro linhas: devolve valor / posição sintática / composição / segundo parâmetro.
- **Correção de terminologia importante**: `list(n)(f)` *parece* construtor privilegiado porque a palavra "construtor" sugere construto. **Não é construto** — `list` é **interno** (§6), como `pow`, e `list(n)(f)` é aplicação curryficada coberta por `postfix` + R4. O que é privilegiado é **existir como interno** (não se pode escrever em XPR puro), não a forma sintática. Mesma distinção que separa `print` (interno) de `fn` (forma sintática). Terminologia de R9 ajustada para "único interno privilegiado de construção".
- **O que C1 de fato proíbe em listas**: construtor que **não devolva valor** — `list { ... }` como bloco de inicialização, `new l = []` como declaração. A forma aceita é a que já existe: literal `[a, b]` como `atom` + `list(n)(f)` como chamada.
- **A disciplina que C1 impõe ao desenho de listas** explica cada linha da tabela de R9: `l[i]` reusa `index_suffix`; a árvore de operações é expressão; **`for` não constrói lista** (devolve contagem, R2) — daí a necessidade de `list(n)(f)` e não de um construto de laço.
- **Spec**: §1 ganhou "**Todo tipo novo é valor, e todo valor é expressão**" (inclusive `List`, R9) — nenhum tipo criado só por construto, nenhum precisando de posição sintática própria. §4.6 explicita "`for` **não** constrói coleções; acumular é trabalho de `list(n)(f)` e `fold` (R9, R9.1)".
- **R15**: 2 linhas novas — "construção de lista sem `list(n)(f)`" (reformulada) e "construtor de lista como construto (`list { ... }`, `new l = []`) ⇒ viola C1".
- **TOC**: 30 entradas no rationale, 0 quebradas. `make check-docs` verde.
