`timescale 1ns / 1ps

module memory #(
	parameter		SIZE     = 8192,
	parameter 		FIRMWARE = ""
) (
	input			clk,
	input			rst_n,

	input			mem_valid,
	output			mem_ready,

	input  [31:0]	mem_addr,
	input  [31:0]	mem_wdata,
	input  [ 3:0]	mem_wstrb,
	output [31:0]	mem_rdata
);

localparam DEPTH = $clog2(SIZE);

//-----------------------------------------------------------------------------
reg [31:0] mem_r [0:SIZE/4-1];

initial begin
	$readmemh(FIRMWARE, mem_r);
end

//-----------------------------------------------------------------------------
reg ready_r;

always @(posedge clk) begin
	if(~rst_n)
		ready_r <= 1'b0;
	else if(ready_r)
		ready_r <= 1'b0;
	else if(mem_valid)
		ready_r <= 1'b1;
end

assign mem_ready = ready_r;

//-----------------------------------------------------------------------------
reg [31:0] rdata_r;

always @(posedge clk) begin
	if(mem_valid && (~mem_ready) && (mem_wstrb == 4'h0))
		rdata_r <= mem_r[mem_addr[DEPTH:2]];
end

assign mem_rdata = rdata_r;

//-----------------------------------------------------------------------------
always @(posedge clk) begin
	if(mem_valid && (~mem_ready) && (mem_wstrb & 4'h1))
		mem_r[mem_addr[DEPTH:2]][7:0]   <= mem_wdata[7:0];

	if(mem_valid && (~mem_ready) && (mem_wstrb & 4'h2))
		mem_r[mem_addr[DEPTH:2]][15:8]  <= mem_wdata[15:8];

	if(mem_valid && (~mem_ready) && (mem_wstrb & 4'h4))
		mem_r[mem_addr[DEPTH:2]][23:16] <= mem_wdata[23:16];

	if(mem_valid && (~mem_ready) && (mem_wstrb & 4'h8))
		mem_r[mem_addr[DEPTH:2]][31:24] <= mem_wdata[31:24];
end

endmodule
