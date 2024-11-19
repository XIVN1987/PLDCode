CROSS = riscv-none-elf-

HDRS = .
SRCS = \
	helper.c \

HDRS += 
SRCS += \
	main.c \

CFLAGS += -march=rv32imc -mabi=ilp32 -nostartfiles -O1
CFLAGS += -Wl,--script=linker.ld -Wl,-Map=$@.map

all: test.dis test.mem size

test.elf: $(SRCS)
	$(CROSS)gcc $(CFLAGS) -I$(HDRS) $^ -o $@

test.dis: test.elf
	$(CROSS)objdump -d $^ > $@

test.bin: test.elf
	$(CROSS)objcopy -O binary $^ $@

test.mem: test.bin
	od -tx4 -w4 -v -An $^ > $@

size: test.elf
	@echo size:
	@$(CROSS)size -t $^

clean:
	rm -f test.elf test.elf.map test.dis test.bin test.mem
