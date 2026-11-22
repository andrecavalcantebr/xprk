# XPR — Rationale Normativo

Companion de `xpr-specs-pt.md`. A spec dá as **definições**; este documento dá as **razões** e é normativo para admissão de mudanças. Os critérios estão em R1; o registro de recusas em R15. Reativar uma recusa exige refutar explicitamente a razão registrada. Cada `R<n>` é estável; a spec cita `R<n>`, este documento cita `§n`.

## Índice

- [R1. Critérios de admissão](#r1-criterios-de-admissao)
- [C1 — Tudo é expressão (critério PRIMARIO)](#c1--tudo-e-expressao-criterio-primario)
- [C2 — Regra da simplicidade](#c2--regra-da-simplicidade)
- [C3 — Preferência por mecanismos existentes](#c3--preferencia-por-mecanismos-existentes)
- [C4 — Falha cedo](#c4--falha-cedo)
- [R1.1 O caso import](#r11-o-caso-import)
- [R1.2 Programa conforme](#r12-programa-conforme)
- [R2. Tudo é expressão](#r2-tudo-e-expressao)
- [R2.1 Produzir valor não obriga a consumi-lo](#r21-produzir-valor-nao-obriga-a-consumilo)
- [R3. Sete tipos, imutáveis](#r3-sete-tipos-imutaveis)
- [R3.1 Três categorias de nome reservado](#r31-tres-categorias-de-nome-reservado)
- [R3.2 Notação de terminal no léxico](#r32-notacao-de-terminal-no-lexico)
- [R3.3 Assimetria de terminação](#r33-assimetria-de-terminacao)
- [R3.4 Sem anotação de tipo](#r34-sem-anotacao-de-tipo)
- [R4. Aritmética da aridade e currying](#r4-aritmetica-da-aridade-e-currying)
- [R4.1 Despacho por valor de função](#r41-despacho-por-valor-de-funcao)
- [R5. Percentual e a ausência de divmod](#r5-percentual-e-a-ausencia-de-divmod)
- [R6. Closures, recursão e delegação](#r6-closures-recursao-e-delegacao)
- [R7. import: avaliação de arquivo em escopo fechado](#r7-import-avaliacao-de-arquivo-em-escopo-fechado)
- [R7.1 O ganho decisivo é o escopo fechado](#r71-o-ganho-decisivo-e-o-escopo-fechado)
- [R7.2 Argumento literal obrigatório](#r72-argumento-literal-obrigatorio)
- [R7.3 Avaliação uma vez por arquivo](#r73-avaliacao-uma-vez-por-arquivo)
- [R7.4 O caminho é metadado, não campo](#r74-o-caminho-e-metadado-nao-campo)
- [R8. Structs e tuplas: da recusa à admissão como Rec](#r8-structs-e-tuplas-da-recusa-a-admissao-como-rec)
- [R9. Listas](#r9-listas)
- [R9.1 Lista passa em C1](#r91-lista-passa-em-c1)
- [R9.2 Vetorização: uma regra única, recursiva](#r92-vetorizacao-uma-regra-unica-recursiva)
- [R9.3 Construtores e I/O de dados](#r93-construtores-e-io-de-dados)
- [R10. native e a matemática](#r10-native-e-a-matematica)
- [R11. Predicados de tipo](#r11-predicados-de-tipo)
- [R12. Internos versus biblioteca](#r12-internos-versus-biblioteca)
- [R13. print de função e Rec](#r13-print-de-funcao-e-rec)
- [R14. Modelo de memória](#r14-modelo-de-memoria)
- [R15. Registro de recusas](#r15-registro-de-recusas)
- [R16. Rec: o reificador de agregado](#r16-rec-o-reificador-de-agregado)
- [R17. Estado: externo, repassado](#r17-estado-externo-repassado)
- [R18. args e o entry point emergente](#r18-args-e-o-entry-point-emergente)
- [R19. try: resultado local e else de default](#r19-try-resultado-local-e-else-de-default)
- [R20. Overflow é falha, não wrap](#r20-overflow-e-falha-nao-wrap)
- [R21. Vazio: sem unidade, sem zeros por tipo](#r21-vazio-sem-unidade-sem-zeros-por-tipo)
- [R22. for: laço de contagem](#r22-for-laco-de-contagem)
- [R23. Sombreamento: definição cria vínculo, atribuição não](#r23-sombreamento-definicao-cria-vinculo-atribuicao-nao)

## R1. Critérios de admissão

Filtros ordenados. O primeiro que reprova decide.

### C1 — Tudo é expressão (critério PRIMARIO)

Que valor o construto produz? Se não produz valor (é efeito ou declaração), precisa de posição sintática própria, regra de onde cabe, e não compõe com `iif`/`fn`/bloco. Isso é pedágio. Um construto que pede nome + acesso + escopo + posição própria é um **valor disfarçado**; reconhecê-lo como valor dissolve os remendos (R1.1).

### C2 — Regra da simplicidade

Contar regras normativas novas, não features. Caso de uso comprovado por código real na própria linguagem. Remover regras conta positivamente.

### C3 — Preferência por mecanismos existentes

Se um mecanismo já dá conta (sufixo, escopo, captura, vetorização, `iif`), usá-lo. Mecanismo novo exige justificativa que o existente não cobre.

### C4 — Falha cedo

Erro detectável na análise não espera a execução. Corpos nunca chamados são analisados. O que depende de valor é falha de execução, capturável por `try`.

### R1.1 O caso import

`include` textual capturava o escopo do importador. Evoluiu por correções: namespace por prefixo; `include` como declaração (sem valor); `import` como expressão que devolve valor. A terceira dissolveu as anteriores: o alias é a variável, o acesso é o `field_suffix` existente, o escopo é fechado por construção. Nesta versão o passo final: o valor é um **Rec** (ou qualquer valor) e o tipo Module desaparece (R7, R16).

### R1.2 Programa conforme

Justifica: §0.

A conformidade é o contrato entre programa e implementação: o programa satisfaz as regras normativas; a implementação aceita-o e produz o comportamento observável definido. Duas escolhas importam:

- **Falha prevista é comportamento definido, não violação.** Como não há UB e toda falha tem diagnóstico do catálogo, um programa que falha em execução é conforme. É coerente com C4 e com o modelo de erro por retorno: a falha é um resultado possível da semântica, não uma saída dela.
- **O que não é observável não é requisito.** Cópia vs compartilhamento, inline, TCO e estratégia de arena são escolhas de implementação (§8, §9). Um programa não pode depender delas; se puder observar diferença, o bug é da implementação. Isso mantém o modelo de memória e as otimizações livres sem criar exceções semânticas.

## R2. Tudo é expressão

Justifica: §3, §4.3, §4.6, §4.7, §4.11.

Programa é uma expressão; bloco devolve a última expressão; `iif` devolve um ramo; `for` devolve o último valor do corpo (R22); atribuição e definição devolvem o valor vinculado; `fn` devolve chamável; `rec` devolve agregado; `try` devolve um Rec de resultado, ou o valor direto com `else` (R19). Não há statement sem valor. O que parece construto (laço que acumula, declaração) ou vira expressão com valor, ou é recusado por C1.

### R2.1 Produzir valor não obriga a consumi-lo

Justifica: §4.11.

C1 é uma regra sobre o **construto**: ele produz valor, compõe, cabe onde uma expressão cabe. O descarte é uma regra sobre o **contexto**: o valor foi produzido e não é usado. São eixos independentes, e confundi-los é o que faz a regra do descarte parecer óbvia demais para ser escrita.

Sem ela, o resto da linguagem seria ilegal: blocos com statements intermediários, `for` por efeito, o açúcar de `for … else` (que liga `__a`/`__b` por efeito), e o programa que apenas imprime. Com ela, todos esses casos são legais sem regra adicional por construto — uma regra geral no lugar de N exceções (C2).

As três garantias que a tornam segura: descarte não suprime falha, não é preguiça, e não exige marcação sintática. A primeira é a que importa: um `for` usado por efeito continua falhando como deve, porque o corpo é avaliado normalmente. Sem essa garantia, o descarte viraria uma forma de engolir erro — o neutro disfarçado que R19/R21 recusaram.

Recusado: sintaxe explícita de descarte (`discard e`, `_ = e`). O contexto já determina; marcar seria uma segunda forma de dizer o que a posição já diz (C3).

## R3. Sete tipos, imutáveis

Justifica: §1.

Quatro básicos e três estruturados. **Rec substitui Module** (R16): não é um oitavo tipo. "Módulo" é papel, não categoria de valor.

**Integer de 32 bits.** Com 64 bits a promoção Integer→Real perderia exatidão acima de 2^53; com 32 bits é sempre exata. Custo aceito: contagens até 2^31; `count_reals` estoura em >2,1 bi; um futuro tipo `size` fica como hipótese. Overflow é falha capturável (R20).

**Imutáveis.** Nenhum valor se altera in-place. Load-bearing para o modelo de memória (R14) e para a ausência de estado interno (R17).

**Sem anotação de tipo (R3.4).**

### R3.1 Três categorias de nome reservado

- **Palavras-chave** (formas): `fn`, `rec`, `iif`, `for`, `try`, `import`, `else`.
- **Constantes** (valores): `true`, `false`, `NaN`, `INF`, `pi`, `e`, `args`. Token próprio para `true`/`false`; `args` inicializado em runtime (R18).
- **Operadores**: `and`, `or`, `not` — o token é de operador.

`true`/`false` como identificadores seriam reatribuíveis em escopo interno; como palavras-chave seriam formas, não valores. Constantes com token próprio é a categoria certa. `rec` entra como palavra-chave paralela a `fn` (R16); `else` como cláusula dos construtos parciais (R21).

### R3.2 Notação de terminal no léxico

String e comentário não compartilham `chars`: compartilhar imporia a proibição de barra invertida ao comentário. O lexer delimita e preserva escapes; a análise decodifica.

### R3.3 Assimetria de terminação

Comentário de linha pode acabar no EOF. Bloco e string não: tolerar `/*` sem `*/` tornaria o resto do arquivo comentário silencioso (C4).

### R3.4 Sem anotação de tipo

`fn(x: T)`, `fn: T(x)`, `x: T = e` recusadas. O retorno de `iif` sem tipo único exigiria união de tipos; a anotação só seria verificável onde a inferência já sabe. Anotação que não pode ser garantida é promessa. O `:` de definição (R16) não é anotação: o que segue é valor.

## R4. Aritmética da aridade e currying

Justifica: §3, §4.4.

Zero ou um parâmetro; zero ou um argumento. Uma regra de passagem, não duas. Múltiplos valores via List/Rec ou currying. `f(a,b)` é syntax-error. A aridade não está no tipo; `arity-mismatch` é falha de execução no caso geral (a análise pode rejeitar quando a função é conhecida — §11).

`f()` é zero argumentos, distinto de `f([])` e `f(rec{})`: conflar os três escolheria um "vazio" arbitrário (R21).

### R4.1 Despacho por valor de função

`iif(c,f,g)(x)` despacha sem mecanismo novo: cai de três decisões já tomadas — `iif` devolve qualquer tipo; aridade fora do tipo; sufixo de chamada em qualquer atom. É ortogonalidade. Não é polimorfismo paramétrico; é seleção de valor. `dispatch(tipo, expr)` recusado: `is_*` + `iif` cobrem (R11).

## R5. Percentual e a ausência de divmod

Justifica: §5. `/` sobre Integer já é divisão inteira; `%` completa o par. Sinal do dividendo: `(a/b)*b + a%b == a`. `%` não aceita Real. Isso elimina o caso de uso mais citado a favor de tuplas. Com Rec (R16), um `divmod` de biblioteca é possível, mas não necessário.

## R6. Closures, recursão e delegação

Justifica: §4.2, §4.4, §4.9.

**Auto-referência estrutural.** O nome definido fica **pendente** durante a própria definição: `fat = fn(n){ … fat(n-1) … }` resolve para a função em construção, congelada com as demais livres. Reatribuir `fat` depois não afeta a cópia guardada. Vale para campos de Rec.

**Vínculo tardio recusado.** Buscar o nome no escopo na chamada quebraria o exemplo e tornaria a recursão dependente de estado no instante da chamada.

**Sem letrec, sem fn com nome próprio.** A auto-referência na definição cobre o caso; um segundo tipo de vínculo custaria regra de sombreamento própria.

**Sem recursão mútua.** Captura é por cópia; um ciclo de closures não se constrói por cópia. Rec não habilita recursão mútua: campos ordenados, auto-referência apenas. Habilitá-la exigiria knot/referência, que briga com captura-por-cópia e com arena (R17).

**Consequência: delegação exige alias.** Como o nome nu dentro da definição é o pendente, não se pode delegar ao nome que a definição oculta — nem a um builtin, nem a uma função anterior:

```c
f = fn(x){ x + 1; };
f = fn(x){ f(x) + 1; };      (* recursao, nao delegacao *)
```

O idioma é capturar antes: `_f = f; f = fn(x){ _f(x) + 1; };`. Vale uniformemente (R23). É o preço explícito do early binding, não uma exceção.

## R7. import: avaliação de arquivo em escopo fechado

Justifica: §4.8, §9.

### R7.1 O ganho decisivo é o escopo fechado

Com inclusão textual o arquivo capturaria variáveis do importador — o bug da macro sem higiene. Com avaliação fechada, a pergunta "a biblioteca captura o `factor` do chamador?" deixa de existir. **A higiene está na fronteira do arquivo, não num tipo Module.** Um `rec{…}` inline é aberto (lê o envolvente); o arquivo importado é fechado. Por isso o nome é `import`, não `include`: cuspir o texto no contexto aberto do importador reabriria o bug.

### R7.2 Argumento literal obrigatório

`import(nome)` variável impediria conhecer todos os arquivos para produzir um único `.k`. Restrição de viabilidade, não de estilo.

### R7.3 Avaliação uma vez por arquivo

O valor não depende de onde o `import` aparece; memoizar é seguro e torna `recursive-import` detectável na análise.

### R7.4 O caminho é metadado, não campo

Sem tipo Module, não há valor que carregue caminho como campo. `r.path` é `field-not-found`. Os campos de um Rec são exatamente o que ele define.

## R8. Structs e tuplas: da recusa à admissão como Rec

Justifica: §1, §4.9, R16.

A recusa original apoiava-se em: `{` já é bloco; ~7 decisões; "Module já é o registro verificado". A versão mínima como Rec dissolve as três:

1. O obstáculo léxico some com a palavra-chave `rec`, paralela a `fn`.
2. As decisões reduzem-se: atualização de campo (imutabilidade → erro existente); `is_rec` (R11); ordem (igualdade ordem-independente); desmontagem (recusada).
3. "Module é o registro verificado" torna-se o **argumento de admissão**: o literal `rec{…}` tem campos conhecidos na análise. E como Module **é** um Rec, há substituição, não adição.

Entra Rec nomeado, heterogêneo, congelado, com `field_suffix`. Ficam recusados: desestruturação, atualização de campo, chaves-string arbitrárias, merge, tupla posicional anônima. O caso de uso que paga é interno à spec: o modelo de erros (R19) e os pares heterogêneos.

## R9. Listas

Justifica: §1, §3, §5, §6.4, §6.8.

### R9.1 Lista passa em C1

Lista é valor: `[a,b]` é atom; `list(n)(f)` é chamada curryficada (interno, não construto). O `for` não constrói lista (R22); daí `list(n)(f)` como único interno privilegiado de construção.

### R9.2 Vetorização: uma regra única, recursiva

Elemento a elemento, recursivo; matriz/tensor são listas aninhadas, sem tipo novo. A exceção do `==` estrutural foi recusada: ceder uma vez é aceitar que a forma de cada operador seja negociável. Igualdade estrutural fica como idioma `all(l1 == l2)`. Broadcast recusado: duas regras em vez de uma; `apply` cobre. **Rec não vetoriza** — é agregado, não sequência (R16).

### R9.3 Construtores e I/O de dados

`list(n)(f)` avalia em ordem `0..n-1`; a ordem é parte da definição. Código é estático (`import` literal), dado é dinâmico (`path` computável). Nenhum interno escreve em disco → arquivo imutável durante a execução → cache invisível seguro. Empacotamento é biblioteca em código host. Socket/rede adiados: sem semântica de bloqueio nem tempo.

## R10. native e a matemática

Justifica: §6.5. `native("código keel")` descartado: ABI não definida; protocolo de erro incompatível; alocação fora da arena. Consequência: matemática é interna. Nomes de tipo na spec são de linguagem (Integer/Real), não do host.

## R11. Predicados de tipo

Justifica: §6.6. `is_*` é a única forma de inspecionar o tipo; não há tag acessível. Um por tipo, sem promoção, sem agregação. `is_rec` substitui `is_module`. Sem `is_*`, biblioteca polimórfica não é escrevível (`abs`).

## R12. Internos versus biblioteca

Justifica: §6, §9.

Critério: expressável em XPR puro → biblioteca; depende de representação/host → interno. `len` é irredutivelmente interno: o comprimento vem do descritor da List e da contagem de codepoints da String; não há como descobri-lo em XPR puro. Com os primitivos `list(n)(f)`, `l[i]` e `len`, o resto (`cat`, `slice`, `map`, `fold`, `filter`, `range`, `any`, `all`, `apply`, `at`, `abs`, …) é biblioteca.

**Internos são nomes nus; biblioteca é qualificada.** Em keel a base é biblioteca e faz sentido qualificá-la; aqui os internos são primitivos da linguagem. Qualificá-los (`xpr.len`) borraria a fronteira que justifica recusas (R23). A stdlib morará em documento próprio; §9 ganha diretório de busca quando existir (§11).

## R13. print de função e Rec

Justifica: §6.1. Function → `<function>` (endereço seria não determinístico e quebraria goldens). Rec → `rec{campo: valor, …}`, recursivo, strings sem aspas. O caso `<module arquivo.x>` sai: não há tipo Module. A impressão é sempre estrutural; renderização específica é método explícito (R23).

## R14. Modelo de memória

Justifica: §8.

Valores imutáveis → tempo de vida = escopo produtor. Arenas por escopo, liberadas em `defer` (saída normal e desmontagem por erro). Sem GC: um GC tornaria pausa/consumo observáveis; com imutabilidade e escopo léxico o tempo de vida é decidível sem regra nova.

**Regra de escape uniforme.** Escapa o que faz parte do valor devolvido; o resto morre no escopo. Rec: campos `:` escapam como agregado; helpers `=` morrem.

**Cópia vs compartilhamento.** Compartilhar armazenamento imutável é seguro enquanto viver; descritor não estende vida. Allocate-in-destination evita cópia mas exige arena de rascunho para os helpers e análise de escape; copy-on-exit não exige e é o ponto de partida.

**Imutabilidade é load-bearing.** É a premissa que torna o compartilhamento não-observável e arenas-sem-GC correto. Estado interno mutável (R17) quebraria essa premissa.

## R15. Registro de recusas

Reativar exige refutar a razão registrada.

| recusa | razão | onde |
|---|---|---|
| `include` textual | captura o escopo do importador; higiene é fronteira fechada | R7.1 |
| importação dinâmica | impede um único `.k` | R7.2 |
| tipo Module separado | Module é um Rec; substituição, não adição | R16 |
| segundo parâmetro / `f(a,b)` | duas regras de passagem; List/Rec/currying cobrem | R4 |
| `fn` com nome próprio / `letrec` | auto-referência na definição cobre | R6 |
| vínculo tardio | quebra recursão após reatribuição | R6 |
| recursão mútua (inclusive entre campos) | cópia não constrói ciclo; exigiria knot | R6, R17 |
| desestruturação | açúcar sobre acesso por campo; pressiona a aridade | R8, R16 |
| tupla posicional anônima | Rec nomeado cobre; exigiria índice constante e vetorização | R8, R16 |
| atualização de campo / mutação de List/String | imutabilidade; construa novo valor | R3, R14 |
| estado interno mutável em Rec | quebra a premissa do R14 | R17 |
| chaves-string arbitrárias em Rec | `field_suffix` exige identificador | R16 |
| merge / aritmética de Rec | agregado, não sequência; só igualdade estrutural | R16 |
| `:` como anotação de tipo | `iif` sem tipo único; anotação não garantível | R3.4 |
| broadcast em List | duas regras em vez de uma; `apply` cobre | R9.2 |
| concat/slice/append/mutação como operadores | `+` é vetorização; existem como biblioteca | R9.2, R12 |
| `==` estrutural entre Lists | exceção de um operador abriria outras | R9.2 |
| construção de List sem `list(n)(f)` | `for` não constrói; literal não constrói em runtime | R9.1, R22 |
| `apply/any/all/at/abs/map/fold` internos | expressáveis em XPR puro | R12 |
| empacotamento como interno | biblioteca em código host | R9.3 |
| socket / rede | sem semântica de bloqueio nem tempo | R9.3 |
| Integer de 64 bits | promoção deixaria de ser exata acima de 2^53 | R3 |
| `native("…")` | ABI, protocolo de erro, arena | R10 |
| `dispatch` / tag acessível / `is_number` | `is_*` + `iif`/`or` cobrem | R4, R11 |
| `bool(val)` / tipo `char` | `s == "true"` / string de comprimento 1 cobrem | R3 |
| `true`/`false` como identificadores ou keywords | constantes com token próprio | R3.1 |
| `/*` sem `*/` até EOF / string implícita na linha | falha silenciosa | R3.3 |
| GC / contagem de referência | arena basta; imutabilidade é a premissa | R14 |
| `print` de função com endereço/origem | não determinístico; quebra goldens | R13 |
| `m.path` como campo | campos = o que o Rec define | R7.4 |
| `longjmp` / exceção com salto | atravessa `defer` | R14 |
| `last_error` global mutável | erro local no Rec de `try` | R19 |
| `try(e1, e2)` com dois argumentos | `else` cobre o default; uma forma a menos | R19 |
| valor neutro em falha de `try` | campo ausente falha; não fabrica valor | R19, R21 |
| overflow Integer silencioso / wrap implícito | falha capturável; wrap explícito só com caso de uso | R20 |
| zeros por tipo como default | identidades de monóide são arbitrárias; neutro disfarçado | R21 |
| unidade universal para bloco vazio | valor que flui silenciosamente; bloco vazio é erro | R21 |
| `for … else` como `try(for(…)) else` | engoliria falhas do corpo; açúcar é sobre `iif` | R22 |
| `for` C-style devolvendo contagem | contagem raramente é o valor querido | R22 |
| atribuição introduzindo sombra | sombra é introdução de vínculo, não atualização | R23 |
| builtins insombreáveis | exceção; impediria campos `len`/`print` em Rec | R23 |
| builtins qualificados (`xpr.len`) | confundem a fronteira interno/biblioteca | R12, R23 |
| membros por tipo (`l.len`) | `.` é campo de Rec, não despacho por tipo | R23 |
| rank no tipo de List | List é ragged; rank é tensor/biblioteca | R23 |
| protocolo implícito de `print` por campo | exceção escondida; render é método explícito | R13, R23 |
| sintaxe explícita de descarte (`discard`, `_ = e`) | o contexto já determina; segunda forma para o que a posição diz | R2.1 |

## R16. Rec: o reificador de agregado

Justifica: §1, §3, §4.2, §4.3, §4.9, §5, §6.6, §8.

**O movimento.** O bloco é o substrato comum; `fn` reifica o escopo como chamável, `rec` como agregado, o bloco nu apenas roda e devolve a última expressão. Um substrato, dois reificadores, três formas de valor. Remover `rec` e deixar o bloco produzir o agregado quebraria a simetria com `fn` e exigiria regra condicional de devolução.

**Module → Rec.** Os 7 tipos permanecem. Saem `is_module`, igualdade-de-Module, print de módulo, caminho-como-metadado-de-tipo. Entram `is_rec`, igualdade estrutural, print `rec{…}`. Balanço C2 negativo.

**`:`/`=` são modificadores de vínculo.** `:` congela; `=` reatribui. Ambos locais. O construto é marcado por `rec`/`fn`, não por `:`. Por isso `:` em bloco nu é válido e é apenas local congelado — não cria agregado nem muda a devolução. Dois eixos ortogonais: vínculo × construto.

**Campos e helpers.** `:` são campos; `=` são privados. "Exportado" = campo do valor, nunca nome visível no pai. Campos escapam como agregado; helpers morrem.

**Verificação.** Conjunto de campos conhecido na análise quando o receptor é identificável → `field-not-found` estático. É a propriedade que R8 celebrava no Module, agora no literal. O resultado de `try` é a exceção: campos condicionais.

**Igualdade.** Agregado nomeado, não sequência: estrutural, ordem-independente, Boolean; demais operadores `type-mismatch`. Evita a exceção que a tupla posicional exigiria.

**Auto-agregação.** Campos podem ser closures que capturam os campos do Rec: encapsulamento de dados congelados + comportamento puro. **Não é objeto** (R17). Métodos são closures de zero argumentos; não há `self` implícito.

## R17. Estado: externo, repassado

Justifica: §4.9, §8.

**Estado interno mutável é recusado, e a recusa é load-bearing.** Campos congelados, capturas por cópia, `lvalue-in-closure` na análise. A razão profunda: a imutabilidade torna o compartilhamento não-observável e arenas-sem-GC correto (R14). Uma célula mutável compartilhada tornaria escritas observáveis, exigindo GC/ownership ou deep-copy everywhere. Estado interno quebraria a soundness do modelo de memória.

**A saída é estado externo.** Threading (`s1 = ops.inc(s0)`) ou acumulador local transitório devolvido por cópia. Valores imutáveis ≠ vínculos imutáveis: `=` reatribui no escopo; `:` congela. O que não pode é estado sobreviver dentro do Rec entre chamadas.

**Consequências.** Iteração com estado = recursão com acumulador; limite de 10.000 chamadas; TCO é otimização, não garantia. Para o alvo "IA para IA", o idioma de threading deve estar documentado: modelos treinados em mainstream emitirão `self.n += 1`. O upside: sem aliasing, sem estado oculto, goldens determinísticos.

**Canais globais.** `last_error` foi removido (R19). Restam `fmt_*` (§11). `args` é imutável por execução (R18) — não é anomalia. A diferença não é ser global, é ser mutável.

## R18. args e o entry point emergente

Justifica: §7, §9.

`args` é List de String, predefinido somente-leitura inicializado em runtime uma vez. Primeiro predefinido inicializado em runtime; imutável por execução, não quebra R3/R14. Sombreável: o somente-leitura é propriedade do vínculo, não do nome; `fn(args){…}` é válido.

**Entry point emergente.** Sem `_main` nem `missing-main`: o programa é uma expressão; efeitos ocorrem se ele chama algo. O arquivo principal faz o wiring de recs e chama um. Modularidade = Rec + import. O valor do programa é descartado (R2.1).

## R19. try: resultado local e else de default

Justifica: §4.7, §6.7, §10.

**O nó.** Sem produto, o motivo da falha ia para um canal global mutável (`last_error`). Com Rec (R16), `try` devolve o resultado localmente e o canal morre.

**C1.** Devolve valor. É forma especial apenas porque precisa estar no controle antes de `e1` avaliar.

**C2.** Remove `last_error` e suas regras de limpeza/aninhamento, e a forma de dois argumentos com casamento de tipo. Adiciona o shape do Rec e o acesso condicional.

**C3.** Rec, `field_suffix`, `iif` preguiçoso. Sem tupla, sem global, sem neutro.

**C4.** O motivo é local e imediato; campo ausente falha em vez de fabricar valor.

**Decisões.** `try(e1)` devolve `rec{ok:true, value:v}` ou `rec{ok:false, error:rec{code,message}}`; `value`/`error` condicionais; sem neutro — funciona para qualquer tipo, inclusive Function e Rec, porque a falha não precisa fabricar valor. `error.code` é o id público do catálogo, permitindo despacho sem casar mensagem.

**`else` é só default.** `try(e1) else(e2)` devolve o valor de `e1` ou `e2` (lazy), não o Rec; o erro é descartado; falha de `e2` propaga para fora. Açúcar: `{ r = try(e1); iif(r.ok, r.value, e2); }`. Sem binder: para inspecionar ou propagar o motivo, usa-se a forma sem `else`. Divisão limpa — com `else`, valor direto; sem `else`, resultado para inspeção. O binder fica como extensão pura adiada (§11), a ser admitida só com caso de uso.

## R20. Overflow é falha, não wrap

Justifica: §2, §5, §10.

Integer é de 32 bits para promoção exata (R3). A aritmética deve preservar essa exatidão: ou o resultado é exato, ou a operação falha. Wrap silencioso mudaria a semântica para módulo 2^32 — outra linguagem — e não há caso de uso atual que a pague (bitwise está fora).

**C4.** Depende de valores: falha de execução, capturável. Com try local (R19), trata-se pelo código.

**Regras.** `+ - *` e `-` unário fora do intervalo → `integer-overflow`. `/` por zero → `div-by-zero`; menor Integer `/ -1` → `integer-overflow`. `%` por zero → `div-by-zero`; menor Integer `% -1` → `0`. Mistos promovem para Real (IEEE). O menor Integer escreve-se `-2147483648`; magnitude 2^31 só sob `-` unário.

**Segurança.** Para código gerado por IA, falha nomeada é melhor que wrap silencioso. Wrap explícito entra depois, como operação/biblioteca, se um caso de uso real pagar.

## R21. Vazio: sem unidade, sem zeros por tipo

Justifica: §1, §4.3, §4.4, §4.6, §4.7.

**A proposta original** era dar a cada tipo um "vazio": `false`, `0`, `""`, `[]`, Rec vazio, função no-op. **Recusada.** Esses valores são **identidades de operações específicas**, não propriedades do tipo: `false` é identidade de `or` mas `true` é de `and`; `0` é de `+` mas `1` é de `*`. Escolher um por tipo privilegia um monóide e esconde a escolha. Como default, é o neutro fabricado que R19 recusou — uniformização que era gambiarra disfarçada.

**Bloco vazio** é `empty-block` (análise): não há última expressão, logo não há valor. Adotar uma unidade universal faria um valor fluir silenciosamente onde o programador não produziu nada. **Rec vazio** (`rec{}`) é válido: é o agregado com zero campos, não uma unidade para os outros tipos. **Fn vazia** é corpo vazio → `empty-block`; "no-op" é a identidade `fn(x){x;}`, que é biblioteca. **Argumento vazio**: `f()` é zero argumentos, distinto de `f([])` e `f(rec{})`.

**`else` é a cláusula uniforme do parcial.** `X else(e)` fornece o valor alternativo para o caso em que `X` não produz valor próprio; o que conta como ausência é definido pelo construto — no `for`, iteração vazia (R22); no `try`, falha capturada (R19). Mesma cláusula, condição de ausência própria de cada construto. Não é exceção: é a forma total de um construto parcial, com o valor dado pelo programador e não fabricado pela linguagem.

## R22. for: laço de contagem

Justifica: §4.6.

**Por que mudar.** Com recursão (e TCO como otimização) e `apply` como foreach, o `for` C-style que devolve **contagem** sobrava: a contagem raramente é o valor querido. O laço de contagem que devolve o **último valor do corpo** compõe com "tudo é expressão" e tem menos regras: um binder, dois limites, um corpo.

**Forma.** `for(i, a, b) body`: `i` é binder congelado por iteração (oculta o externo; atribuir a ele é `assign-to-definition`); `a`,`b` Integer avaliados uma vez; passo 1, ascendente, limite exclusivo; devolve o último valor do corpo. `i` fresco por iteração + captura por cópia resolve o bug clássico de closure em laço. Descendente/passo ficam para `range`+`apply` ou recursão: não inflam o núcleo.

**O vazio.** Sem `else`, `a >= b` é falha nomeada `empty-loop` — não há último valor e não se fabrica um (R21). Com `else(e)`, o vazio tem valor dado pelo programador.

**O açúcar é sobre `iif`, não sobre `try`.** `try(for(…)) else(e)` capturaria **qualquer** falha do corpo (índice, divisão, overflow) e devolveria o default, mascarando bugs — o neutro disfarçado outra vez. O açúcar correto liga os limites uma vez e escolhe com `iif`:

```c
{ __a = a; __b = b; iif(__a < __b, for(i, __a, __b) body, e); }
```

Falhas do corpo propagam; o `else` cobre só o vazio. Para filtrar por código via `try` seria preciso o binder que R19 recusou, e ainda se perderia o código no rethrow (§11). Os vínculos `__a`/`__b` são ligados por efeito, o que é legal porque o descarte de valor é permitido (R2.1).

**O laço não acumula.** Continua não construindo listas: `list(n)(f)` segue como construtor (R9.1). Acumulação é threading ou `fold` de biblioteca (R17).

## R23. Sombreamento: definição cria vínculo, atribuição não

Justifica: §4.2, §4.9, §6.

**O eixo certo.** Sombreamento é **introdução de vínculo local**, não atualização. `:` e parâmetro introduzem; `=` atualiza o vínculo visível mais próximo e nunca introduz sombra. Isso mata a sombra acidental por atribuição e mantém a captura clara: nome sem vínculo local visível é livre e congela.

**Rec obriga a definição sombrear.** Um campo `x` precisa ocultar um `x` externo dentro do Rec, senão o método capturaria o de fora e o agregado deixaria de ser autocontido. Fora, o acesso é qualificado (`r.x`) e nada sombreia. Restringir a ocultação a parâmetros quebraria o Rec ou exigiria `self` (mecanismo novo).

**Builtins são uniformes.** São vínculos predefinidos somente-leitura, como as constantes: sombreáveis por `:`/parâmetro, não atribuíveis. Sombrear não é redefinir — o interno permanece intacto nos escopos externos, e os arquivos são fechados no import, então o raio é local. Proibir o sombra de builtins criaria exceção e impediria campos chamados `len`, `print`, `input` em Rec. A proteção contra acidente é lint, não semântica.

**Delegação por alias.** Como o nome nu na definição é o pendente (R6), delegar ao nome sombreado exige capturá-lo antes (`_len = len; len: fn(){ _len(x); }`). É o mesmo idioma de embrulhar uma função anterior. Explícito, local, sem exceção.

**Recusas que preservam o estilo.**

- **Builtins qualificados (`xpr.len`)**: em keel a base é biblioteca; aqui os internos são primitivos da linguagem. Qualificá-los borraria a fronteira R12. Internos nus; biblioteca qualificada.
- **Membros por tipo (`l.len`)**: `.` é acesso a campo de Rec. Estendê-lo a qualquer tipo exigiria tabela de membros e despacho por tipo — o protocolo de objeto que R16/R17 recusaram, e builtin qualificado pelo receptor.
- **Rank no tipo de List**: List é ragged (`[[1,2],[3]]` é válido); rank estático exigiria retangularidade ou viraria propriedade dinâmica. É tipagem de tensor, que pertence a biblioteca, não ao núcleo.
- **Protocolo implícito de `print`**: se `print` inspecionasse um campo `print` do Rec, seria exceção escondida. A impressão é sempre estrutural; renderização específica é método explícito que devolve String (R13).
