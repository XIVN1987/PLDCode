SRCS = \
	riscv_tb.v \
	../picorv32/picorv32.v \
	../picorv32/memory.v \
	i2cm.v \
	i2cm_reg.v \
	i2cm_bit.v \
	24FC04.v \

VCD_FILE=./__riscv.vcd
SIM_FILE=./__riscv.sim

all:
	@iverilog -Wall -o $(SIM_FILE) -DSIMULATOR -DVCD_FILE=\"$(VCD_FILE)\" $(SRCS)
	@vvp -n $(SIM_FILE)

wave:
	@gtkwave.exe -a riscv.gtkw $(VCD_FILE)

clean:
	rm -f $(VCD_FILE) $(SIM_FILE)
