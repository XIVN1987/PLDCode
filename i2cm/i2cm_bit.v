`timescale 1ns / 1ps

module i2cm_bit (
	input		  clk,
	input		  rst_n,

	input		  clr_n,
	input  [11:0] ckdiv,
	input  [ 4:0] cmd,
	input		  tbit,
	output reg	  rbit,
	output		  bdone,	// bit done
	output		  error,

	input		  i2c_scl_i,
	output		  i2c_scl_o,
	output		  i2c_scl_oe,
	input		  i2c_sda_i,
	output		  i2c_sda_o,
	output		  i2c_sda_oe
);

localparam STATE_IDLE		= 6'h00;
localparam STATE_START_1	= 6'h01;
localparam STATE_START_2	= 6'h02;
localparam STATE_START_3	= 6'h03;
localparam STATE_START_4	= 6'h04;
localparam STATE_WRITE_1	= 6'h11;
localparam STATE_WRITE_2	= 6'h12;
localparam STATE_WRITE_3	= 6'h13;
localparam STATE_WRITE_4	= 6'h14;
localparam STATE_READ_1		= 6'h21;
localparam STATE_READ_2		= 6'h22;
localparam STATE_READ_3		= 6'h23;
localparam STATE_READ_4		= 6'h24;
localparam STATE_STOP_1		= 6'h31;
localparam STATE_STOP_2		= 6'h32;
localparam STATE_STOP_3		= 6'h33;
localparam STATE_STOP_4		= 6'h34;

reg [5:0] state_r;

reg [4:0] bdone_r;
reg 	  error_r;

reg 	  scl_oe_r;
reg 	  sda_oe_r;

reg 	  clk_en_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		state_r  <= STATE_IDLE;
		bdone_r  <= 1'b0;
		error_r  <= 1'b0;
		scl_oe_r <= 1'b0;
		sda_oe_r <= 1'b0;
	end
	else begin
		bdone_r  <= 1'b0;
		error_r  <= 1'b0;

		if(clk_en_r) begin
			case(state_r)
			STATE_IDLE: begin
				case(cmd)
					`CMD_START: state_r <= STATE_START_1;
					`CMD_WRITE: state_r <= STATE_WRITE_1;
					`CMD_READ:  state_r <= STATE_READ_1;
					`CMD_STOP:  state_r <= STATE_STOP_1;
				endcase
			end

			STATE_START_1: begin
				state_r  <= STATE_START_2;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b0;	// SDA 1
			end
			STATE_START_2: begin
				state_r  <= STATE_START_3;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b1;	// SDA 0
			end
			STATE_START_3: begin
				state_r  <= STATE_START_4;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b1;	// SDA 0
			end
			STATE_START_4: begin
				state_r  <= STATE_IDLE;
				bdone_r  <= 1'b1;
				scl_oe_r <= 1'b1;	// SCL 0
				sda_oe_r <= 1'b1;	// SDA 0
			end

			STATE_WRITE_1: begin
				state_r  <= STATE_WRITE_2;
				scl_oe_r <= 1'b1;	// SCL 0
				sda_oe_r <= ~tbit;	// SDA v
			end
			STATE_WRITE_2: begin
				state_r  <= STATE_WRITE_3;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= ~tbit;	// SDA v
			end
			STATE_WRITE_3: begin
				state_r  <= STATE_WRITE_4;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= ~tbit;	// SDA v
			end
			STATE_WRITE_4: begin
				state_r  <= STATE_IDLE;
				bdone_r  <= 1'b1;
				scl_oe_r <= 1'b1;	// SCL 0
				sda_oe_r <= ~tbit;	// SDA v
			end

			STATE_READ_1: begin
				state_r  <= STATE_READ_2;
				scl_oe_r <= 1'b1;	// SCL 0
				sda_oe_r <= 1'b0;	// SDA week pull-up
			end
			STATE_READ_2: begin
				state_r  <= STATE_READ_3;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b0;	// SDA week pull-up
			end
			STATE_READ_3: begin
				state_r  <= STATE_READ_4;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b0;	// SDA week pull-up
			end
			STATE_READ_4: begin
				state_r  <= STATE_IDLE;
				bdone_r  <= 1'b1;
				scl_oe_r <= 1'b1;	// SCL 0
				sda_oe_r <= 1'b0;	// SDA week pull-up
			end

			STATE_STOP_1: begin
				state_r  <= STATE_STOP_2;
				scl_oe_r <= 1'b1;	// SCL 0
				sda_oe_r <= 1'b1;	// SDA 0
			end
			STATE_STOP_2: begin
				state_r  <= STATE_STOP_3;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b1;	// SDA 0
			end
			STATE_STOP_3: begin
				state_r  <= STATE_STOP_4;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b1;	// SDA 0
			end
			STATE_STOP_4: begin
				state_r  <= STATE_IDLE;
				bdone_r  <= 1'b1;
				scl_oe_r <= 1'b0;	// SCL 1
				sda_oe_r <= 1'b0;	// SDA 1
			end
			endcase
		end
	end
end


//----------------------------------------------------------------------------
reg [11:0] count_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n || ~clr_n) begin
		count_r  <= 12'b0;
		clk_en_r <= 1'b0;
	end
	else if(count_r < 12'h5) begin
		count_r  <= ckdiv;
		clk_en_r <= 1'b1;
	end
	else begin
		count_r  <= count_r - 12'h5;	// 5 clock cycle per bit
		clk_en_r <= 1'b0;
	end
end


//----------------------------------------------------------------------------
reg [1:0] scl_i;
reg [1:0] sda_i;

always @(posedge clk_en_r or negedge rst_n) begin
	if(~rst_n) begin
		scl_i <= 2'b11;
		sda_i <= 2'b11;
	end
	else begin
		scl_i <= {scl_i[0], i2c_scl_i};
		sda_i <= {sda_i[0], i2c_sda_i};
	end
end

always @(posedge clk) begin
	if(scl_i[0] & ~scl_i[1])	// at middle of SCL
		rbit <= i2c_sda_i;
end


//----------------------------------------------------------------------------
assign bdone   = bdone_r;
assign error   = error_r;

assign i2c_scl_o  = 1'b0;	// use oe setting line level
assign i2c_sda_o  = 1'b0;
assign i2c_scl_oe = scl_oe_r;
assign i2c_sda_oe = sda_oe_r;

endmodule
