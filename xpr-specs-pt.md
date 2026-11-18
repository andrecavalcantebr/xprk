# Especificação do XPR

XPR é uma linguagem orientada a expressões onde cada construto devolve um valor.

## Índice

- [1. Conceitos Principais](#1-conceitos-principais)
- [2. Tipos](#2-tipos)
- [3. Gramática (EBNF)](#3-gramatica-ebnf)
- [4. Semântica](#4-semantica)
  - [4.1 Sinais numéricos unários e espaços em branco](#41-sinais-numericos-unarios-e-espacos-em-branco)
  - [4.2 Ordem de avaliação](#42-ordem-de-avaliacao)
  - [4.3 Carregamento Estático de Arquivos](#43-carregamento-estatico-de-arquivos)
  - [4.4 Blocos](#44-blocos)
  - [4.5 iif (Ternário)](#45-iif-ternario)
  - [4.6 loop "for"](#46-loop-for)
  - [4.7 funções](#47-funcoes)
  - [4.8 Escopo](#48-escopo)
  - [4.9 Atribuições](#49-atribuicoes)
  - [4.10 Valores e cópias](#410-valores-e-copias)
  - [4.11 Tratamento de erros em execução](#411-tratamento-de-erros-em-execucao)
- [5. Funções Internas](#5-funcoes-internas)
  - [5.1 Formatação de números](#51-formatacao-de-numeros)
  - [5.2 Semântica de operadores](#52-semantica-de-operadores)
- [6. Constantes Matemáticas](#6-constantes-matematicas)
- [7. Erros](#7-erros)
- [8. Interface de linha de comando](#8-interface-de-linha-de-comando)

## 1. Conceitos Principais
- **Orientada a Expressões**: Cada instrução é uma expressão. Blocos, `iif` e loops devolvem valores.
- **Carregamento Estático**: `include("arquivo.x")` insere o conteúdo do arquivo na posição da chamada, tal como se aquele conteúdo estivesse escrito diretamente ali. O arquivo é resolvido em tempo de compilação; não encontrado, há emissão de erro.
- **Funções de Primeira Classe**: Funções podem ser passadas como argumentos e retornadas como valores.
- **Execução em duas fases**: todo o arquivo é analisado em um AST e transpilado para um arquivo `.k` (Keel) e, depois, compilado para a execução; erros são divididos em tempo de análise e tempo de execução (veja a Seção 7).

## 2. Tipos
- **Integer**: inteiro de 64bits, sinalizado;
- **Real**: ponto flutuante de dupla precisão (suporta notação científica).
- **String**: cadeias UTF-8, contendo qualquer ponto Unicode, com sequências de escape (`\n`, `\t`, `\r`, `\0`, `\"`, `\'`, `\\`). Não existe tipo `char`: um caractere é uma `String` de comprimento 1 (em pontos Unicode).
- **Boolean**: `true` e `false`.
- **Function**: blocos executáveis de código; a aridade (zero ou um parâmetro) não faz parte do tipo — é verificada na chamada.

A única conversão implícita da linguagem é a promoção de `Integer` para `Real`. Não existe nenhuma outra conversão implícita entre tipos.

## 3. Gramática (EBNF)

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
term           = factor { ( "*" | "/" ) factor } ;
factor         = [ "+" | "-" ] indexed ;

indexed        = primary { "[" expression "]" } ;

primary        = literal 
               | fn_call 
               | block 
               | iif_expr 
               | for_expr 
               | try_expr 
               | "(" expression ")" ;

literal        = integer | real | string | boolean | identifier ;
fn_call        = identifier "(" [ expression ] ")" ;
block          = "{" { statement } "}" ;
statement      = expression ";" ;
iif_expr       = "iif" "(" expression "," expression "," expression ")" ;
for_expr       = "for" "(" expression ";" expression ";" expression ")" expression ;
try_expr       = "try" "(" expression [ "," expression ] ")" ;

// detectado pelo lexer
integer   = int_num ;
real      = ( int_num "." { digit } [ exp_part ] )
          | ( int_num exp_part )
          | ( "." int_num [ exp_part ] ) ;
int_num   = digit { digit } ;
exp_part  = ( "e" | "E" ) [ "+" | "-" ] int_num ;
digit          = ( "0"-"9" ) ;

string         = '"' { chars | escaped } '"' | "'" { chars | escaped } "'" ;
chars          = ? qualquer ponto Unicode exceto as aspas delimitadoras e
                 U+005C ( \ ); pontos de controle são aceitos, portanto uma
                 string pode se estender por várias linhas ? ;
// O lexer apenas delimita strings e não valida seu conteúdo. Pontos de controle
// são sanitizados quando o texto é exibido em diagnósticos (veja diagnostic.c).
escaped        = "\\" ( "n" | "t" | "r" | "0" | '"' | "'" | "\\" ) ;

identifier     = ( alfa | "_" ) { alfa | digit | "_" } ;
alfa           = ( "a"-"z" | "A"-"Z" ) ;
// Identificadores são apenas ASCII (identificadores também nomeiam os arquivos
// {identificador}.x carregados via include). Caracteres não‑ASCII são aceitos
// apenas em strings e comentários.

keywords       = ( "fn", "iif", "for", "try", "not", "and", "or", "true", "false" ) ;

boolean        = "true" | "false" ; 
operators      = ( "+", "-", "*", "/", 
                   "<", ">", "=", ">=", "<=", "==", "!=" ) ;

// ignorado pelo lexer
comments          = line_comment | multiline_comment ;
line_comment      = "//" { chars } ( "\n" | EOF ) ;
multiline_comment = "/*" { chars } "*/" ;
```

## 4. Semântica

### 4.1 Sinais numéricos unários e espaços em branco

Quando `+` ou `-` unário precede um literal numérico,

- `2 * -3`, `2 *-3`, `2 *- 3`, `- 3` e `+ 3` são válidos.
- A subtração binária ainda permite espaços em branco: `2 - 3` e `2 - -3` é válido.

A gramática existente também admite operandos unários como `-x` e `-(2 + 3)`.

### 4.2 Ordem de avaliação

A precedência determina o agrupamento das expressões. Os operandos binários são avaliados da esquerda para a direita, exceto quando se aplica a avaliação em curto-circuito. A atribuição é associativa à direita: `a = b = expression` significa `a = (b = expression)`.

Um erro de avaliação aborta a avaliação em curso, a menos que capturado por `try` (4.11). A expressão que falhou não produz resultado. Os efeitos já realizados, incluindo a saída, não são desfeitos automaticamente.

### 4.3 Carregamento Estático de Arquivos

O carregamento ocorre em tempo de compilação, quando o transpilador resolve uma chamada `include("arquivo.x")`:

1. Ele busca por um arquivo chamado `arquivo.x` no caminho de busca (abaixo).
2. Se encontrado, o conteúdo do arquivo é inserido byte a byte no lugar da chamada, antes que aquele trecho seja analisado; a análise então prossegue normalmente sobre o texto resultante.
3. Se não for encontrado, é levantado um erro `file-not-found`.

Não existe carregamento dinâmico: nenhum identificador não resolvido dispara busca automática de arquivos. A busca ocorre apenas no diretório que contém o script principal. O transpilador atualmente não procura em `XPRPATH` nem em um diretório de biblioteca padrão.

`include` é resolvido pelo carregador durante a análise; não é uma função em tempo de execução e, por isso, não figura entre as funções internas (Seção 5). Não confundir com `input`, o interno que lê dados do stdin (Seção 5).

Um arquivo carregado é avaliado no ambiente léxico do local da chamada, como se sua expressão tivesse sido escrita ali. Os valores de função criados durante essa avaliação congelam as variáveis livres visíveis de acordo com as regras de closure. Em um local de chamada, este é o ambiente léxico da chamada; durante a criação de uma closure, é o ambiente no qual essa closure está sendo definida.

As funções definidas em arquivos carregados seguem as mesmas regras das locais, incluindo globais congelados e recursão.

- Cada ocorrência de `include` carrega o arquivo e o "cola" na posição do código fonte; novos `include` sobre o mesmo arquivo são tratados independentemente, ou seja, haverá outra cópia, mas carregamentos circulares não são permitidos, ou seja: se A carrega B, B carrega C e C carrega A, erro `recursive-include`. Como todo carregamento é resolvido em tempo de compilação, `file-not-found` e `recursive-include` são erros de análise, não de execução.

### 4.4 Blocos
Um bloco `{ expr1; expr2; ... exprN; }` avalia todas as expressões sequencialmente e devolve o valor de `exprN`.

Um bloco vazio `{}` é um erro de análise (`empty-block`). Não existe um valor de bloco vazio.

As instruções exigem `;` no final. Então:

```c
{3;} // ok
{3} // erro
```

E:

```c
{
  f = fn(x){ x + 9; };
}
```

Precisa de 2 ';': um depois da expressão `(x+9)` e um depois da definição da expressão `fn`.

Um programa é uma expressão, então:

`3`
`3+1`
`fn(x){...}`
`{statement1; statement2;}`

são todos válidos, mas...

```c
3;
3+1;
{3;};
3 4;
```

são erros de sintaxe: o programa é uma única expressão e, depois dela, qualquer
token restante — um `;` extra ou uma segunda expressão — é sobra na origem.



### 4.5 iif (Ternário)

`iif(cond, then_expr, else_expr)`:

- Avalia `cond`.
- Se for `true`, avalia e devolve `then_expr`.
- Se for `false`, avalia e devolve `else_expr`.
- Os ramos são avaliados de forma preguiçosa.
- A condição deve avaliar para um boolean. Nenhuma conversão implícita é realizada; uma condição não booleana levanta `type-mismatch`.

### 4.6 loop "for"

`for(init; cond; step) expr` — onde `expr` normalmente é um bloco:

- Executa `init`.
- Enquanto `cond` for verdadeira:
  - Executa `expr` (o corpo do loop).
  - Executa `step`.
- Devolve o número de avaliações concluídas de seu corpo. Se a condição inicial for falsa, devolve `0`. Os valores produzidos pela inicialização, pelo corpo e pelo passo são descartados. Qualquer erro de avaliação aborta o loop sem produzir resultado. Um loop concluído com sucesso devolve sempre um `Integer`: zero ou uma contagem de iterações positiva.
- A condição deve avaliar para um boolean; caso contrário, a avaliação levanta `type-mismatch`. Nenhuma conversão implícita é realizada.

### 4.7 funções

- As funções têm **zero ou um** parâmetro e sempre devolvem um valor: `y = f()` ou `y = f(x)`.

- Uma função sem parâmetro é um *thunk*: um cálculo adiado até a chamada — útil para efeitos e valores que mudam entre chamadas.

- Note que `y = f(a,b)` é um erro de sintaxe. As funções xpr têm no máximo um argumento. Mas funções podem sofrer composição e podem ser usadas como parâmetros de outras funções, ou seja: `f(g(x))`, `f(g)` e `f()` são válidos.

- Invocar com aridade incompatível — chamar `f(x)` quando `f` é `fn(){...}`, ou `f()` quando `f` é `fn(x){...}` — é um erro de avaliação `arity-mismatch`. Quando a função é conhecida estaticamente, a análise pode rejeitar antes; no geral (função recebida como argumento), a verificação ocorre na chamada. 

- Uma função pode retornar outra função, então, se f retorna uma função: `f(x)(y)` é perfeitamente válido.

- Como tal, uma função é um tipo de dado válido e pode participar de quaisquer expressões.

- Então, para se declarar uma função, usa-se a keyword `fn`:

```c
f = fn(x){x + 9;};
use_func(f);        // passa a função
use_value(f(1));    // passa o valor 10
```

- Não existem variáveis salvas:

```c
c = 9;
f9 = fn(x){x + c;}; // define uma função
f19 = fn(x){x + c;}; // define a mesma função
c = 19;   // não muda f9 nem f19
f19 = fn(x){x + c;}; // re-define uma função
print(f19(1));   //imprime 20.00
```

- Um programa pode ser carregado como uma função, da seguinte forma:

```c
f = fn(x) include("myfunc.x");   // note que o programa é, em si, um bloco
a = f(1);    // uso
```

- As variáveis livres são resolvidas e congeladas no momento da definição. Uma variável livre comum que não está definida naquele momento levanta `undefined-identifier` na definição:

```c
g = fn(x){ x + c; };   // erro: c ainda não foi definido
```

- Um valor de função é uma **closure**: seu nó de definição mais os valores de todas as variáveis livres, congelados **por cópia** no momento da definição (como no exemplo `f9`/`f19` acima). Reatribuir uma variável depois nunca muda uma closure que já a capturou.

- Leitura de uma variável capturada usa seu valor congelado no momento da definição da função. A atribuição àquele nome é em erro `lvalue-in-closure`.

```c
{
    c = 10;
    f = fn(x){ c = c + x; c; };   // erro
    print(f(1));
    print(c);
}
```

- Os nomes devem ser definidos antes do uso, seguindo a ordem das expressões no corpo da função. Os parâmetros são definidos na entrada da definição da função, embora seus valores de argumento só fiquem disponíveis durante a invocação. Uma atribuição local pode depender desses valores; expressões subsequentes podem usar a variável local que ela define. Uma atribuição posterior não torna válido um uso anterior. Verificar essa ordem não executa o corpo da função.

```c
f = fn(x){ print(y); y = x; };   // undefined-identifier na definição
```

```c
f = fn(x){ y = x; print(y); };   // válido: y é definido antes do uso
```

- O valor capturado inclui as capturas congeladas da própria função, não apenas seu nó de definição do AST nem o endereço de uma variável que guarda a função. O AST registra a estrutura da chamada; cada closure em tempo de execução possui suas próprias capturas.

```c
{
    c = 10;
    helper = fn(x){ x + c; };
    f = fn(x){ helper(x); };
    c = 20;
    helper = fn(x){ x + 100; };
    f(1);
}
```

  Este programa devolve `11`: definir `f` captura o `helper` original, incluindo seu `c = 10` congelado, sem executar `helper(x)`. A chamada ocorre quando `f(1)` é executado, depois que seu parâmetro recebeu um valor.

- O próprio nome pendente da função pode ser capturado para recursão direta, mas não pode ser invocado antes que a função seja totalmente inicializada.

- Em uma cadeia de atribuições de identificadores cuja expressão mais à direita é uma definição de função, todos os nomes-alvo são reconhecidos como vínculos pendentes antes de o valor de função ser criado. As referências a esses nomes dentro da função capturam a função que está sendo criada. As atribuições permanecem associativas à direita, e a função pendente não pode ser invocada antes que a inicialização seja concluída. Esses nomes-alvo identificam a mesma função em construção; eles não introduzem recursão mútua entre definições de funções distintas.

```c
{
    a = b = fn(x){ iif(x == 0, 0, a(x - 1)); };
    a(2);
}
```

  Este programa devolve `0`. O nome `a` é um auto-nome pendente quando a função é criada, mesmo que a atribuição mais interna tenha `b` como alvo.

- Dentro de `nome = fn(...){ ... }`, o nome que está sendo definido conta como uma variável livre já resolvida: a closure congela uma referência à função que está sendo criada (vínculo antecipado), como uma declaração adiante em keel. O corpo nunca procura `nome` no escopo no momento da chamada. Consequências:

```c
fat = fn(x){ iif(x<=1, 1, x * fat(x-1)); };   // corpo recursivo
g = fat;
fat = fn(x){ 999; };   // esta é uma nova função
g(5);                  // 120: a chamada recursiva foi vinculada à primeira função no momento da definição
fat(5);                // 999: esta chamada passa pela variável, que agora guarda a nova função
```

  Se o corpo resolvesse `fat` por meio da variável no momento da chamada (vínculo tardio), `g(5)` avaliaria `fat(4)` com a nova função e devolveria `999`.

- Uma função capturada como variável livre comum segue a mesma regra: `h = fn(x){ fat(x); };` continua chamando a função que existia quando `h` foi definida, mesmo que `fat` seja reatribuída depois.

- Os parâmetros sobrepujam os globais: em `fn(c){ c + 1; }`, o `c` no corpo é o
  parâmetro.

- A recursão mútua não é possível: todo nome livre é resolvido no momento da definição. Um `odd` não resolvido dentro de `even = fn(x){ ... odd(...) ...; };` deve ser resolvido antecipadamente ou levantará `undefined-identifier`.

### 4.8 Escopo

Os blocos definem escopo. Um programa roda em um único escopo global, e o próprio programa é uma expressão (mais geralmente um bloco). As variáveis existem apenas dentro do escopo de suas definições. Se uma função é atribuída a uma variável e essa variável sai de escopo, a definição também sai — a menos que outras variáveis guardem a mesma função.

Um escopo pode acessar variáveis definidas nos seus escopos envolventes. A atribuição a uma variável existente atualiza o vínculo visível mais próximo; ela não cria uma nova variável local. A atribuição a um nome não definido cria uma variável no escopo atual. As variáveis criadas em um escopo interno não são visíveis fora dele.

Os parâmetros de função criam vínculos locais, mesmo quando um escopo envolvente contém variáveis com os mesmos nomes.

```c
{
    x = 1;
    { x = 2; };
    x;
}
```

Este programa devolve `2`: o bloco interno atualiza o `x` existente, e o bloco externo devolve o valor de sua última expressão. Um bloco não vazio devolve o valor de sua última expressão; um bloco vazio é erro (veja 4.4). Essa regra de bloco não muda o resultado de `for`, que devolve o número de execuções
de seu corpo (veja 4.6).

As variáveis e funções só podem ser usadas **depois** de sua definição. Dentro das funções, a distinção entre um nome definido cujo valor está pendente e um nome não definido segue 4.7. A atribuição a um nome capturado segue a regra do vínculo original naquela seção; suas leituras permanecem congeladas.

```c
fat = fn(x){ iif(int(x) == 0 or int(x) == 1, 1, fat(int(int(x)-1))); };

c = fat(5);  //a variável fat já está definida
```

### 4.9 Atribuições

- Uma atribuição é uma expressão, portanto devolve o valor atribuído.
- Cadeias de atribuições são avaliadas da direita para a esquerda.
- O tipo de uma variável é definido na primeira atribuição; reatribuir um valor
  de um tipo diferente é um `type-mismatch`, exceto pela única conversão
  implícita permitida: um `Integer` pode ser promovido para `Real` quando a
  variável já é `Real` (o inverso, atribuir `Real` a uma variável `Integer`, é
  `type-mismatch`).

Exemplo (com `a` e `b` não definidos antes):
```c
a = b = 1.0; // a e b são Real
a = 3;       // ok: 3 (Integer) é promovido para Real
b = "Hello"; // [type-mismatch]
```

### 4.10 Valores e cópias

Tudo é um valor; não existem referências visíveis ao usuário. Atribuição e passagem de parâmetro preservam a semântica de valor: reatribuir uma variável não muda o valor guardado por outra variável.

Os valores string são imutáveis. Não existe tipo `char`: indexar uma string devolve uma `String` de comprimento 1 (por exemplo, `{ s = "Hello"; s[0]; }` devolve `"H"`). A atribuição pode substituir o valor inteiro de uma variável, sujeito ao seu tipo fixo, mas as expressões de indexação são somente leitura e não podem ser alvos de atribuição.

```c
{
    a = "Hello";
    b = a;
    b = b[1];    //OK, b[1] == "e", então b = "e" 
    println(a);  //Hello
    println(b);  //e
}
```

Uma função pode, da mesma forma, substituir o valor inteiro de um parâmetro sem alterar a variável do chamador. As capturas congeladas retêm seus valores do momento da definição; a atribuição a um vínculo externo original segue 4.9.

Não é necessário fazer cópia profunda física quando o armazenamento imutável pode ser compartilhado com segurança. O armazenamento interno pode ser compartilhado desde que a independência de valores e a vida útil do armazenamento sejam preservadas. Copiar um descritor não estende a vida útil de
seu armazenamento base: um resultado que de outra forma apontaria para uma arena de escopo liberada deve ser copiado para a arena de destino ou mantido vivo por uma estratégia de posse compatível. A imutabilidade por si só não muda os requisitos de vida útil de arena do projeto.

### 4.11 Tratamento de erros em execução

Erros de tempo de execução podem ser capturados em linguagem com `try` e
levantados com `fail` (Seção 5). `try` é um construto da linguagem, como `iif`
e `for` — não é um valor e não pode ser passado como argumento; `fail` é um
interno como qualquer outro.

`try` avalia sua expressão sob proteção, em duas formas, ambas no estilo de
`iif`:

- **`try(expr)`** — sonda: devolve `true` sem erro, `false` com erro. Se `expr`
  for uma atribuição (`try(v = expr)`), a atribuição acontece apenas no sucesso
  e a primeira atribuição bem-sucedida fixa o tipo de `v`; se for uma expressão
  comum (`try(f(0))`), o valor é descartado.
- **`try(expr, default)`** — valor ou default: devolve o valor de `expr` se não
  houver erro; caso contrário, o valor de `default`. Equivale ao
  `outcome T r = expr else default; return outcome.value(r);` do keel.
  `default` é avaliado de forma preguiçosa, apenas na falha, e **sem
  proteção**: um erro dentro de `default` é um erro novo, que propaga
  normalmente. Os tipos de `expr` e `default` devem ser compatíveis sob a
  mesma regra de promoção `Integer` → `Real` dos operandos binários
  (`type-mismatch` em caso contrário).

Comum às duas formas:

- **Sem erro**: `last_error` é zerada (`""`) ao fim da avaliação.
- **Com erro**: a atribuição, quando houver, não acontece — `v` permanece com o
  valor anterior, ou indefinida se nunca existiu. O diagnóstico foi gravado em
  `last_error` no momento do levantamento (`fail` ou o interno que falhou) e
  permanece lá; **não** é relatado no stderr.
- A captura vale para qualquer erro que escape de `expr`: os levantados dentro
  de funções chamadas por ela e pela própria atribuição (por exemplo, um
  `type-mismatch` ao vincular `v`).
- Efeitos já realizados dentro de `expr` não são desfeitos (4.2).
- Armadilha (sonda com atribuição): na falha com `v` nunca definida, ler `v`
  depois é `undefined-identifier` — na falha use `last_error`, nunca `v`. A
  forma com `default` não tem essa armadilha: não introduz variável.

`last_error` é uma variável global predefinida, `String`, **somente leitura**,
atualizada automaticamente a cada `try` que falha. Seu conteúdo é livre — os
internos gravam a mensagem do diagnóstico; `fail(msg)` grava a `msg` do usuário
— e é detalhe: o controle de fluxo se faz com o `Boolean` de `try`.

`try` aninhado: um `try` interno que falha devolve `false` (sonda) ou o valor
de `default` (dois argumentos) como **valor**; o `try` externo conclui com
sucesso. O erro não escapa — checar o resultado interno é responsabilidade de
quem aninha.

Não são capturáveis: o limite de profundidade de chamada e o orçamento de passos
de avaliação (Seção 7) sempre abortam o programa, capturados ou não.

O programa compilado é envolvido pelo gerador em um `try` implícito: um erro
não capturado em linguagem é capturado nesse envoltório, relatado uma única vez
no stderr e o processo termina com status diferente de zero (Seção 7). A
estratégia de implementação — propagação um-nível com `outcome` do keel e a
tabela de mapeamento para o código gerado — está descrita em
[diretrizes-erros.md](docs/diretrizes-erros.md).

Idiomas usuais:

```c
// valor default em caso de erro — sem variável auxiliar
num = try(a / b, 0.0);
```

```c
// ignorar qualquer erro dentro de f
{ try(f(0)); print("seguimos"); }
```

```c
// usar last_error no ramo de falha
iif(try(v = f(x)), print(v), print(last_error));
```


## 5. Funções Internas

- `print(x)`: Imprime o argumento no stdout. Devolve um `Integer` com o número
  de **pontos** impressos. Strings são impressas sem aspas delimitadoras.
  Booleanos são impressos como `true` ou `false`. Valores `Real` usam
  `fmt_decimals` e `fmt_sigdigits`. Nenhuma nova linha final é acrescentada
  automaticamente: use `println(x)`, um `print("\n")` explícito ou inclua `\n`
  em uma string quando necessário. Caracteres de nova linha explícitos contam
  para o número de pontos devolvido.

- `println(x)`: Igual a `print(x)`, mas acrescenta automaticamente um `\n` ao
  final da saída e inclui esse `\n` na contagem de pontos devolvida.

- `len(string)`: Devolve um `Integer` com o comprimento da string em pontos.
  Passar outro tipo (como `Integer` ou `Real`) é `type-mismatch`.

- `input(prompt)`: imprime a `String` `prompt` e lê uma linha do stdin,
  devolvendo-a como `String`. O tratamento de fim de entrada (EOF) permanece a
  especificar.

- `upper(string)` / `lower(string)`: devolvem uma nova string com as letras
  ASCII convertidas para maiúsculas/minúsculas (`A`–`Z` ↔ `a`–`z`); os demais
  pontos são preservados. Passar outro tipo é `type-mismatch`. São a base da
  comparação sem caixa (5.2).

- `string(val)`: Converte explicitamente `val` para `String` (`Real` usa
  `fmt_decimals` e `fmt_sigdigits`).

- `integer(s)`: Converte uma `String` decimal em `Integer`. Passar um valor que
  não seja `String` (por exemplo `integer(3.9)`) é `type-mismatch` — no caso
  de `Real`, o diagnóstico orienta a usar `int`, `round`, `floor` ou `ceil`.
  Não existe `bool(val)`: expressões como `(s == "true")` cumprem esse papel.

- `real(s)`: Converte uma `String` em `Real`. Passar um valor que não seja
  `String` é `type-mismatch` (a conversão de `Integer` para `Real` ocorre pela
  regra de promoção implícita).

- `int(num)`, `frac(num)`, `ceil(num)`, `floor(num)`, `round(num)`:
  arredondamento sobre `Real`. `int` devolve a parte inteira de `num` (trunca
  em direção a zero); `floor`/`ceil` arredondam para baixo/cima; `round`
  arredonda metade para longe de zero; `frac` devolve a parte fracionária com
  sinal (`frac(x) == x - int(x)`).

| x | int | floor | ceil | round | frac |
|---|---|---|---|---|---|
| 3.99 | 3 | 3 | 4 | 4 | 0.99 |
| -3.7 | -3 | -4 | -3 | -4 | -0.7 |
| 5.5 | 5 | 5 | 6 | 6 | 0.5 |

Infinito e NaN se propagam (`int(INF) == INF`, `int(NaN) == NaN`), seguindo
`trunc`, `floor`, `ceil`, `round` do `math.h` de C.

- `at(s)(i)`: recebe uma string `s` e devolve uma função que recebe o índice
  `i` (`Integer`, baseado em 0), devolvendo uma `String` de comprimento 1 (um
  ponto Unicode), pois não há tipo `char` (composição/currying estilo Haskell).
  `s[i]` é açúcar sintático para `at(s)(i)`; as regras de índice em 4.10 se
  aplicam.

- `fail(msg)`: levanta um erro de execução cujo diagnóstico é a `String`
  `msg`, gravada em `last_error`; o controle salta para o `try` que envolve a
  expressão (Seção 4.11) — sem `try` em vigor, o programa aborta. `fail` nunca
  devolve valor. É um valor de função e pode ser passado como argumento
  (`use_func(fail)`).

- `last_error`: variável global predefinida, `String`, somente leitura; reflete
  o `try` mais recente: vazia (`""`) quando ele teve sucesso — `try` a zera ao
  fim da avaliação — e com o diagnóstico quando ele falhou. O diagnóstico é
  gravado no momento do levantamento: `fail(msg)` grava a `msg`; internos que
  falham gravam a mensagem do diagnóstico. Atribuir a `last_error` é erro, como
  a qualquer vínculo predefinido.

- Os internos são símbolos globais predefinidos e **somente leitura**:
  atribuir a um nome interno é um erro (`builtin-redefinition`). Sem essa
  proteção não há garantia de funcionalidade — `print` e `println` são as
  únicas formas de saída da linguagem; sobrepujados, o programa fica sem
  output. Essa regra vale apenas para os internos: funções de biblioteca
  (incluindo uma futura stdlib) podem ser redefinidas livremente pelo usuário.
  Não há carregamento dinâmico: arquivos `.x` só entram no programa pelo
  carregamento estático via `include` (Seção 4.3). Uma definição do usuário
  vincula um valor de função anônima a uma variável.

- Os internos guardam valores de função e podem ser passados como argumentos
  como qualquer função (`use_func(print)` é válido).

### 5.1 Formatação de números

`fmt_decimals` (`Integer`, padrão `2`) e `fmt_sigdigits` (`Integer`, padrão `5`)
são variáveis globais predefinidas que controlam como `print` e `string`
convertem valores `Real` em texto: `fmt_decimals` é o número de **casas
decimais** da notação fixa, para expressões em ponto flutuante bem
representáveis; `fmt_sigdigits` é o número de **dígitos significativos** da
notação científica, usada quando o valor não é bem representado em notação
fixa — por ser pequeno demais (as casas decimais virariam zeros à esquerda)
ou grande demais (a parte inteira ultrapassaria `fmt_sigdigits` dígitos):

A configuração de formatação se aplica atualmente apenas a valores `Real`.
Extensões para outros tipos e campos de formatação adicionais ainda não estão
especificadas.

- `NaN`, `INF` e `-INF` são impressos literalmente, ignorando `fmt_decimals` e
  `fmt_sigdigits`.
- Se `10^-fmt_decimals <= |x| < 10^fmt_sigdigits`: notação fixa com
  `fmt_decimals` dígitos após a vírgula — `20.0` é impresso como `20.00`.
- Caso contrário: notação científica com `fmt_sigdigits` dígitos
  significativos — `0.001` é impresso como `1.0000e-3`;
  `1234567890123456789.0` como `1.2346e+18`. O primeiro dígito da mantissa
  conta como significativo: `1.2346e+18` exibe os 5 dígitos `1`, `2`, `3`,
  `4`, `6`.
- O arredondamento segue o `printf` de C (arredonda metade para o par).
- `real(string(x)) == x` não é garantido; use `fmt_decimals = 17` e
  `fmt_sigdigits = 17` para idas e voltas exatas.

### 5.2 Semântica de operadores

| operandos | `+` | `-` `*` `/` | `< <= > >=` | `== !=` | `not`/`and`/`or` |
|---|---|---|---|---|---|
| `Integer` ⊗ `Integer` | soma (`Integer`) | aritmética (`Integer`) | `Boolean` | `Boolean` | — |
| `Real` ⊗ `Real` | soma (`Real`) | aritmética (`Real`) | `Boolean` | `Boolean` | — |
| `Integer` ⊗ `Real` (ou `Real` ⊗ `Integer`) | promoção implícita `Integer` → `Real`; soma (`Real`) | promoção implícita `Integer` → `Real`; aritmética (`Real`) | `Boolean` (após promoção) | `Boolean` (após promoção) | — |
| `String` ⊗ `String` | concatenação | `type-mismatch` | `Boolean`, lexicográfico por ponto (`"A" < "a"`) | `Boolean` | — |
| `Boolean` ⊗ `Boolean` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `Boolean` | `Boolean`; `and`/`or` em curto-circuito |
| operandos `Function` | `type-mismatch` | `type-mismatch` | `type-mismatch` | `type-mismatch` | — |

- `+`: `Integer` e `Real` somam (com promoção implícita `Integer` → `Real` em operandos mistos); `String` concatenam.

- `-`, `*`, `/`: somente `Integer` e `Real` (com promoção implícita `Integer` → `Real` em operandos mistos).

- comparações: `Integer`, `Real` e `String` produzem um `Boolean`. Fora `Integer` → `Real`, não há conversão implícita entre tipos distintos (`type-mismatch`).

- NaN segue a IEEE-754: toda comparação que envolve NaN é falsa.

- comparações de `String` são **sensíveis a caixa** — os pontos são comparados lexicograficamente, `"A" != "a"`. Para uma comparação que ignore caixa, compare as duas strings convertidas: `upper(s1) == upper(s2)` ou `lower(s1) == lower(s2)`. Não há interno dedicado a comparação sem caixa: a composição com `==` cobre o caso.

## 6. Constantes Matemáticas

As constantes matemáticas predefinidas são vínculos somente leitura. Atribuir a
uma constante é um erro. A comparação de igualdade lê seu valor normalmente.
Assim, `pi = 3.14` é inválido, enquanto `pi == 3.14` é válido e avalia para
`false`. O código de erro público para atribuição a uma constante permanece a
especificar. Atualmente não existe sintaxe para constantes definidas pelo
usuário; `const` não é uma palavra-chave nem um construto de linguagem
implementado.

- `NaN` : Not a Number (não é um número)
- `INF` : Infinito — pode ser usado com unário "+" ou "-"
- `pi` ou `PI` : o pi;
- `exp` ou `EXP` : o número de Euler

## 7. Erros

xpr é um transpilador/compilador: todo o arquivo é analisado em um AST e
transpilado para Keel antes da execução, portanto os erros existem em duas
fases: **tempo de análise** e **tempo de execução**. Erros de sintaxe são
detectados até dentro de corpos de função que nunca são chamados.

Um erro de avaliação não capturado por `try` (4.11) para a avaliação no
primeiro erro e não produz resultado para a expressão que falhou. Um
diagnóstico não capturado é relatado uma única vez no stderr; um erro capturado
por `try` é tratado em linguagem e não é relatado. Erros relacionados
à origem incluem o nome, a linha e a coluna da origem, com as colunas contadas
em pontos. Erros sem localização de origem relatam em vez disso o arquivo, a
operação ou o argumento relevante. Uma compilação ou execução com falha
devolve um status de processo diferente de zero, independente da enumeração
interna de diagnósticos. Os efeitos já realizados não são desfeitos
automaticamente.

**Fonte única de definições de diagnóstico**

O catálogo `XPR_DIAG_LIST` em [src/xpr.h](src/xpr.h) é a fonte autorizada
para os códigos de diagnóstico, identificadores públicos, severidades, modelos
de mensagem e dicas. `XprErrorCode` e `XPR_DIAG_TABLE` são derivados desse
catálogo. Esta especificação não mantém uma tabela normativa separada de
diagnósticos. Qualquer referência gerada de diagnóstico deve derivar suas
entradas do catálogo, em vez de duplicá-las manualmente.

As seções semânticas desta especificação determinam quais operações devem
falhar e quando. Os nomes de erro citados ali descrevem as condições
semânticas; o catálogo determina o identificador de diagnóstico e a
apresentação reais. Se um nome em outro lugar da documentação diferir do
catálogo, o catálogo prevalece para a definição do diagnóstico. Uma condição de
erro exigida ainda não representada no catálogo permanece uma tarefa de
implementação; sua ausência não torna a operação válida.

O projeto de propagação e limpeza de diagnósticos está descrito em
[diretrizes-diagnosticos.md](docs/diretrizes-diagnosticos.md). Abortar a avaliação
significa relatar a falha por meio desse fluxo de diagnóstico e desenrolar a
pilha com a limpeza exigida, não chamar `abort()` de C nem sair diretamente do
avaliador. Um diagnóstico fatal encerra o processo após o relato e a limpeza
finais.

**Condições de erro exigidas**

- A análise rejeita sintaxe inválida, alvos de atribuição inválidos, blocos
  vazios e uma origem completa que não contém nenhuma expressão. Os alvos de
  atribuição devem ser identificadores. Expressões indexadas nunca são alvos de
  atribuição válidos.
- A avaliação rejeita tipos incompatíveis, identificadores
  não definidos, divisão por zero, chamadas a valores que não são função, chamadas com aridade
  incompatível (`arity-mismatch`), índices inválidos e atribuições a vínculos predefinidos somente leitura
  (constantes matemáticas, `last_error` e nomes das funções internas —
  `builtin-redefinition`), de acordo com as seções semânticas.
- A profundidade de chamada de função é limitada a 10.000; excedê-la é um erro
  de avaliação. Esse limite de profundidade de chamada é separado do orçamento
  de passos de avaliação e da pilha de manipuladores de exceção da
  implementação. Nem o limite de profundidade nem o orçamento de passos são
  capturáveis por `try` (4.11); eles sempre abortam o programa.
- Esgotar um orçamento de passos de avaliação habilitado aborta a avaliação com
  um erro.

## 8. Interface de linha de comando

O transpilador é invocado como `xpr <opção>`. As formas suportadas são:

| Invocação | Comportamento |
| --- | --- |
| `xpr <nome-do-arquivo.x>` | Compila o programa do arquivo especificado: transpila para um arquivo `.k` e aciona a compilação final. |
| `xpr --lex-dump <arquivo>` | Interrompe a compilação no lexer, despejando os tokens do arquivo especificado para depuração. |
| `xpr --parse-dump <arquivo>` | Interrompe a compilação no parser, despejando a árvore de sintaxe analisada do arquivo especificado para depuração. |
| `xpr --gen-dump <arquivo>` | Interrompe a compilação na geração, despejando o código Keel (`.k`) produzido para depuração. |
| `xpr -h` ou `xpr --help` | Mostra a ajuda de uso. |

A ajuda também exibe primeiro a versão do transpilador.

Todo `include` é inclusão textual (um verdadeiro `#include` do C), então o
programa inteiro vira uma única unidade: a geração produz sempre **um único
arquivo `.k`** na pasta atual, por maior que seja o programa. Não há módulos
nem geração de múltiplos arquivos nesta versão da linguagem.

O programa compilado não imprime automaticamente o valor da expressão final.
A saída deve ser solicitada explicitamente por meio das funções de saída.
