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


i2cm_reg u_reg (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr[11:0]),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata)
);


endmodule
