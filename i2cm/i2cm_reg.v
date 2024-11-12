`timescale 1ns / 1ps

module i2cm_reg (
	input  		  clk,
	input  		  rst_n,

	input  		  mem_valid,
	output 		  mem_ready,
	input  [11:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  clr_n,	// clear internal state
	output [11:0] ckdiv,
	output [ 4:0] cmds,		// commands
	input  [ 4:0] cdone,	// command done
	output [ 7:0] tbyte,	// byte to transmit
	input  		  rxack,	// received ack
	input  [ 7:0] rbyte,	// received byte
	output 		  txack,	// ack to transmit
	input  		  error
);

`include "i2cm.vh"

localparam ADDR_CR	 = 12'h00;
localparam ADDR_SR	 = 12'h04;
localparam ADDR_CMD	 = 12'h08;
localparam ADDR_DATA = 12'h0C;


//----------------------------------------------------------------------------
reg 		ena_r;
reg [11: 0]	ckdiv_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ena_r	<= 0;
		ckdiv_r <= 0;
	end
	else if((mem_addr == ADDR_CR) && (mem_wstrb != 0) && mem_ready) begin
		ena_r	<= mem_wdata[   0];
		ckdiv_r <= mem_wdata[19:8];
	end
end

assign clr_n = ena_r;
assign ckdiv = ckdiv_r;


//----------------------------------------------------------------------------
reg [ 4: 0]	cmd_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n || ~clr_n) begin
		cmd_r <= 0;
	end
	else if((mem_addr == ADDR_CMD) && (mem_wstrb != 0) && mem_ready) begin
		cmd_r <= mem_wdata[4:0];
	end
	else if(cdone) begin
		cmd_r <= cmd_r & ~(cdone | (cdone == CMD_READ ? CMD_TXACK_Msk : 0));
	end
end

assign cmds  = cmd_r;
assign txack = cmd_r[CMD_TXACK_Pos];


//----------------------------------------------------------------------------
reg [ 7: 0]	data_r;
reg [ 7: 0]	rbyte_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		data_r  <= 0;
		rbyte_r <= 0;
	end
	else if((mem_addr == ADDR_DATA) && (mem_wstrb != 0) && mem_ready) begin
		data_r  <= mem_wdata[7:0];
	end
	else if(cdone == CMD_READ)
		rbyte_r <= rbyte;
end

assign tbyte = data_r;


//-----------------------------------------------------------------------------
reg [31:0] rdata_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		rdata_r <= 32'b0;
	else if(mem_valid) begin
		case(mem_addr)
			ADDR_CR:	rdata_r <= {ckdiv_r, 7'b0, ena_r};
			ADDR_SR:	rdata_r <= {rxack, error};
			ADDR_CMD:	rdata_r <= cmd_r;
			ADDR_DATA:	rdata_r <= rbyte_r;
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
