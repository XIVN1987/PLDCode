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

	inout         i2c_scl,
	inout         i2c_sda
);


endmodule
