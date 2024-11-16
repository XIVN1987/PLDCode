`timescale 1ns / 1ps

module spim (
	input         clk,
	input         rst_n,

	input         mem_valid,
	output        mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  spi_cs,
	output 		  spi_ck,
	input  [ 3:0] spi_di,
	output [ 3:0] spi_do,
	output [ 3:0] spi_oe
);

//----------------------------------------------------------------------------
wire 		clr_n;
wire [ 1:0] ckmod;
wire [ 7:0] ckdiv;
wire [ 1:0] oper;
reg 		odone;
wire [ 7:0] icode;
wire [ 1:0] imode;
wire [31:0] addr;
wire [ 1:0] amode;
wire [ 1:0] asize;
wire [31:0] altb;
wire [ 1:0] abmode;
wire [ 1:0] absize;
wire [ 4:0] dummy;
wire [ 1:0] dmode;
wire [31:0] dlen;

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

spim_reg u_reg (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr[11:0]),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.clr_n (clr_n ),
	.ckmod (ckmod ),
	.ckdiv (ckdiv ),

	.oper  (oper  ),
	.odone (odone ),
	.icode (icode ),
	.imode (imode ),
	.addr  (addr  ),
	.amode (amode ),
	.asize (asize ),
	.altb  (altb  ),
	.abmode(abmode),
	.absize(absize),
	.dummy (dummy ),
	.dmode (dmode ),
	.dlen  (dlen  ),

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
`include "spim.vh"

localparam STATE_IDLE	 = 4'h0;
localparam STATE_CS_0	 = 4'h1;
localparam STATE_INST	 = 4'h2;
localparam STATE_ADDR	 = 4'h3;
localparam STATE_ALTB	 = 4'h4;
localparam STATE_DUMMY	 = 4'h5;
localparam STATE_DATAT_0 = 4'h6;
localparam STATE_DATAT_1 = 4'h7;
localparam STATE_DATAR_0 = 4'h8;
localparam STATE_DATAR_1 = 4'h9;
localparam STATE_CS_1	 = 4'hA;
localparam STATE_WAIT	 = 4'hB;	// wait for oper to be cleared, then switch to IDLE

reg [ 3:0] state_r;

reg 	   spi_cs_r;

reg 	   boper;	// byte transfer oper
reg 	   bmode;	// byte transfer mode
reg [ 7:0] tbyte;	// byte to transmit
wire[ 7:0] rbyte;	// received byte
wire 	   bdone;	// byte transfer done

