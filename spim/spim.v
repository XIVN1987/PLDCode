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
wire [ 1:0] oper;
reg 		odone;
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

wire 		tf_write;
wire [ 7:0]	tf_wbyte;
wire 		tf_read;
wire [ 7:0]	tf_rbyte;
wire 		tf_full;
wire 		tf_empty;
wire [ 5:0]	tf_level;

wire 		rf_write;
wire [ 7:0]	rf_wbyte;
wire 		rf_read;
wire [ 7:0]	rf_rbyte;
wire 		rf_full;
wire 		rf_empty;
wire [ 5:0]	rf_level;

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

	.oper  (oper  ),
	.odone (odone ),
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
	.dlen  (dlen  ),

	.tf_write(tf_write),
	.tf_wbyte(tf_wbyte),
	.tf_level(tf_level),
	.tf_full (tf_full),
	.rf_read (rf_read),
	.rf_rbyte(rf_rbyte),
	.rf_level(rf_level),
	.rf_empty(rf_empty)
);


byte_fifo #(
	.DEPTH(32),
	.WADDR( 5)
) u_tfifo (
	.clk  (clk),
	.rst_n(rst_n),
	.clr_n(clr_n),
	.write(tf_write),
	.wbyte(tf_wbyte),
	.read (tf_read),
	.rbyte(tf_rbyte),
	.full (tf_full),
	.empty(tf_empty),
	.level(tf_level)
);


byte_fifo #(
	.DEPTH(32),
	.WADDR( 5)
) u_rfifo (
	.clk  (clk),
	.rst_n(rst_n),
	.clr_n(clr_n),
	.write(rf_write),
	.wbyte(rf_wbyte),
	.read (rf_read),
	.rbyte(rf_rbyte),
	.full (rf_full),
	.empty(rf_empty),
	.level(rf_level)
);


//----------------------------------------------------------------------------
`include "spim.vh"


endmodule
