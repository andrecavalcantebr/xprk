/*
   FILE: main.k
   DESC: Entry point for the XPR compiler, handling CLI arguments and file loading.
   AUTHOR: Andre Cavalcante with GPT Sol 6.1 AI Model
   DATE: November, 2026
   LICENSE: GPL-v3
*/

module main;

import_c <stdio.h>;
import_c <string.h>;

import xpr.diag as diag types;

constexpr i8 VERSION_MAJOR = 0;
constexpr i8 VERSION_MINOR = 1;
constexpr i8 VERSION_BUGS  = 0;

void help(const char *program) {
    const char *msg =
        "%s version %d.%d.%d\n"
        "USE: %s <options> \n"
        "where <options> can be\n"
        "    <filename.x>        :  compiles the program (single .k in the current folder)\n"
        "    --lex-dump <file>   :  dumps the tokens of a file (stops at the lexer)\n"
        "    --parse-dump <file> :  dumps the parsed tree of a file (stops at the parser)\n"
        "    --gen-dump <file>   :  dumps the generated keel code (stops at codegen)\n"
        "    --diag-list         :  prints the diagnostics catalog (spec section 10)\n"
        "    -h | --help         :  this help\n"
        "\n";
    printf(msg,
        program, VERSION_MAJOR, VERSION_MINOR, VERSION_BUGS,
        program
    );
}

// catalog load: proves the module crosses the interface before any phase
// of the compiler exists (lexer, parser and codegen are still pending)
static void diag_list(void) {
    for (i32 i = 0; i < diag.COUNT; i++) {
        const diag.DiagEntry *e = diag.entry(i);
        if (e == 0) {
            fprintf(stderr, "xpr: diag: row %d missing (table behind the tags list)\n", i);
            continue;
        }
        printf("%3d  %-22s %-7s %s\n", (i32)e->code, e->id, e->sev, e->msg);
    }
}

pub int main(int argc, char *argv[]) {
    if (argc != 2) {
        help(argv[0]);
        return 2;                       /* tool invocation error (diretrizes 4) */
    }
    if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        help(argv[0]);
        return 0;
    }
    if (strcmp(argv[1], "--diag-list") == 0) {
        diag_list();
        return 0;
    }
    fprintf(stderr, "xpr: not implemented yet: %s\n", argv[1]);
    return 2;
}
