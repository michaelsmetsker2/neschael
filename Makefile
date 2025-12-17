#
# neschael 
# Makefile
#

ASSEMBLER = ca65
LINKER = ld65
ASMFLAGS = --cpu 6502
LINKFLAGS = --config config/nes.cfg

default: assemble link build

# Assemble .s -> .o
assemble: neschael.s
	$(ASSEMBLER) $(ASMFLAGS) -o bin/neschael.o neschael.s

# .o -> .bin
link: bin/neschael.o
	$(LINKER) bin/neschael.o $(LINKFLAGS)

# This target entry concatenates the .bin ROM files into a .nes iNES emulator-compatible ROM file
build: bin/hdr.bin bin/prg.bin bin/chr.bin
	cat bin/hdr.bin bin/prg.bin bin/chr.bin > neschael.nes

# Cleans bin directory
clean:
	$(RM) bin/*.bin bin/*.o neschael.nes a.out

# End of Makefile
	