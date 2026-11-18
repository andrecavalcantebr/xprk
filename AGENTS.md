# Diretrizes de Agentes de IA - Projeto XPR

## Objetivos
- Este projeto é para exercitar as capacidades da linguagem keel;
  - Detalhes da linguagem em @keel-llm-context.md e @keel-maunual;
  - Pasta com o compilador: /home/andre/Apps/keel-0.3.0-dev (física; existe um symlink ~/code/keel-0.3.0-dev apontando para lá, e ~/.local/bin/cgen é um link para o binário; dentro, `docs/` tem os normativos da linguagem, se precisar de mais alguma informação — avise o usuário se precisar consultá-los). Para ambientes isolados (sandbox), existe uma cópia mínima do toolchain dentro do projeto em `tools/keel/` (bin/cgen + lib/base, gitignored); use `tools/keel/bin/cgen` quando o cgen do sistema não estiver acessível. A cópia interna é a usada pelo build (reprodutibilidade); `make keel-check` acusa drift contra a oficial e `make keel-sync` atualiza a cópia (rodar num terminal que veja a oficial).
- Este projeto visa construir um transpilador da linguagem de programação XPR para keel, compilar e executar programas escritos em XPR (veja @xpr-specs-pt.md);
  - XPR é uma linguagem orientada a expressões imutáveis. Detalhes em @xpr-specs-pt.md
  - Dois documentos normativos, e a divisão é obrigatória:
    - `xpr-specs-pt.md` — **definições** (o que a linguagem é).
    - `xpr-rationale.md` — **razões** (por que cada regra existe, o que foi recusado). É normativo para admissão de mudanças: os critérios estão em R1 e o registro de recusas em R15. Reativa uma recusa de R15 só com refutação explícita da razão registrada.
  - Ao mudar uma regra, atualize os dois: a definição na spec, a razão em R<n>. Razão sem regra na spec significa spec incompleta — corrija a spec, não o rationale.
- Quando solicitado pelo usuário, crie ferramentas de apoio, preferencialmente em bash;
- Responda com clareza e objetividade.

## Padrões de Codificação
- **Linguagem**: Todo o código (nomes de arquivos, variáveis, constantes, funções) e comentários devem estar em **Inglês**.
- **Documentação**: Pode ser em Português ou Inglês.
- **Comentários**: Foque no "porquê" (intenção/lógica), não no "como" (sintaxe).
- **Cabeçalho**: Cada arquivo deve iniciar com o seguinte cabeçalho:

```c
/*
   FILE: filename.k
   DESC: short description of the file
   AUTHOR: Andre Cavalcante with AI partner
   DATE: November, 2026
   LICENSE: GPL-v3
*/
```

## Detalhes de Implementação do Transpilador
- **Gerenciamento de Memória**: Use o modelo de memória de keel à risca, isto é, arenas hierárquicas. Dois alocadores com tempos de vida diferentes:.
- **Arquitetura** (pode ser preciso a criação de mais módulos):
    - `lexer.k`: Tokenização.
    - `parser.k`: Geração de AST por descentralização recursiva.
    - `emmit.k`: Avaliador dos arquivos `.x` e gerador do código keel resultante.
    - `exec.k`: Compila e executa os arquivos keel gerados
    - `builtins.k`: Funções nativas.
    - `diagnostic.k`: Relatório de erros.
    - `loader.k`: Carga dos arquivos .x em memória.
    - `main.k`: Ponto de entrada: tratamento de opções e orquestação das demais funcionalidades.

## Continuidade da Sessão
- Leia `MEMORY.md` ao retomar o trabalho no projeto.
- Distinga decisões de linguagem confirmadas, suposições da suíte de testes, trabalho em progresso e resultados verificados. Binários existentes não provam que as fontes atuais compilem.
- Ao final da sessão atualize a memória `MEMORY.md`
