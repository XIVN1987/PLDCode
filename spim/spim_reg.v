`timescale 1ns / 1ps

module spim_reg (
	input  		  clk,
	input  		  rst_n,

	input  		  mem_valid,
	output 		  mem_ready,
	input  [11:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  clr_n,		// clear internal state
	output [ 1:0] ckmod,
	output [ 7:0] ckdiv,

	output reg [ 1:0] oper,
	input  			  odone,	// operation done
	output reg [ 7:0] icode,
	output reg [ 1:0] imode,
	output reg [31:0] addr,
	output reg [ 1:0] amode,
	output reg [ 1:0] asize,
	output reg [31:0] altb,
	output reg [ 1:0] abmode,
	output reg [ 1:0] absize,
	output reg [ 4:0] dummy,
	output reg [ 1:0] dmode,
	output reg [19:0] dlen,

	output 		  tf_write,
	output [ 7:0] tf_wbyte,
	input  [ 5:0] tf_level,
	input  		  tf_full,
	output 		  rf_read,
	input  [ 7:0] rf_rbyte,
	input  [ 5:0] rf_level,
	input  		  rf_empty
);

`include "spim.vh"

localparam ADDR_CR	= 12'h00;
localparam ADDR_SR	= 12'h04;
localparam ADDR_AR	= 12'h08;
localparam ADDR_ABR	= 12'h0C;
localparam ADDR_DLR	= 12'h10;
localparam ADDR_CCR = 12'h14;
localparam ADDR_DR	= 12'h18;


//----------------------------------------------------------------------------
reg 	   ena_r;
reg [ 1:0] ckmod_r;
reg [ 7:0] ckdiv_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ena_r	<= 0;
		ckmod_r <= 0;
		ckdiv_r <= 0;
	end
	else if((mem_addr == ADDR_CR) && (mem_wstrb != 0) && mem_ready) begin
		ena_r	<= mem_wdata[   0];
		ckmod_r <= mem_wdata[ 2:1];
		ckdiv_r <= ~|mem_wdata[15:9] ? 2 : mem_wdata[15:8];
	end
end

assign clr_n = ena_r;
assign ckmod = ckmod_r;
assign ckdiv = ckdiv_r;


//----------------------------------------------------------------------------
reg [ 1:0] oper_r;

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
		oper_r	<= 0;
		oper	<= 0;
	end
	if((mem_addr == ADDR_AR) && (mem_wstrb != 0) && mem_ready) begin
		addr	<= mem_wdata;

		oper	<= amode != PhaseMode_None ? oper_r : 0;
	end
	if((mem_addr == ADDR_ABR) && (mem_wstrb != 0) && mem_ready) begin
		altb	<= mem_wdata;
	end
	if((mem_addr == ADDR_DLR) && (mem_wstrb != 0) && mem_ready) begin
		dlen	<= mem_wdata[19:0];
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
		oper_r	<= mem_wdata[27:26];

		oper	<= mem_wdata[11:10] == PhaseMode_None ? mem_wdata[27:26] : 0;
	end
end

always @(posedge odone)
	oper <= 0;


//----------------------------------------------------------------------------
reg 	   write_r;
reg [ 7:0] wbyte_r;
reg 	   read_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		write_r <= 0;
		read_r  <= 0;

	if(write_r)
		write_r <= 0;
	else if((mem_addr == ADDR_DR) && (mem_wstrb != 0) && mem_ready) begin
		write_r <= tf_full ? 0 : 1;
		wbyte_r <= mem_wdata[ 7: 0];
	end

	if(read_r)
		read_r  <= 0;
	else if((mem_addr == ADDR_DR) && (mem_wstrb == 0) && mem_ready) begin
		read_r  <= rf_empty ? 0 : 1;
	end
end

assign tf_write = write_r;
assign tf_wbyte = wbyte_r;
assign rf_read  = read_r;


//-----------------------------------------------------------------------------
reg [31:0] rdata_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		rdata_r <= 32'b0;
	else if(mem_valid) begin
		case(mem_addr)
			ADDR_CR:	rdata_r <= {ckdiv_r, 4'b0, 1'b0, ckmod_r, ena_r};
			ADDR_SR:	rdata_r <= {oper_r == Oper_Write ? tf_level : rf_level, 6'b0, |oper, 1'b0};
			ADDR_AR:	rdata_r <= addr;
			ADDR_ABR:	rdata_r <= altb;
			ADDR_DLR:	rdata_r <= dlen;
			ADDR_CCR:	rdata_r <= {oper_r, dmode, 1'b0, dummy, absize, abmode, asize, amode, imode, icode};
			ADDR_DR:	rdata_r <= rf_rbyte;
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



module byte_fifo #(
	parameter DEPTH = 16,
	parameter WADDR =  4
) (
	input  		  clk,
	input  		  rst_n,
	input  		  clr_n,

	input  		  write,
	input  [ 7:0] wbyte,
	input  		  read,
	output [ 7:0] rbyte,
	output		  full,
	output 		  empty,
	output [WADDR:0] level
);

reg [7:0] mem[DEPTH-1:0];
reg [WADDR-1:0] wptr;
reg [WADDR-1:0] rptr;
reg [WADDR  :0] count;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		wptr	<= 0;
		rptr	<= 0;
		count	<= 0;
	end
	else begin
		if(write & ~full) begin			// write
			mem[wptr]	<= wbyte;
			wptr		<= wptr + 1;
		end

		if(read & ~empty) begin			// read
			rptr		<= rptr + 1;
		end

		if((write & ~full) & ~(read & ~empty))			// write only
			count		<= count + 1;
		else if((read & ~empty) & ~(write & ~full))		// read only
			count		<= count - 1;
	end
end

assign rbyte = mem[rptr];

assign level =  count;
assign empty = (count == 0);
assign full  = (count == DEPTH);

endmodule
