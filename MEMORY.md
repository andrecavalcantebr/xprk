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
- **Pendência sugerida, agora FEITA** (ver seção de 2026-11-19): `tools/check-docs.sh`
  + `make check-docs`, ligado a `make test`.

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

## 2026-11-19 (c) — Estado do repositório e briefing para a sessão de listas

### Onde as coisas estão

- **Commits**: `5c4c530` (rationale normativo, R1..R15, taxonomia do léxico) e
  `f6dcfeb` (C1 como critério primário, R1.1, R9.1, `check-docs`). `main` = `origin/main`.
- **Tamanhos**: spec 804 linhas, rationale 771, MEMORY ~250. Índice do rationale com
  **30 entradas**, 0 âncoras quebradas; spec 26/26.
- **`make check-docs` verde.** Valida: índice ↔ headings (só títulos numerados `N.`/`N.M`/
  `R<n>`/`C<n>`; ignora "_Índice_" e prosa), `R<n>` citado ↔ definido, links cruzados
  entre os dois normativos. **Testado com falhas plantadas** (link quebrado + heading
  órfão + R inexistente): acusa e sai 1.
- **Fixtures**: lexer 12, parser 14. `make test` segue **vermelho por construção**
  (`MISSING-IN-CATALOG`: `src/xpr.h` não existe; e os `POS` estão `pending-golden`).
  **Nada foi compilado até hoje** — o projeto está inteiro em fase de especificação.
- **`xpr-specs-pt.md` é a fonte das definições; `xpr-rationale.md` é normativo também**
  (admissão + desempate + R15). Regra: razão sem regra na spec ⇒ corrija a **spec**.

### Briefing: a próxima sessão é sobre listas

O desenho já acordado está em **R9** (tabela de 9 linhas) e o enquadramento em **R9.1**.
**C1 não está em discussão** — lista é tipo de dado, logo expressão; aprovada. O que
falta são decisões de detalhe, e várias delas têm **tensão real** com regras já escritas:

1. **`==` entre listas devolve `[bool]` — e isso fura a §5.** Confirmado na spec: a
   tabela de operadores dá `Boolean` para `==` em **todos** os tipos (`Function` e
   `Module` dão `type-mismatch`). Lista seria a **única exceção** da tabela. R9 hoje
   assume `==` → `[bool]` e por isso declara `any`/`all` "obrigatórios". **A premissa
   merece reexame**: `==` estrutural (devolvendo `Boolean`) é mais útil, mantém §5
   intacta e **elimina `any`/`all` como internos** — o que também reduz R12. A
   contrapartida: `==` estrutural sobre lista aninhada é recursivo, e isso é regra
   nova (mas uma só, contra duas de `any`+`all` mais a exceção em §5).
2. **Lista aninhada.** `[[1,2]] == [[1,2]]` sob regra elemento a elemento daria
   `[[bool]]`, e `any`/`all` não consomem isso diretamente. Se `==` for estrutural,
   o problema desaparece. **As duas questões 1 e 2 são a mesma.**
3. **`len` e `at` são String-only (§6.4).** Lista precisa de comprimento e acesso.
   Opções: (a) tornar `len`/`at` polimórficos — **contraria R11/"sem sobrecarga"**;
   (b) `at(s)(i)` continua String e lista ganha `l[i]` com regra própria de `index_suffix`;
   (c) `at` vira biblioteca com `is_*`. **Decidir antes de escrever a seção.**
4. **`is_list`** é obrigatório por R11 ("um tipo, um predicado"). Entra em §6.6 e na
   tabela de R11.
5. **`size-mismatch`** é diagnóstico novo — precisa entrar na tabela de §10 (fase de
   execução) e a linha de R15 que já o cita.
6. **Literal heterogêneo**: `[1, 2.0]` → `[Real]` por promoção; `[1, "a"]` → qual id?
   (`type-mismatch` provavelmente, mas é uma mensagem sobre o *literal*, não sobre um
   operando — ver se cabe em `diretrizes-diagnosticos.md`).
