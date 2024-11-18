`timescale 1ns / 1ps

module uart (
	input         clk,
	input         rst_n,

	input         mem_valid,
	output        mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output reg	  uart_txd,
	output 		  uart_rxd
);

//----------------------------------------------------------------------------
wire 		clr_n;
wire [23:0] ckdiv;
wire 		data9b;
wire 		stop2b;
wire [ 7:0] totime;
reg  		txbusy;
reg  		timeout;
wire 		int_req;

wire 		tf_write;
wire [ 7:0]	tf_wbyte;
reg 		tf_read;
wire [ 7:0]	tf_rbyte;
wire 		tf_full;
wire 		tf_empty;
wire [ 5:0]	tf_level;

reg 		rf_write;
reg [ 7:0]	rf_wbyte;
wire 		rf_read;
wire [ 7:0]	rf_rbyte;
wire 		rf_full;
wire 		rf_empty;
wire [ 5:0]	rf_level;

uart_reg u_reg (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr[11:0]),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.clr_n  (clr_n  ),
	.ckdiv  (ckdiv  ),
	.data9b (data9b ),
	.stop2b (stop2b ),
	.totime (totime ),
	.error  (1'b0   ),
	.txbusy (txbusy ),
	.timeout(timeout),
	.int_req(int_req),

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
localparam STATE_IDLE	 = 4'h0;

reg [ 3:0] state_r;

reg [ 3:0] count;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		state_r	 <= STATE_IDLE;
	end
	else begin
		tf_read	 <= 0;
		rf_write <= 0;

		case(state_r)
		STATE_IDLE: begin
		end
		endcase
	end
end


endmodule
