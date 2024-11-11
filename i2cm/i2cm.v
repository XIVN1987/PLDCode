`timescale 1ns / 1ps

module i2cm (
	input         clk,
	input         rst_n,

	input         mem_valid,
	output        mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	input         i2c_scl_i,
	output        i2c_scl_o,
	output        i2c_scl_oe,
	input         i2c_sda_i,
	output        i2c_sda_o,
	output        i2c_sda_oe
);

wire		clr_n;
wire [11:0]	ckdiv;
wire [ 7:0] tbyte;
wire [ 4:0] cmds;
reg  [ 4:0] cdone;	// command done
wire		error;
reg			rxack;
wire [ 7:0] rbyte;

i2cm_reg u_reg (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr[11:0]),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.clr_n(clr_n),
	.ckdiv(ckdiv),
	.tbyte(tbyte),
	.cmds (cmds ),
	.cdone(cdone),

	.error(error),
	.rxack(rxack),
	.rbyte(rbyte)
);


//----------------------------------------------------------------------------
localparam STATE_IDLE	= 4'h0;
localparam STATE_START	= 4'h1;
localparam STATE_WRITE	= 4'h2;
localparam STATE_RXACK	= 4'h3;
localparam STATE_READ	= 4'h4;
localparam STATE_TXACK	= 4'h5;
localparam STATE_STOP	= 4'h6;
localparam STATE_WAIT	= 4'h7;		// wait for cmds clear, then switch to IDLE

reg [3:0] state_r;

reg [4:0] cmd;		// cmd to excute
reg 	  tbit;		// bit to transmit
wire 	  rbit;		// received bit
wire 	  bdone;	// bit done
reg 	  load;
reg 	  shift;
reg [7:0] shift_r;	// shift register
reg [2:0] shift_cnt;
wire 	  shift_done;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
	end
	else if(load) begin
		shift_r   <= tbyte;
		shift_cnt <= 3'h7;
	end
	else if(shift) begin
		shift_r   <= {shift_r[6:0], rbit};
		shift_cnt <= shift_cnt - 3'b1;
	end
end

assign rbyte = shift_r;
assign shift_done = ~|shift_cnt;


always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		state_r <= STATE_IDLE;
	end
	else begin
		tbit  <= shift_r[7];
		load  <= 1'b0;
		shift <= 1'b0;

		case(state_r)
		STATE_IDLE: begin
			if(cmds & `CMD_START) begin
				cmd     <= `CMD_START;
				state_r <= STATE_START;
			end
			else if(cmds & `CMD_WRITE) begin
				cmd     <= `CMD_WRITE;
				state_r <= STATE_WRITE;

				load <= 1'b1;
			end
			else if(cmds & `CMD_READ) begin
				cmd     <= `CMD_READ;
				state_r <= STATE_READ;

				load <= 1'b1;
			end
			else if(cmds & `CMD_STOP) begin
				cmd     <= `CMD_STOP;
				state_r <= STATE_STOP;
			end
		end

		STATE_START: begin
			if(bdone) begin
				state_r <= STATE_WAIT;
				cdone   <= `CMD_START;
			end
		end

		STATE_WRITE: begin
			if(bdone) begin
				if(shift_done) begin
					cmd     <= `CMD_READ;
					state_r <= STATE_RXACK;
				end
				else
					shift <= 1'b1;
			end
		end

		STATE_RXACK: begin
			if(bdone) begin
				state_r <= STATE_WAIT;
				cdone   <= `CMD_WRITE;
				rxack   <= rbit;
			end
		end

		STATE_READ: begin
			if(bdone) begin
				if(shift_done) begin
					cmd     <= `CMD_WRITE;
					state_r <= STATE_TXACK;
				end
				else
					shift <= 1'b1;
			end
		end

		STATE_TXACK: begin
			if(bdone) begin
				state_r <= STATE_WAIT;
				cdone   <= `CMD_READ;
				tbit    <= cmds & `CMD_TXACK ? 1 : 0;
			end
		end

		STATE_STOP: begin
			if(bdone) begin
				state_r <= STATE_WAIT;
				cdone   <= `CMD_STOP;
			end
		end

		STATE_WAIT: begin
			state_r <= STATE_IDLE;
			cdone   <= 5'b0;
		end
		endcase
	end
end


i2cm_bit u_bit (
	.clk   (clk   ),
	.rst_n (rst_n ),
	
	.clr_n (clr_n ),
	.ckdiv (ckdiv ),
	.cmd   (cmd   ),
	.tbit  (tbit  ),
	.rbit  (rbit  ),
	.bdone (bdone ),
	.error (error ),

	.i2c_scl_i (i2c_scl_i ),
	.i2c_scl_o (i2c_scl_o ),
	.i2c_scl_oe(i2c_scl_oe),
	.i2c_sda_i (i2c_sda_i ),
	.i2c_sda_o (i2c_sda_o ),
	.i2c_sda_oe(i2c_sda_oe)
);

endmodule