7. **`list(n)(f)`**: `f` recebe o índice; e se `n` for negativo ou não-`Integer`?
   (provavelmente `index-out-of-range` / `type-mismatch`, mas fixar).
8. **`print`/`string` de lista (R13).** `Function` → `<function>`, `Module` →
   `<module arq.x>`. Lista precisa de formato: `[1, 2, 3]`? Com que separador, e com que
   notação de `Real` (usa `fmt_decimals`/`fmt_sigdigits`, §6.2)?
9. **Cópia e arena (R14).** Lista é valor no escopo; ao escapar do escopo, precisa
   estar na arena de destino. Mesma regra de §4.9, mas a **lista de elementos** é o
   primeiro valor de tamanho variável — vale conferir se R14 cobre sem regra nova.
10. **Notação de tipo `[int]`** existe **só em diagnóstico** (R9). Não pode vazar para
    `print` de valor nem virar sintaxe.

### Ordem sugerida de trabalho

1. Fechar questões **1+2** (uma decisão: `==` estrutural ou `[bool]`). Elas determinam
   se `any`/`all` existem como internos — e isso muda R9, R12 e a tabela de §5.
2. Fechar **3** (`len`/`at` × `l[i]`), porque define se R11 ganha exceção.
3. Escrever **§1** (tipo `List` na tabela), **§3** (`list_literal` em `atom`), **§5**
   (linha `List` na tabela de operadores), **§6** (`is_list`, e o que for decidido em 3),
   **§10** (`size-mismatch`).
4. Depois é que o rationale ganha a seção nova (R9.2+), nunca antes — a spec é a
   definição.
5. Rodar `make check-docs` a cada passo.

### Armadilha a evitar nesta sessão

O erro que já aconteceu duas vezes (com `import` e com a "tabela de despacho" em `for`):
**desenhar a sintaxe antes de fixar o valor**. Antes de propor `[a, b]`, responder "que
valor a lista produz e como ele se compõe com `iif`/`fn`/`for`". A segunda armadilha
específica de listas: **assumir que `for` constrói** — não constrói (devolve contagem,
R2), e é por isso que `list(n)(f)` existe.

## 2026-11-20 — Listas: todas as decisões fechadas; escrita da spec pendente

> Sessão de DISCUSSÃO — o usuário pediu "não altere ainda nada". ZERO edições em
> spec/rationale. Tudo abaixo está DECIDIDO com o usuário; falta só executar o
> plano do fim desta entrada. (Usuário chamou a sessão de "18/11"; datada 20/11
> para preservar a ordem cronológica do arquivo.)

### 1. O sétimo tipo

- `List`: sequência homogênea de valores de um mesmo tipo; `[T]` existe SÓ em
  diagnóstico (nunca sintaxe, nunca `print`). §1 ganha a linha; "Seis tipos" →
  "Sete tipos".
- Homogeneidade sob a única promoção: `[1, 2.0]` é `[Real]`; `[1, "a"]` →
  `type-mismatch`. Vale para o literal E para `list(n)(f)` com `f` polimórfico
  (checagem dinâmica em execução).
- `[]` tem tipo `[?]`, compatível com qualquer `[T]`. **Exceção única em §4.2**:
  atribuir `[]` NÃO fixa o tipo do vínculo; fixa a primeira atribuição de `[T]`
  concreto. Usuário pediu destaque explícito: "é a primeira exceção a uma regra".
- `Integer` muda **64 → 32 bits** (só a linha da tabela §1; verificado). Razões:
  promoção `Integer`→`Real` passa a ser SEMPRE exata (i64 perderia acima de
  2^53); `int` de C / SIMD 8 lanes. Custo aceito: contagens limitadas a 2^31
  (`count_reals` de SLM > ~2.1B pesos estoura; leitura por camada segue ok).
  Hipótese futura anotada: tipo `size` estilo `size_t` para comprimentos.

### 2. Vetorização: uma regra única (recusada a exceção do `==`)

