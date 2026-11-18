/*
   FILE: main.k
   DESC: Entry point for the XPR compiler, handling CLI arguments and file loading.
   AUTHOR: Andre Cavalcante with GPT Sol 6.1 AI Model
   DATE: November, 2026
   LICENSE: GPL-v3
*/

module main;

import_c <stdio.h>;

constexpr i8 VERSION_MAJOR = 0;
constexpr i8 VERSION_MINOR = 1;
constexpr i8 VERSION_BUGS = 0;

void help(const char *program) {
    const char *msg =
        "%s version %d.%d.%d\n"
        "USE: %s <options> \n"
        "where <options> can be\n"
        "    <filename.x>        :  compiles the program (single .k in the current folder)\n"
        "    --lex-dump <file>   :  dumps the tokens of a file (stops at the lexer)\n"
        "    --parse-dump <file> :  dumps the parsed tree of a file (stops at the parser)\n"
        "    --gen-dump <file>   :  dumps the generated keel code (stops at codegen)\n"
        "    -h | --help         :  this help\n"
        "\n";
    printf(msg,
        program, VERSION_MAJOR, VERSION_MINOR, VERSION_BUGS,
        program
    );
}

int main(int argc, char *argv[]) {
    (void) argc;   /* entry signature keeps argc/argv; only argv is used */
    help(argv[0]);
    return 0;
}
