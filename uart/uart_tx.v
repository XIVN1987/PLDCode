`timescale 1ns / 1ps

module uart_tx (
	input  		  clk,
	input  		  rst_n,

	input  		  clr_n,
	input  [23:0] ckdiv,
	input  		  data9b,
	input  		  stop2b,

	output 		  txbusy,

	output reg	  tf_read,
	input  [ 8:0] tf_rbyte,
	input  		  tf_empty,

	output reg	  uart_txd
);

//----------------------------------------------------------------------------
reg [23:0] cnt_ck;
reg 	   clk_en;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		cnt_ck <= 0;
		clk_en <= 0;
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

reg [ 8:0] tbyte_r;

reg [ 3:0] count;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		state_r <= STATE_IDLE;
		uart_txd<= 1;
	end
	else begin
		tf_read	<= 0;

		if(clk_en) begin
			case(state_r)
			STATE_IDLE: begin
				if(~tf_empty) begin
					state_r <= STATE_START;
					uart_txd<= 0;

					tbyte_r <= tf_rbyte;
					tf_read <= 1;
				end
			end

			STATE_START: begin
				state_r <= STATE_DATA;
				uart_txd<= tbyte_r[0];
				tbyte_r <= {1'b0, tbyte_r[8:1]};
				count	<= 8 + data9b - 1;
			end

			STATE_DATA: begin
				if(~|count) begin
					state_r <= STATE_STOP;
					uart_txd<= 1;
					count	<= stop2b;
				end
				else begin
					uart_txd<= tbyte_r[0];
					tbyte_r <= {1'b0, tbyte_r[8:1]};
					count	<= count - 1;
				end
			end

			STATE_STOP: begin
				if(~|count) begin
					state_r <= STATE_IDLE;
				end
				else begin
					count	<= count - 1;
				end
			end
			endcase
		end
	end
end

assign txbusy = ~(tf_empty & (state_r == STATE_IDLE));

endmodule
