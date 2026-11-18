# FILE: Makefile
# DESC: keel-style build for the xprk transpiler (cgen drives, gcc compiles).
# AUTHOR: Andre Cavalcante with AI partner
# DATE: November, 2026
# LICENSE: GPL-v3

PRJ    := xprk
SRCDIR := src
OBJDIR := obj
GENDIR := gen
MAIN   := main

CC     := tools/keel/bin/cgen   # vendored driver (works sandboxed); real cc is CCC
CCC    := gcc
CFLAGS := -std=c2x -I$(SRCDIR) -Wall -Wextra -g -O0
LDLIBS := -lm

ALL_K  := $(shell find $(SRCDIR) -name '*.k')
# generic module = 'module name dim|tags|type ...;' header (cannot build alone)
GEN_K  := $(shell grep -lE '^module[[:space:]]+[A-Za-z0-9_.]+[[:space:]]+(dim|tags|type)[[:space:]]' $(ALL_K) /dev/null)
K_SRCS := $(filter-out $(SRCDIR)/$(MAIN).k $(GEN_K),$(ALL_K))
C_SRCS := $(shell find $(SRCDIR) -name '*.c')
OBJS   := $(patsubst $(SRCDIR)/%.k,$(OBJDIR)/%.o,$(K_SRCS)) \
          $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.o,$(C_SRCS))

KGEN := $(CC) --cc=$(CCC) --dest-dir $(GENDIR) -I $(SRCDIR) $(CFLAGS)

all: $(PRJ)

vars:
	@echo "PRJ=$(PRJ)"
	@echo "CC=$(CC) CCC=$(CCC)"
	@echo "K_SRCS=$(K_SRCS)"
	@echo "C_SRCS=$(C_SRCS)"
	@echo "OBJS=$(OBJS)"

# one .k per invocation; -c only compiles (no C main is generated)
$(OBJDIR)/%.o: $(SRCDIR)/%.k
	@mkdir -p $(dir $@)
	$(KGEN) -MMD -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CCC) $(CFLAGS) -MMD -c $< -o $@

# the entry module compiles and links in one go (it generates the C main)
$(PRJ): $(SRCDIR)/$(MAIN).k $(OBJS)
	@mkdir -p $(OBJDIR)
	$(KGEN) -MMD -MF $(OBJDIR)/$(MAIN).d -MT $@ $< $(OBJS) $(LDLIBS) -o $@

-include $(shell find $(OBJDIR) -name '*.d' 2>/dev/null)

# inspect the generated C without calling the compiler
genc:
	$(KGEN) --stop-after=gen $(SRCDIR)/$(MAIN).k
	@echo "generated C in $(GENDIR)/"

run: $(PRJ)
	./$(PRJ)

test tests: keel-check $(PRJ)
	@[ -f tests/run_tests.sh ] || { echo "tests/run_tests.sh not created yet"; exit 2; }
	bash tests/run_tests.sh

clean:
	rm -rf $(OBJDIR) $(GENDIR) $(PRJ)

# vendored toolchain guard (see tools/keel-tool.sh): fails on version drift
keel-check:
	bash tools/keel-tool.sh check

keel-sync:
	bash tools/keel-tool.sh sync

# wipe the project-local scratch directory (see tools/clean-tmp.sh)
cleantmp:
	bash tools/clean-tmp.sh

.PHONY: all vars genc run test tests clean cleantmp keel-check keel-sync
