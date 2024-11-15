`timescale 1ns / 1ps

module spim_reg (
	input         clk,
	input         rst_n,

	input         mem_valid,
	output        mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  clr_n,	// clear internal state
	output [ 1:0] ckmod,
	output [ 7:0] ckdiv,
	input  		  busy,
	input  [ 5:0] fflvl,

	output reg	  oper,		// 0 idle, 1 write, 2 read
	output [ 7:0] icode,
	output [ 1:0] imode,
	output [31:0] addr,
	output [ 1:0] amode,
	output [ 1:0] asize,
	output [31:0] altb,
	output [ 1:0] abmode,
	output [ 1:0] absize,
	output [ 4:0] dummy,
	output [ 1:0] dmode,
	output [31:0] dlen
);

localparam ADDR_CR	= 12'h00;
localparam ADDR_SR	= 12'h04;
localparam ADDR_AR	= 12'h08;
localparam ADDR_ABR	= 12'h0C;
localparam ADDR_DLR	= 12'h10;
localparam ADDR_CCR = 12'h14;
localparam ADDR_DR	= 12'h18;


//----------------------------------------------------------------------------
reg 		ena_r;
reg [ 1: 0]	ckmod_r;
reg [ 7: 0]	ckdiv_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ena_r	<= 0;
		ckmod_r <= 0;
		ckdiv_r <= 0;
	end
	else if((mem_addr == ADDR_CR) && (mem_wstrb != 0) && mem_ready) begin
		ena_r	<= mem_wdata[   0];
		ckmod_r <= mem_wdata[ 2:1];
		ckdiv_r <= mem_wdata[15:8];
	end
end

assign clr_n = ena_r;
assign ckmod = ckmod_r;
assign ckdiv = ckdiv_r;


//----------------------------------------------------------------------------
reg icode;
reg imode;
reg addr;
reg amode;
reg asize;
reg altb;
reg abmode;
reg absize;
reg dummy;
reg dmode;
reg dlen;
reg mode;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		addr	<= 0;
		altb	<= 0;
		dlen	<= 0;
		icode	<= 0;
		imode	<= 0;
		amode	<= 0;
		asize	<= 0;
		abmode	<= 0;
		absize	<= 0;
		dummy	<= 0;
		dmode	<= 0;
		mode	<= 0;
	end
	if((mem_addr == ADDR_AR) && (mem_wstrb != 0) && mem_ready) begin
		addr	<= mem_wdata;
	end
	if((mem_addr == ADDR_ABR) && (mem_wstrb != 0) && mem_ready) begin
		altb	<= mem_wdata;
	end
	if((mem_addr == ADDR_DLR) && (mem_wstrb != 0) && mem_ready) begin
		dlen	<= mem_wdata;
	end
	if((mem_addr == ADDR_CCR) && (mem_wstrb != 0) && mem_ready) begin
		icode	<= mem_wdata[ 7: 0];
		imode	<= mem_wdata[ 9: 8];
		amode	<= mem_wdata[11:10];
		asize	<= mem_wdata[13:12];
		abmode	<= mem_wdata[15:14];
		absize	<= mem_wdata[17:16];
		dummy	<= mem_wdata[22:18];
		dmode	<= mem_wdata[25:24];
		mode	<= mem_wdata[27:26];
	end
end


//-----------------------------------------------------------------------------
reg [31:0] rdata_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		rdata_r <= 32'b0;
	else if(mem_valid) begin
		case(mem_addr)
			ADDR_CR:	rdata_r <= {ckdiv_r, 4'b0, 1'b0, ckmod_r, ena_r};
			ADDR_SR:	rdata_r <= {fflvl, 6'b0, busy, 1'b0};
			ADDR_AR:	rdata_r <= addr;
			ADDR_ABR:	rdata_r <= altb;
			ADDR_DLR:	rdata_r <= dlen;
			ADDR_CCR:	rdata_r <= {mode, dmode, 1'b0, dummy, absize, abmode, asize, amode, imode, icode};
			ADDR_DR:	rdata_r <= 0;
		endcase
	end
end

assign mem_rdata = rdata_r;


//-----------------------------------------------------------------------------
reg ready_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		ready_r <= 1'b0;
	else if(ready_r)
		ready_r <= 1'b0;
	else if(mem_valid)
		ready_r <= 1'b1;
end

assign mem_ready = ready_r;

endmodule
