BIN = test

CROSS = riscv-none-embed-

HDRS = .
SRCS = \
	helper.c \

HDRS += 
SRCS += \
	alu/main.c \

CFLAGS += -march=rv32imc -mabi=ilp32
CFLAGS += --std=c99 -nostartfiles -O0
CFLAGS += -Wl,--script=linker.ld -Wl,-Map=$@.map

all: $(BIN).elf $(BIN).bin $(BIN).mem size

$(BIN).elf: $(SRCS)
	@echo CC
	@$(CROSS)gcc $(CFLAGS) -I$(HDRS) $^ -o $@
	@$(CROSS)objdump -d $@ > $@.dis

$(BIN).bin: $(BIN).elf
	@echo OBJCOPY
	@$(CROSS)objcopy -O binary $^ $@

$(BIN).mem: $(BIN).bin
	@echo MEM
	@od -tx4 -w4 -v -An $^ > $@

size: $(BIN).elf
	@echo size:
	@$(CROSS)size -t $^

clean:
	-rm $(BIN).elf $(BIN).elf.map $(BIN).elf.dis $(BIN).bin $(BIN).mem
