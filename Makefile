#
# neschael 
# Makefile
#

ASSEMBLER = ca65
LINKER    = ld65
EMU       = mesen

ASMFLAGS  = --cpu 6502
LINKFLAGS = --config config/nes.cfg --dbgfile bin/neschael.dbg

default: assemble link build

dev: assemble link build test
# Builds and opens it in the emulator i use for debugging
test: 
	$(EMU) neschael.nes

# Assemble .s -> .o
assemble: neschael.s
	$(ASSEMBLER) $(ASMFLAGS) -o bin/neschael.o neschael.s

# .o -> .bin
link: bin/neschael.o
	$(LINKER) -o bin/neschael.link $(LINKFLAGS) bin/neschael.o

# This target entry concatenates the .bin ROM files into a .nes iNES emulator-compatible ROM file
build: bin/hdr.bin bin/prg.bin bin/chr.bin
	cat bin/hdr.bin bin/prg.bin bin/chr.bin > neschael.nes

# Cleans bin directory
clean:
	$(RM) bin/*.bin bin/*.o bin/neschael.link neschael.nes a.out

# End of Makefile
	