ASM     = nasm
LD      = ld
ASFLAGS = -f elf64
LDFLAGS = 

SRC     = hexu.asm
OBJ     = hexu.o
BIN     = hexu

all: $(BIN)

$(BIN): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.asm
	$(ASM) $(ASFLAGS) $< -o $@

clean:
	rm -f $(BIN) $(OBJ)

.PHONY: all clean
