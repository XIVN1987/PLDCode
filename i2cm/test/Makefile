CROSS = riscv-none-embed-

HDRS = ../../picorv32/test
SRCS = \
	../../picorv32/test/helper.c \

HDRS +=
SRCS += \
	main.c \
	i2cm_drv.c \
	AT24C04.c  \

CFLAGS += -march=rv32imc -mabi=ilp32 -nostartfiles -O1
CFLAGS += -Wl,--script=../../picorv32/test/linker.ld -Wl,-Map=$@.map

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