reg [ 5:0] count;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n | ~clr_n) begin
		state_r	 <= STATE_IDLE;
		spi_cs_r <= 1;
		odone	 <= 0;
		boper	 <= 0;
	end
	else begin
		odone	 <= 0;
		boper	 <= 0;

		case(state_r)
		STATE_IDLE: begin
			if(oper != 0) begin
				state_r	 <= STATE_CS_0;
				spi_cs_r <= 0;
				count	 <= 3;
			end
		end

		STATE_CS_0: begin
			if(~|count) begin
				state_r	 <= STATE_INST;
				boper	 <= Oper_Write;
				bmode	 <= imode;
				tbyte	 <= icode;
			end
			else begin
				count	 <= count - 1;
			end
		end

		STATE_INST: begin
			if(bdone) begin
				if(amode) begin
					state_r	 <= STATE_ADDR;
					boper	 <= Oper_Write;
					bmode	 <= amode;
					tbyte	 <= addr[asize-8 +: 8];
					count	 <= (asize >> 3) - 1;
				end
				else if(abmode) begin
					state_r	 <= STATE_ALTB;
					boper	 <= Oper_Write;
					bmode	 <= abmode;
					tbyte	 <= altb[absize-8 +: 8];
					count	 <= (absize >> 3) - 1;
				end
				else if(dummy) begin
					state_r	 <= STATE_DUMMY;
					boper	 <= Oper_Dummy;
				end
				else if(dmode & (oper == Oper_Read)) begin
					state_r	 <= STATE_DATAR_0;
					boper	 <= Oper_Read;
					bmode	 <= dmode;
					count	 <= dlen;
				end
				else if(dmode & (oper == Oper_Write)) begin
					state_r	 <= STATE_DATAT_0;
					count	 <= dlen;
				end
				else begin
					state_r  <= STATE_CS_1;
					spi_cs_r <= 1;
					count    <= 7;
				end
			end
		end

		STATE_ADDR: begin
			if(bdone) begin
				if(~|count) begin
					if(abmode) begin
						state_r	 <= STATE_ALTB;
						boper	 <= Oper_Write;
						bmode	 <= abmode;
						tbyte	 <= altb[absize-8 +: 8];
						count	 <= (absize >> 3) - 1;
					end
					else if(dummy) begin
						state_r	 <= STATE_DUMMY;
						boper	 <= Oper_Dummy;
					end
					else if(dmode & (oper == Oper_Read)) begin
						state_r	 <= STATE_DATAR_0;
						boper	 <= Oper_Read;
						bmode	 <= dmode;
						count	 <= dlen;
					end
					else if(dmode & (oper == Oper_Write)) begin
						state_r	 <= STATE_DATAT_0;
						count	 <= dlen;
					end
					else begin
						state_r  <= STATE_CS_1;
						spi_cs_r <= 1;
						count    <= 7;
					end
				end
				else begin
					boper	 <= Oper_Write;
					tbyte	 <= addr[(count<<3)-8 +: 8];
					count	 <= count - 1;
				end
			end
		end

		STATE_ALTB: begin
			if(bdone) begin
				if(~|count) begin
					if(dummy) begin
						state_r	 <= STATE_DUMMY;
						boper	 <= Oper_Dummy;
					end
					else if(dmode & (oper == Oper_Read)) begin
						state_r	 <= STATE_DATAR_0;
						boper	 <= Oper_Read;
						bmode	 <= dmode;
						count	 <= dlen;
					end
					else if(dmode & (oper == Oper_Write)) begin
						state_r	 <= STATE_DATAT_0;
						count	 <= dlen;
					end
					else begin
						state_r  <= STATE_CS_1;
						spi_cs_r <= 1;
						count    <= 7;
					end
				end
				else begin
					boper	 <= Oper_Write;
					tbyte	 <= altb[(count<<3)-8 +: 8];
					count	 <= count - 1;
				end
			end
		end

		STATE_DUMMY: begin
			if(bdone) begin
				if(dmode & (oper == Oper_Read)) begin
					state_r	 <= STATE_DATAR_0;
					boper	 <= Oper_Read;
					bmode	 <= dmode;
					count	 <= dlen;
				end
				else if(dmode & (oper == Oper_Write)) begin
					state_r	 <= STATE_DATAT_0;
					count	 <= dlen;
				end
				else begin
					state_r  <= STATE_CS_1;
					spi_cs_r <= 1;
					count    <= 7;
				end
			end
		end

		STATE_DATAT_0: begin
			if(~tf_empty) begin
				state_r	 <= STATE_DATAT_1;
				boper	 <= Oper_Write;
				bmode	 <= dmode;
				tbyte	 <= tf_rbyte;
				tf_read	 <= 1;
				count	 <= count - 1;
			end
		end

		STATE_DATAT_1: begin
			if(bdone) begin
				if(~|count) begin
					state_r  <= STATE_CS_1;
					spi_cs_r <= 1;
					count    <= 7;
				end
				else begin
					state_r	 <= STATE_DATAT_0;
				end
			end
		end

		STATE_DATAR_0: begin
			if(bdone) begin
				state_r	 <= STATE_DATAR_1;
				count	 <= count - 1;
			end
		end

		STATE_DATAR_1: begin
			if(~rf_full) begin
				rf_write <= 1;
				rf_wbyte <= rbyte;

				if(~|count) begin
					state_r  <= STATE_CS_1;
					spi_cs_r <= 1;
					count    <= 7;
				end
				else begin
					state_r	 <= STATE_DATAR_0;
					boper	 <= Oper_Read;
					bmode	 <= dmode;
				end
			end
		end

		STATE_CS_1: begin
			if(~|count) begin
				state_r  <= STATE_WAIT;
				odone	 <= 1;
			end
			else begin
				count    <= count - 1;
			end
		end

		STATE_WAIT: begin
			state_r	 <= STATE_IDLE;
		end
		endcase
	end
end

endmodule
