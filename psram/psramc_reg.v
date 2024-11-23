`timescale 1ns / 1ps

module psramc_reg (
	input  		  clk,
	input  		  rst_n,

	input  		  mem_valid,
	output 		  mem_ready,
	input  [11:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,

	output 		  clr_n,	// clear internal state
	output [ 4:0] ckdiv,

	input  		  ready,
	input  		  error,

	output reg [ 7:0] tSYS,		// tSYS, system clock period in ns
	output reg [ 3:0] tRP,		// tRP, RESET# Pulse Width in us
	output reg [ 3:0] tRH,		// tRH, Time between RESET# (High) and CS# (Low) in us
	output reg [ 7:0] tRWR,		// tRWR, Read-Write Recovery Time in ns
	output reg [ 3:0] tCSM, 	// tCSM, Chip Select Maximum Low Time in us

	/* HyperRAM registers r/w */
	output 		  hrr_reset,
	output reg	  hrr_read,
	input  		  hrr_rdone,
	input  [63:0] hrr_rdata,
	output reg 	  hrr_write,
	output [15:0] hrr_wdata,

	output 		  fix_delay,
	output [ 3:0] ini_delay
);

localparam ADDR_CR	= 12'h00;
localparam ADDR_SR	= 12'h04;
localparam ADDR_TR	= 12'h08;
/* HyperRAM registers defined in Register Space */
localparam ADDR_ID0	= 12'h0C;
localparam ADDR_ID1	= 12'h10;
localparam ADDR_CR0	= 12'h14;
localparam ADDR_CR1	= 12'h18;


//----------------------------------------------------------------------------
reg 	   ena_r;
reg 	   ena_pre;
reg [ 3:0] ckdiv_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		ena_r	<= 0;
		ena_pre <= 0;
		ckdiv_r	<= 3;
	end
	else if((mem_addr == ADDR_CR) && (mem_wstrb != 0) && mem_ready) begin
		ena_pre	<= ena_r;
		ena_r	<= mem_wdata[0];
		ckdiv_r	<= ~|mem_wdata[7:4] ? 1 : mem_wdata[7:4];

		hrr_read<= ena_r;
	end
	else
		hrr_read<= 0;
end

assign clr_n = ena_r;
assign ckdiv = ckdiv_r + 1;

assign hrr_reset = ~ena_pre & ena_r;


//----------------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		tSYS	<= 10;
		tRP		<=  2;
		tRH		<=  2;
		tRWR	<= 50;
		tCSM	<=  4;
	end
	else if((mem_addr == ADDR_TR) && (mem_wstrb != 0) && mem_ready) begin
		tSYS	<= ~|mem_wdata[ 7: 0] ? 1 : mem_wdata[ 7: 0];
		tRP		<= ~|mem_wdata[11: 8] ? 1 : mem_wdata[11: 8];
		tRH		<= ~|mem_wdata[15:12] ? 1 : mem_wdata[15:12];
		tRWR	<= ~|mem_wdata[23:16] ? 1 : mem_wdata[23:16];
		tCSM	<= ~|mem_wdata[27:24] ? 1 : mem_wdata[27:24];
	end
end


//----------------------------------------------------------------------------
reg [15:0] hrr_id0;
reg [15:0] hrr_id1;
reg [15:0] hrr_cr0;
reg [15:0] hrr_cr1;
reg [15:0] hrr_wdata_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		hrr_id0		<= 0;
		hrr_id1		<= 0;
		hrr_cr0		<= 0;
		hrr_cr1		<= 0;
	end
	else if(hrr_rdone) begin
		hrr_id0		<= hrr_rdata[15: 0];
		hrr_id1		<= hrr_rdata[31:16];
		hrr_cr0		<= hrr_rdata[47:32];
		hrr_cr1		<= hrr_rdata[63:48];
	end
	else if((mem_addr == ADDR_CR0) && (mem_wstrb != 0) && mem_ready && (mem_wdata[15:0] == ~mem_wdata[31:16])) begin
		hrr_cr0		<= mem_wdata[15:0];

		hrr_write	<= 1;
		hrr_wdata_r	<= mem_wdata[15:0];
	end
	else if((mem_addr == ADDR_CR1) && (mem_wstrb != 0) && mem_ready && (mem_wdata[15:0] == ~mem_wdata[31:16])) begin
		hrr_cr1		<= mem_wdata[15:0];

		hrr_write	<= 1;
		hrr_wdata_r	<= mem_wdata[15:0];
	end
	else
		hrr_write	<= 0;
end

assign hrr_wdata = hrr_wdata_r;

assign fix_delay = hrr_cr0[3];
assign ini_delay = ({4{hrr_cr0[7:4] == 4'b0000}} & 4'h5) |
				   ({4{hrr_cr0[7:4] == 4'b0001}} & 4'h6) |
				   ({4{hrr_cr0[7:4] == 4'b0010}} & 4'h7) |
				   ({4{hrr_cr0[7:4] == 4'b1110}} & 4'h3) |
				   ({4{hrr_cr0[7:4] == 4'b1111}} & 4'h4);

//-----------------------------------------------------------------------------
reg [31:0] rdata_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		rdata_r <= 32'b0;
	else if(mem_valid) begin
		case(mem_addr)
			ADDR_CR:  rdata_r <= {ckdiv_r, ena_r};
			ADDR_SR:  rdata_r <= {error, ready};
			ADDR_TR:  rdata_r <= {tCSM, tRWR, tRH, tRP, tSYS};
			ADDR_ID0: rdata_r <= hrr_id0;
			ADDR_ID1: rdata_r <= hrr_id1;
			ADDR_CR0: rdata_r <= hrr_cr0;
			ADDR_CR1: rdata_r <= hrr_cr1;
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
