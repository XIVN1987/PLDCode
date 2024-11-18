`timescale 1ns / 1ps

module uart (
	input  		  clk,
	input  		  rst_n,

	input  		  mem_valid,
	output 		  mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  uart_txd,
	input  		  uart_rxd
);

//----------------------------------------------------------------------------
wire 		clr_n;
wire [23:0] ckdiv;
wire 		data9b;
wire 		stop2b;
wire [ 7:0] totime;
wire 		txbusy;
wire 		timeout;
wire 		int_req;

wire 		tf_write;
wire [ 8:0]	tf_wbyte;
wire 		tf_read;
wire [ 8:0]	tf_rbyte;
wire 		tf_full;
wire 		tf_empty;
wire [ 5:0]	tf_level;

wire 		rf_write;
wire [ 8:0]	rf_wbyte;
wire 		rf_read;
wire [ 8:0]	rf_rbyte;
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

uart_tx u_utx (
	.clk     (clk     ),
	.rst_n   (rst_n   ),

	.clr_n   (clr_n   ),
	.ckdiv   (ckdiv   ),
	.data9b  (data9b  ),
	.stop2b  (stop2b  ),
	.txbusy  (txbusy  ),

	.tf_read (tf_read ),
	.tf_rbyte(tf_rbyte),
	.tf_empty(tf_empty),

	.uart_txd(uart_txd)
);


uart_rx u_urx (
	.clk     (clk     ),
	.rst_n   (rst_n   ),

	.clr_n   (clr_n   ),
	.ckdiv   (ckdiv   ),
	.data9b  (data9b  ),
	.totime  (totime  ),
	.timeout (timeout ),

	.rf_write(rf_write),
	.rf_wbyte(rf_wbyte),
	.rf_full (rf_full ),

	.uart_rxd(uart_rxd)
);

endmodule
