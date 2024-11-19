`timescale 1ns / 1ps

module riscv_tb;

parameter MEM_SIZE = 16'h4000;

reg clk;
reg rst_n;

wire        mem_valid;
wire        mem_ready;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire [31:0] mem_rdata;

wire 		uart_int;

picorv32 #(
	.ENABLE_MUL(1),
	.ENABLE_DIV(1),
	.COMPRESSED_ISA(1),
	.STACKADDR(MEM_SIZE),
	.ENABLE_IRQ(1),
	.PROGADDR_IRQ(32'h100)
) u_core (
	.clk(clk),
	.resetn(rst_n),

	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.pcpi_wr(1'b0),
	.pcpi_rd(32'b0),
	.pcpi_wait(1'b0),
	.pcpi_ready(1'b0),

	.irq({27'b0, uart_int, 4'b0})
);

//----------------------------------------------------------------------------
wire sel_ram, sel_uart;
wire		mem_ready_ram;
wire [31:0] mem_rdata_ram;
wire		mem_ready_uart;
wire [31:0] mem_rdata_uart;

assign sel_ram   = ((mem_addr >> 28) == 0) || ((mem_addr >> 28) == 8) || ((mem_addr >> 28) == 9);
assign sel_uart  = ((mem_addr >> 28) == 5);
assign mem_ready = sel_ram ? mem_ready_ram : mem_ready_uart;
assign mem_rdata = sel_ram ? mem_rdata_ram : mem_rdata_uart;

memory #(
	.SIZE(MEM_SIZE),
	.FIRMWARE("test/test.mem")
) u_memory (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_ram),
	.mem_ready(mem_ready_ram),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_ram)
);

//----------------------------------------------------------------------------
wire 		uart_txd;
wire 		uart_rxd;

uart u_uart (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_uart),
	.mem_ready(mem_ready_uart),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_uart),

	.int_req (uart_int),
	
	.uart_txd(uart_txd),
	.uart_rxd(uart_rxd)
);

assign uart_rxd = uart_txd;		// loopback TX/RX test


//----------------------------------------------------------------------------
always #10 clk = !clk;

initial begin
	$dumpfile(`VCD_FILE);
	$dumpvars(0, riscv_tb);

	clk = 1;
	rst_n = 0;
	@(posedge clk);
	#20;
	rst_n = 1;

	#100000000;

	$write("\n--- done ---\n");
	$finish;
end

//----------------------------------------------------------------------------
always @(posedge clk) begin
	if ((mem_addr == 32'h80000000) && (mem_wstrb != 0)) begin
		$write("\n--- done ---\n");
		$finish;
	end

	if ((mem_addr == 32'h90000000) && (mem_wstrb != 0) && mem_ready) begin
		$write("%c", mem_wdata);
	end
end

endmodule
