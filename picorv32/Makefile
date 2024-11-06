SRCS = \
	riscv_tb.v \
	picorv32.v \
	memory.v \

VCD_FILE=./__riscv.vcd
SIM_FILE=./__riscv.sim

all:
	@iverilog -Wall -o $(SIM_FILE) -DSIMULATOR -DVCD_FILE=\"$(VCD_FILE)\" $(SRCS)
	@vvp -n $(SIM_FILE)

wave:
	@gtkwave.exe -a riscv.gtkw $(VCD_FILE)

clean:
	-rm $(VCD_FILE) $(SIM_FILE)
