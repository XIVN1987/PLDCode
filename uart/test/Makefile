CROSS = riscv-none-elf-

HDRS = ../../picorv32/test
SRCS = \
	../../picorv32/test/helper.c \
	../../picorv32/test_irq/irq_handler_A.S \

HDRS +=
SRCS += \
	main.c \
	uart_drv.c \

CFLAGS += -march=rv32imc -mabi=ilp32 -nostartfiles -O1 -DSYS_FREQ=50000000
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
