# XPR — Rationale Normativo

Este é o **segundo documento normativo** do XPR. A
[especificação](xpr-specs-pt.md) define **o que** a linguagem é; este documento
define **por que** cada regra existe e quais alternativas foram recusadas.

Ele é normativo em dois sentidos concretos:

1. **Critério de admissão.** Toda proposta futura de mudança é avaliada contra
   os critérios de [R1](#r1-criterios-de-admissao). Uma proposta que
   contrarie uma recusa registrada em [R15](#r15-registro-de-recusas) só é aceita
   se refutar, explicitamente, a razão que motivou a recusa.
2. **Fonte de intenção.** Quando a especificação for ambígua, a razão registrada
   aqui desempata a leitura — mas **nunca acrescenta regra que a especificação
   não tenha**. Se a razão exigir uma regra ausente, a especificação é que está
   incompleta e deve ser corrigida.

A numeração é estável. Cada seção declara qual parte da especificação ela
justifica, e os identificadores `R<n>` são referenciados entre documentos.

## Índice

- [R1. Critérios de admissão](#r1-criterios-de-admissao)
  - [C1 — Tudo é expressão](#c1--tudo-e-expressao)
  - [C2 — Regra da simplicidade](#c2--regra-da-simplicidade)
  - [C3 — Preferência por mecanismos existentes](#c3--preferencia-por-mecanismos-existentes)
  - [C4 — Falha cedo](#c4--falha-cedo)
  - [R1.1 O caso `import`: o construto que era um valor disfarçado](#r11-o-caso-import-o-construto-que-era-um-valor-disfarcado)
- [R2. Tudo é expressão](#r2-tudo-e-expressao)
- [R3. Sete tipos, imutáveis](#r3-sete-tipos-imutaveis)
  - [R3.1 Três categorias de nome reservado](#r31-tres-categorias-de-nome-reservado)
  - [R3.2 Notação de terminal no léxico](#r32-notacao-de-terminal-no-lexico)
  - [R3.3 Assimetria de terminação: linha pode acabar no EOF, bloco não](#r33-assimetria-de-terminacao-linha-pode-acabar-no-eof-bloco-nao)
  - [R3.4 Sem anotação de tipo — nem no parâmetro, nem no retorno](#r34-sem-anotacao-de-tipo--nem-no-parametro-nem-no-retorno)
- [R4. Aritmética da aridade e currying](#r4-aritmetica-da-aridade-e-currying)
  - [R4.1 Despacho por valor de função — o "polimorfismo" que sai de graça](#r41-despacho-por-valor-de-funcao--o-polimorfismo-que-sai-de-graca)
- [R5. `%` e a ausência de `divmod`](#r5--e-a-ausencia-de-divmod)
- [R6. Closures e recursão](#r6-closures-e-recursao)
- [R7. Módulos são valores, não texto incluído](#r7-modulos-sao-valores-nao-texto-incluido)
  - [R7.1 O ganho decisivo foi de escopo](#r71-o-ganho-decisivo-foi-de-escopo)
  - [R7.2 Argumento literal obrigatório](#r72-argumento-literal-obrigatorio)
  - [R7.3 Avaliação uma vez por arquivo](#r73-avaliacao-uma-vez-por-arquivo)
  - [R7.4 O caminho do módulo é metadado, não campo](#r74-o-caminho-do-modulo-e-metadado-nao-campo)
- [R8. Structs e tuplas: recusadas por ora](#r8-structs-e-tuplas-recusadas-por-ora)
- [R9. Listas](#r9-listas)
  - [R9.1 Lista passa em C1: é valor, logo é expressão](#r91-lista-passa-em-c1-e-valor-logo-e-expressao)
  - [R9.2 Vetorização: uma regra única, recursiva](#r92-vetorizacao-uma-regra-unica-recursiva)
  - [R9.3 Construtores e I/O de dados](#r93-construtores-e-io-de-dados)
- [R10. `native` e o `math.h`](#r10-native-e-o-mathh)
- [R11. Predicados de tipo](#r11-predicados-de-tipo)
- [R12. Internos versus biblioteca](#r12-internos-versus-biblioteca)
- [R13. `print` de função e módulo](#r13-print-de-funcao-e-modulo)
- [R14. Modelo de memória](#r14-modelo-de-memoria)
- [R15. Registro de recusas](#r15-registro-de-recusas)

## R1. Critérios de admissão

Justifica: o conjunto da especificação.

**Meta.** Uma linguagem pequena, explicável por um documento curto, orientada a
programas funcionais pequenos — inclusive de IA para IA, onde o custo de gerar e
revisar código domina.

Os critérios são **filtros em ordem**. Uma proposta que falha em C1 não passa
para C2: não há trade-off a negociar depois de uma falha categórica.

### C1 — Tudo é expressão

> Se a feature só pode existir como construto — algo que **não devolve valor** e
> por isso precisa de posição sintática própria —, ela não é XPR.

Este é o critério **primário**, e não a contagem de regras. A ordem importa:
um construto pode *reduzir* o número de regras e mesmo assim ser recusado, porque
custo de construto não se mede em regras. Um construto cria, de uma vez:

- uma posição sintática nova, com regra de onde pode e onde não pode aparecer;
- uma segunda gramática (a de "instruções"), que a §3 não tem;
- a pergunta "que valor devolve?", que reabre a cada uso;
- exceções de composição: não compõe com `iif`, não vira argumento, não vira
  campo de módulo, não é devolvido por função.

**O teste operacional.** Antes de aceitar uma feature, pergunte: *que valor ela
produz?* Se a resposta for "nenhum, é só um efeito/declaração", a feature está mal
enquadrada — o mais provável é que exista um valor por trás dela. Encontre o
valor e a feature passa a ser expressão; não encontre, e ela não entra.

A história de `import` é o caso-escola, e está em R1.1.

### C2 — Regra da simplicidade

> Uma feature entra se reduz ou mantém o número de regras normativas. Se
> aumenta, só entra quando o caso de uso é comprovado por código real escrito na
> própria linguagem.

O critério é sobre **regras**, não sobre linhas de código nem sobre poder
expressivo. Uma feature pode valer muitas linhas de implementação e poucas
regras; o que se mede é quantas decisões normativas novas ela cria. Só se
aplica **depois** de C1: entre duas features que são expressões, ganha a que
custa menos regra.

### C3 — Preferência por mecanismos existentes

Se a feature pode ser expressa compondo regras que já existem, ela não é uma
feature: é um idioma. Exemplos estruturais neste projeto:

| necessidade | mecanismo já existente | feature evitada |
| --- | --- | --- |
| ler campo de módulo | `field_suffix` em `postfix` | acesso qualificado como categoria léxica |
| despachar por tipo | `iif` preguiçoso + `is_*` | sobrecarga, `dispatch` |
| escolher função em runtime | `iif` como `atom` + `call_suffix` | construto de despacho (R4.1) |
| funções de duas entradas | currying por aninhamento de `fn` | segundo parâmetro |

### C4 — Falha cedo

Entre duas semânticas equivalentes, prefira a que permite detectar o erro na
análise. É o que motiva `import` com argumento literal, `field-not-found`
estático quando o receptor é identificável, e a análise de corpos de função
nunca chamados.

**Como usar este documento numa proposta.** Uma proposta deve declarar, nesta
ordem: (a) **que valor a feature produz** — se nenhum, C1 já a rejeita;
(b) qual regra da especificação muda; (c) quantas decisões normativas novas
cria; (d) qual caso de uso a paga, com código; (e) se contraria alguma recusa de
R15, a refutação daquela razão.

### R1.1 O caso `import`: o construto que era um valor disfarçado

Justifica: §1 (`Module`), §3, §4.8; a história completa está em R7.

Enquanto `import` foi pensado como **construto**, três remendos tiveram de entrar
na linguagem para sustentar algo que não era expressão:

| remendo | por que era necessário | o que era o problema |
| --- | --- | --- |
| segundo argumento de alias (`include("lib.x","std")`) | o construto não produzia valor, então o nome tinha de ser dado a ele | um construto precisando de parâmetro para se tornar nomeável |
| `qualified_name` como classe de literal | o acesso `std.range` não derivava de `postfix`, porque não havia valor à esquerda do ponto | gramática paralela só para nomear |
| "colado no ambiente léxico do chamador" | o texto entrava no ponto do construto, logo herdava o escopo de quem chamou | dependência de estado oculto, o bug clássico de macro sem higiene |

Nenhum dos três era um problema de **módulos**. Os três eram sintomas de C1
violado: um construto sem valor precisa que a linguagem lhe dê nome, caminho de
acesso e escopo, um por um.

**O valor estava lá desde o começo: uma referência ao módulo.** Reconhecido isso,
`import` virou `import_expr` que produz um `Module`, e os três remendos
desapareceram **juntos**, sem substituição:

- o alias virou a variável que recebe o valor;
- o acesso virou o `field_suffix` que já existia em `postfix`;
- o escopo virou o do próprio módulo, autocontido por construção (R7.1).

**A lição, que é a razão de C1 ser primário.** O construto não era mais
"simples" que a expressão: era mais caro. Parecia simples porque escondia o
valor, e o valor escondido cobrava pedágio em cada lugar onde a linguagem
precisava falar sobre ele — nome, acesso, escopo. Uma feature "mais simples que
parece" é o sintoma clássico de valor não identificado.

**Sinal de alarme para propostas futuras.** Se uma proposta pede duas ou mais
destas coisas ao mesmo tempo — um nome próprio, uma forma de acesso, uma regra
de escopo, uma posição onde pode aparecer — a causa provável não é a lista de
pedidos; é que o valor da feature não foi identificado.

## R2. Tudo é expressão

Justifica: §3 (gramática), §4 (semântica), especialmente §4.6.

Um programa é uma expressão e cada construto devolve valor. Isso elimina a
distinção comando/expressão: blocos, `iif`, `for`, `import` e `fn` compartilham
a mesma regra de composição, e não há uma segunda gramática para "instruções".

**R2 é o alicerce e C1 é o guardião.** R2 descreve o resultado; C1 é o filtro que
o mantém. Toda feature que entrasse como construto abriria a segunda gramática
que R2 nega — por isso C1 é categórico e vem antes de qualquer conta de regras.
O caso `import` (R1.1) mostra o custo de deixar um construto passar: ele cobra
nome, acesso e escopo, um a um, e cada remendo parece uma feature nova.

**Consequência aceita.** `for` devolve a contagem de iterações, não o valor do
corpo. A alternativa — devolver o último valor do corpo — exigiria uma regra
própria de acumulação, porque o corpo é descartado como qualquer expressão
intermediária de bloco (§4.3). A contagem foi escolhida porque é a única
informação que `for` produz sem precisar de regra nova.

**Tensão registrada.** A ausência de acumulação é o que torna `list(n)(f)`
necessário no futuro (R9): não há como construir uma coleção de `n` elementos
sem um construtor privilegiado.

## R3. Sete tipos, imutáveis

Justifica: §1, §4.9.

`Integer`, `Real`, `String`, `Boolean`, `List`, `Function`, `Module`. Todos
imutáveis.

**Sem `char`.** Strings são sequências de pontos Unicode; um caractere é uma
string de comprimento 1. Um tipo `char` separado duplicaria toda a
funcionalidade de string para representar um único ponto.

**Sem tuplas, registros nem tipos definidos pelo usuário.** É o que mantém a
análise de tipos tratável com despacho por tag em runtime. Cada tipo novo é uma
variante em `xpr_Value`, um predicado `is_*`, uma linha na tabela de operadores
(§5) e uma regra de igualdade — quatro custos por tipo.

**`Integer` é de 32 bits.** O tamanho acompanha a promoção `Integer` → `Real`
(§1): com 64, inteiros acima de 2^53 perderiam exatidão ao serem promovidos ao
`Real` de dupla precisão; com 32, a promoção é **sempre exata**. Alinha o valor
com o `int` de C e as larguras de SIMD. O custo é aceito de olhos abertos:
contagens limitadas a 2^31 — `count_reals` de um arquivo com mais de ~2,1
bilhões de valores estoura; ler por camadas segue possível. Hipótese futura
registrada: um tipo `size`, estilo `size_t`, dedicado a comprimentos, caso essa
contagem se torne limite real.

**Uma única conversão implícita.** `Integer` → `Real`, e apenas quando um
operador ou interno espera `Real`. A restrição existe para que o custo de
qualquer outra conversão apareça no código-fonte, como chamada explícita (§6.3).

### R3.1 Três categorias de nome reservado

Justifica: §2, §6, §7.

Nem todo nome reservado é palavra-chave. A distinção é semântica, não
cosmética, e o critério é **ter ou não valor**:

| categoria | membros | tem valor? | por quê é reservado |
| --- | --- | --- | --- |
| palavra-chave | `fn`, `iif`, `for`, `try`, `import` | **não** | são formas sintáticas; o token inicia um construto |
| operador | `not`, `and`, `or` (+ os simbólicos) | não (agem sobre valores) | o lexer emite token de operador; sem reserva, `a and b` seria ambíguo com uma sequência de nomes |
| constante | `true`, `false` | **sim**, `Boolean` | o lexer emite token próprio, mas semanticamente são literais como `42` |

`true` e `false` merecem ênfase porque a classificação errada tem consequência:
tratá-los como palavra-chave sugeriria que introduzem um construto, quando na
verdade **são valores** — passíveis de atribuição a variável, argumento e
resultado de função. São somente leitura pelo mesmo motivo que `pi`: atribuir a
um nome predefinido é `builtin-redefinition`.

**Consequência registrada.** `true = 1` é `wrong-assignment`, não
`builtin-redefinition`: o alvo de uma atribuição deve ser identificador (§4.2), e
`true` não é identificador. A distinção importa para o diagnóstico correto: o
erro é de forma, não de permissão.

**Por que não tratar `true`/`false` como identificadores predefinidos** (que é o
que `pi` e `e` são): eles seriam reatribuíveis na primeira atribuição do escopo
onde não houvesse a constante, e `fn(){ true = 1; }` passaria a ser legal em
escopo interno. Token próprio fecha isso na análise. O custo é uma linha no
léxico; o benefício é que a semântica de `true` não depende de escopo.

### R3.2 Notação de terminal no léxico

Justifica: §2 (terminais, strings, comentários).

As regras léxicas não usam EBNF puro: o conteúdo de uma string ou comentário é
descrito por um predicado, não por uma produção. A notação adotada em §2:

```
any_not( P ) = ? um ponto Unicode, desde que ele não inicie P ?
```

**O predicado não consome nada.** `any_not(P)` consome exatamente um ponto, e o
ponto consumido não pode ser o **início** de `P`. Isso resolve os três casos
corretamente, o que uma negação de sequência não faria:

| construto | predicado | por quê |
| --- | --- | --- |
| string com `"` | `any_not( '"' ou "\\" )` | a aspa de fechamento termina; a barra inicia `escaped` |
| comentário de linha | `any_not( quebra de linha )` | a quebra termina o comentário |
| comentário de bloco | `any_not( a sequência "*/" )` | o par termina, o `*` isolado não |

O último caso é o que exige a notação de **sequência**: `/* a * b */` é um
comentário válido, e um predicado que excluísse o ponto `*` recusaria o `*` que
não forma `*/`.

**Um erro de notação que foi corrigido.** A versão anterior definia
`chars = ? qualquer ponto Unicode exceto as aspas delimitadoras e U+005C ?` e
depois usava `chars` também nos comentários. Como `chars` exclui a barra
invertida, `// C:\path` ficaria mal definido: o comentário não tem escapes, mas
a definição herdada os proibia. `chars` foi substituído por `any` e
`any_not(P)`, com um predicado por construto — sem termo compartilhado que
carregue uma restrição que só vale para um deles.

### R3.3 Assimetria de terminação: linha pode acabar no EOF, bloco não

Justifica: §2 (comentários), §10 (`unterminated-comment`, `unterminated-string`).

Os três construtos que consomem conteúdo têm delimitador de fechamento, exceto
um:

| construto | fechamento | EOF sem fechar |
| --- | --- | --- |
| string | aspa de fechamento | `unterminated-string` |
| comentário de bloco | `*/` | `unterminated-comment` |
| comentário de linha | quebra de linha **ou** EOF | **válido**: não há o que fechar |

**A assimetria é do construto, não da implementação.** O comentário de linha não
tem delimitador de fechamento — a quebra de linha é o que o encerra quando
existe, e no EOF simplesmente não há mais texto. Já o bloco declara `*/`
explicitamente, então o arquivo terminar antes dele é texto incompleto, do mesmo
modo que uma string sem a aspa.

**Recusa registrada: aceitar `/*` sem `*/`.** Seria tolerante com arquivo
truncado, mas o efeito prático é o oposto do desejado: o resto do arquivo vira
comentário silencioso, e o programa compila e roda sem as expressões que o autor
escreveu depois do `/*`. Um erro de digitação em uma linha desativa
silenciosamente o resto do programa — exatamente o tipo de falha que o critério
de falha cedo (C4) manda evitar. A aspa faltante tem o mesmo argumento e por
isso a mesma regra.

### R3.4 Sem anotação de tipo — nem no parâmetro, nem no retorno

Justifica: §1, §3 (`fn_def`), §4.4.

Nenhum construto declara tipo. `fn(x)` é a forma completa: não existem
`fn(x: Integer)`, `fn: Boolean(s)`, `x: Integer = 1`, `fn(): Integer`, nem
`import` com tipo. Anotação é `syntax-error`.

**A pergunta que a anotação responderia.** Ela existe para responder uma destas
três coisas: (a) como chamar a função corretamente; (b) como documentar a
intenção; (c) o que o compilador consegue verificar. XPR tem resposta para as
três sem anotação, e cada uma tem um mecanismo próprio:

| a anotação daria | o que XPR usa | por que basta |
| --- | --- | --- |
| contrato de chamada | `arity-mismatch` na chamada (§4.4) | a aridade é a única coisa que se pode errar na chamada |
| inspeção de tipo pelo chamador | `is_*` + `iif` (R11) | inspeção explícita, no ponto de uso |
| documentação da intenção | nome da função, comentário e corpo | o corpo tem 1 expressão a 1 parâmetro — cabe na tela |

**O argumento decisivo é que XPR não tem função de tipo de retorno único.**
`iif` não exige que os dois ramos tenham o mesmo tipo (§4.5): o tipo do
resultado é o do ramo escolhido. Logo uma função como

```c
describe = fn(x){ iif(is_real(x), "real", 0); };
```

devolve `String` ou `Integer` conforme o argumento — **em runtime**. Uma
anotação de retorno teria de ser uma **união de tipos**, e união de tipos é uma
feature estruturalmente maior que listas ou registros: exige regra de
compatibilidade, de estreitamento, de erro na união e de representação. Ou seja:
aceitar `fn: Boolean(s)` obriga a aceitar `fn: Integer|String(x)`, que viola o
critério de R1 por uma margem grande.

**Anotação que não pode ser garantida não é anotação, é promessa.** Com tipagem
dinâmica (R3), a anotação só seria verificável nos casos em que a análise
consegue inferir o tipo — e nesses casos a anotação não acrescenta nada, porque a
inferência já sabia. Nos demais — função recebida como argumento, valor vindo
de `m.campo`, resultado de `try` — ela teria de ser verificada em runtime, gerando
o mesmo `type-mismatch` que já aconteceria no uso. O ganho seria uma mensagem de
erro mais cedo; o custo, uma anotação em cada função.

**Consequência aceita.** `x = 1; x = "a";` é `type-mismatch` só porque o tipo do
**vínculo** é fixado na primeira atribuição (§4.2); não há como declarar o tipo
antes. Quem precisa de um vínculo polimórfico usa dois nomes, ou `iif` com
`is_*` no ponto de uso.

**Recusa registrada em R15:** anotação de tipo em qualquer posição.

## R4. Aritmética da aridade e currying

Justifica: §3 (`fn_def`, `call_suffix`), §4.4.

Funções têm no máximo um parâmetro. A restrição não é economia de parser.

**A razão real.** Sem listas nem tuplas, um segundo parâmetro seria a única
forma de passar duas entradas. Isso criaria duas regras de passagem de argumento
— uma para `fn(a)` e outra para `fn(a, b)` — com regras distintas de aridade,
de erro e de geração. Com um parâmetro, há uma regra só, e funções de N entradas
se escrevem como cadeias curried: `pow(base)(exp)`.

**O que vem de graça.** A cadeia de chamadas aninha à esquerda pela regra de
`postfix` (§3), então `f(x)(y)` é `(f(x))(y)` sem nenhuma disposição
adicional. `f(x, y)` é `syntax-error`.

**Consequência: toda operação de duas entradas é curried**, e essa é a única
forma. Uma variável global não serve como segundo operando, porque a closure a
congela na definição (§4.4).

**Recusa associada.** `dispatch(tipo, expr)` — tabela de tipos para simular
sobrecarga — era sintoma da ausência de inspeção de tipo, resolvida por `is_*` +
`iif` preguiçoso (R11), sem sintaxe nova.

### R4.1 Despacho por valor de função — o "polimorfismo" que sai de graça

Justifica: §3 (`atom`/`postfix`), §4.4 (composição), §4.5 (`iif`).

O que se pode escrever:

```c
iif(modo == "csv", fmt_csv, fmt_json)(dados);
```

Chama a função escolhida em tempo de execução. Não há construto novo: é `iif`
(preguiçoso, tipo livre) composto com o sufixo de chamada, e funciona porque
`iif_expr` é um `atom` — logo aceita `postfix` diretamente.

**Chamar isto de "polimorfismo" é impreciso, e a imprecisão esconde o valor.** O
que existe aqui são três mecanismos ortogonais, cada um com seu nome:

| mecanismo | o que varia | como se escreve |
| --- | --- | --- |
| **união dinâmica** | o tipo do valor, em runtime | `x = iif(c, 1, "a")` — e é justamente o que impede anotação de tipo (R3.4) |
| **seleção de valor** | qual função é usada | `f = iif(c, g, h)` |
| **despacho** | qual código roda para um dado | `iif(c, g, h)(x)` |

**Por que isso é estrutural e não um idioma.** O que torna o despacho possível
são **três** decisões que já estavam tomadas por outros motivos:

1. `iif` devolve valor de **qualquer** tipo e não unifica os ramos (§4.5). Se
   unificasse, `iif(c, g, h)` exigiria `g` e `h` do mesmo tipo — que é o caso
   banal.
2. `Function` é um valor como outro qualquer (R3), e **a aridade não faz parte
   do tipo** (§1). Sem essa segunda metade, `iif(c, f0, f1)` exigiria as duas
   funções com a mesma aridade, e o despacho entre `fn()` e `fn(x)` seria
   impossível.
3. O sufixo de chamada se aplica a **qualquer** `atom` (§3), inclusive a um `iif`.

Ou seja: **o despacho não custou nenhuma regra.** Ele caiu de decisões que
existem por outros motivos. É o caso mais forte da tabela de R1 — um mecanismo
existente cobrindo uma necessidade que em outras linguagens é feature própria.

**A ligação com a ausência de anotação.** A união dinâmica é o que permite
`iif(c, 1, "a")` **e** o que torna anotação de tipo cara (R3.4): as duas coisas são
a mesma decisão lida de dois ângulos. Não dá para ter a flexibilidade sem o
custo na anotação, nem a anotação sem perder a flexibilidade.

**O limite honesto.** Isto não é polimorfismo paramétrico: não há quantificação
nem verificação estática. É **despacho dinâmico com closure** — o que Smalltalk
chama de envio de mensagem, sem objetos. O preço é conhecido: um erro na escolha
só aparece quando a chamada acontece, não na análise. O `fail` no ramo final
(§4.4, tabela de despacho) é o que transforma esse erro em diagnóstico nominal em
vez de `not-callable` genérico.

**Recusa reafirmada.** `dispatch(tipo, expr)` — tabela de tipos com sobrecarga
resolvida por assinatura — continua recusado (R4, R15). O que existe é a
composição acima, que não resolve sobrecarga: escolhe **um** valor.

## R5. `%` e a ausência de `divmod`

Justifica: §3 (`term`), §5.

`/` sobre `Integer` já era divisão inteira; `%` completa o par, como em C. Isso
elimina o caso de uso mais citado a favor de tuplas: quociente e resto são
`a / b` e `a % b`, duas chamadas independentes.

**`%` não aceita `Real`, nem por promoção.** Não há resto fracionário útil, e
aceitá-lo exigiria uma regra de tipo a mais em §5. O sinal segue o dividendo, como
em C, porque é o comportamento que permite reconstruir o dividendo:
`(a / b) * b + a % b == a`.

**Consequência para R8.** Sem a necessidade de `divmod`, o argumento mais forte
a favor de tuplas desaparece. É a principal razão de a recusa de R8 se sustentar.

## R6. Closures e recursão

Justifica: §4.4.

**A auto-referência é estrutural, não por busca tardia.** Na definição
`fat = fn(n){ ... fat(n-1) ... }`, a ocorrência de `fat` no corpo resolve para
**a própria função em construção**, não para o valor atual da variável. O valor
dessa auto-referência é congelado junto com as demais variáveis livres.

Isso dá o comportamento esperado quando o vínculo é reatribuído:

```c
{
    fat = fn(n){ ... fat(n-1) ...; };
    g = fat;
    fat = fn(x){ x + 1; };
    g(5);   // 120, não 6
}
```

`g` aponta para a definição original, que embute uma referência àquela mesma
definição congelada. Reatribuir `fat` cria outro vínculo e não afeta a função
guardada em `g`.

**Alternativa descartada: vínculo tardio.** A função buscaria `fat` no escopo no
momento da chamada. Quebraria o exemplo acima — `g(5)` passaria a chamar a nova
`fat` e devolveria `6`. Também tornaria a recursão dependente do estado do
escopo no instante da chamada, o que é incompatível com a independência de
closure que R3 (imutabilidade) estabelece.

**Por que não há `letrec` nem forma especial para recursão.** A auto-referência
na atribuição cobre o caso completo. `fn` com nome próprio (`fn fact(n){...}`)
exigiria um segundo tipo de vínculo, com regra de sombreamento própria — custo
sem caso de uso.

## R7. Módulos são valores, não texto incluído

Justifica: §1 (`Module`), §4.8, §9.

A primeira versão tinha `include`, com semântica de `#include`: o texto entrava
no ponto do construto. Evoluiu por três correções registradas em ordem:

1. **Namespace por prefixo** — `include("stdlib.x")` expondo `stdlib.range`.
   Resolveu colisão de nomes.
2. **`include` como construto de declaração** — não produz valor, não é
   expressão. Correção de categoria, mas criou um problema novo: onde ele podia
   aparecer? Não no corpo de uma função, não como argumento.
3. **`import` como expressão** — a solução. O alias é a variável que recebe o
   valor: `std = import("stdlib.x")`. Módulo é valor, como `fn` é valor.

A terceira dissolveu as duas anteriores. Saíram da linguagem: o segundo argumento
de alias, a classe especial `qualified_name`, e a semântica "colado no ambiente
léxico do chamador". O campo `m.nome` passou a ser o `field_suffix` que já existia
em `postfix` (R1, mecanismo existente).

### R7.1 O ganho decisivo foi de escopo

Com inclusão textual, um arquivo importado capturaria variáveis do importador —
dependência de estado oculto, o bug clássico de macro sem higiene. Com módulo
como valor, o nível superior é avaliado em escopo próprio e **não vê** o
importador.

A pergunta "a biblioteca captura o `factor` do chamador?" não foi respondida:
ela **deixou de existir**. Autocontenção por construção é mais forte que
autocontenção por regra.

### R7.2 Argumento literal obrigatório

Com `import(nome)` variável haveria importação dinâmica, e a análise não saberia
quais arquivos carregar — o que impediria produzir um único `.k` (§9). A
restrição é de viabilidade do modelo de compilação, não de estilo.

### R7.3 Avaliação uma vez por arquivo

Como o módulo não vê o importador (R7.1), seu valor não depende de onde o
`import` aparece. Memoizar é seguro, e torna `recursive-import` detectável na
análise sem ambiguidade.

### R7.4 O caminho do módulo é metadado, não campo

`<module arquivo.x>` existe só para diagnóstico (R13). Não é acessível: `m.path`
é `field-not-found`. Um campo acessível violaria "o conjunto de campos é
exatamente o que o arquivo define" (§4.8).

## R8. Structs e tuplas: recusadas por ora

Justifica: §1, §2 (ausência de `:` na lista de operadores).

**O obstáculo é léxico, não semântico.** `{` já é bloco — sequência de
expressões com `;`, valor da última (§4.3). Um literal de registro seria conjunto
de vínculos com `,`. Duas gramáticas internas no mesmo delimitador,
distinguidas por um token no meio, geram ambiguidade de leitura mesmo quando o
parser desambigua:

```c
{ x = 1; y = 2; }    // bloco: duas expressões, devolve 2
{ x: 1, y: 2 }       // registro? mesma abertura, semântica oposta
```

**As saídas custam.** `record{...}` exige keyword nova; `(f: 1, g: 2)` exige `:`
novo e retira `(` da função de agrupamento puro; `<<f: 1>>` inventa delimitador.

**O custo em decisões normativas.** Cada saída traz ~7 decisões novas:
igualdade estrutural (é estrutural ou por identidade? a ordem importa? é
recursiva?), atualização de campo, desmontagem por padrão (que não existe),
`is_record` versus `is_module` (são o mesmo tipo?), representação em `print`,
notação de tipo em diagnóstico, e ordem dos campos. Isso viola R1.

**`Module` já é o tipo registro, e é mais forte.** Seu conjunto de campos é
conhecido na análise, porque vem do arquivo importado: um campo inexistente é
rejeitado antes da execução (§4.8). Um literal anônimo nunca tem essa
propriedade — o conjunto de campos de um valor anônimo só é conhecido em runtime.
Ou seja: módulo não é a versão pobre do registro, é a versão que a análise
consegue verificar.

**Condição de retorno.** O token `:` está livre na lista de operadores de §2, e a
regra de acesso a campo já existe. Um literal pode entrar depois como
**extensão pura**: mesmas regras de acesso, congelamento e erro, sem alterar nada
já escrito. A proposta que o trouxer deve responder as ~7 decisões acima e
declarar qual caso de uso as paga.

## R9. Listas

Justifica: §1 (`List`), §3 (`list_literal`), §5 (vetorização), §6.4, §6.8, §10.

**O adiamento terminou.** Nunca foi recusa — era ordem de implementação:
`xpr_Value` não existia, e uma variante no enum antes do codegen custaria uma
refatoração transversal. A spec mudou **antes** de qualquer código existir,
então trazer listas custou documento, não refatoração. O desenho é o da tabela
de R9.1, com as decisões de detalhe fechadas em R9.2 e R9.3.

### R9.1 Lista passa em C1: é valor, logo é expressão

Justifica: §1 (`List`), §3 (`list_literal`), R1 (C1), R2.

A pergunta que C1 obriga a fazer antes de qualquer discussão de sintaxe: **que
valor uma lista produz?** A resposta é imediata — a própria lista, como `42`
produz `42`. Lista é **tipo de dado**, não construto, e por isso passa em C1 sem
precisar de exceção alguma:

| | construto (recusado por C1) | lista (aceita) |
| --- | --- | --- |
| devolve valor? | não — é efeito/declaração | **sim**, um `List` |
| posição sintática | própria, com regra de onde cabe | nenhuma nova: é `atom` |
| compõe com `iif`/`fn`/bloco? | não | **sim**, como qualquer valor |
| segundo parâmetro? | exigiria construto | não: currying (R4) |

**O ponto que a intuição erra.** `list(n)(f)` *parece* um construtor privilegiado —
a palavra "construtor" sugere construto. Não é: `list` é um **interno** (§6), uma
função como `pow`, e `list(n)(f)` é aplicação de função curryficada, coberta
por `postfix` e R4. Privilegiado é o **fato de existir como interno** (não se
pode escrever em XPR puro), não sua forma sintática — que é a de qualquer
chamada. Mesma distinção que separa `print` (interno) de `fn` (forma sintática).

**Nada impede um construtor de listas**, e é por isso que listas não são
recusadas. O que C1 impede é um construtor que *não devolva valor*: `list { ... }`
como bloco de inicialização, ou `new l = []` como declaração. A forma aceita é
a que já existe — literal `[a, b]` como `atom` e `list(n)(f)` como chamada.

**A disciplina que C1 impõe sobre o desenho de listas** é o que explica cada
linha da tabela abaixo: `l[i]` é `index_suffix` que já existe; a árvore de
operações é expressão; `for` **não** constrói lista (devolve contagem, R2) —
daí a necessidade de `list(n)(f)`, e não de um construto de laço.

**O desenho acordado:**

| aspecto | decisão |
| --- | --- |
| literal | `[a, b, ...]`, homogêneo, com promoção `Integer` → `Real` |
| notação de tipo | `[Integer]`, `[[Real]]` — **só em diagnóstico**, não é sintaxe |
| operadores | vetorização única, elemento a elemento, recursiva (R9.2) |
| tamanhos diferentes | `size-mismatch` |
| indexação | somente leitura, `l[i]` por `postfix` (§6.4) |
| vazio | `[]` tem tipo `[?]`, compatível com qualquer `[T]`, fixando no primeiro `[T]` concreto (§4.2) |
| construtor | `list(n)(f)`, único interno privilegiado (R9.3) |
| leitura de dados | `read_reals`/`count_reals`, internos (R9.3) |
| biblioteca | `range`, `map`, `filter`, `fold`, `any`, `all`, `apply`, `apply2`, `identity`, `zeros`, `ones`, `at` |
| fora | concatenação, slice, append, mutação, broadcast |

**`any`/`all` são recursivos e biblioteca.** `==` entre listas devolve
`[Boolean]`, como todo operador (R9.2), e `iif` exige `Boolean` (§4.5): sem
agregação, não há como consumir o resultado de uma comparação de listas.
`any`/`all` colapsam a árvore — inclusive aninhada — até `Boolean`, com
recursão própria porque agregam. A igualdade estrutural é o idioma
`all(l1 == l2)`.

**`list(n)(f)` é o único interno privilegiado de construção** — interno, não
construto: é chamada curryficada (R9.1). Não pode ser biblioteca porque o
literal não constrói `n` elementos em execução e `for` devolve contagem, não
valores (R2). Sem ele, não há como montar uma lista de tamanho dinâmico — e a
alternativa seria exatamente o construto de laço que C1 proíbe.

### R9.2 Vetorização: uma regra única, recursiva

Justifica: §5 (bloco Vetorização), §10 (`size-mismatch`).

Todos os operadores de §5 aplicam a listas elemento a elemento por **uma**
regra: comprimentos iguais, resultado do comprimento comum, cada elemento o
resultado escalar da tabela. A recursão é da própria regra — o elemento que é
lista invoca a regra de novo — então `[[1,2]] + [[10,20]]` é `[[11,22]]` sem
tipo novo: matriz e tensor são listas aninhadas.

**A exceção do `==` estrutural foi recusada.** `==` devolvendo `Boolean` para
listas manteria a tabela de §5 uniforme e dispensaria `any`/`all` — parece
simplificação. O argumento decisivo, do usuário: *"abrimos uma exceção para UMA
operação porque parece que simplifica e acabamos com várias exceções adiante"*.
Ceder uma vez é aceitar que a forma de cada operador seja negociável; a regra
única fecha a questão para todos os operadores de uma vez. A igualdade
estrutural fica como idioma: `all(l1 == l2)`.

**Operadores preservam a forma; `any`/`all` colapsam.** A vetorização é
recursão da regra geral e devolve a forma dos operandos. `any`/`all` agregam
até `Boolean` e precisam de recursão própria — por isso são o par inseparável
da vetorização, e biblioteca (R12).

Unários vetorizam pela mesma regra: `-[1,2]` é `[-1,-2]`, `not [true]` é
`[false]`. `NaN` compara falso por elemento. Comprimentos diferentes são
`size-mismatch` — falha cedo (C4), sem regra de preenchimento. **Broadcast é
recusado**: `2 * [1,2]` é `type-mismatch`; combinar escalar com lista é papel
de `apply` (biblioteca), e duplicar essa semântica no operador seria a segunda
regra que a vetorização evita (R15).

### R9.3 Construtores e I/O de dados

Justifica: §6.8, §10 (`size-out-of-range`, `allocation-failure`, `file-not-found`
em execução).

**`list(n)(f)` é o único interno privilegiado de construção** (R9.1). `f`
recebe o índice e é avaliado em ordem `0..n-1` — os efeitos acontecem nessa
ordem, e a ordem é parte da definição, não detalhe de implementação.

**`read_reals`/`count_reals` fazem o caminho inverso de `import`.** Código é
estático: `import` exige literal (R7.2) porque a análise precisa conhecer todos
os arquivos para produzir um único `.k`. Dado é dinâmico: `path` é `String`
computável em execução, o offset é em **elementos** f64 (a aritmética de bytes
é detalhe do interno), e a falha de arquivo é `file-not-found` **em execução** —
mesmo id da análise, com o precedente de `undefined-identifier`, que também
existe nas duas fases com condições distintas.

Nenhum interno escreve em disco, então o arquivo é imutável durante a execução
— o que torna seguro um cache invisível por `(path, k, n)` (nota de
implementação, não regra de linguagem).

**Empacotamento é biblioteca, e nasce a terceira categoria.** f32, quantização,
cabeçalhos: nada disso é regra de linguagem — é código que decodifica bits e
devolve `Integer`/`Real`. Essa biblioteca precisará das primitivas
`bitbuffer`/`bitslice` do host, portanto não é XPR puro nem interno da spec: é
a terceira categoria de R12 — XPR puro / interno da spec / biblioteca em código
host.

**Socket e rede: adiados com registro.** A linguagem não tem semântica de
bloqueio nem de tempo; adicionar rede agora decidiria essas semânticas pelo
flanco. Dados estáticos entram por `import("data.x").campo`; sequência textual
de stdin é `list(n)(fn(i){ real(input("")); })`.

## R10. `native` e o `math.h`

Justifica: §6.5 (toda a matemática é interna).

`native("código keel")` foi proposto como o `asm{}` da linguagem, o que
permitiria escrever `math.h` como biblioteca em vez de internos. **Descartado.**

**Motivos, em ordem de peso:**

1. **ABI não definida.** O snippet precisa saber como acessar o argumento — que
   no código gerado é um valor etiquetado. Resolver isso exige ou vazar a
   representação interna no fonte (destruindo a abstração de R3), ou declarar
   tipos no fonte — e anotações de tipo são uma feature bem maior que listas.
2. **Protocolo de erro incompatível.** A propagação é por retorno
   (`outcome` + `else`, ver `docs/diretrizes-erros.md`). Um snippet não sabe
   levantar um erro da linguagem; portanto `native` só seria seguro para
   expressões infalíveis.
3. **Alocação insegura.** O snippet não participaria do modelo de arena (R14).
   Um ponteiro para arena liberada escaparia como valor.

**Consequência aceita:** toda a matemática permanece em internos. Quando houver
listas, a fronteira pode ser revista para as operações puras (R12).

## R11. Predicados de tipo

Justifica: §6.6.

`is_*` é a única forma de inspecionar o tipo de um valor. Não há tag acessível
nem operador de tipo — coerente com R3, onde o tipo é uma propriedade do valor e
não um dado manipulável.

**O critério é o de R12.** Sem `is_*`, nenhuma biblioteca polimórfica é
escrevível: `abs` para `Integer` e para `Real` não teria como se distinguir, e
teria de ser interno. Com eles, `abs` é biblioteca.

**Não promovem.** `is_real(1)` é `false`, mesmo que `1` seja promovido em
contexto `Real`. A promoção é uma regra de operador (§5), não uma mudança de
tipo do valor — e um predicado que promovesse esconderia isso.

**Um por tipo, sem exceção nem agregação.** Não há `is_number` nem
`is_numeric`: essas seriam regras a mais, e a composição com `or` já as cobre.

## R12. Internos versus biblioteca

Justifica: §6 (a lista de internos), §9 (ausência de biblioteca padrão).

**Critério:** se a operação é expressável em XPR puro, é biblioteca; se depende
da representação interna do valor ou do host, é interno.

| categoria | exemplos | por quê |
| --- | --- | --- |
| interno | `print`, `println`, `input`, `len`, `int`, `exp`, `pow` | acesso a stdio, `math.h` ou à representação de string |
| interno | `list`, `read_reals`, `count_reals` | construção de lista em execução e leitura de arquivo (R9.3) |
| interno | `is_*`, `fail`, `string`, `integer`, `real` | acesso à tag de tipo ou ao parser numérico |
| biblioteca | `map`, `fold`, `filter`, `range`, `abs`, `at`, `apply`, `apply2`, `any`, `all`, `identity`, `zeros`, `ones` | expressável em XPR puro |

`at` desceu para biblioteca: `at = fn(x){ fn(i){ x[i]; }; };` é XPR puro sobre a
primitiva `x[i]` (§6.4) — a inversão é deliberada, o sufixo é a forma
primitiva e a função curryficada é açúcar. `len` é polimórfico sobre os tipos
indexáveis: segue o precedente de `print`/`string`, que aceitam qualquer tipo —
o valor decide a leitura, e não há sobrecarga a escolher.

**A fronteira é normativa porque justifica recusas.** Ela é o que permite negar
"adicione `abs` como interno" sem reanálise: `abs` é biblioteca.

**Consequência registrada.** Hoje não há diretório de biblioteca padrão nem
`XPRPATH`; a busca de `import` é só no diretório do arquivo principal (§9). Por
isso o que seria biblioteca ainda não tem onde morar. A fronteira fica registrada
para quando houver — e é ela que decide onde cada nome vai cair.

**Stdlib no roadmap.** A biblioteca padrão morará em `xpr-stdlib-spec.md`,
terceiro documento normativo de definições (planejado); §9 ganha diretório de
busca quando ele existir. Com o empacotamento de R9.3 surge também a biblioteca
escrita em código do host — a terceira categoria: XPR puro / interno da spec /
biblioteca em código host.

## R13. `print` de função e módulo

Justifica: §6.1.

`<function>` e `<module arquivo.x>`.

**Por que não o endereço.** Seria não determinístico entre execuções e quebraria
testes golden — que são a única verificação automatizada que o projeto tem
(`tests/`).

**Por que o caminho relativo ao arquivo principal.** Absoluto vazaria o layout do
disco da máquina e quebraria reprodutibilidade entre máquinas, exatamente o
mesmo problema.

**Assimetria deliberada.** Módulo é unidade de origem: são poucos, um por
arquivo, e o caminho identifica algo. Função é valor de fluxo: são muitas,
anônimas, e o arquivo de origem não distingue nada. Por isso o módulo carrega
origem e a função não.

**Não é campo.** Ver R7.4.

## R14. Modelo de memória

Justifica: §8.

Valores imutáveis (R3) tornam o tempo de vida de uma alocação igual ao do escopo
que a produziu. Arenas por escopo, liberadas em `defer` do Keel, cobrem saída
normal e desmontagem por erro — o modelo de erro por retorno respeita `defer`.

**Por que não coletor de lixo.** Um GC é uma decisão normativa disfarçada: ele
torna a pausa e o consumo de memória observáveis, e no limite exige que a
linguagem defina o que é acessível. Com imutabilidade e escopo léxico, o tempo de
vida é decidível sem nenhuma regra nova.

**Por que a cópia entre arenas é necessária.** Imutabilidade não dispensa cópia
de **armazenamento**: um valor que escapa do escopo que o alocou precisa estar na
arena de destino antes que a origem seja liberada. Compartilhar descritores é
seguro enquanto o armazenamento viver; não é uma alternativa à cópia.

**Relação com §4.9.** §4.9 garante independência **observável** entre valores
copiados. R14 explica como a implementação a obtém sem copiar tudo: o que se
compartilha é armazenamento imutável, e o que se copia é o que escaparia.

**Listas: descritor sobre armazenamento.** Uma lista é uma vista `{len, ptr}`
sobre armazenamento alocado em arena. A deep-copy acontece quando o valor
escapa para escopo de vida maior; se o armazenamento já vive na arena de
destino, copiar o descritor basta. O buffer de capacidade crescente existe
apenas internamente, antes de a lista imutável existir. As operações
vetorizadas (§5) viram loops C planos — a vetorização real é trabalho do
compilador.

## R15. Registro de recusas

Justifica: o conjunto da especificação. É o artefato de consulta para propostas
futuras — cada linha é uma negação já fundamentada.

Uma proposta que reative qualquer item desta tabela deve refutar explicitamente
a razão registrada. Sem refutação, a resposta é a da tabela.

| recusa | razão | onde |
| --- | --- | --- |
| `include` textual (`#include`) | captura o escopo do importador (R7.1) | R7 |
| alias como 2º argumento de `import` | o alias é a variável (R7) | R7 |
| `qualified_name` como categoria léxica | `field_suffix` já existia (R1) | R7 |
| importação dinâmica (`import(expr)`) | impede um único `.k` (R7.2) | R7.2 |
| `import` como construto de declaração | módulo é valor (R7) | R7 |
| segundo parâmetro em `fn` | duas regras de passagem de argumento (R4) | R4 |
| `fn` com nome próprio / `letrec` | auto-referência na atribuição cobre (R6) | R6 |
| vínculo tardio de variável livre | quebra recursão após reatribuição (R6) | R6 |
| `divmod` / retorno múltiplo | `%` cobre; tuplas não pagam (R5, R8) | R5 |
| tuplas e registros literais | `{` já é bloco; ~7 decisões novas (R8) | R8 |
| broadcast em operadores de lista | duas regras em vez de uma (R9.2) | R9.2 |
| concatenação de listas (`+` como junção), slice, append, mutação | fora do desenho: `+` é vetorização (R9.2) | R9.2 |
| construção de lista sem `list(n)(f)` | `for` devolve contagem e o literal não constrói em runtime (R9, R9.1) | R9.1 |
| construtor de lista como construto (`list { ... }`, `new l = []`) | viola C1: precisa devolver valor (R9.1) | R9.1 |
| `==` estrutural entre listas | a exceção de um operador abriria exceções adiante (R9.2) | R9.2 |
| `apply`/`apply2`/`any`/`all` como internos | expressáveis em XPR puro (R12) | R12 |
| `at` como interno | `at(x)(i)` é XPR puro sobre a primitiva `x[i]` (§6.4, R12) | R12 |
| empacotamento (f32, quantização, headers) como internos da spec | biblioteca sustentada por primitivas do host (R9.3) | R9.3 |
| socket / rede | sem semântica de bloqueio nem de tempo (R9.3) | R9.3 |
| `Integer` de 64 bits | promoção para `Real` deixaria de ser exata acima de 2^53 (R3) | R3 |
| `native("...")` | ABI, protocolo de erro, arena (R10) | R10 |
| `dispatch(tipo, expr)` | `is_*` + `iif` cobre (R11) | R4, R11 |
| tag de tipo acessível / operador de tipo | `is_*` é suficiente (R11) | R11 |
| `is_number`, `is_numeric` | composição com `or` cobre (R11) | R11 |
| `bool(val)` | `s == "true"` cobre (R1) | R3 |
| tipo `char` | string de comprimento 1 cobre (R3) | R3 |
| `true`/`false` como identificadores predefinidos | seriam reatribuíveis em escopo interno (R3.1) | R3.1 |
| `true`/`false` como palavras-chave | são valores, não formas sintáticas (R3.1) | R3.1 |
| `not`/`and`/`or` como palavras-chave | são operadores; o token é de operador (R3.1) | R3.1 |
| `/*` sem `*/` tolerado até o EOF | o resto do arquivo viraria comentário silencioso (R3.3) | R3.3 |
| anotação de tipo (`fn(x: T)`, `fn: T(x)`, `x: T = e`) | retorno de `iif` sem tipo único exigiria união de tipos; e a anotação só seria verificável onde a inferência já sabe (R3.4) | R3.4 |
| string terminando implicitamente no fim de linha | mesma falha silenciosa (R3.3) | R3.3 |
| `chars` compartilhado entre string e comentário | imporia a proibição de `\\` a comentário (R3.2) | R3.2 |
| GC / contagem de referência | arena por escopo basta (R14) | R14 |
| `abs`, `map`, `fold` como internos | expressáveis em XPR puro (R12) | R12 |
| `print` de função com endereço ou origem | não determinístico (R13) | R13 |
| `m.path` como campo acessível | viola "campos = topo do arquivo" (R7.4) | R7.4 |
| `longjmp` / exceção com salto | atravessa `defer` (ver diretrizes-erros) | R14 |
