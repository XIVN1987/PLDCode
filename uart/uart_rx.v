`timescale 1ns / 1ps

module uart_rx (
	input  		  clk,
	input  		  rst_n,

	input  		  clr_n,
	input  [23:0] ckdiv,
	input  		  data9b,
	input  [ 7:0] totime,

	output reg	  timeout,

	output reg	  rf_write,
	output [ 8:0] rf_wbyte,
	input  		  rf_full,

	input  		  uart_rxd
);

//----------------------------------------------------------------------------
reg [23:0] cnt_ck;
reg 	   clk_en;
reg 	   synclk;	// synchronize clk_en to the middle point of the signal

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		cnt_ck <= 0;
		clk_en <= 0;
	end
	else if(synclk) begin
		cnt_ck <= ckdiv[23:1];
		synclk <= 0;
	end
	else if(~|cnt_ck) begin
		cnt_ck <= ckdiv;
		clk_en <= 1;
	end
	else begin
		cnt_ck <= cnt_ck - 1;
		clk_en <= 0;
	end
end


//----------------------------------------------------------------------------
localparam STATE_IDLE	= 4'h0;
localparam STATE_START	= 4'h1;
localparam STATE_DATA	= 4'h2;
localparam STATE_STOP	= 4'h3;

reg [ 3:0] state_r;

reg [ 8:0] rbyte_r;

reg [ 3:0] count;

reg 	   to_start;
reg [ 7:0] to_count;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		state_r <= STATE_IDLE;
		rbyte_r <= 0;
	end
	else begin
		rf_write<= 0;

		case(state_r)
		STATE_IDLE: begin
			if(~uart_rxd) begin
				state_r <= STATE_START;
				synclk	<= 1;

				to_start<= 0;
			end
		end

		STATE_START: if(clk_en) begin
			state_r <= STATE_DATA;
			count	<= 8 + data9b - 1;
		end

		STATE_DATA: if(clk_en) begin
			if(~|count) begin
				state_r <= STATE_STOP;

				rbyte_r <= {uart_rxd, rbyte_r[8:1]};
			end
			else begin
				rbyte_r <= {uart_rxd, rbyte_r[8:1]};
				count	<= count - 1;
			end
		end

		STATE_STOP: if(clk_en) begin
			state_r <= STATE_IDLE;
			if(~rf_full) begin
				rf_write<= 1;
			end

			to_start<= 1;
			to_count<= totime;
		end
		endcase
	end
end

assign rf_wbyte = data9b ? rbyte_r : rbyte_r[8:1];


always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		timeout <= 0;
		to_start<= 0;
	end
	else if(timeout) begin
		timeout <= 0;
	end
	else if(to_start) begin
		if(~|to_count) begin
			timeout	<= 1;
			to_start<= 0;
		end
		else if(clk_en) begin
			to_count<= to_count - 1;
		end
	end
end

endmodule
