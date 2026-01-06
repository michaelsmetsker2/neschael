#
# neschael 
# Makefile
#

ASSEMBLER = ca65
LINKER    = ld65
EMU       = mesen

ASMFLAGS  = --cpu 6502 -I .
LINKFLAGS = --config config/nes.cfg --dbgfile bin/neschael.dbg

BIN_DIR = bin

# source files
SRC = neschael.s $(wildcard lib/**/*.s)

# objects
OBJECTS = $(SRC:%.s=$(BIN_DIR)/%.o)

default: assemble link build

# Builds and opens it in the emulator i use for debugging
dev: assemble link build test

test: 
	$(EMU) neschael.nes

# Assemble .s -> .o
assemble: $(OBJECTS)

$(BIN_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(ASSEMBLER) $(ASMFLAGS) -o $@ $<

# .o -> .bin
link: $(BIN_DIR)/neschael.link

$(BIN_DIR)/neschael.link: $(OBJECTS)
	@mkdir -p $(dir $@)
	$(LINKER) -o $@ $(LINKFLAGS) $(OBJECTS)

# This target entry concatenates the .bin ROM files into a .nes iNES emulator-compatible ROM file
build: bin/hdr.bin bin/prg.bin bin/chr.bin
	cat bin/hdr.bin bin/prg.bin bin/chr.bin > neschael.nes

# Cleans bin directory
clean:
	$(RM) -r $(BIN_DIR)/* neschael.nes a.out

.PHONY: default dev test assemble link build clean
	