- TODOS os operadores de §5 aplicam a listas elemento a elemento, por UMA regra:
  comprimentos iguais (senão `size-mismatch`); resultado com o comprimento comum,
  cada elemento = resultado escalar da tabela §5, listificado. **Recursiva por
  construção**: elemento lista invoca a mesma regra (`[[1,2]] + [[10,20]]` →
  `[[11,22]]`); matriz/tensor = lista de listas, sem tipo novo.
- `==`/`!=` → `[Boolean]`. Usuário RECUSOU `==` estrutural com o argumento dele:
  "abrimos uma exceção para UMA operação porque parece que simplifica e acabamos
  com várias exceções adiante". Igualdade estrutural é o **idioma
  `all(l1 == l2)`**. Registrar recusa em R15.
- `and`/`or`/`not` vetorizam; exigem `Boolean` por elemento (a exigência vem da
  §5; sem regra própria — a recursão é só a da regra geral). Unários vetorizam:
  `-[1,2]` → `[-1,-2]`, `not [true]` → `[false]`.
- `fn`/`module` propagam o `type-mismatch` escalar por elemento. NaN por
  elemento: `[NaN] == [NaN]` → `[false]`. Sem broadcast (`2 * [1,2]` →
  `type-mismatch`, segue R15) — para isso existe `apply`.
- Distinção para o rationale: operadores **preservam a forma** (recursão da
  regra geral); `any`/`all` **colapsam** a árvore (recursão própria, porque
  agregam até `Boolean`).

### 3. Construtores e I/O de dados

- `list(n)(f)` = `[f(0), ..., f(n-1)]`; único interno privilegiado de construção.
  `f` recebe o ÍNDICE, avaliada em ordem `0..n-1` (efeitos nessa ordem); `n=0` →
  `[]`; `n<0` → `size-out-of-range`; `n` não-Integer → `type-mismatch`; `f`
  não-função → `not-callable` (mecanismo existente); arena sem espaço →
  `allocation-failure`.
- `read_reals(path)(k)(n)`: `[Real]` com `n` doubles f64 little-endian a partir
  do ELEMENTO `k` (não bytes — aritmética de offset fica em elementos).
  Equivale a `list(n)(fn(i){ elemento k+i de p; })`. Erros: `file-not-found`
  (agora também em EXECUÇÃO — precedente: `undefined-identifier` nas duas fases);
  `index-out-of-range` (k<0 ou k+n além do fim); `size-out-of-range` (n<0).
  `path` é String qualquer, computável em runtime: **código é estático
  (`import` exige literal), dado é dinâmico** — não fura R7.2.
- `count_reals(path)`: Integer com o nº de f64 do arquivo. "Ler tudo" = idioma
  `read_reals(p)(0)(count_reals(p))`.
- Nenhum interno escreve em disco → arquivo imutável durante a execução → cache
  invisível por (path,k,n) é seguro (nota de implementação, não spec).
- **Empacotamento** (f32/quantização/headers) = biblioteca futura, sustentada por
  `bitbuffer`/`bitslice` do keel v1+; entrega o valor como Integer ou Real.
  REGISTRO: essa biblioteca é código keel no runtime (não XPR puro) — nasce a
  terceira categoria de R12 (XPR puro / interno da spec / biblioteca keel).
- Socket/rede: ADIADO com registro (sem semântica de bloqueio/tempo na
  linguagem). `include` textual REAFIRMADO RECUSADO (higiene R7.1/R1.1); dados
  estáticos via `import("data.x").campo`; sequência textual via stdin:
  `list(n)(fn(i){ real(input("")); })`.

### 4. Internos, biblioteca e stdlib

- `len(x)` estendido a indexáveis: pontos de String, elementos de List. Interno
  polimórfico — precedente: `print`/`string` já aceitam qualquer tipo. (O
  briefing suspeitava "sem sobrecarga"; usuário decidiu estender.)
- `at` REBAIXADO a biblioteca: `at = fn(x){ fn(i){ x[i]; }; };` é XPR puro (R12).
  §6.4 inverte o açúcar: `index_suffix` é a forma primitiva. `s[i]` → String de
  comprimento 1; `l[i]` → elemento por cópia; somente leitura
  (`wrong-assignment`); fora de `0..len-1` → `index-out-of-range`.
