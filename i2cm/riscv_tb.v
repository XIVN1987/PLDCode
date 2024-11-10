`timescale 1ns / 1ps

module riscv_tb;

parameter MEM_SIZE = 8192;

reg clk;
reg rst_n;

wire        mem_valid;
wire        mem_ready;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire [31:0] mem_rdata;

picorv32 #(
	.ENABLE_MUL(1),
	.ENABLE_DIV(1),
	.COMPRESSED_ISA(1),
	.STACKADDR(MEM_SIZE)
) u_core (
	.clk(clk),
	.resetn(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.pcpi_wr(1'b0),
	.pcpi_rd(32'b0),
	.pcpi_wait(1'b0),
	.pcpi_ready(1'b0),

	.irq(32'b0)
);

//----------------------------------------------------------------------------
wire sel_ram, sel_i2cm;
wire		mem_ready_ram;
wire [31:0] mem_rdata_ram;
wire		mem_ready_i2cm;
wire [31:0] mem_rdata_i2cm;

assign sel_ram   = ((mem_addr >> 28) == 0) || ((mem_addr >> 28) == 8) || ((mem_addr >> 28) == 9);
assign sel_i2cm  = ((mem_addr >> 28) == 5);
assign mem_ready = sel_ram ? mem_ready_ram : mem_ready_i2cm;
assign mem_rdata = sel_ram ? mem_rdata_ram : mem_rdata_i2cm;

memory #(
	.SIZE(MEM_SIZE),
	.FIRMWARE("test/test.mem")
) u_memory (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_ram),
	.mem_ready(mem_ready_ram),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_ram)
);

//----------------------------------------------------------------------------
wire i2c_scl;
wire i2c_sda;
wire i2c_scl_i;
wire i2c_scl_o;
wire i2c_scl_oe;
wire i2c_sda_i;
wire i2c_sda_o;
wire i2c_sda_oe;

i2cm u_i2cm (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_i2cm),
	.mem_ready(mem_ready_i2cm),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_i2cm),

	.i2c_scl_i (i2c_scl_i),
	.i2c_scl_o (i2c_scl_o),
	.i2c_scl_oe(i2c_scl_oe),
	.i2c_sda_i (i2c_sda_i),
	.i2c_sda_o (i2c_sda_o),
	.i2c_sda_oe(i2c_sda_oe)
);

M24FC04 u_eeprom (
	.A0 (1'b0),
	.A1 (1'b0),
	.A2 (1'b0),
	.WP (1'b0),
	.SCL(i2c_scl),
	.SDA(i2c_sda),
	.RESET(~rst_n)
);

assign i2c_scl_i = i2c_scl;
assign i2c_scl   = i2c_scl_oe ? i2c_scl_o : 1'bz;
assign i2c_sda_i = i2c_sda;
assign i2c_sda   = i2c_sda_oe ? i2c_sda_o : 1'bz;

//----------------------------------------------------------------------------
always #10 clk = !clk;

initial begin
	$dumpfile(`VCD_FILE);
	$dumpvars(0, riscv_tb);

	clk = 1;
	rst_n = 0;
	@(posedge clk);
	#20;
	rst_n = 1;

	#50000000;

	$write("\n--- done ---\n");
	$finish;
end

//----------------------------------------------------------------------------
always @(posedge clk) begin
	if ((mem_addr == 32'h80000000) && (mem_wstrb != 0)) begin
		$write("\n--- done ---\n");
		$finish;
	end

	if ((mem_addr == 32'h90000000) && (mem_wstrb != 0) && mem_ready) begin
		$write("%c", mem_wdata);
	end
end

endmodule
