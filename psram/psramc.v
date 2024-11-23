/*******************************************************************************************************************************
* @brief	PSRAM (HyperRAM) Controller
*
*******************************************************************************************************************************/
`timescale 1ns / 1ps

module psramc (
	input  		  clk,
	input  		  rst_n,

	input  		  mem_valid,
	output 		  mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output reg    psram_rst,
	output reg    psram_cs,
	output reg    psram_ck,
	output reg    psram_ckn,
	output reg    psram_rwds,
	input  [ 7:0] psram_di,
	output [ 7:0] psram_do,
	output reg    psram_doen
);

wire 		mem_valid_mem;
wire 		mem_ready_mem;
wire [31:0] mem_rdata_mem;
wire 		mem_valid_reg;
wire 		mem_ready_reg;
wire [31:0] mem_rdata_reg;

assign mem_valid_mem = mem_valid & (~mem_addr[27]);
assign mem_valid_reg = mem_valid &   mem_addr[27] ;
assign mem_ready = mem_valid_mem ? mem_ready_mem : mem_ready_reg;
assign mem_rdata = mem_valid_mem ? mem_rdata_mem : mem_rdata_reg;

//----------------------------------------------------------------------------
wire 		clr_n;
wire [ 4:0] ckdiv;
reg 		ready;
reg 		error;
wire [ 7:0] tSYS;
wire [ 3:0] tRP;
wire [ 3:0] tRH;
wire [ 7:0] tRWR;
wire [ 3:0] tCSM;
wire 		hrr_reset;
wire 		hrr_read;
reg  		hrr_rdone;
reg  [63:0] hrr_rdata;
wire		hrr_write;
wire [15:0] hrr_wdata;
wire 		fix_delay;
wire [ 3:0] ini_delay;

psramc_reg u_reg(
	.clk      (clk      ),
	.rst_n    (rst_n    ),

	.mem_valid(mem_valid_reg),
	.mem_ready(mem_ready_reg),
	.mem_addr (mem_addr[11:0]),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_reg),

	.clr_n    (clr_n    ),
	.ckdiv    (ckdiv    ),
	.ready    (ready    ),
	.error    (error    ),

	.tSYS     (tSYS     ),
	.tRP      (tRP      ),
	.tRH      (tRH      ),
	.tRWR     (tRWR     ),
	.tCSM     (tCSM     ),

	.hrr_reset(hrr_reset),
	.hrr_read (hrr_read ),
	.hrr_rdone(hrr_rdone),
	.hrr_rdata(hrr_rdata),
	.hrr_write(hrr_write),
	.hrr_wdata(hrr_wdata),
	.fix_delay(fix_delay),
	.ini_delay(ini_delay)
);


endmodule
