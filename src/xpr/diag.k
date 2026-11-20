/*
   FILE: xpr/diag.k
   DESC: XPR diagnostics catalog — closed tag set + entry table (spec section 10).
   AUTHOR: Andre Cavalcante with AI partner
   DATE: November, 2026
   LICENSE: GPL-v3
*/

module xpr.diag;

// The closed set. Spec section 10 is the normative source. Values are the
// positions (cgen takes them all-or-none, so none is written): OK anchors 0,
// every insertion keeps the sequence, and LAST_DIAGNOSTIC — the sentinel one
// past the last real code — IS the row count. Numbers stay stable by order:
// new diagnostics go at the end, before the sentinel; inserting in the middle
// renumbers what follows, and goldens print the id, not the number.
// file-not-found, field-not-found and undefined-identifier name conditions of
// BOTH phases (analysis table and execution table share the id): one row each.
pub tags Diag [
    OK,
    // analysis (spec 10, "Analise" table, in table order)
    UNTERMINATED_STRING,
    UNTERMINATED_COMMENT,
    SYNTAX_ERROR,
    EMPTY_PROGRAM,
    EMPTY_BLOCK,
    EMPTY_MODULE,
    WRONG_ASSIGNMENT,
    UNDEFINED_IDENTIFIER,
    LVALUE_IN_CLOSURE,
    BUILTIN_REDEFINITION,
    IMPORT_NOT_LITERAL,
    FILE_NOT_FOUND,
    RECURSIVE_IMPORT,
    FIELD_NOT_FOUND,
    // execution (spec 10, "Execucao" table, ids not already above)
    TYPE_MISMATCH,
    ARITY_MISMATCH,
    NOT_CALLABLE,
    DIVISION_BY_ZERO,
    INDEX_OUT_OF_RANGE,
    SIZE_MISMATCH,
    SIZE_OUT_OF_RANGE,
    ALLOCATION_FAILURE,
    CALL_DEPTH_EXCEEDED,
    STEP_BUDGET_EXCEEDED,
    // sentinel: one past the last real code — the total, derived by position
    LAST_DIAGNOSTIC,
];

// Row count for consumers that iterate the whole catalog; derived from the
// sentinel, never written by hand. Declared BEFORE the table so the table is
// born with the right dimension — and C zero-fills any row left without an
// initializer, which --diag-list reports instead of printing garbage.
pub constexpr i32 COUNT = LAST_DIAGNOSTIC;

// One row binds tag constant, public id, severity and message template: the
// row IS the single source (diretrizes-diagnosticos.md section 1). ids are
// kebab-case and stable — the id is what appears between brackets.
// hint is 0 while no hint is specified.
pub typedef struct {
    Diag        code;
    const char *id;
    const char *sev;
    const char *msg;
    const char *hint;
} DiagEntry;

pub array DiagEntry table[COUNT] = {
    {OK,                    "ok",                     "none",  "no diagnostic", 0},
    {UNTERMINATED_STRING,   "unterminated-string",    "error", "literal de String sem a aspa de fechamento", 0},
    {UNTERMINATED_COMMENT,  "unterminated-comment",   "error", "comentario de bloco sem o */ de fechamento", 0},
    {SYNTAX_ERROR,          "syntax-error",           "error", "o texto nao forma uma unidade valida (bloco), ou sobra token depois dela", 0},
    {EMPTY_PROGRAM,         "empty-program",          "error", "a origem nao contem nenhuma expressao", 0},
    {EMPTY_BLOCK,           "empty-block",            "error", "bloco {} sem expressoes", 0},
    {EMPTY_MODULE,          "empty-module",           "error", "unidade importada cujo bloco nao define nenhum vinculo", 0},
    {WRONG_ASSIGNMENT,      "wrong-assignment",       "error", "alvo de atribuicao nao e identificador", 0},
    {UNDEFINED_IDENTIFIER,  "undefined-identifier",   "error", "nome usado antes de qualquer definicao", 0},
    {LVALUE_IN_CLOSURE,     "lvalue-in-closure",      "error", "atribuicao a nome capturado por closure", 0},
    {BUILTIN_REDEFINITION,  "builtin-redefinition",   "error", "atribuicao a interno, constante, last_error ou args", 0},
    {IMPORT_NOT_LITERAL,    "import-not-literal",     "error", "argumento de import nao e literal de String", 0},
    {FILE_NOT_FOUND,        "file-not-found",         "error", "arquivo inexistente (import, read_reals, count_reals)", 0},
    {RECURSIVE_IMPORT,      "recursive-import",       "error", "ciclo de importacao", 0},
    {FIELD_NOT_FOUND,       "field-not-found",        "error", "campo ausente em modulo", 0},
    {TYPE_MISMATCH,         "type-mismatch",          "error", "operando ou argumento de tipo inadequado", 0},
    {ARITY_MISMATCH,        "arity-mismatch",         "error", "chamada com aridade incompativel com a funcao", 0},
    {NOT_CALLABLE,          "not-callable",           "error", "aplicacao de valor que nao e funcao", 0},
    {DIVISION_BY_ZERO,      "division-by-zero",       "error", "divisor zero em / ou %", 0},
    {INDEX_OUT_OF_RANGE,    "index-out-of-range",     "error", "indice fora de 0..len-1", 0},
    {SIZE_MISMATCH,         "size-mismatch",          "error", "vetorizacao de listas com comprimentos diferentes", 0},
    {SIZE_OUT_OF_RANGE,     "size-out-of-range",      "error", "tamanho negativo em list(n)(f) ou read_reals(p)(k)(n)", 0},
    {ALLOCATION_FAILURE,    "allocation-failure",     "error", "arena sem espaco na construcao de um valor", 0},
    {CALL_DEPTH_EXCEEDED,   "call-depth-exceeded",    "error", "profundidade de chamada acima de 10.000", 0},
    {STEP_BUDGET_EXCEEDED,  "step-budget-exceeded",   "error", "orcamento de passos de avaliacao esgotado", 0},
};

// linear lookup by numeric code; the table is dense (0..COUNT-1). Transport is
// i32 (diretrizes section 1): the cast keeps the typed column and the i32
// query comparable without -Wsign-compare.
pub const DiagEntry *entry(i32 code) {
    for (i32 i = 0; i < COUNT; i++) {
        if ((i32)table[i].code == code) return &table[i];
    }
    return 0;
}

// severity and message come from the table row — match does not replace data
pub const char *severity(i32 code) {
    const DiagEntry *e = entry(code);
    return e == 0 ? "unknown" : e->sev;
}
