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

picorv32 #(
	.ENABLE_MUL(1),
	.ENABLE_DIV(1),
	.COMPRESSED_ISA(1),
	.STACKADDR(MEM_SIZE)
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

	.irq(32'b0)
);

//----------------------------------------------------------------------------
wire sel_ram, sel_psram;
wire		mem_ready_ram;
wire [31:0] mem_rdata_ram;
wire		mem_ready_psram;
wire [31:0] mem_rdata_psram;

assign sel_ram   = ((mem_addr >> 28) == 0) || ((mem_addr >> 28) == 8) || ((mem_addr >> 28) == 9);
assign sel_psram = ((mem_addr >> 28) == 3);
assign mem_ready = sel_ram ? mem_ready_ram : mem_ready_psram;
assign mem_rdata = sel_ram ? mem_rdata_ram : mem_rdata_psram;

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
wire 		psram_rst;
wire 		psram_cs;
wire 		psram_ck;
wire		psram_ckn;
wire 		psram_rwds;
wire [ 7:0] psram_di;
wire [ 7:0] psram_do;
wire 		psram_doen;
wire [ 7:0] psram_dq;

psramc u_psramc (
	.clk(clk),
	.rst_n(rst_n),

	.mem_valid(mem_valid & sel_psram),
	.mem_ready(mem_ready_psram),
	.mem_addr (mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata_psram),

	.psram_rst (psram_rst),
	.psram_cs  (psram_cs),
	.psram_ck  (psram_ck),
	.psram_ckn (psram_ckn),
	.psram_rwds(psram_rwds),
	.psram_di  (psram_di),
	.psram_do  (psram_do),
	.psram_doen(psram_doen)
);

s27kl0642 u_psram (
	.RESETNeg(psram_rst),
	.CSNeg   (psram_cs),
	.CK      (psram_ck),
	.CKn     (psram_ckn),
	.RWDS    (psram_rwds),
	.DQ7     (psram_dq[7]),
	.DQ6     (psram_dq[6]),
	.DQ5     (psram_dq[5]),
	.DQ4     (psram_dq[4]),
	.DQ3     (psram_dq[3]),
	.DQ2     (psram_dq[2]),
	.DQ1     (psram_dq[1]),
	.DQ0     (psram_dq[0])
);

assign psram_di = psram_dq;
assign psram_dq = psram_doen ? psram_do : 8'bzzzzzzzz;


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

	#50000000;

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
