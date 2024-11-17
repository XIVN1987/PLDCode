module spim_byte (
	input  		  clk,
	input  		  rst_n,

	output 		  clr_n,		// clear internal state
	output [ 1:0] ckmod,
	output [ 7:0] ckdiv,

	input  [ 1:0] boper,
	input  [ 1:0] bmode,
	input  [ 7:0] tbyte,
	output [ 7:0] rbyte,
	input  [ 4:0] dummy,
	output 		  bdone,

	output 		  spi_ck,
	input  [ 3:0] spi_di,
	output [ 3:0] spi_do,
	output [ 3:0] spi_oe
);

`include "spim.vh"

localparam STATE_IDLE		= 4'h0;
localparam STATE_TBYTE_00_0	= 4'h1;
localparam STATE_TBYTE_00_1	= 4'h2;
localparam STATE_TBYTE_11_0	= 4'h3;
localparam STATE_TBYTE_11_1	= 4'h4;
localparam STATE_RBYTE_00_0	= 4'h5;
localparam STATE_RBYTE_00_1	= 4'h6;
localparam STATE_RBYTE_11_0	= 4'h7;
localparam STATE_RBYTE_11_1	= 4'h8;
localparam STATE_DUMMY_0	= 4'h9;
localparam STATE_DUMMY_1	= 4'hA;

reg [ 3:0] state_r;

reg [ 7:0] rbyte_r;
reg 	   bdone_r;
reg [ 4:0] count;

reg 	   spi_ck_r;
reg [ 3:0] spi_do_r;
reg [ 3:0] spi_oe_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		state_r	 <= STATE_IDLE;
		spi_ck_r <= |ckmod ? 1 : 0;
		spi_oe_r <= 4'b0000;
		bdone_r	 <= 0;
	end
	else begin
		bdone_r	 <= 0;

		case(state_r)
		STATE_IDLE: begin
			case(boper)
			Oper_Read: begin
				spi_oe_r <= 4'b0000;
				rbyte_r	 <= 0;
				count	 <= 8;

				if(|ckmod) begin
					state_r	 <= STATE_RBYTE_11_0;
				end
				else begin
					state_r	 <= STATE_RBYTE_00_0;
				end
			end

			Oper_Write: begin
				if(|ckmod) begin
					state_r	 <= STATE_TBYTE_11_0;
					count	 <= 8;
				end
				else begin
					state_r	 <= STATE_TBYTE_00_0;

					case(bmode)
					PhaseMode_1bit: begin
						spi_oe_r <= 4'b0001;
						spi_do_r <= tbyte[8-1 +: 1];
						count	 <= 8 - 1;
					end

					PhaseMode_2bit: begin
						spi_oe_r <= 4'b0011;
						spi_do_r <= tbyte[8-2 +: 2];
						count	 <= 8 - 2;
					end
					
					PhaseMode_4bit: begin
						spi_oe_r <= 4'b1111;
						spi_do_r <= tbyte[8-4 +: 4];
						count	 <= 8 - 4;
					end
					endcase
				end
			end

			Oper_Dummy: begin
				state_r	 <= STATE_DUMMY_0;
				count	 <= dummy;
			end
			endcase
		end

		STATE_TBYTE_00_0: begin
			spi_ck_r <= spi_ck_r ^ 1;
			state_r	 <= STATE_TBYTE_00_1;
		end

		STATE_TBYTE_00_1: begin
			spi_ck_r <= spi_ck_r ^ 1;

			if(~|count) begin
				state_r	 <= STATE_IDLE;
				bdone_r	 <= 1;
			end
			else begin
				state_r	 <= STATE_TBYTE_00_0;
				case(bmode)
				PhaseMode_1bit: begin
					spi_do_r <= tbyte[count-1 +: 1];
					count	 <= count - 1;
				end

				PhaseMode_2bit: begin
					spi_do_r <= tbyte[count-2 +: 2];
					count	 <= count - 2;
				end
				
				PhaseMode_4bit: begin
					spi_do_r <= tbyte[count-4 +: 4];
					count	 <= count - 4;
				end
				endcase
			end
		end

		STATE_TBYTE_11_0: begin
			spi_ck_r <= spi_ck_r ^ 1;
			state_r	 <= STATE_TBYTE_11_1;

			case(bmode)
			PhaseMode_1bit: begin
				spi_oe_r <= 4'b0001;
				spi_do_r <= tbyte[count-1 +: 1];
				count	 <= count - 1;
			end

			PhaseMode_2bit: begin
				spi_oe_r <= 4'b0011;
				spi_do_r <= tbyte[count-2 +: 2];
				count	 <= count - 2;
			end
			
			PhaseMode_4bit: begin
				spi_oe_r <= 4'b1111;
				spi_do_r <= tbyte[count-4 +: 4];
				count	 <= count - 4;
			end
			endcase
		end

		STATE_TBYTE_11_1: begin
			spi_ck_r <= spi_ck_r ^ 1;

			if(~|count) begin
				state_r	 <= STATE_IDLE;
				bdone_r	 <= 1;
			end
			else begin
				state_r	 <= STATE_TBYTE_11_0;
			end
		end

		STATE_RBYTE_00_0: begin
			spi_ck_r <= spi_ck_r ^ 1;
			state_r	 <= STATE_RBYTE_00_1;

			case(bmode)
			PhaseMode_1bit: begin
				rbyte_r	 <= (rbyte_r << 1) | spi_di[1:1];
				count	 <= count - 1;
			end

			PhaseMode_2bit: begin
				rbyte_r	 <= (rbyte_r << 2) | spi_di[1:0];
				count	 <= count - 2;
			end
			
			PhaseMode_4bit: begin
				rbyte_r	 <= (rbyte_r << 4) | spi_di[3:0];
				count	 <= count - 4;
			end
			endcase
		end

		STATE_RBYTE_00_1: begin
			spi_ck_r <= spi_ck_r ^ 1;

			if(~|count) begin
				state_r	 <= STATE_IDLE;
				bdone_r	 <= 1;
			end
			else begin
				state_r	 <= STATE_RBYTE_00_0;
			end
		end

		STATE_RBYTE_11_0: begin
			spi_ck_r <= spi_ck_r ^ 1;
			state_r	 <= STATE_RBYTE_11_1;

			case(bmode)
			PhaseMode_1bit: count	 <= count - 1;
			PhaseMode_2bit: count	 <= count - 2;
			PhaseMode_4bit: count	 <= count - 4;
			endcase
		end

		STATE_RBYTE_11_1: begin
			spi_ck_r <= spi_ck_r ^ 1;

			case(bmode)
			PhaseMode_1bit: begin
				rbyte_r	 <= (rbyte_r << 1) | spi_di[1:1];
			end

			PhaseMode_2bit: begin
				rbyte_r	 <= (rbyte_r << 2) | spi_di[1:0];
			end
			
			PhaseMode_4bit: begin
				rbyte_r	 <= (rbyte_r << 4) | spi_di[3:0];
			end
			endcase

			if(~|count) begin
				state_r	 <= STATE_IDLE;
				bdone_r	 <= 1;
			end
			else begin
				state_r	 <= STATE_RBYTE_11_0;
			end
		end

		STATE_DUMMY_0: begin
			spi_ck_r <= spi_ck_r ^ 1;
			state_r	 <= STATE_DUMMY_1;

			count	 <= count - 1;
		end

		STATE_DUMMY_1: begin
			spi_ck_r <= spi_ck_r ^ 1;

			if(~|count) begin
				state_r	 <= STATE_IDLE;
				bdone_r	 <= 1;
			end
			else begin
				state_r	 <= STATE_DUMMY_0;
			end
		end
		endcase
	end
end

assign rbyte  = rbyte_r;
assign bdone  = bdone_r;

assign spi_ck = spi_ck_r;
assign spi_do = spi_do_r;
assign spi_oe = spi_oe_r;

endmodule
