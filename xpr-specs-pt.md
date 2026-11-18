# Especificação do XPR

XPR é uma linguagem orientada a expressões: cada construto devolve um valor. Um
programa é uma expressão. Não há comandos.

**Não existe construto sem valor.** Toda forma sintática da linguagem — `fn`,
`iif`, `for`, `try`, `import`, bloco — é uma expressão e produz valor. Uma
feature que só pudesse existir como construto (efeito sem valor, declaração)
não pertence à linguagem; é o primeiro critério de admissão (C1 em
[xpr-rationale.md](xpr-rationale.md#c1--tudo-e-expressao)).

Este documento contém **definições** — o que a linguagem é. As **razões** de cada
regra e as alternativas recusadas estão em [xpr-rationale.md](xpr-rationale.md),
o segundo documento normativo: ele decide a admissão de mudanças futuras
(critérios em R1) e desempata leitura ambígua desta especificação, mas nunca
acrescenta regra que aqui não exista.

## Índice

- [1. Tipos](#1-tipos)
- [2. Léxico](#2-lexico)
- [3. Gramática](#3-gramatica)
- [4. Semântica](#4-semantica)
  - [4.1 Precedência e ordem de avaliação](#41-precedencia-e-ordem-de-avaliacao)
  - [4.2 Escopo e atribuição](#42-escopo-e-atribuicao)
  - [4.3 Blocos](#43-blocos)
  - [4.4 Funções e closures](#44-funcoes-e-closures)
  - [4.5 iif](#45-iif)
  - [4.6 for](#46-for)
  - [4.7 Erros em execução](#47-erros-em-execucao)
  - [4.8 Módulos e importação](#48-modulos-e-importacao)
  - [4.9 Valores e cópias](#49-valores-e-copias)
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
- [7. Constantes predefinidas](#7-constantes-predefinidas)
- [8. Modelo de memória](#8-modelo-de-memoria)
- [9. Execução: geração Keel e driver](#9-execucao-geracao-keel-e-driver)
- [10. Diagnósticos](#10-diagnosticos)

## 1. Tipos

Sete tipos. Todos os valores são imutáveis.

| tipo | descrição |
| --- | --- |
| `Integer` | inteiro de 32 bits, sinalizado |
| `Real` | ponto flutuante de dupla precisão, incluindo `NaN`, `INF`, `-INF` |
| `String` | sequência de pontos Unicode em UTF-8 |
| `Boolean` | `true` e `false` |
| `List` | sequência homogênea de valores de um mesmo tipo, de comprimento qualquer |
| `Function` | código executável mais as capturas congeladas. A aridade (zero ou um parâmetro) **não** faz parte do tipo; é verificada na chamada |
| `Module` | conjunto finito e congelado de vínculos nome→valor, produzido somente por `import` (4.8) |

Não existe tipo `char`: um caractere é uma `String` de comprimento 1. Não
existem tuplas, registros nem tipos definidos pelo usuário. A razão desta
lista fechada está em R3; as recusas correspondentes, em R8 e R15.

**Homogeneidade de `List`.** Os elementos são de um só tipo, sob a única
promoção da linguagem: `[1, 2.0]` é `[Real]`; `[1, "a"]` é `type-mismatch`. A
lista vazia `[]` tem tipo `[?]`, compatível com qualquer `[T]` (4.2). Em
diagnóstico, o tipo de uma lista escreve-se `[T]` — `[Integer]`, `[[Real]]`
para a aninhada. A notação existe **somente em diagnóstico**: não é sintaxe
(não há anotação de tipo) e nunca aparece em `print`/`string`.

**Todo tipo novo é valor, e todo valor é expressão.** Um tipo de dado que entre
na linguagem — inclusive `List` (R9) — segue C1: aparece como literal, é
produzido por interno e participa de qualquer expressão. Não existe tipo que só
seja criado por um construto, nem que precise de posição sintática própria.

**Não há anotação de tipo na sintaxe.** Nenhum construto declara tipo: nem `fn`
(`fn(x: Integer)`, `fn: Boolean(...)`), nem variável, nem parâmetro, nem retorno,
nem `import`. O tipo de um valor é sempre derivado do valor. Anotação é
`syntax-error`, e a razão está em R3.4.

**Conversão implícita.** A única é a promoção `Integer` → `Real`, aplicada
quando um operador ou interno espera `Real` e recebe `Integer`. Toda outra
conversão é explícita, por função interna (6.3).

## 2. Léxico

### Palavras-chave

```
fn   iif   for   try   import
```

Uma palavra-chave não pode ser usada como identificador (`syntax-error`).
São reservas lexicais: o lexer emite um token próprio para cada uma, e nenhuma
delas é produzida por outra regra léxica.

### Constantes booleanas

```
true   false
```

São **constantes**, não palavras-chave: produzem um valor `Boolean` e nada mais.
O lexer as reconhece como tokens próprios (não como identificador seguido de
resolução de nome), mas semanticamente são literais como `42`. São
**somente leitura**, como as constantes matemáticas (Seção 7): atribuir a elas é
`builtin-redefinition`. A distinção importa: `fn`, `iif`, `for`, `try` e
`import` **não têm valor** — são formas sintáticas — enquanto `true` e `false`
**são valores**.

### Identificadores

```
identifier = ( alfa | "_" ) { alfa | digit | "_" }
alfa       = "a"–"z" | "A"–"Z"
```

Apenas ASCII. Caracteres não-ASCII são aceitos somente em strings e
comentários. Maiúsculas e minúsculas são distintas.

### Operadores e pontuação

Operadores **simbólicos**:

```
+   -   *   /   %   <   <=   >   >=   ==   !=   =
```

Operadores **alfabéticos**:

```
not   and   or
```

Pontuação (não são operadores):

```
(   )   {   }   [   ]   ,   ;   .
```

`not`, `and` e `or` são operadores como `+` e `<`, apenas escritos com letras:
o lexer emite para eles um token de operador, e a precedência está em §4.1. São
reservados porque, se fossem identificadores, `a and b` seria ambíguo com uma
sequência de nomes.

### Números

```
integer   = int_num
real      = int_num "." { digit } [ exp_part ]
          | int_num exp_part
          | "." int_num [ exp_part ]
int_num   = digit { digit }
exp_part  = ( "e" | "E" ) [ "+" | "-" ] int_num
digit     = "0"–"9"
```

Um número com `.` ou com expoente é `Real`; caso contrário, `Integer`.

### Terminais de conteúdo

Duas classes de terminal aparecem nas regras léxicas. São notação de
reconhecimento, não produções:

```
any              = ? qualquer ponto Unicode ?
any_not( P )     = ? um ponto Unicode, desde que ele não inicie P ?
```

`any_not(P)` consome **exatamente um** ponto. O predicado `P` decide se aquele
ponto pode ser consumido como conteúdo; ele não é consumido por `P`.

### Strings

```
string     = dq_string | sq_string
dq_string  = '"'  { any_not( '"' ou "\\" )  | escaped } '"'
sq_string  = "'" { any_not( "'" ou "\\" ) | escaped } "'"
escaped    = "\\" ( "n" | "t" | "r" | "0" | '"' | "'" | "\\" )
```

As duas aspas são equivalentes. Uma string pode se estender por várias linhas: a
quebra de linha é conteúdo, não terminador. O lexer delimita a string mas não
valida seu conteúdo; pontos de controle são sanitizados quando o texto é exibido
em diagnósticos.

**A aspa de fechamento é obrigatória.** Chegar ao EOF antes dela é
`unterminated-string`, erro da fase de análise. Não existe string que termine
implicitamente no fim da linha nem no fim do arquivo.

### Comentários

```
line_comment      = "//" { any_not( quebra de linha ) } ( "\n" | EOF )
multiline_comment = "/*" { any_not( a sequência "*/" ) } "*/"
```

O lexer os descarta. Não geram token. Não há processamento de escape dentro de
comentário: `// C:\path` e `/* 50% \n */` são comentários comuns.

**Assimetria de terminação.** Um comentário de linha termina legitimamente no
EOF — ele não tem delimitador de fechamento. Um comentário de bloco tem, e por
isso chegar ao EOF sem o `*/` é `unterminated-comment`, erro da fase de análise.

## 3. Gramática

```ebnf
program        = expression ;

expression     = assignment | fn_def | logical_or | block ;

assignment     = identifier "=" expression ;
fn_def         = "fn" "(" [ identifier ] ")" block ;

logical_or     = logical_and { "or" logical_and } ;
logical_and    = logical_not { "and" logical_not } ;
logical_not    = "not" logical_not | equality ;
equality       = relational { ( "==" | "!=" ) relational } ;
relational     = arithmetic { ( "<" | ">" | "<=" | ">=" ) arithmetic } ;
arithmetic     = term { ( "+" | "-" ) term } ;
term           = factor { ( "*" | "/" | "%" ) factor } ;
factor         = [ "+" | "-" ] postfix ;

postfix        = atom { call_suffix | index_suffix | field_suffix } ;
call_suffix    = "(" [ expression ] ")" ;
index_suffix   = "[" expression "]" ;
field_suffix   = "." identifier ;

atom           = literal
               | import_expr
               | block
               | iif_expr
               | for_expr
               | try_expr
               | "(" expression ")" ;

literal        = integer | real | string | boolean
               | list_literal | identifier ;
list_literal   = "[" [ expression { "," expression } ] "]" ;
boolean        = "true" | "false" ;

import_expr    = "import" "(" string ")" ;

block          = "{" { statement } "}" ;
statement      = expression ";" ;
iif_expr       = "iif" "(" expression "," expression "," expression ")" ;
for_expr       = "for" "(" expression ";" expression ";" expression ")" expression ;
try_expr       = "try" "(" expression [ "," expression ] ")" ;
```

Aplicação, indexação e acesso a campo são sufixos repetíveis e aninham à
esquerda: `f(x)(y)` é `(f(x))(y)`, `s[i][j]` é `(s[i])[j]` e `m.a.b` é `(m.a).b`.
O programa é **uma única expressão**; qualquer token restante depois dela é
`syntax-error`.

Como `iif_expr` é um `atom`, um `iif` pode receber sufixos diretamente:
`iif(c, f, g)(x)` é `(iif(c, f, g))(x)` — a função escolhida é chamada com `x`.
Não é preciso parênteses extras. O mesmo vale para `for`, `try`, blocos e
`import`.

Um literal de lista `[a, b, c]` é um `atom` e um valor `List`. Os colchetes e a
vírgula já são pontuação do léxico (2): nenhuma regra léxica nova. As
expressões internas são avaliadas da esquerda para a direita; homogeneidade e
o caso `[]` estão em 1 e 4.2.

## 4. Semântica

### 4.1 Precedência e ordem de avaliação

Do menor para o maior vínculo, na ordem em que a gramática agrupa:

```
or  <  and  <  not  <  == !=  <  < <= > >=  <  + -  <  * / %  <  unário + -
    <  postfix (chamada, índice, campo)
```

- Operandos binários avaliam da esquerda para a direita.
- `and` e `or` avaliam em curto-circuito: o operando direito só é avaliado se o
  esquerdo não decide o resultado.
- `iif` é preguiçoso em ambos os ramos (4.5).
- Atribuição é associativa à direita: `a = b = e` é `a = (b = e)`.
- Espaços em branco não são significativos entre tokens. O sinal unário pode
  colar no número: `2 * -3`, `- 3` e `2 - -3` são válidos.

Um erro de avaliação aborta a avaliação em curso, a menos que capturado por
`try` (4.7). Os efeitos já realizados, incluindo saída, não são desfeitos.

### 4.2 Escopo e atribuição

Blocos definem escopo. Um programa roda em um único escopo global.

- A atribuição a um nome já visível atualiza o vínculo mais próximo.
- A atribuição a um nome não definido cria o vínculo no escopo atual.
- Nomes só podem ser usados **depois** de sua definição (`undefined-identifier`).
- Vínculos criados em escopo interno não são visíveis fora dele.
- Parâmetros criam vínculos locais, mesmo que um escopo envolvente tenha o mesmo
  nome; o parâmetro sobrepuja o global.

O tipo é fixado na primeira atribuição. Reatribuir valor de outro tipo é
`type-mismatch`, exceto pela promoção `Integer` → `Real` quando o vínculo já é
`Real`:

```c
a = b = 1.0;   // a e b são Real
a = 3;         // ok: Integer promovido a Real
b = "x";       // type-mismatch
```

**Exceção única.** Atribuir `[]` **não** fixa o tipo do vínculo: ele fica
`[?]` e o tipo é fixado pela primeira atribuição de lista concreta. É a
primeira exceção a uma regra na linguagem — e deliberadamente a única:

```c
a = [];       // a é [?]
a = [1, 2];   // agora a é [Integer]
a = [1.0];    // type-mismatch: a já é [Integer]
```

Antes de ganhar tipo concreto, um vínculo `[?]` comporta-se como lista de
comprimento zero.

Uma atribuição é uma expressão e devolve o valor atribuído.

### 4.3 Blocos

`{ e1; e2; ... eN; }` avalia as expressões em sequência e devolve o valor de
`eN`. Cada expressão do bloco exige `;`.

Um bloco vazio `{}` é `empty-block`. Os valores das expressões intermediárias
são descartados; só o último é o valor do bloco.

Sem `;` final, o bloco é `syntax-error`:

```c
{3;}   // ok
{3}    // syntax-error
```

### 4.4 Funções e closures

Uma função tem **zero ou um** parâmetro e sempre devolve um valor. `f(x, y)` é
`syntax-error`. O parâmetro é um identificador puro, **sem anotação de tipo**, e
o tipo de retorno não é declarado: `fn(x: Integer){...}` e `fn: Integer(x){...}`
são `syntax-error` (§1, R3.4). A razão da aridade única e do currying está em R4.

**Definição.** `n = fn(p){ corpo }` é avaliada em ordem:

1. `n` é registrado como vínculo pendente.
2. O corpo é analisado. Toda ocorrência de `n` dentro do corpo resolve para a
   **própria função que está sendo criada**, não para o valor atual da variável.
   É o que torna a recursão sistemática (R6).
3. As demais variáveis livres do corpo são resolvidas nos escopos visíveis e
   devem já estar definidas (`undefined-identifier`).
4. O valor `Function` é criado, congelando por cópia os valores das variáveis
   livres, e atribuído a `n`.

```c
{
    fat = fn(n){ iif(n <= 1, 1, n * fat(n - 1)); };   // auto-referência
    g = fat;                    // g aponta para aquela definição
    fat = fn(x){ x + 1; };      // reatribui o vínculo, não a função
    g(5);                       // 120
}
```

`g(5)` devolve `120`: a auto-referência embutida na função aponta para a
definição original, que `g` também referencia. Reatribuir `fat` não a altera.

Em cadeia `a = b = fn(p){...}`, todos os nomes-alvo são registrados como
pendentes antes da criação da função, e todos identificam a mesma função em
construção.

**Closure.** Um valor `Function` é o nó de definição mais os valores das
variáveis livres, congelados por cópia no momento da definição. Reatribuir uma
variável depois nunca altera uma closure que já a capturou.

```c
c = 9;
f9  = fn(x){ x + c; };
f19 = fn(x){ x + c; };
c = 19;                    // não altera f9 nem f19
f19 = fn(x){ x + c; };
f19(1);                    // 20
```

**Aritmética da aridade.** Chamar com aridade incompatível é `arity-mismatch`:
`f(x)` quando `f` é `fn(){...}`, ou `f()` quando `f` é `fn(x){...}`. Se a função
é conhecida estaticamente, a análise pode rejeitar antes; no caso geral —
função recebida como argumento — a verificação ocorre na chamada.

**Composição.** Uma função pode devolver outra: se `f` devolve função,
`f(x)(y)` é válido e aninha à esquerda. `f(g(x))`, `f(g)` e `f()` também são
válidos. Funções são valores e participam de qualquer expressão.

**Seleção de função e despacho.** Como `iif` é preguiçoso e devolve valor de
qualquer tipo, escolher **qual função** usar é uma expressão comum:

```c
fmt = iif(modo == "csv", fmt_csv, fmt_json);   // fmt é Function
fmt(dados);                                     // chama a escolhida
iif(n > 0, abs, neg)(x);                        // idem, sem vínculo intermediário
```

Isso não é um construto novo: é `iif` (§4.5) composto com o sufixo de chamada
(§3). Não há `dispatch`, nem tabela de tipos, nem palavra-chave (R4, R15).

**Tabela de despacho.** A mesma composição constrói uma tabela por `iif`
aninhado — a forma que não depende de acumulação:

```c
{
    ops = fn(nome){
        iif(nome == "soma", soma,
        iif(nome == "media", media,
        fail("op desconhecida: " + nome)));
    };
    ops("soma")(xs);
}
```

Isso funciona porque `iif` aninha como `else_expr` do anterior, a cadeia
resolve da esquerda para a direita e o `fail` do último ramo só é avaliado se
nenhum nome casar (§4.5, ramos preguiçosos).

**Limite registrado: `for` não acumula.** Uma tabela montada em loop **não** é
possível, porque o corpo de `for` é descartado e o resultado do loop é a contagem
de iterações (§4.6, R2):

```c
ops = for(i = 0; i < n; i = i + 1){ ops = iif(..., corpo[i], ops); };
// ops passa a ser um Integer: a contagem. As atribuições internas morreram no
// escopo do corpo.
```

Montar a tabela exige `iif` aninhado (acima) ou, no futuro, listas e
`fold` (R9). É a mesma limitação que motiva `list(n)(f)`.

**Corpo inválido.** Ler uma variável antes de sua definição no corpo é
`undefined-identifier` já na definição, sem executar o corpo:

```c
f = fn(x){ print(y); y = x; };   // undefined-identifier
f = fn(x){ y = x; print(y); };   // ok
```

**Atribuição a captura.** Atribuir a um nome capturado é `lvalue-in-closure`.

### 4.5 iif

`iif(cond, then_expr, else_expr)`:

- Avalia `cond`. Se não for `Boolean`, é `type-mismatch`.
- Se `true`, avalia e devolve `then_expr`; se `false`, `else_expr`.
- Os ramos são preguiçosos: só o escolhido é avaliado.
- Os dois ramos **não** precisam ter o mesmo tipo. O tipo do resultado é o do
  ramo escolhido.
- Por ser preguiçoso, um ramo pode ser inválido para o valor concreto desde que
  não seja o escolhido: `iif(is_real(x), x, fail("não é Real"))`.

### 4.6 for

`for(init; cond; step) corpo`:

1. Executa `init`.
2. Enquanto `cond` for `true`: executa `corpo`, depois `step`.
3. Devolve o número de execuções **concluídas** do corpo, como `Integer`.

- Condição inicial falsa devolve `0`.
- Os valores de `init`, `corpo` e `step` são descartados; o resultado é sempre
  uma contagem (`Integer`, zero ou positiva). `for` **não** constrói coleções;
  acumular é trabalho de `list(n)(f)` e `fold` (R9, R9.1).
- `cond` deve ser `Boolean` (`type-mismatch` caso contrário).
- Um erro de avaliação aborta o loop sem produzir resultado.

### 4.7 Erros em execução

**`try(expr)`** — sonda. Avalia `expr` e devolve `Boolean`: `true` se concluiu,
`false` se um erro escapou. Não relata o erro no stderr.

**`try(expr, default)`** — valor padrão. Devolve o valor de `expr`, ou `default`
se um erro escapou. `default` é avaliado preguiçosamente: só quando `expr`
falha, e seu tipo deve casar com o de `expr` sob a mesma regra de promoção
`Integer` → `Real`.

Em ambos:

- Sem erro: `last_error` é zerada para `""`.
- Com erro: o diagnóstico é gravado em `last_error` no momento do levantamento e
  permanece lá. Não é relatado no stderr.
- A captura vale para qualquer erro que escape de `expr`, inclusive os
  levantados em funções chamadas por ela.
- Na forma com atribuição (`try(v = f(x))`), a atribuição **não** acontece:
  `v` mantém o valor anterior, ou permanece indefinida se nunca existiu. Ler
  `v` nesse caso é `undefined-identifier` — use `last_error`.
- Efeitos já realizados dentro de `expr` não são desfeitos.
- `try` aninhado: um `try` interno que falha devolve `false` ou seu `default`
  como valor, e o externo conclui com sucesso.

**`fail(msg)`** levanta um erro de execução cujo diagnóstico é a `String` `msg`
do usuário. Sem `try` em vigor, o programa aborta.

Não são capturáveis: o limite de profundidade de chamada (10.000) e o
orçamento de passos de avaliação. Eles sempre abortam o programa.

O programa inteiro é envolvido pelo gerador em um `try` implícito: um erro não
capturado em linguagem é relatado uma única vez no stderr e o processo termina
com status diferente de zero.

### 4.8 Módulos e importação

`import` é uma expressão e produz um valor `Module`.

```c
std = import("stdlib.x");   // std nomeia o módulo
std.range(2);               // acesso a campo, depois chamada
```

O argumento deve ser um **literal de `String`**. Não existe importação
dinâmica: um argumento variável é `import-not-literal` (R7.2).

**O valor.** Um `Module` é o conjunto dos vínculos definidos no nível superior do
arquivo importado, congelado. Não há literal de módulo, atribuição a campo,
indexação nem remoção. `m.nome` lê um campo; nome ausente é `field-not-found`.

**Dois tempos.** Na **análise**, o arquivo é localizado, lido e analisado,
recursivamente para seus próprios imports; `file-not-found` e
`recursive-import` são erros desta fase. Na **execução**, o nível superior do
módulo é avaliado no ponto do `import`, e o resultado é o valor.

**Escopo.** O nível superior do arquivo é avaliado em escopo próprio, que contém
os internos (Seção 6), as constantes (Seção 7), os vínculos que o próprio
arquivo define e os módulos que ele mesmo importa. O módulo **não vê** o escopo
do importador (R7.1).

**Unicidade.** O nível superior é avaliado uma vez por arquivo, na primeira vez
que um `import` daquele arquivo é alcançado; as ocorrências seguintes
reaproveitam o mesmo valor. Importar de novo não reavalia nem cria outro módulo.

**Ciclos.** A importa B, B importa C, C importa A → `recursive-import`. Um
arquivo que importa a si mesmo idem.

**Uso como valor.** Um módulo pode ser passado como argumento, guardado em
variável e devolvido por função. Operadores de igualdade, ordem e aritmética
sobre `Module` são `type-mismatch`. `is_module` (6.6) é a única forma de
reconhecê-lo.

```c
use_mod(import("mathx.x"));          // argumento
mk = fn(){ import("mathx.x"); };     // devolvido
mk().step(1);                        // mesmo módulo de antes
```

**Nome no diagnóstico.** Um módulo não tem nome: é impresso como
`<module arquivo.x>`, com o caminho relativo ao arquivo principal.

### 4.9 Valores e cópias

Tudo é valor; não há referências visíveis ao usuário. Atribuição e passagem de
parâmetro copiam: reatribuir uma variável não altera o valor guardado por outra.

Strings são imutáveis. `s[i]` devolve uma `String` de comprimento 1. Indexar é
somente leitura: `s[i] = x` é `wrong-assignment`.

```c
{
    a = "Hello";
    b = a;
    b = b[1];      // b = "e"
    println(a);    // Hello
    println(b);    // e
}
```

Listas seguem a mesma regra: `l[i]` devolve o elemento **por cópia** — na
lista aninhada, a lista interna inteira — e indexar é somente leitura
(`l[i] = x` é `wrong-assignment`). O compartilhamento interno do próximo
parágrafo é invisível: a garantia é a independência observável entre valores
copiados.
O armazenamento interno de um valor imutável pode ser compartilhado; a
independência observável é que se preserva, não a cópia física. Ver Seção 8.

## 5. Operadores

| operandos | `+` | `-` `*` `/` | `%` | `<` `<=` `>` `>=` | `==` `!=` | `not` `and` `or` |
| --- | --- | --- | --- | --- | --- | --- |
| `Integer` ⊗ `Integer` | soma (`Integer`) | aritmética (`Integer`) | resto (`Integer`) | `Boolean` | `Boolean` | — |
| `Real` ⊗ `Real` | soma (`Real`) | aritmética (`Real`) | `type-mismatch` | `Boolean` | `Boolean` | — |
| `Integer` ⊗ `Real` | promoção para `Real` | promoção para `Real` | `type-mismatch` | `Boolean` após promoção | `Boolean` após promoção | — |
| `String` ⊗ `String` | concatenação | `type-mismatch` | `type-mismatch` | lexicográfico por ponto | `Boolean` | — |
| `Boolean` ⊗ `Boolean` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `Boolean` | `Boolean` |
| `Function` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `type-mismatch` | — |
| `Module` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `type-mismatch` | — |
| `List` ⊗ `List` | vetorizado (`[T]`) | vetorizado (`[T]`) | vetorizado (`[Integer]`) | vetorizado (`[Boolean]`) | vetorizado (`[Boolean]`) | vetorizado (`[Boolean]`), elemento `Boolean` |

- `/` sobre `Integer` é divisão inteira, truncando em direção a zero
  (`-7 / 3` é `-2`).
- `%` é resto da divisão inteira, **somente `Integer`** — não há resto para
  `Real`, nem por promoção. O sinal segue o dividendo: `-7 % 3` é `-1`,
  `7 % -3` é `1` (R5).
- Divisão por zero em `/` ou `%` é `division-by-zero`.
- Comparação de `String` é sensível a caixa e compara ponto a ponto:
  `"A" != "a"`. Para ignorar caixa, compare via `upper`/`lower` (6.4).
- Toda comparação que envolve `NaN` é falsa.
- `not` exige `Boolean`; `and` e `or` exigem `Boolean` em ambos os operandos.

**Vetorização.** Todo operador desta tabela aplica a listas elemento a
elemento, por uma única regra:

- os operandos têm comprimentos iguais — comprimentos diferentes são
  `size-mismatch` (Seção 10);
- o resultado tem o comprimento comum; cada elemento é o resultado escalar da
  tabela para os elementos correspondentes, e as exigências escalares — por
  exemplo, `and` exige `Boolean` — valem **por elemento**;
- a regra é **recursiva**: elemento que é lista invoca a mesma regra, então
  `[[1,2]] + [[10,20]]` é `[[11,22]]`; matriz e tensor são listas aninhadas,
  sem tipo novo (R9.2);
- operadores unários vetorizam igualmente: `-[1, 2]` é `[-1, -2]`,
  `not [true]` é `[false]`;
- `NaN` compara falso por elemento: `[NaN] == [NaN]` é `[false]`;
- não há broadcast: `2 * [1, 2]` é `type-mismatch`. Combinar escalar com lista
  é papel de `apply`, função de biblioteca (R12).

Igualdade estrutural não é operador: o idioma é `all(l1 == l2)` (R9.2).

## 6. Funções internas

Os internos são símbolos globais predefinidos. Distinguem-se três classes:

- **Funções internas** — valores `Function`, **somente leitura**: atribuir a um
  deles é `builtin-redefinition`. Podem ser passados como argumento
  (`use_func(print)`).
- **Variáveis predefinidas** — `fmt_decimals` e `fmt_sigdigits` são **graváveis**
  (6.2); `last_error` é somente leitura (6.7).
- **Constantes predefinidas** — as booleanas `true`/`false` e as matemáticas da
  Seção 7. São somente leitura; as booleanas têm token próprio no léxico (§2).

Um nome interno é sempre um valor: nenhum interno depende de sintaxe especial. O
critério que separa interno de biblioteca está em R12.

### 6.1 Saída e entrada

- `print(x)` — escreve a representação de `x` no stdout e devolve um `Integer`
  com o número de pontos escritos. Sem nova linha automática.
- `println(x)` — igual a `print`, acrescentando `\n`, que entra na contagem.
- `input(prompt)` — escreve `prompt` e lê uma linha do stdin: até `
`
  (consumido, não incluso) ou fim de entrada; fim de entrada imediato devolve
  `""`. O resultado é `String`.

Strings são escritas sem as aspas delimitadoras. `Boolean` escreve `true` ou
`false`. `List` escreve `[e1, e2, e3]`: abre `[`, elementos separados por
vírgula e espaço, fecha `]`; a vazia escreve `[]`; cada elemento segue as
regras deste parágrafo e de 6.2, recursivamente para listas aninhadas.
`Function` escreve `<function>`; `Module` escreve `<module arquivo.x>` com o
caminho relativo ao arquivo principal. Esses dois não têm representação
textual de conteúdo (R13).

### 6.2 Formatação de números

`fmt_decimals` (`Integer`, padrão `2`) e `fmt_sigdigits` (`Integer`, padrão `5`)
são variáveis globais predefinidas **graváveis** que controlam como `print` e
`string` escrevem valores `Real`. São configuração, não constantes: atribuir é
válido e afeta as escritas seguintes. A configuração vale apenas para `Real`.

- `NaN`, `INF` e `-INF` escrevem literalmente, ignorando a configuração.
- Se `10^-fmt_decimals <= |x| < 10^fmt_sigdigits`: notação fixa com
  `fmt_decimals` casas após a vírgula. `20.0` escreve `20.00`.
- Caso contrário: notação científica com `fmt_sigdigits` dígitos significativos.
  `0.001` escreve `1.0000e-3`; `1234567890123456789.0` escreve `1.2346e+18`.
- O arredondamento segue `printf` de C: metade para o par.
- `real(string(x)) == x` não é garantido. Para ida e volta exata, use
  `fmt_decimals = 17` e `fmt_sigdigits = 17`.

### 6.3 Conversões

Conversões são explícitas. Não há `bool(val)`: use `s == "true"`.

- `string(val)` — `val` para `String`. `Real` usa `fmt_decimals` e
  `fmt_sigdigits`; `Function` e `Module` produzem as formas de 6.1.
- `integer(s)` — `String` decimal para `Integer`. Outro tipo é `type-mismatch`;
  para `Real`, o diagnóstico orienta a usar `int`, `round`, `floor` ou `ceil`.
- `real(s)` — `String` para `Real`. Outro tipo é `type-mismatch`.

### 6.4 Comprimento, indexação e strings

- `len(x)` — `Integer` com o comprimento de `x`: pontos de uma `String`,
  elementos de uma `List`. Outro tipo é `type-mismatch`.
- `upper(s)` / `lower(s)` — novas strings com `A`–`Z` ↔ `a`–`z` convertidos e os
  demais pontos preservados. Outro tipo é `type-mismatch`.

**Indexação.** `x[i]` — o `index_suffix` de 3 — é a forma primitiva. Sobre
`String`, devolve a `String` de comprimento 1 do ponto de índice `i` (base 0).
Sobre `List`, devolve o elemento `i` **por cópia** (4.9) — na lista aninhada, a
lista interna inteira. Indexar é somente leitura: `x[i] = e` é
`wrong-assignment`. Índice fora de `0..len(x)-1` é `index-out-of-range`; índice
não-`Integer` é `type-mismatch`. A forma curried `at(x)(i)` é biblioteca —
açúcar em XPR puro sobre `x[i]` (R12).

### 6.5 Matemática

- `int(x)`, `frac(x)`, `ceil(x)`, `floor(x)`, `round(x)` — sobre `Real`.
  `int` trunca em direção a zero; `frac(x) == x - int(x)`, com sinal; `round`
  arredonda metade para longe de zero.

  | x | int | floor | ceil | round | frac |
  | --- | --- | --- | --- | --- | --- |
  | 3.99 | 3 | 3 | 4 | 4 | 0.99 |
  | -3.7 | -3 | -4 | -3 | -4 | -0.7 |
  | 5.5 | 5 | 5 | 6 | 6 | 0.5 |

  `INF` e `NaN` se propagam (`int(INF)` é `INF`, `int(NaN)` é `NaN`).

- `exp(x)`, `log(x)` — exponencial de base `e` e logaritmo natural. Aceitam
  `Integer` ou `Real` e devolvem `Real`. Fora do domínio seguem IEEE-754, sem
  erro: `log(0)` é `-INF`, `log(-1)` é `NaN`. Outro tipo é `type-mismatch`.

- `pow(base)(exponent)` — `base` elevado a `exponent`, na forma curried.
  Acompanha `pow` do `math.h` de C: base negativa com expoente inteiro preserva
  o sinal (`pow(-2)(3)` é `-8`), `pow(0)(0)` é `1`, base negativa com expoente
  fracionário é `NaN`.

### 6.6 Predicados de tipo

`is_integer(x)`, `is_real(x)`, `is_string(x)`, `is_boolean(x)`, `is_list(x)`,
`is_function(x)`, `is_module(x)` — devolvem `Boolean`. Há exatamente um por tipo
da linguagem (R11). Não promovem: `is_real(1)` é `false`. São a única forma de
inspecionar o tipo de um valor em execução, e o que permite escrever funções
polimórficas em XPR puro:

```c
abs = fn(x){
    iif(is_real(x),    iif(x < 0.0, -x, x),
    iif(is_integer(x), iif(x < 0,   -x, x),
    fail("abs: type-mismatch")));
};
```

### 6.7 Erros

- `fail(msg)` — levanta erro com diagnóstico `msg` (4.7). Nunca devolve valor.
- `last_error` — `String` global predefinida, somente leitura. Reflete o `try`
  mais recente: `""` em caso de sucesso, o diagnóstico em caso de falha.
  Atribuir a ela é `builtin-redefinition`.

### 6.8 Listas: construção e leitura de dados

- `list(n)(f)` — devolve `[f(0), ..., f(n-1)]`. `f` é avaliada uma vez por
  elemento, em ordem de índice `0..n-1`, e recebe **o índice** como argumento;
  efeitos acontecem nessa ordem. `n = 0` devolve `[]`. `n < 0` é
  `size-out-of-range`; `n` não-`Integer` é `type-mismatch`; `f` que não é
  `Function` é `not-callable`. A homogeneidade vale sob promoção: `f`
  polimórfico cujos resultados divirjam sem promoção é `type-mismatch` em
  execução.
- `read_reals(path)(k)(n)` — `[Real]` com `n` valores f64 de dupla precisão,
  little-endian, lidos a partir do **elemento** `k` do arquivo `path` (offset
  em elementos, não bytes). Equivale a `list(n)(fn(i){ elemento k+i de path; })`.
  `k < 0` ou `k + n` além do fim é `index-out-of-range`; `n < 0` é
  `size-out-of-range`; arquivo inexistente é `file-not-found`. `path` é
  `String` qualquer, computável em execução — código é estático (`import`
  exige literal, 4.8), dado é dinâmico (R7.2).
- `count_reals(path)` — `Integer` com o número de valores f64 do arquivo. Ler
  o arquivo inteiro é o idioma `read_reals(p)(0)(count_reals(p))`.

Nenhum interno escreve em disco: um arquivo aberto por `read_reals`/
`count_reals` não muda durante a execução. Empacotamento de dados — f32,
quantização, cabeçalhos — é biblioteca futura, sustentada por primitivas do
host (R9.3).

## 7. Constantes predefinidas

Vínculos globais predefinidos, somente leitura. Atribuir é `builtin-redefinition`.
A comparação lê o valor normalmente (`pi == 3.14` é `false`).

**Booleanas** — são constantes do mesmo tipo que as matemáticas, apenas com
token próprio no lexer (§2): `true`, `false`.

**Matemáticas**:

| constante | valor |
| --- | --- |
| `NaN` | Not a Number |
| `INF` | infinito; aceita `+` e `-` unários |
| `pi`, `PI` | π |
| `e`, `E` | base dos logaritmos naturais |

`2e3` e `2E3` são o literal `2000.0` (Seção 2), não `2 * e * 3`. `e` é lido como
constante apenas onde um identificador é esperado.

## 8. Modelo de memória

Todos os valores são imutáveis, então o tempo de vida de uma alocação é o do
escopo que a produziu. Isso permite arena, sem coletor de lixo (R14).

- Cada escopo de execução tem sua arena. Valores alocados nele — corpos de
  string, o armazenamento de elementos de lista, o conjunto de campos de um
  módulo — são liberados quando o escopo termina.
- Keel oferece `defer`; a liberação da arena de um escopo é agendada na entrada
  dele, de modo que acontece tanto na saída normal quanto na desmontagem por
  erro.
- Um valor que escapa do escopo que o alocou é copiado para a arena de destino
  antes que a origem seja liberada. Um resultado de função chamada é copiado
  para a arena do chamador.
- Como o armazenamento é imutável, a cópia física pode ser evitada por
  compartilhamento seguro. Copiar um descritor não estende o tempo de vida do
  armazenamento que ele referencia: um descritor que apontaria para arena
  liberada precisa ser copiado.
- Não há alocação que sobreviva ao fim do escopo que a produziu, e portanto não
  há vazamento fora do escopo.

## 9. Execução: geração Keel e driver

### Fases

1. **Análise** — o arquivo de entrada é tokenizado e analisado em AST. Os
   `import` são resolvidos nesta fase, recursivamente.
2. **Geração** — o AST é transpilado para um único arquivo `.k` em Keel.
3. **Compilação** — o arquivo `.k` é compilado por `cgen` e o executável é
   produzido.

Erros de sintaxe são detectados na fase 1, inclusive dentro de corpos de função
que nunca são chamados. Ver Seção 10.

### Unidade de entrada

O driver recebe **um único arquivo `.x`**. Todo o resto entra por
`import("arquivo.x")`, e como todo `import` tem argumento literal, a análise
conhece de antemão o conjunto completo de arquivos. O programa inteiro vira
**um único arquivo `.k`** na pasta atual. Não há geração de múltiplos arquivos
nem linkedição separada.

`import` procura o arquivo apenas no diretório do arquivo principal. Não há
busca em `XPRPATH` nem diretório de biblioteca padrão.

### Driver

| invocação | comportamento |
| --- | --- |
| `xpr <arquivo.x>` | compila: transpila para `.k` e aciona a compilação final |
| `xpr --lex-dump <arquivo>` | interrompe no lexer e despeja os tokens |
| `xpr --parse-dump <arquivo>` | interrompe no parser e despeja a AST |
| `xpr --gen-dump <arquivo>` | interrompe na geração e despeja o Keel produzido |
| `xpr -h`, `xpr --help` | ajuda; exibe também a versão do transpilador |

O programa compilado **não** imprime automaticamente o valor da expressão
final. A saída é solicitada explicitamente por `print`/`println`. Status de
saída é zero em sucesso e diferente de zero em qualquer falha.

## 10. Diagnósticos

Todo diagnóstico tem um identificador. A fase indica quando ele é detectado.

### Análise

| id | condição |
| --- | --- |
| `unterminated-string` | literal de `String` sem a aspa de fechamento |
| `unterminated-comment` | comentário de bloco sem o `*/` de fechamento |
| `syntax-error` | o texto não forma uma expressão válida, ou sobra token depois dela |
| `empty-program` | a origem não contém nenhuma expressão |
| `empty-block` | bloco `{}` sem expressões |
| `wrong-assignment` | alvo de atribuição não é identificador (literal, constante booleana, chamada, índice, campo) |
| `undefined-identifier` | nome usado antes de qualquer definição, inclusive variável livre de função |
| `lvalue-in-closure` | atribuição a nome capturado por closure |
| `builtin-redefinition` | atribuição a interno, constante ou `last_error` |
| `import-not-literal` | argumento de `import` não é literal de `String` |
| `file-not-found` | arquivo de `import` inexistente |
| `recursive-import` | ciclo de importação |
| `field-not-found` | campo ausente em módulo cujo conjunto é conhecido estaticamente |

### Execução

| id | condição |
| --- | --- |
| `type-mismatch` | operando ou argumento de tipo inadequado |
| `arity-mismatch` | chamada com aridade incompatível com a função |
| `not-callable` | aplicação de valor que não é função |
| `division-by-zero` | `/` ou `%` com divisor zero |
| `index-out-of-range` | índice fora de `0..len-1` |
| `size-mismatch` | vetorização de listas com comprimentos diferentes |
| `size-out-of-range` | tamanho negativo em `list(n)(f)` ou `read_reals(p)(k)(n)` |
| `allocation-failure` | arena sem espaço na construção de um valor |
| `file-not-found` | arquivo de `read_reals`/`count_reals` inexistente (id da análise, fase de execução) |
| `field-not-found` | campo ausente em módulo cujo conjunto não é conhecido estaticamente |
| `undefined-identifier` | leitura de variável nunca atribuída, por exemplo após `try` que falhou |
| `call-depth-exceeded` | profundidade de chamada acima de 10.000 |
| `step-budget-exceeded` | orçamento de passos de avaliação esgotado |

Um erro não capturado é relatado uma única vez no stderr. Erros com origem
incluem nome do arquivo, linha e coluna, com a coluna contada em pontos.
`call-depth-exceeded` e `step-budget-exceeded` não são capturáveis por `try`.

O catálogo desta seção mora no módulo keel `xpr/diag.k`, consumido por
`import xpr.diag;` — keel não tem cabeçalho escrito à mão; a interface é
gerada. O conjunto fechado de códigos é um `tags Diag` (um por linha das
tabelas acima) e a tabela `DiagEntry` liga cada código ao identificador
público, à severidade e ao modelo de mensagem — fonte única, nada duplicado. O
projeto de propagação e limpeza está em
[diretrizes-diagnosticos.md](docs/diretrizes-diagnosticos.md).
