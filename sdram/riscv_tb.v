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
wire sel_ram, sel_sdram;
wire		mem_ready_ram;
wire [31:0] mem_rdata_ram;
wire		mem_ready_sdram;
wire [31:0] mem_rdata_sdram;

assign sel_ram   = ((mem_addr >> 28) == 0) || ((mem_addr >> 28) == 8) || ((mem_addr >> 28) == 9);
assign sel_sdram = ((mem_addr >> 28) == 3);
assign mem_ready = sel_ram ? mem_ready_ram : mem_ready_sdram;
assign mem_rdata = sel_ram ? mem_rdata_ram : mem_rdata_sdram;

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
wire        sdram_clk;
wire        sdram_cke;
wire        sdram_cs;
wire        sdram_ras;
wire        sdram_cas;
wire        sdram_we;
wire [12:0] sdram_addr;
wire [ 1:0] sdram_ba;
wire [15:0] sdram_data;
wire [ 1:0] sdram_dqm;

sdramc #(
	.SDRAM_MHZ(50)
) u_sdramc (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_sdram),
	.mem_ready(mem_ready_sdram),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_sdram),

	.sdram_clk (sdram_clk),
	.sdram_cke (sdram_cke),
	.sdram_cs  (sdram_cs),
	.sdram_ras (sdram_ras),
	.sdram_cas (sdram_cas),
	.sdram_we  (sdram_we),
	.sdram_addr(sdram_addr),
	.sdram_ba  (sdram_ba),
	.sdram_data(sdram_data),
	.sdram_dqm (sdram_dqm)
);

MT48LC8M16A2 u_sdram (
	.clk (sdram_clk),
	.cke (sdram_cke),
	.csb (sdram_cs),
	.rasb(sdram_ras),
	.casb(sdram_cas),
	.web (sdram_we),
	.addr(sdram_addr),
	.ba  (sdram_ba),
	.dq  (sdram_data),
	.dqm (sdram_dqm)
);

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
