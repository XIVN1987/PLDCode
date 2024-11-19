`timescale 1ns / 1ps

module uart_reg (
	input  		  clk,
	input  		  rst_n,

	input  		  mem_valid,
	output 		  mem_ready,
	input  [11:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  clr_n,		// clear internal state
	output [23:0] ckdiv,
	output 		  data9b,
	output 		  stop2b,
	output [ 7:0] totime,

	input  		  error,
	input  		  txbusy,
	input  		  timeout,

	output 		  int_req,

	output 		  tf_write,
	output [ 8:0] tf_wbyte,
	input  [ 5:0] tf_level,
	input  		  tf_full,
	output 		  rf_read,
	input  [ 8:0] rf_rbyte,
	input  [ 5:0] rf_level,
	input  		  rf_empty
);

localparam ADDR_CR	  = 12'h00;
localparam ADDR_SR	  = 12'h04;
localparam ADDR_DR	  = 12'h08;
localparam ADDR_CKDIV = 12'h0C;


//----------------------------------------------------------------------------
reg 	   ena_r;
reg 	   data9b_r;
reg 	   stop2b_r;
reg [ 7:0] totime_r;
reg 	   ie_txhalf;
reg 	   ie_rxhalf;
reg 	   ie_rxtout;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ena_r	  <= 0;
		data9b_r  <= 0;
		stop2b_r  <= 0;
		totime_r  <= 0;
		ie_txhalf <= 0;
		ie_rxhalf <= 0;
		ie_rxtout <= 0;	
	end
	else if((mem_addr == ADDR_CR) && (mem_wstrb != 0) && mem_ready) begin
		ena_r	  <= mem_wdata[   0];
		data9b_r  <= mem_wdata[   1];
		stop2b_r  <= mem_wdata[   2];
		totime_r  <= mem_wdata[15:8];
		ie_txhalf <= mem_wdata[  16];
		ie_rxhalf <= mem_wdata[  17];
		ie_rxtout <= mem_wdata[  18];
	end
end

assign clr_n  = ena_r;
assign data9b = data9b_r;
assign stop2b = stop2b_r;
assign totime = totime_r;


//----------------------------------------------------------------------------
wire	   if_txhalf;
wire	   if_rxhalf;
reg 	   if_rxtout;

always @(posedge timeout)
	if_rxtout <= timeout;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		if_rxtout <= 0;
	end
	else if((mem_addr == ADDR_SR) && (mem_wstrb != 0) && mem_ready) begin
		if_rxtout <= if_rxtout & ~mem_wdata[18];
	end
end

assign if_txhalf = tf_level < 16;
assign if_rxhalf = rf_level > 16;

assign int_req = (ie_txhalf & if_txhalf) |
				 (ie_rxhalf & if_rxhalf) |
				 (ie_rxtout & if_rxtout);

//----------------------------------------------------------------------------
reg [23:0] ckdiv_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ckdiv_r <= 16;
	end
	else if((mem_addr == ADDR_CKDIV) && (mem_wstrb != 0) && mem_ready) begin
		ckdiv_r <= ~|mem_wdata[23:4] ? 16 : mem_wdata[23:0];
	end
end

assign ckdiv = ckdiv_r;


//----------------------------------------------------------------------------
reg 	   write_r;
reg [ 8:0] wbyte_r;
reg 	   read_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		write_r <= 0;
		read_r  <= 0;

	if(write_r)
		write_r <= 0;
	else if((mem_addr == ADDR_DR) && (mem_wstrb != 0) && mem_ready) begin
		write_r <= tf_full ? 0 : 1;
		wbyte_r <= mem_wdata[ 8: 0];
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
			ADDR_CR:	rdata_r <= {ie_rxtout, ie_rxhalf, ie_txhalf, totime_r, 5'b0, stop2b_r, data9b_r, ena_r};
			ADDR_SR:	rdata_r <= {if_rxtout, if_rxhalf, if_txhalf, 12'b0, rf_empty, tf_full, txbusy, error};
			ADDR_DR:	rdata_r <= rf_rbyte;
			ADDR_CKDIV:	rdata_r <= ckdiv_r;
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



//-----------------------------------------------------------------------------
module byte_fifo #(
	parameter DEPTH = 16,
	parameter WADDR =  4
) (
	input  		  clk,
	input  		  rst_n,
	input  		  clr_n,

	input  		  write,
	input  [ 8:0] wbyte,
	input  		  read,
	output [ 8:0] rbyte,
	output		  full,
	output 		  empty,
	output [WADDR:0] level
);

reg [8:0] mem[DEPTH-1:0];
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
