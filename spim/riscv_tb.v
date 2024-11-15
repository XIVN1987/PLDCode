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
wire sel_ram, sel_spim;
wire		mem_ready_ram;
wire [31:0] mem_rdata_ram;
wire		mem_ready_spim;
wire [31:0] mem_rdata_spim;

assign sel_ram   = ((mem_addr >> 28) == 0) || ((mem_addr >> 28) == 8) || ((mem_addr >> 28) == 9);
assign sel_spim  = ((mem_addr >> 28) == 5);
assign mem_ready = sel_ram ? mem_ready_ram : mem_ready_spim;
assign mem_rdata = sel_ram ? mem_rdata_ram : mem_rdata_spim;

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
wire 		spi_cs;
wire 		spi_ck;
wire [ 3:0] spi_di;
wire [ 3:0] spi_do;
wire [ 3:0] spi_oe;
wire [ 3:0] spi_io;

spim u_spim (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_spim),
	.mem_ready(mem_ready_spim),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_spim),

	.spi_cs(spi_cs),
	.spi_ck(spi_ck),
	.spi_di(spi_di),
	.spi_do(spi_do),
	.spi_oe(spi_oe)
);

pullup(spi_io[0]);
pullup(spi_io[1]);
pullup(spi_io[2]);
pullup(spi_io[3]);

W25Q128JVxIM spiflash (
	.CSn  (spi_cs),
	.CLK  (spi_ck),
	.DIO  (spi_io[0]),
	.DO   (spi_io[1]),
	.WPn  (spi_io[2]),
	.HOLDn(spi_io[3])
);

assign spi_di[0] = spi_io[0];
assign spi_io[0] = spi_oe[0] ? spi_do[0] : 1'bz;
assign spi_di[1] = spi_io[1];
assign spi_io[1] = spi_oe[1] ? spi_do[1] : 1'bz;
assign spi_di[2] = spi_io[2];
assign spi_io[2] = spi_oe[2] ? spi_do[2] : 1'bz;
assign spi_di[3] = spi_io[3];
assign spi_io[3] = spi_oe[3] ? spi_do[3] : 1'bz;


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
