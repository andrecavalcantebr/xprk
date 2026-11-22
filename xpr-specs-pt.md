# Especificação do XPR

XPR é uma linguagem orientada a expressões: cada construto devolve um valor e um
programa inteiro é uma única expressão. Não há comandos, não há construto sem
valor. O transpilador `xprk` traduz XPR para keel e aciona a compilação final.

Dois documentos normativos, com divisão obrigatória:

- `xpr-specs-pt.md` — **definições**: o que a linguagem é.
- `xpr-rationale.md` — **razões**: por que cada regra existe, o que foi recusado.
  Normativo para admissão de mudanças (critérios em R1, recusas em R15). Uma recusa
  só é reativada refutando a razão registrada.

## Índice

- [0. Conformidade](#0-conformidade)
- [1. Tipos](#1-tipos)
- [2. Léxico](#2-lexico)
- [3. Gramática](#3-gramatica)
- [4. Semântica](#4-semantica)
- [4.1 Precedência e ordem de avaliação](#41-precedencia-e-ordem-de-avaliacao)
- [4.2 Escopo, atribuição, definição e sombreamento](#42-escopo-atribuicao-definicao-e-sombreamento)
- [4.3 Blocos](#43-blocos)
- [4.4 Funções e closures](#44-funcoes-e-closures)
- [4.5 iif](#45-iif)
- [4.6 for](#46-for)
- [4.7 Erros em execução](#47-erros-em-execucao)
- [4.8 import](#48-import)
- [4.9 Rec (agregados)](#49-rec-agregados)
- [4.10 Valores e cópias](#410-valores-e-copias)
- [4.11 Descarte de valor](#411-descarte-de-valor)
- [5. Operadores](#5-operadores)
- [6. Funções internas](#6-funcoes-internas)
- [6.1 Saída e entrada](#61-saida-e-entrada)
- [6.2 Formatação de números](#62-formatacao-de-numeros)
- [6.3 Conversões](#63-conversoes)
- [6.4 Comprimento, indexação e strings](#64-comprimento-indexacao-e-strings)
- [6.5 Matemática](#65-matematica)
- [6.6 Predicados de tipo](#66-predicados-de-tipo)
- [6.7 Erros](#67-erros)
- [6.8 Listas: construção e leitura de dados](#68-listas-construcao-e-leitura-de-dados)
- [6.9 Biblioteca](#69-biblioteca)
- [7. Constantes e vínculos predefinidos](#7-constantes-e-vinculos-predefinidos)
- [8. Modelo de memória](#8-modelo-de-memoria)
- [9. Execução: geração Keel e driver](#9-execucao-geracao-keel-e-driver)
- [10. Diagnósticos](#10-diagnosticos)
- [11. Pontos em aberto](#11-pontos-em-aberto)

## 0. Conformidade

Um **programa XPR** é um arquivo `.x` contendo uma expressão (§3), mais os
arquivos que ele importa (§4.8). O arquivo dado ao driver é o arquivo principal.

Um programa é **conforme** se satisfaz todas as regras normativas desta
especificação. Em particular:

1. **Aceitação estática.** O programa e todos os arquivos importados passam pela
   fase de análise: léxico, gramática, nomes definidos antes do uso, definições
   congeladas não reatribuídas, `lvalue-in-closure`, imports literais resolvidos,
   ausência de ciclos, campos conhecidos, e demais regras de análise (§10).
   Corpos de função são analisados mesmo se nunca chamados (C4).
2. **Comportamento definido.** Toda operação que o programa executa está definida
   por esta especificação. **Não há comportamento indefinido.** Toda operação ou
   é definida, ou é erro de análise, ou falha em execução com um diagnóstico do
   catálogo.
3. **Independência de implementação.** O programa não depende de escolhas de
   implementação não observáveis (§8, §9): cópia vs compartilhamento de
   armazenamento, copy-on-exit vs allocate-in-destination, inline, lowering de
   recursão em cauda. Essas escolhas não alteram o comportamento observável.

**Falhas de execução previstas não tornam o programa não-conforme.** Um programa
conforme pode falhar: `div-by-zero`, `integer-overflow`, `empty-loop`,
`index-out-of-range`, `fail`, etc. são comportamento definido. Se a falha não for
capturada, o programa termina com diagnóstico em stderr e status não-zero
(§4.7); isso é conformidade, não violação.

**Não é conforme:** programa rejeitado pela análise; programa que viole qualquer
regra normativa desta especificação; programa cujo resultado observável dependa
de comportamento não especificado.

**Comportamento observável:** os bytes escritos em stdout, os bytes escritos em
stderr e o status de saída. O valor final do programa não é impresso
automaticamente (§9); só é observável se o programa o imprimir.

**Não-terminação** não é não-conformidade. A especificação não exige terminação;
execuções longas são interrompidas pelo orçamento de passos (§4.7) ou por meio
externo.

**Pontos em aberto (§11)** não impõem requisitos de conformidade até serem
fechados. Enquanto um ponto que afeta o comportamento observável estiver aberto,
a conformidade plena depende do seu fechamento.

## 1. Tipos

Sete tipos: quatro básicos e três estruturados. Todos os valores são imutáveis.

**Básicos**

- **Boolean** — `true` e `false` (constantes predefinidas, §7).
- **Integer** — inteiro de 32 bits com sinal. A promoção Integer→Real é sempre
  exata (R3). Overflow de aritmética é falha capturável `integer-overflow` (R20).
- **Real** — ponto flutuante de precisão dupla (IEEE-754 binary64). `NaN`, `INF`,
  `pi`, `e` são Reals.
- **String** — sequência imutável de codepoints Unicode, em UTF-8. Indexação e
  comprimento em codepoints, não bytes.

**Estruturados**

- **List** — coleção ordenada, homogênea, de comprimento dinâmico. O literal
  `[a, b, …]` exige elementos do mesmo tipo, com promoção Integer→Real. `[]` tem
  tipo `[?]`, compatível com qualquer `[T]`, fixando no primeiro `[T]` concreto
  (§4.2). Indexação somente leitura `l[i]`. Operadores vetorizam (§5). Sublistas
  podem ter comprimentos diferentes: não há rank no tipo (R23).
- **Record** — agregado de campos nomeados e congelados, de tipos quaisquer
  (heterogêneo permitido). Criado por `rec{ … }` (§4.9). Acesso por campo
  `r.nome`. Igualdade estrutural, independente de ordem. Não é sequência: não
  vetoriza.
- **Function** — valor chamável, criado por `fn( … ){ … }`. A aridade não faz
  parte do tipo; uma função tem zero ou um parâmetro (§4.4).

Módulo é um arquivo cujo valor, obtido por `import`, é um Rec (ou qualquer outro valor).
(§6.6). A origem de arquivo é metadado de diagnóstico, não campo (§4.8).

**Escalonamento.** A única promoção implícita é Integer→Real, em contexto de
operador ou de unificação de elemento de List. Não há coerção String↔número nem
Boolean↔número; conversões são explícitas (§6.3). Um valor não muda de tipo; um
vínculo `=` fixa o tipo na primeira atribuição (§4.2).

**Não há valor de unidade nem "vazio por tipo".** `false`, `0`, `""` e `[]` são
identidades de operações específicas, não defaults da linguagem (R21).

## 2. Léxico

### Palavras-chave

`fn`, `rec`, `iif`, `for`, `try`, `import`, `else`. São formas sintáticas; não
podem ser usadas como identificadores.

### Operadores de palavra

`and`, `or`, `not` são **operadores**, não palavras-chave; o token é de operador
(R3.1).

### Constantes booleanas

`true` e `false` são constantes predefinidas (§7), com token próprio. Não são
palavras-chave nem identificadores.

### Identificadores

`[A-Za-z_][A-Za-z0-9_]*`, ASCII. Case-sensitive. Não podem ser palavra-chave.
Nomes de campo de Rec e nomes de arquivo seguem a mesma regra.

### Operadores e pontuação

Operadores: `+ - * / % < > <= >= == != and or not`.
Pontuação: `( ) { } [ ] , ; . : =`.
`:` marca **definição**; `=` marca **atribuição** (§4.2). Nenhum dos dois é
anotação de tipo (R3.4).
`@`, `<<`, `>>`, `&`, `|`, `^`, `~` não são tokens da linguagem.

### Números

- Integer: dígitos decimais, sem ponto nem expoente. Fora do intervalo de 32 bits
  com sinal → `integer-out-of-range` (análise). O menor Integer escreve-se
  `-2147483648`; a magnitude `2147483648` é aceita apenas como operando de `-`
  unário (R20).
- Real: dígitos com ponto decimal e/ou expoente (`3.14`, `2e3`, `.5`, `1.`).
  `2e3` é um literal Real; `e` isolado, onde um identificador é esperado, é a
  constante de Euler (§7).

### Strings

Aspas duplas ou simples. Escapes: `\n \t \r \\ \" \' \0`. String não terminada
até o fim do arquivo → `unterminated-string` (análise). Uma string pode abranger
várias linhas. Codepoints de controle são sanitizados em diagnósticos.

### Comentários

- Linha: `// …` até o fim da linha. Pode terminar no EOF legitimamente.
- Bloco: `/* … */`. Não aninha. `/*` sem `*/` → `unterminated-comment` (análise);
  não é tolerado até o EOF (R3.3).

## 3. Gramática

EBNF. `program` é a unidade de entrada; cada arquivo importado tem a mesma forma.

```ebnf
program      = expression ;

expression   = assign_or_def | fn_expr | rec_expr | iif_expr | for_expr
             | try_expr | import_expr | logic_or ;

assign_or_def = identifier ( "=" | ":" ) expression ;
(* ambas sao expressoes e devolvem o valor vinculado *)

fn_expr      = "fn" "(" [ identifier ] ")" block ;
rec_expr     = "rec" block ;
iif_expr     = "iif" "(" expression "," expression "," expression ")" ;
for_expr     = "for" "(" identifier "," expression "," expression ")"
               expression [ "else" "(" expression ")" ] ;
try_expr     = "try" "(" expression ")" [ "else" "(" expression ")" ] ;
import_expr  = "import" "(" string ")" ;   (* argumento literal *)

block        = "{" { statement } "}" ;
statement    = expression ";" ;

logic_or     = logic_and { "or" logic_and } ;
logic_and    = logic_not { "and" logic_not } ;
logic_not    = "not" logic_not | comparison ;
comparison   = sum { ( "==" | "!=" | "<" | ">" | "<=" | ">=" ) sum } ;
sum          = term { ( "+" | "-" ) term } ;
term         = unary { ( "*" | "/" | "%" ) unary } ;
unary        = ( "+" | "-" ) unary | postfix ;
postfix      = atom { call_suffix | index_suffix | field_suffix } ;
call_suffix  = "(" [ expression ] ")" ;     (* um argumento, no maximo *)
index_suffix = "[" expression "]" ;
field_suffix = "." identifier ;

atom         = integer | real | string | "true" | "false"
             | identifier | list_literal | "(" expression ")" | block ;
list_literal = "[" [ expression { "," expression } ] "]" ;
```

Notas de gramática:

- Sufixos são repetíveis sobre qualquer `atom`: `f(x)(y)`, `l[i][j]`, `r.a.b`,
  `iif(c,f,g)(x)`, `buf.len()`.
- `f(a, b)` (dois argumentos) é `syntax-error`. Múltiplos valores via List, Rec
  ou currying (R4).
- `field_suffix` aplica-se a Rec; `index_suffix` a List e String. Não há acesso a
  membro por tipo (R23).
- No `for`, o primeiro item é um **binder** (identificador), não uma expressão.
- `else` liga-se ao `for`/`try` mais interno que o precede; parênteses
  desambiguam aninhamentos.
- O construto é marcado por `rec`/`fn`, não pela presença de `:` (§4.3, R16).
- `{}` é `empty-block` (análise). `rec{}` é agregado vazio, válido.
- Espaço em branco não é significativo entre tokens. O sinal unário pode colar no
  número: `2 * -3`, `- 3`, `2 - -3` são válidos.

## 4. Semântica

### 4.1 Precedência e ordem de avaliação

Precedência, do mais fraco ao mais forte: `or` < `and` < `not` < comparação <
`+ -` < `* / %` < unário `+ -` < sufixos (chamada, índice, campo).

Operandos avaliam da esquerda para a direita; o argumento de uma chamada é
avaliado antes de resolver o alvo. `iif`, `for … else` e `try … else` avaliam
apenas os ramos necessários. `and`/`or` têm curto-circuito. Campos de Rec e
elementos de List avaliam na ordem do fonte.

### 4.2 Escopo, atribuição, definição e sombreamento

Blocos, corpos de função e `rec` definem escopo. Um nome existe a partir da sua
definição/atribuição até o fim do escopo.

- **`=` (atribuição):** atualiza o vínculo visível mais próximo; se não há
  vínculo visível, cria um vínculo local reatribuível. A primeira atribuição fixa
  o tipo do vínculo; tipo incompatível depois é `type-mismatch` (execução).
  Exceção única: `[]` tem tipo `[?]` e fixa no primeiro `[T]` concreto.
  **Atribuição nunca introduz sombra.**
- **`:` (definição):** cria um vínculo **congelado**, atribuído uma vez.
  Reatribuir (por `=` ou `:`) um nome definido com `:` no mesmo escopo é
  `assign-to-definition` (análise). Se o nome existe apenas em escopo externo, a
  definição o oculta **dentro deste escopo**.
- **Parâmetro:** cria vínculo local reatribuível; oculta o externo.
- Atribuir a um vínculo congelado, capturado ou predefinido visível é erro
  (`assign-to-definition`, `lvalue-in-closure`, `assign-to-constant`).
- Um nome deve ser definido antes do uso; uso anterior → `undefined-identifier`
  (análise, mesmo em corpos nunca chamados — C4).
- Palavras-chave e literais (`fn`, `rec`, `iif`, `for`, `try`, `import`, `else`,
  `true`, `false`) não são identificadores e não participam de sombreamento.

**Captura.** Um nome sem vínculo local visível no ponto de uso é livre: resolve
no escopo envolvente e **congela por cópia** na definição da closure (§4.4).
Dentro da closure é somente-leitura; atribuir a ele é `lvalue-in-closure`
(análise), independentemente de `:` ou `=`. Uma definição local anterior ao uso
elimina a captura.

**Qualificação.** Campos de Rec e valores importados são acessados por
qualificação (`r.x`). Nunca introduzem nomes no escopo do usuário; nada vindo de
um Rec sombreia no escopo externo.

**Builtins e constantes.** São vínculos predefinidos somente-leitura,
**sombreáveis uniformemente** por `:` e por parâmetro. Sombrear não é redefinir:
o predefinido permanece intacto nos escopos externos. `=` sobre o predefinido
visível é `assign-to-constant`.

**Delegação a um nome sombreado.** O nome nu dentro de uma definição resolve para
o **nome pendente** (a própria coisa sendo definida, R6), não para o sombreado.
Para delegar, capture o valor num vínculo local **antes** da definição que o
sombreia:

```c
rec{
    data = xs;
    _len = len;                (* captura o interno antes do sombra *)
    len: fn(){ _len(data); };  (* o campo len oculta; o corpo usa _len *)
};
```

O idioma é geral: vale para qualquer nome sombreado, não apenas internos.

### 4.3 Blocos

`{ s1; s2; …; sn; }` avalia as expressões em ordem, num escopo novo, e devolve o
valor de `sn`. Cada statement termina com `;`. Os valores de `s1 … s(n-1)` são
descartados (§4.11).

Bloco vazio `{}` é `empty-block` (análise). Não há valor de unidade nem default
por tipo (R21).

A presença de definições `:` **não** muda o que o bloco devolve: continua sendo a
última expressão. `:` num bloco nu é apenas um vínculo local congelado (R16).
Para obter um agregado, use `rec` (§4.9).

```c
{ a = 10; b: a + 1; b; }      (* -> 11; b é local congelado, não campo *)
```

### 4.4 Funções e closures

`fn(x){ … }` (um parâmetro) ou `fn(){ … }` (zero) cria um valor Function. O corpo
é um bloco; chamá-lo avalia o corpo e devolve a última expressão. Corpo vazio é
`empty-block`.

- **Um argumento, no máximo.** `f(a,b)` é `syntax-error`. Múltiplos valores via
  List/Rec ou currying: `fn(a){ fn(b){ … } }`, chamado `f(a)(b)`.
- **`f()` é chamada de zero argumentos**, distinta de `f([])` (List vazia) e de
  `f(rec{})` (Rec vazio).
- **Captura congelada por cópia.** Variáveis livres resolvem e congelam na
  definição. Reatribuir a variável depois não altera a closure. Nome livre sem
  vínculo visível na definição → `undefined-identifier` (análise).
- **Auto-referência estrutural (nome pendente).** Em
  `fat = fn(n){ … fat(n-1) … }`, `fat` no corpo resolve para a função em
  construção, não para o valor atual da variável. Reatribuir `fat` depois não
  afeta a cópia guardada (R6). O mesmo vale para campos de Rec (§4.9).
- **Sem vínculo tardio, sem letrec, sem recursão mútua.** Um ciclo de closures
  não se constrói por cópia (R6, R17).
- **Corpo analisado mesmo se nunca chamado** (C4).
- "No-op" é a identidade `fn(x){ x; }` (biblioteca `id`), não um corpo vazio.

### 4.5 iif

`iif(c, a, b)`: avalia `c` (deve ser Boolean; senão `type-mismatch` em execução);
avalia e devolve apenas o ramo escolhido. Os ramos podem ter tipos diferentes —
não há unificação de tipo no `iif` (R3.4).

### 4.6 for

`for(i, a, b) body` — laço de contagem.

- `i` é **binder novo**, local ao corpo, **congelado por iteração**. Oculta
  qualquer `i` externo; atribuir a `i` no corpo é `assign-to-definition`.
- `a`, `b` são Integer, avaliados **uma vez**, esquerda→direita, antes do laço.
  Não-Integer → `type-mismatch` (execução).
- Itera `i = a, a+1, …, b-1`: passo 1, ascendente, limite superior **exclusivo**.
- Devolve o **valor da última avaliação do corpo**. Os valores das iterações
  anteriores são descartados (§4.11).
- `a >= b` → falha `empty-loop` (execução).

`for(i, a, b) body else(e)` — forma total: devolve o último valor do corpo, ou o
valor de `e` (avaliado apenas no caso vazio). Com `else`, o laço nunca emite
`empty-loop`. Equivale a:

```c
{ __a = a; __b = b;
  iif(__a < __b, for(i, __a, __b) body, e); }
```

com `__a`/`__b` frescos e higiênicos, ligados por efeito (§4.11). **Não** equivale
a `try(for(…)) else(e)`: falhas do corpo **propagam**; o `else` cobre apenas o
vazio (R22).

Descendente e passo diferente de 1 ficam para `range`+`apply` (biblioteca) ou
recursão. O laço não acumula valores; `list(n)(f)` (§6.8) é o construtor de
listas. Cada iteração tem `i` fresco, e a captura é por cópia: closures criadas no
corpo capturam o `i` daquela iteração.

### 4.7 Erros em execução

Falhas interrompem a avaliação e propagam por retorno até o `try` mais interno
ativo, ou até o topo. Efeitos já realizados não são desfeitos; valores criados
pela avaliação abandonada são descartados.

**`try(e1)`** é forma especial: `e1` não é avaliado antes de `try` estar no
controle. Devolve um Rec de resultado:

- sucesso: `rec{ ok: true, value: v }`, onde `v` é o valor de `e1`;
- falha capturável:
  `rec{ ok: false, error: rec{ code: String, message: String } }`.

`ok` está sempre presente. `value` existe se e somente se `ok = true`; `error`
existe se e somente se `ok = false`. Acessar campo ausente é `field-not-found` em
execução, capturável por um `try` externo. O conjunto de campos depende de `ok`:
`value`/`error` são verificados em execução; `ok` é fixo.

Não há valor neutro: uma falha não fabrica `value` (R19).

**`try(e1) else(e2)`** — forma total: devolve o valor de `e1` em sucesso, ou o
valor de `e2` em falha, avaliado apenas na falha. **Não** devolve um Rec. Não há
binder: o erro é descartado. Se `e2` falhar, essa falha propaga para fora — não é
capturada pelo mesmo `try`. Equivale a:

```c
{ r = try(e1); iif(r.ok, r.value, e2); }
```

Idiomas:

```c
n = try(integer(input("idade: "))) else(0);      (* default *)

r = try(integer(input("idade: ")));              (* inspecao *)
iif(r.ok, r.value, fail(r.error.message));

r = try(a / b);                                  (* despacho pelo codigo *)
iif(r.ok, r.value,
    iif(r.error.code == "div-by-zero", 0, fail(r.error.message)));
```

`try` não captura `call-depth-exceeded`, `step-budget-exceeded`,
`allocation-failure` nem erros internos do runtime; esses terminam o programa.

Uma falha é capturada uma vez, pelo `try` mais interno ativo. Para retransmitir,
teste `ok` e chame `fail(r.error.message)`; a mensagem é preservada, o `code`
passa a `fail` (§11).

`fail(msg)` levanta falha explícita; `msg` deve ser String. Quando capturada,
`error.code = "fail"` e `error.message = msg`.

Não há `last_error`. O motivo da falha é local ao resultado de `try`.

O programa tem um `try` implícito no topo: falha não capturada reporta o
diagnóstico do catálogo em stderr, descarrega os buffers e termina com status
não-zero.

### 4.8 import

`import("caminho.x")` avalia a expressão do arquivo em **escopo fechado** e
devolve o seu valor — de qualquer tipo (Rec, Function, List, escalar).

- **Argumento literal obrigatório.** A análise resolve todos os arquivos para
  produzir um único `.k` (§9). `import(expr)` não-literal → `syntax-error`.
- **Escopo fechado.** O arquivo não vê os nomes do importador; seus nomes livres
  devem estar definidos no próprio arquivo ou ser predefinidos. A higiene está na
  fronteira do arquivo (R7.1).
- **Uma vez por arquivo.** O valor é memoizado; o arquivo avalia no ponto do
  primeiro `import` alcançado.
- **Ciclo de import** → `recursive-import` (análise).
- **Busca:** diretório do arquivo principal (§9). Diretório de biblioteca padrão
  pendente (R12, §11).
- **Arquivo não encontrado** → `file-not-found` (análise, pois o caminho é
  literal).
- O valor importado é tratado pelo que é: Rec por campo, Function por chamada,
  escalar diretamente. Não há categoria "módulo" no valor.
- O caminho é metadado de diagnóstico; não é campo acessível (`r.path` →
  `field-not-found`).

```c
std = import("lib.x");     (* lib.x avalia para rec{ ... } -> std é um Rec *)
f   = import("fat.x");     (* fat.x avalia para fn(n){ ... } -> f é Function *)
```

### 4.9 Rec (agregados)

`rec{ … }` avalia o seu bloco num escopo novo, em ordem, e devolve um agregado dos
**campos** — as definições `:` daquele escopo. As atribuições `=` são helpers
privados, não campos.

- **Campos = definições `:`.** `rec{ x: 1, y: "a" }` tem campos `x` (Integer) e
  `y` (String). `rec{ tmp = 1+2; x: tmp }` tem só o campo `x`.
- **Acesso por campo:** `r.x`, via `field_suffix`. `field-not-found` é erro de
  análise quando o conjunto de campos do receptor é fixo e conhecido (literal
  `rec`, ou `import` de caminho literal cujo valor é Rec de campos fixos). No
  resultado de `try` (§4.7), `value`/`error` são condicionais: verificados em
  execução.
- **Campos congelados.** `r.x = e` → `wrong-assignment` (o lvalue é apenas
  identificador). Para "alterar", construa um novo Rec.
- **Ordem e referência.** Campos avaliam em ordem; um campo vê os anteriores. O
  nome do próprio campo está pendente durante a sua definição (R6):
  `rec{ main: fn(a){ … main(a) … } }` recursa. Referência a campo posterior →
  `undefined-identifier`. **Sem recursão mútua** entre campos.
- **Igualdade estrutural, independente de ordem, recursiva → Boolean.**
  `rec{x:1,y:2} == rec{y:2,x:1}` é `true`. Demais operadores sobre Rec →
  `type-mismatch` (§5). Rec é agregado, não sequência: não vetoriza.
- **Sem estado interno mutável.** Campos congelados; métodos capturam campos por
  cópia. Estado vive fora do Rec (R17).
- **Rec vazio:** `rec{}` é válido (zero campos). Um `rec` só com helpers `=`
  também é agregado vazio.
- **print:** `rec{x: 1, y: a}` — recursivo, strings sem aspas, separador `, `.
  Notação de tipo em diagnóstico: `rec{x: Integer, y: String}`.

**Métodos.** Um campo pode ser uma função de zero argumentos que captura os
campos do Rec; `buf.len()` é acesso a campo seguido de chamada de zero
argumentos. **Não há `self` implícito**: o método é uma closure sobre o escopo do
Rec. Para delegar a um interno cujo nome o campo oculta, use o alias (§4.2).

```c
make = fn(xs){
    rec{
        data = xs;                              (* helper privado *)
        _len = len;                             (* alias do interno *)
        len: fn(){ _len(data); };
        get: fn(i){ data[i]; };
        set: fn(i){ fn(v){
                 make(list(_len(data))(fn(j){ iif(j == i, v, data[j]); }));
             }; };
    };
};

b0 = make([1, 2, 3]);
b1 = b0.set(0)(9);
println(b0.get(0));   (* 1 -- original intacto *)
println(b1.get(0));   (* 9 *)
println(b1.len());    (* 3 *)
```

O Rec resultante é um valor novo; o original permanece. É estrutura persistente
com métodos puros, não objeto mutável (R17).

### 4.10 Valores e cópias

Tudo é valor; não há referências observáveis. Atribuir/comparar/passar copia o
valor (a implementação pode compartilhar armazenamento imutável; §8). List,
String e Rec não se alteram in-place; operações devolvem novos valores. A
independência observável entre valores é garantida; o compartilhamento físico não
é observável (R14).

### 4.11 Descarte de valor

Toda expressão produz um valor (§3, R2). Nenhum contexto obriga que esse valor
seja consumido: **qualquer valor pode ser descartado**.

Um contexto que não usa o valor de uma subexpressão a avalia normalmente e
descarta o resultado. São contextos de descarte, entre outros:

- os statements de um bloco que não são o último (§4.3);
- as avaliações do corpo de um `for` que não são a última (§4.6);
- o valor do programa (§9), que não é impresso automaticamente;
- o Rec de resultado de `try` quando a forma com `else` é usada (§4.7).

Descartar um valor **não** altera a avaliação:

- os efeitos colaterais ocorrem;
- as falhas propagam normalmente — `{ 1/0; 42; }` falha, não devolve `42`;
- a ordem de avaliação é a definida em §4.1.

Descarte não é preguiça: a expressão é avaliada; apenas o resultado não é usado.
(`iif`, `for … else` e `try … else` são preguiçosos por regra própria: não avaliam
o ramo não escolhido.)

Não há sintaxe de descarte: nenhum operador, palavra-chave ou atribuição a nome
especial. O contexto determina o descarte (R2.1).

## 5. Operadores

**Escalares**

| operandos | `+` | `- * / %` | `< <= > >=` | `== !=` |
|---|---|---|---|---|
| Integer ⊗ Integer | soma | aritmética; `/` inteira truncante; `%` sinal do dividendo | Boolean | Boolean |
| Real ⊗ Real | soma | aritmética | Boolean | Boolean |
| Integer ⊗ Real | soma (promove) | aritmética (promove) | Boolean | Boolean |
| String ⊗ String | concatenação | type-mismatch | Boolean (lexicográfico por codepoint) | Boolean |
| Boolean ⊗ Boolean | type-mismatch | type-mismatch | type-mismatch | Boolean |

- `and`/`or`/`not` sobre Boolean, com curto-circuito.
- `%` apenas Integer; Real → `type-mismatch`. `(a/b)*b + a%b == a`.
- Divisão ou `%` por zero → `div-by-zero` (execução).
- NaN: toda comparação envolvendo NaN é `false`.
- Sem coerção implícita String↔número, Boolean↔número.

**Aritmética Integer verificada (R20).** `+`, `-`, `*` e o `-` unário cujo
resultado exato esteja fora de `[-2^31, 2^31-1]` falham com `integer-overflow`
(execução, capturável). `/` por zero: `div-by-zero`; o menor Integer `/ -1` é
`integer-overflow`. `%` por zero: `div-by-zero`; o menor Integer `% -1` é `0`.
Operandos mistos Integer/Real promovem para Real e seguem IEEE-754, sem
`integer-overflow`.

**List — vetorização (R9.2).** Uma regra única, recursiva: elemento a elemento,
comprimentos iguais, resultado do comprimento comum. Comprimentos diferentes →
`size-mismatch` (execução). `==` entre Lists devolve `[Boolean]`; colapsa com
`any`/`all` (biblioteca). Unários vetorizam (`-[1,2]` → `[-1,-2]`). **Sem
broadcast:** escalar ⊗ List → `type-mismatch`; use `apply` (biblioteca).
Concatenação, slice, append e mutação não são operadores (R15); existem como
funções de biblioteca.

**Rec — agregado, não sequência.** `==`/`!=` estrutural, ordem-independente,
recursivo → Boolean. Demais operadores → `type-mismatch`. A vetorização é regra de
List, não de agregados nomeados (R16).

**Function** — operadores sobre Function → `type-mismatch`.

## 6. Funções internas

Internos dependem da representação do valor ou do host; o que é expressável em
XPR puro é biblioteca (R12). **Internos são nomes nus**; biblioteca são módulos
Rec qualificados, obtidos por `import`. Não há internos qualificados (R23).

Cada interno tem zero ou um argumento; múltiplos via List/Rec ou currying.
Internos são vínculos predefinidos somente-leitura, sombreáveis uniformemente
(§4.2); para delegar a um interno sombreado, use alias.

### 6.1 Saída e entrada

- `print(v)` / `println(v)` — escrevem em stdout; devolvem o número de codepoints
  escritos (Integer). `println` acrescenta `\n`. Strings sem aspas; List com
  `[ ]` e `, `; Rec com `rec{ }` e `, `; Function → `<function>`; Boolean →
  `true`/`false`; Real no formato padrão (§6.2). A impressão é **sempre
  estrutural**: não há protocolo implícito de renderização por campo (R23).
  Renderização específica é método explícito que devolve String.
- `input(prompt)` — lê uma linha de stdin como String; fim de entrada imediato
  devolve `""` (§11).

### 6.2 Formatação de números

`fmt_decimals` e `fmt_sigdigits` são vínculos globais **graváveis** que controlam
o formato padrão de Real em `print`/`string` (§11). Notação fixa se
`10^-decimals <= |x| < 10^sigdigits`; senão científica. Round-half-to-even.
`NaN`/`INF`/`-INF` literais.

### 6.3 Conversões

- `string(v)` — representação textual de qualquer valor.
- `integer(s)` / `real(s)` — analisam **String**; falha → `invalid-number`
  (execução). `real` aceita `NaN`, `INF`, `-INF`.
- `int(x)` / `frac(x)` / `ceil(x)` / `floor(x)` / `round(x)` — sobre Real,
  devolvem Real. `int` trunca em direção a zero; `round` meio para longe de zero;
  `frac(x) == x - int(x)`. NaN/inf passam inalterados. Real→Integer não é
  implícito.

### 6.4 Comprimento, indexação e strings

- `len(v)` — List ou String; comprimento em codepoints (Integer). Depende da
  representação: é interno, não biblioteca (R12).
- `l[i]` / `s[i]` — somente leitura; índice Integer; fora de intervalo →
  `index-out-of-range` (execução). `s[i]` devolve String de um codepoint.
- `upper(s)` / `lower(s)` — caixa ASCII (A–Z ↔ a–z); demais pontos preservados
  (§11).

### 6.5 Matemática

`exp(x)`, `log(x)` (Real; domínio IEEE). `pow(base)(exp)` curryficado. Toda a
matemática é interna (R10).

### 6.6 Predicados de tipo

`is_boolean`, `is_integer`, `is_real`, `is_string`, `is_list`, `is_rec`,
`is_function` — um por tipo, sem promoção, sem agregação (R11).

### 6.7 Erros

- `fail(msg)` — levanta falha explícita com mensagem String (§4.7). O código
  público da falha é `fail`.

`try` é forma especial (§4.7), não builtin. `last_error` não existe.

### 6.8 Listas: construção e leitura de dados

- `list(n)(f)` — List de `n` elementos, `f(i)` para `i` em `0..n-1`, em ordem.
  `n` Integer; negativo → `size-out-of-range`. Único interno privilegiado de
  construção (R9.1).
- `read_reals(path)(k)(n)` — lê `n` Reals (f64 little-endian) do arquivo `path`, a
  partir do offset `k` em elementos. `count_reals(path)` — número de elementos.
  `path` é String computável em runtime; falha de arquivo → `file-not-found`
  (execução). Nenhum interno escreve em disco (R9.3).

### 6.9 Biblioteca

Expressáveis em XPR puro sobre os primitivos (`list(n)(f)`, `l[i]`, `len`):
`map`, `fold`, `filter`, `range`, `abs`, `at`, `apply`, `any`, `all`, `identity`,
`zeros`, `ones`, `cat`, `slice`, `id`. São biblioteca, não internos (R12). O
diretório da biblioteca padrão está pendente (§11); os idiomas que dependem dela
são condicionais a ela.

## 7. Constantes e vínculos predefinidos

Somente-leitura; `=` sobre eles é `assign-to-constant` (análise). Podem ser
ocultados por definições `:` e por parâmetros (§4.2).

- `true`, `false` — Boolean (token próprio).
- `NaN`, `INF` — Real. `-INF` via unário.
- `pi`, `PI` — Real (π). `e`, `E` — Real (Euler). `exp` não é constante.
- `args` — **List de String**, os argumentos de linha de comando. Predefinido
  somente-leitura **inicializado em runtime**, uma vez, no startup. Imutável por
  execução (R18).

Não há palavra-chave `const`. As definições `:` são os vínculos congelados da
linguagem.

## 8. Modelo de memória

Valores imutáveis → tempo de vida de uma alocação = escopo que a produziu. Arenas
por escopo (bloco, corpo de função, rec), liberadas em `defer` do keel, cobrindo
saída normal e desmontagem por erro. Sem GC (R14).

**Regra de escape uniforme.** Escapa para a arena de destino o que faz parte do
valor devolvido pelo escopo; os demais vínculos morrem na saída do escopo.

- Bloco/fn: o valor da última expressão (ou a closure) escapa; locais morrem.
- Rec: os campos `:` escapam como o agregado; os helpers `=` morrem na saída do
  rec. O Rec de resultado de `try` escapa como qualquer valor devolvido.
- A implementação pode alocar o que escapa direto na arena destino
  (allocate-in-destination); nesse caso os helpers `=` precisam de arena de
  rascunho do rec, liberada na saída. Copy-on-exit e allocate-in-destination são
  ambas conformes.

Compartilhar armazenamento imutável é seguro enquanto ele viver; descritor não
estende a vida do armazenamento. A imutabilidade é a premissa que torna o
compartilhamento não-observável e, portanto, arenas-sem-GC correto (R14, R17).

## 9. Execução: geração Keel e driver

**Fases.** léxico → análise (AST + resolução de nomes/imports) → geração de um
único `.k` → `cgen` → executável. A análise resolve todos os `import` antes da
geração; não há carregamento em runtime.

**Unidade de entrada.** Um arquivo `.x` é um programa (uma expressão). Cada
arquivo importado tem a mesma forma e avalia em escopo fechado (§4.8).

**Driver.** `xprk arquivo.x` transpila, compila e executa.
`xprk --lex-dump arquivo.x` / `--parse-dump` / `--gen-dump` param no estágio e
despejam o resultado. `xprk -h` ajuda e versão.

**Entry point emergente.** Não há convenção `_main` nem `missing-main`. O
programa é uma expressão; efeitos ocorrem se o programa chama algo, tipicamente
como última expressão (R18). O valor do programa é descartado (§4.11).

```c
{
    app = rec{ ...; main: fn(args){ ... } };
    app.main(args);
}
```

Não há auto-print do valor final; saída é explícita via `print`/`println`.

**Otimizações (não normativo).** O transpilador pode inlinear `apply` no corpo de
um laço, baixar recursão em cauda para laço, e implementar `list(n)(f)` como laço
sobre buffer. Nenhuma dessas escolhas altera o comportamento observável (§0).

## 10. Diagnósticos

Catálogo fechado, fonte única no módulo keel `xpr/diag.k` (`tags Diag` + tabela
`DiagEntry`: código, identificador público, severidade, modelo de mensagem, dica).
Nada duplicado. Duas fases: **Análise** e **Execução**. Colunas em codepoints.
Alguns ids existem nas duas fases com condições distintas
(`undefined-identifier`, `file-not-found`, `field-not-found`,
`integer-out-of-range`).

O campo `code` do `error` devolvido por `try` (§4.7) é o identificador público do
catálogo.

**Análise (seleção):** `syntax-error`, `wrong-assignment`, `assign-to-definition`,
`assign-to-constant`, `lvalue-in-closure`, `undefined-identifier`,
`field-not-found`, `recursive-import`, `file-not-found`, `empty-block`,
`unterminated-string`, `unterminated-comment`, `integer-out-of-range`.

**Execução (seleção):** `type-mismatch`, `size-mismatch`, `index-out-of-range`,
`div-by-zero`, `integer-overflow`, `invalid-number`, `size-out-of-range`,
`empty-loop`, `file-not-found`, `field-not-found`, `fail`, `call-depth-exceeded`,
`step-budget-exceeded`, `allocation-failure`.

`empty-loop` ocorre apenas no `for` sem `else` (§4.6). `field-not-found` em
execução cobre o acesso a campo condicional ausente no resultado de `try`.
`last_error` não existe; não há diagnóstico associado.

## 11. Pontos em aberto

1. **Valor do orçamento de passos** (`step-budget-exceeded`): o limite existe, o
   número não está definido.
2. **`fmt_decimals`/`fmt_sigdigits` graváveis** vs `format()` explícito: tensão
   com a imutabilidade (R14). Inclui os valores padrão de ambos.
3. **`upper`/`lower` ASCII-only** vs comparação case-insensitive e o compromisso
   Unicode do resto.
4. **`input` com EOF → `""`** confla linha vazia com fim de entrada. Alternativa:
   falha nomeada `end-of-input`.
5. **Diretório da biblioteca padrão** e caminho de busca de `import` (§9, R12).
6. **Retransmissão preservando o `code` original**: `fail(msg)` produz
   `code = "fail"`.
7. **Checagem estática de aridade**: hoje a análise *pode* rejeitar quando a
   função é estaticamente conhecida; decidir se passa a ser obrigatório (C4).
8. **Binder no `else` do `try`** (`else(err) e2`): extensão pura, adiada; hoje o
   `else` é apenas default (§4.7).