- `is_list` entra em §6.6 (R11: um predicado por tipo, agora sete).
- **Stdlib no roadmap** (decisão do usuário: "vamos ter que fazê-la logo, logo"):
  doc futuro `xpr-stdlib-spec.md`. Morarão lá: `apply`, `apply2`, `any`, `all`,
  `map`, `filter`, `fold`, `range`, `identity`, `zeros`, `ones`, `at`, `abs`.
  Consequências futuras: §9 (diretório de biblioteca na busca) e
  AGENTS/check-docs reconhecendo o 3º normativo de definições.
- `print`/`string` de lista: `[1, 2, 3]` — abre `[`, separador `, ` (vírgula +
  espaço), fecha `]`; vazio `[]`; elementos pelas regras de §6.1/§6.2 (Real usa
  fmt_*, String sem aspas, aninhamento recursivo). `input` FECHADO: semântica
  `getline` — lê até `\n` (consumido, não incluso) ou EOF; EOF imediato → `""`
  (encerra a pendência antiga de §6.1).
- Representação (nota R14): lista = descritor/vista `{len, ptr}` sobre
  armazenamento alocado na arena do escopo; deep-copy ao escapar; se o
  armazenamento já vive na arena de destino, copia-se só o descritor ("muito
  rápido"). Buffer com capacidade crescente só existe internamente ANTES da
  lista imutável existir. Operações geram loops C planos → vetorização real
  pelo compilador (nota de rationale; spec não fala de desempenho).

### 5. Diagnósticos novos (§10, fase execução)

- `size-mismatch` — vetorização com comprimentos desiguais.
- `size-out-of-range` — `n < 0` em `list(n)(f)` ou `read_reals(p)(k)(n)`.
- `allocation-failure` — arena sem espaço na construção do valor.
- `file-not-found` — arquivo de `read_reals`/`count_reals` (id reusado, fase nova).

### Plano de escrita (a executar na próxima sessão)

1. **Spec** (`xpr-specs-pt.md`): §1 ("Sete tipos"; Integer "inteiro de 32 bits,
   sinalizado"; linha `List`); §3 (`list_literal = "[" [ expression { "," expression } ] "]" ;`
   em `literal` + prosa: avaliação E→D, homogeneidade/promoção, `[]`/`[?]`,
   `[ ]`/`,` já são pontuação de §2 — nenhuma regra léxica nova); §4.2 (exceção
   única do `[]`, com destaque); §4.9 (listas: `l[i]` por cópia; compartilhamento
   interno invisível); §5 (linha `List ⊗ List` na tabela, células "vetorizado →
   `[T]`" / "`[Integer]`" / "`[Boolean]`" + bloco **Vetorização** com a regra
   única e bullets: recursão, escalar cai na tabela, sem broadcast/apply,
   `all(l1==l2)`, NaN por elemento); §6.1 (formato de lista + input
   getline/EOF→`""`); §6.4 (heading → "Comprimento, indexação e strings":
   `len` estendido, `upper`/`lower`, parágrafo **Indexação**, `at`→biblioteca);
   §6.6 (+`is_list`); §6.8 NOVO "Listas: construção e leitura de dados"
   (`list`, `read_reals`, `count_reals`, nota empacotamento); §8 (bullet:
   armazenamento de elementos de lista junto a corpos de string/campos de
   módulo); §10 (4 linhas); **índice** (6.4 renomeia →
   `#64-comprimento-indexacao-e-strings`; acrescenta 6.8).
2. **Rationale** (`xpr-rationale.md`): R3 (heading → "R3. Sete tipos, imutáveis"
   + parágrafo do Integer 32: promoção exata/2^53, C/SIMD, limite 2^31 aceito,
   hipótese `size`); R9 (heading → "R9. Listas"; abertura: adiamento encerrado —
   a spec mudou antes do código, custo de documento e não refatoração; tabela
   atualizada: operadores = vetorização única, biblioteca = +any/all/apply/
   apply2/identity/zeros/ones, fora = concat/slice/append/mutação/broadcast;
   substituir "any/all são obrigatórios" por recursivos + biblioteca); **R9.2
   NOVO** (Vetorização: regra única recursiva; a recusa do `==` estrutural com o
   argumento do usuário; unários; NaN; size-mismatch; broadcast recusado);
   **R9.3 NOVO** (Construtores e I/O: `list` privilegiado; `read_reals`/
   `count_reals`; código estático × dado dinâmico; empacotamento com
   bitbuffer/bitslice + terceira categoria; socket adiado; include reafirmado);
   R12 (tabela: internos +`list`/`read_reals`/`count_reals`, −`at`; biblioteca
   +any/all/apply/apply2/identity/zeros/ones/at; parágrafo stdlib roadmap);
   R14 (nota vista/descritor/deep-copy); R15 (linhas novas: `==` estrutural;
   apply/apply2/any/all como internos; `at` como interno; empacotamento como
   internos; socket adiado; Integer 64; REFORMULAR linha "slice, `+` entre
   listas" → concatenação, pois `+` agora É vetorizado); **índice** (+R9.2,
   +R9.3; âncoras novas de R3/R9).
3. `make check-docs` (valida índice↔headings ASCII-folded, `R<n>` citados↔definidos,
   links cruzados; regenerar índices derivando dos headings, nunca à mão).
4. Fixture `tests/parser/list_literal.x` (positivo, golden pendente, estilo
   `call_chain.x`: comentário + programa curto). `make test` segue vermelho por
   construção (TDD).
5. Atualizar `MEMORY.md`.

### Verificações já feitas (não repetir)

- "64 bits" aparece SÓ em `xpr-specs-pt.md:53` (tabela §1); nenhum outro doc.
- Âncoras que mudam — `#r3-seis-tipos-imutaveis`, `#r9-listas-adiadas`,
  `#64-strings` — são citadas apenas nos índices dos próprios arquivos (grep
  confirmou); nenhum link cruzado as usa.
- `tools/check-docs.sh`: slugify ASCII-fold; índice completo exigido para
  headings `N.`, `N.M`, `R<n>`, `C<n>`; links spec↔rationale; `R<n>` citado na
  spec precisa de heading no rationale. Novos headings (R9.2, R9.3, §6.8) e
  títulos alterados (R3, R9, 6.4) exigem índices atualizados no mesmo commit.
## 2026-11-20 (b) — Listas escritas na spec e no rationale

> Sessão de EXECUÇÃO do plano da entrada anterior. 19 edições na spec e 13 no
> rationale, todas com assert de unicidade de correspondência (falha alto).
> `make check-docs` verde: spec 27/27, rationale 32/32, 19 R citadas/28 definidas.

### Spec (`xpr-specs-pt.md`) — o que entrou

- §1: "Sete tipos"; `Integer` 32 bits; linha `List`; parágrafo **Homogeneidade**
  (promoção, `[?]`, notação `[T]` só em diagnóstico).
- §3: `list_literal` em `literal` + prosa (avaliação E→D; pontuação já existia).
- §4.2: bloco **Exceção única** do `[]` (não fixa tipo; `[?]` = comprimento
  zero até lista concreta), com destaque pedido pelo usuário.
- §4.9: `l[i]` por cópia; compartilhamento interno invisível.
- §5: linha `List ⊗ List` + bloco **Vetorização** (size-mismatch; por elemento;
  recursiva; unários; NaN; sem broadcast/`apply`; idioma `all(l1 == l2)`).
  Corrigida referência `upper`/`lower` de (6.3)→(6.4) — erro pré-existente.
- §6.1: `input` FECHADO (getline até `\n` consumido; EOF imediato → `""`);
  formato de lista `[1, 2, 3]` (`, ` como separador; `[]`; recursivo).
- §6.4: heading → "Comprimento, indexação e strings"; `len` polimórfico
  (String/List); parágrafo **Indexação** (`x[i]` primitivo; `at` biblioteca).
- §6.6: +`is_list` (sete predicados).
- §6.8 NOVO: `list(n)(f)`, `read_reals(path)(k)(n)`, `count_reals(path)` +
  nota de empacotamento como biblioteca futura.
- §8: armazenamento de elementos de lista na lista de valores de arena.
- §10 Execução: +`size-mismatch`, `size-out-of-range`, `allocation-failure`,
  `file-not-found` (id reusado da análise; precedente `undefined-identifier`).
- Índice: 6.4 renomeado (`#64-comprimento-indexacao-e-strings`), +6.8.

### Rationale (`xpr-rationale.md`)

- R3 → "Sete tipos, imutáveis" + parágrafo Integer 32 (promoção exata/2^53,
  C/SIMD, limite 2^31 aceito, hipótese `size`).
- R9 → "Listas" (adiamento encerrado; custo de documento). R9.1: justifica
  atualizada, tabela reescrita (`[Integer]`/`[[Real]]` — minúsculas
  corrigidas; +linhas leitura de dados/biblioteca expandida; fora =
  concatenação), parágrafo "any/all recursivos e biblioteca".
- R9.2 NOVO: vetorização por uma regra; recusa do `==` estrutural com o
  argumento registrado do usuário; "operadores preservam a forma, any/all
  colapsam"; unários; NaN; size-mismatch (C4); broadcast recusado.
- R9.3 NOVO: `list` privilegiado (ordem 0..n-1 é definição); read_reals/
  count_reals como inverso de `import` (código estático × dado dinâmico);
  cache invisível seguro; empacotamento → terceira categoria de R12; socket
  adiado com registro.
- R12: tabela com `list`/`read_reals`/`count_reals` como internos, `at` fora;
  biblioteca +`apply`/`apply2`/`any`/`all`/`identity`/`zeros`/`ones`/`at`;
  nota `at`/`len`; parágrafo stdlib roadmap (`xpr-stdlib-spec.md` futuro).
- R14: nota descritor `{len, ptr}`/deep-copy ao escapar/loops C planos.
- R15: broadcast reancorado em R9.2; linha "slice/`+`" reformulada para
  concatenação (`+` é vetorização); +6 linhas (`==` estrutural; apply/any/all
  internos; `at` interno; empacotamento interno; socket; Integer 64).
- Índice: R3/R9 renomeados; +R9.2; +R9.3.

### Testes e verificação

- Fixture `tests/parser/list_literal.x` (positivo, golden pendente): `[]`,
  promoção `[1, 2.0, 3]`, aninhada `[[1,2],[3,4]]`, indexação `e[0]+m[0][1]`.
- Runner reconhece: `pending parser/list_literal`. `make test` segue vermelho
  **por construção** (parser pass:0 fail:9 pending:5) — nenhum caso existente
  mudou de estado.

### Pendências sinalizadas (não executadas)

- `src/xpr.h` → `src/xpr.k` (edição pendente da sessão anterior, spec §10)
  ainda sem eco em `tests/run_tests.sh` (CATALOG), `tests/README.md` e
  `docs/diretrizes-erros.md`/`docs/diretrizes-diagnosticos.md` — decidir se o
  catálogo vira `src/xpr.k` de vez antes da implementação.
- `xpr-stdlib-spec.md` (terceiro normativo) e diretório de busca em §9: só
  quando a stdlib começar.
## 2026-11-20 (c) — Catálogo de diagnósticos vira módulo keel (probe validado)

> Decisão do usuário: keel não tem `.h` escrito à mão — o idiomático é
> `import module`. Diretrizes de diagnóstico atualizadas (aceite explícito);
> spec §10 e tooling ficaram pendentes de aceite (ver fim).

### Probe empírico (tmp/diagprobe/, verde de ponta a ponta)

- `xpr/diag.k` = `module xpr.diag;` com `pub tags Diag [OK=0, ...]` → enum C
  **com identidade de tipo** (precedente e argumento de `corot.Status` contra
  `typedef i32`); `typedef struct DiagEntry` + `array DiagEntry table[N]` com
  a linha ligando {constante, id público, severidade, mensagem} — **a linha é
  a fonte única**, sem macro X. Headers de interface gerados pelo cgen.
- Consumo: `import xpr.diag as diag types;` + `outcome` (código viaja como
  i32; `else` na declaração; objeto sem `&`). `match` sobre
  `tagged Diag void` = despacho exaustivo verificado pelo cgen.
- **Bug do cgen v0.2.0-14**: constante de `tags` qualificado ENTRE módulos não
  é baixado ao nome C (`diag.Diag.SIZE_MISMATCH` sai `xpr_diag_Diag.SIZE_...`).
  Dentro do módulo, correto. Contorno validado: ponte `pub constexpr i32
  ERR_X = X;` (padrão `coll.EMPTY`, golden 007). Reportar/corrigir no keel.
- Lições de estilo keel do probe: `typedef struct` (struct puro não atravessa
  interface), `M.Set.CONST` fora do módulo, sem `usize` (usar `size_t`),
  `outcome.fail(r, código)` sem `&`, `else` preso à declaração com
  inicializador.

### Diretrizes alteradas (aceitas)

- `docs/diretrizes-diagnosticos.md`: §1 reescrito (catálogo = módulo keel;
  transporte por outcome; nota de versão cgen + pontes; injeção da tabela no
  `.k` gerado p/ runtime sob a regra do arquivo único — terceira categoria de
  R12); §3 `include`→`import`; §6 reescrito (`import` não cola texto — não há
  mapa de origem; pilha só para `recursive-import`); §7 + decisão aberta da
  correção do cgen; §8 checklist (módulo + injeção).
- `docs/diretrizes-erros.md`: §7 e §10.1 apontam ao módulo (spec 10);
  §9 "numeração do outcome.fail" marcada resolvida (i32 carrega o valor do
  tag, como `corot.tag`).

### Pendências (aceite ainda não dado)

- **Spec §10** (normativo): trocar "catálogo `XPR_DIAG_LIST` em `src/xpr.k`"
  pelo módulo `xpr/diag.k` (tags + tabela, fonte única). Redação pronta.
- **Tooling**: `tests/run_tests.sh` (CATALOG) e `tests/README.md:62` ainda
  apontam `src/xpr.h`.
- **Podridão era-`include` em diretrizes-erros.md** (não tocada, fora do
  escopo aceito): l.127-128 ("todo include já foi colado textualmente... sem
  módulos" — hoje é `import`), l.130 "(spec 8)" (dumps = spec 9), l.150
  ("carregamento estático de include... recursive-include").
## 2026-11-20 (d) — Spec §10 e runner alinhados ao catálogo-módulo; push

- **Spec §10** (aceite do usuário): "O catálogo desta seção mora no módulo keel
  `xpr/diag.k`, consumido por `import xpr.diag;` — keel não tem cabeçalho
  escrito à mão; a interface é gerada. O conjunto fechado de códigos é um
  `tags Diag` (um por linha das tabelas acima) e a tabela `DiagEntry` liga cada
  código ao identificador público, à severidade e ao modelo de mensagem —
  fonte única, nada duplicado." `XPR_DIAG_LIST`/`src/xpr.k` não existem mais
  em nenhum documento.
- **Runner**: `tests/run_tests.sh` CATALOG → `src/xpr/diag.k` (a checagem é
  grep no fonte do módulo — os ids são literais de string nas linhas da
  tabela); `tests/README.md` idem. `--list` segue MISSING-IN-CATALOG por
  construção (módulo ainda não existe) — comportamento inalterado.
- `make check-docs` verde (27/27, 32/32). Nenhuma menção a `xpr.h` resta em
  tests/, docs/ ou spec.
- Consequência de layout para a implementação: o módulo será `src/xpr/diag.k`
  (`module xpr.diag;`); o Makefile já cobre (find src -name '*.k' + regra de
  objeto com subdiretório). Usuário ficou de investigar a correção do bug do
  cgen (constante `tags` entre módulos) — reprodutor em tmp/diagprobe/.
