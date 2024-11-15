`timescale 1ns / 1ps

module spim (
	input         clk,
	input         rst_n,

	input         mem_valid,
	output        mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  spi_cs,
	output 		  spi_ck,
	input  [ 3:0] spi_di,
	output [ 3:0] spi_do,
	output [ 3:0] spi_oe
);

//----------------------------------------------------------------------------
wire 		clr_n;
wire [ 1:0] ckmod;
wire [ 7:0] ckdiv;
wire 		busy;
wire [ 5:0] fflvl;
wire 		oper;
wire [ 7:0] icode;
wire [ 1:0] imode;
wire [31:0] addr;
wire [ 1:0] amode;
wire [ 1:0] asize;
wire [31:0] altb;
wire [ 1:0] abmode;
wire [ 1:0] absize;
wire [ 4:0] dummy;
wire [ 1:0] dmode;
wire [31:0] dlen;

spim_reg u_reg (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr[11:0]),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.clr_n (clr_n ),
	.ckmod (ckmod ),
	.ckdiv (ckdiv ),
	.busy  (busy  ),
	.fflvl (fflvl ),

	.oper  (oper  ),
	.icode (icode ),
	.imode (imode ),
	.addr  (addr  ),
	.amode (amode ),
	.asize (asize ),
	.altb  (altb  ),
	.abmode(abmode),
	.absize(absize),
	.dummy (dummy ),
	.dmode (dmode ),
	.dlen  (dlen  )
);


endmodule
