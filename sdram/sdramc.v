//-----------------------------------------------------------------
//                      Simple SDRAM Controller
//                              V0.1
//                        Ultra-Embedded.com
//                          Copyright 2015
//
//                 Email: admin@ultra-embedded.com
//
//                         License: GPL
// If you would like a version with a more permissive license for
// use in closed source commercial applications please contact me
// for details.
//-----------------------------------------------------------------
//
// This file is open source HDL; you can redistribute it and/or 
// modify it under the terms of the GNU General Public License as 
// published by the Free Software Foundation; either version 2 of 
// the License, or (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public 
// License along with this file; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//-----------------------------------------------------------------

`timescale 1ns / 1ps

module sdramc #(
	parameter    SDRAM_MHZ          = 20,
	parameter    SDRAM_ROW_W        = 13,
	parameter    SDRAM_COL_W        = 9,
	parameter    SDRAM_BANK_W       = 2,
	parameter    SDRAM_REFRESH_CNT  = 2 ** SDRAM_ROW_W,
	parameter    SDRAM_START_DELAY  = 100000 / (1000 / SDRAM_MHZ), // 100uS
	parameter    SDRAM_READ_LATENCY = 2
) (
	input         clk,
	input         rst_n,

	input         mem_valid,
	output        mem_ready,
	input  [31:0] mem_addr,
	input  [31:0] mem_wdata,
	input  [ 3:0] mem_wstrb,
	output [31:0] mem_rdata,
	
	// SDRAM Interface
	output        sdram_clk,
	output        sdram_cke,
	output        sdram_cs,
	output        sdram_ras,
	output        sdram_cas,
	output        sdram_we,
	output [12:0] sdram_addr,
	output [ 1:0] sdram_ba,
	inout  [15:0] sdram_data,
	output [ 1:0] sdram_dqm
);

//-----------------------------------------------------------------
// Defines / Local params
//-----------------------------------------------------------------
localparam SDRAM_DATA_W      = 16;
localparam SDRAM_DQM_W       = SDRAM_DATA_W / 8;
localparam SDRAM_BANKS       = 2 ** SDRAM_BANK_W;
localparam SDRAM_REFRESH_CYCLES = (64000*SDRAM_MHZ) / SDRAM_REFRESH_CNT-1;

// Command
localparam CMD_W             = 4;
localparam CMD_NOP           = 4'b0111;
localparam CMD_ACTIVE        = 4'b0011;
localparam CMD_READ          = 4'b0101;
localparam CMD_WRITE         = 4'b0100;
localparam CMD_TERMINATE     = 4'b0110;
localparam CMD_PRECHARGE     = 4'b0010;
localparam CMD_REFRESH       = 4'b0001;
localparam CMD_LOAD_MODE     = 4'b0000;

// Mode: Burst Length = 2 words, CAS=2
localparam MODE_REG          = {3'b000,1'b0,2'b00,3'b010,1'b0,3'b001};

// SM states
localparam STATE_W           = 4;
localparam STATE_INIT        = 4'd0;
localparam STATE_DELAY       = 4'd1;
localparam STATE_IDLE        = 4'd2;
localparam STATE_ACTIVATE    = 4'd3;
localparam STATE_READ0       = 4'd4;
localparam STATE_READ1       = 4'd5;
localparam STATE_WRITE0      = 4'd6;
localparam STATE_WRITE1      = 4'd7;
localparam STATE_PRECHARGE   = 4'd8;
localparam STATE_REFRESH     = 4'd9;

localparam AUTO_PRECHARGE    = 10;	// A10
localparam ALL_BANKS         = 10;

localparam CYCLE_TIME_NS     = 1000 / SDRAM_MHZ;

// SDRAM timing
localparam SDRAM_TRCD_CYCLES = (20 + (CYCLE_TIME_NS-1)) / CYCLE_TIME_NS;
localparam SDRAM_TRP_CYCLES  = (20 + (CYCLE_TIME_NS-1)) / CYCLE_TIME_NS;
localparam SDRAM_TRFC_CYCLES = (60 + (CYCLE_TIME_NS-1)) / CYCLE_TIME_NS;	// refresh cycle


//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
reg                    cke_r;
reg [CMD_W-1:0]        cmd_r;
reg [SDRAM_ROW_W-1 :0] addr_r;
reg [SDRAM_BANK_W-1:0] bank_r;
reg [SDRAM_DATA_W-1:0] data_r;
reg [SDRAM_DQM_W-1 :0] dmsk_r;

reg                    io_read_en;

// Buffer half word during read and write commands
reg [SDRAM_DATA_W-1:0] data_buf_r;
reg [SDRAM_DQM_W-1 :0] dmsk_buf_r;

reg [SDRAM_BANKS-1 :0] row_open_r;		// 每个bank一位：激活命令时置位，充电刷新时清零
reg [SDRAM_ROW_W-1 :0] row_used_r[0:SDRAM_BANKS-1];	// 每个bank中正在使用的行

reg [STATE_W-1:0]      state_r;
reg [STATE_W-1:0]      next_state_r;
reg [STATE_W-1:0]      delay_state_r;	// 延时时将 next_state_r 存入 delay_state_r
reg [STATE_W-1:0]      target_state_r;
reg [STATE_W-1:0]      target_state_q;

// Address bits
wire [SDRAM_ROW_W-1 :0] addr_col_w  = {{(SDRAM_ROW_W-SDRAM_COL_W){1'b0}}, mem_addr[SDRAM_COL_W:1]};
wire [SDRAM_BANK_W-1:0] addr_bank_w = mem_addr[SDRAM_COL_W+SDRAM_BANK_W:SDRAM_COL_W+1];
wire [SDRAM_ROW_W-1 :0] addr_row_w  = mem_addr[SDRAM_COL_W+SDRAM_BANK_W+SDRAM_ROW_W:SDRAM_COL_W+SDRAM_BANK_W+1];


//-----------------------------------------------------------------
// SDRAM State Machine
//-----------------------------------------------------------------
always @(*) begin
	next_state_r   = state_r;
	target_state_r = target_state_q;

	case(state_r)
	STATE_INIT: begin
		if(refresh_req)
			next_state_r = STATE_IDLE;
	end
	
	STATE_IDLE: begin
		// Pending refresh
		// Note: tRAS (open row time) cannot be exceeded due to periodic auto refreshes.
		if(refresh_req) begin
			// Close open rows, then refresh
			if (|row_open_r)
				next_state_r = STATE_PRECHARGE;
			else
				next_state_r = STATE_REFRESH;

			target_state_r = STATE_REFRESH;
		end
		// Access request
		else if(mem_valid && (~mem_ready)) begin
			// Open row hit
			if(row_open_r[addr_bank_w] && addr_row_w == row_used_r[addr_bank_w]) begin
				if(mem_wstrb != 4'b0000)
					next_state_r = STATE_WRITE0;
				else
					next_state_r = STATE_READ0;
			end
			// Row miss, close row, open new row
			else if(row_open_r[addr_bank_w]) begin
				next_state_r = STATE_PRECHARGE;

				if(mem_wstrb != 4'b0000)
					target_state_r = STATE_WRITE0;
				else
					target_state_r = STATE_READ0;
			end
			// No open row, open row
			else begin
				next_state_r = STATE_ACTIVATE;

				if(mem_wstrb != 4'b0000)
					target_state_r = STATE_WRITE0;
				else
					target_state_r = STATE_READ0;
			end
		end
	end
	
	STATE_ACTIVATE: begin
		// Proceed to read or write state
		next_state_r = target_state_r;
	end
	
	STATE_READ0: begin
		next_state_r = STATE_READ1;
	end
	
	STATE_READ1: begin
		next_state_r = STATE_IDLE;
	end
	
	STATE_WRITE0: begin
		next_state_r = STATE_WRITE1;
	end
	
	STATE_WRITE1: begin
		next_state_r = STATE_IDLE;
	end
	
	STATE_PRECHARGE: begin
		// Closing row to perform refresh
		if(target_state_r == STATE_REFRESH)
			next_state_r = STATE_REFRESH;
		// Must be closing row to open another
		else
			next_state_r = STATE_ACTIVATE;
	end
	
	STATE_REFRESH: begin
		next_state_r = STATE_IDLE;
	end
	
	STATE_DELAY: begin
		next_state_r = delay_state_r;
	end

	default:
		;
   endcase
end

// Update actual state
always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		state_r <= STATE_INIT;
	else if(delay_r != {DELAY_W{1'b0}})	// Delaying...
		state_r <= STATE_DELAY;
	else
		state_r <= next_state_r;
end

// Record delayed state
always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		delay_state_r <= STATE_IDLE;
	// On entering into delay state, record intended next state
	else if(delay_r != {DELAY_W{1'b0}} && state_r != STATE_DELAY)
		delay_state_r <= next_state_r;
end

// Record target state
always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		target_state_q <= STATE_IDLE;
	else
		target_state_q <= target_state_r;
end


//-----------------------------------------------------------------
// Delays
//-----------------------------------------------------------------
localparam DELAY_W = 4;

reg [DELAY_W-1:0] delay_r;
reg [DELAY_W-1:0] delay_q;

always @(*) begin
	case(state_r)
	STATE_ACTIVATE: begin
		// tRCD (ACTIVATE -> READ / WRITE)
		delay_r = SDRAM_TRCD_CYCLES;        
	end
	
	STATE_READ1: begin
		delay_r = SDRAM_READ_LATENCY;
	end    
	
	STATE_PRECHARGE: begin
		// tRP (PRECHARGE -> ACTIVATE)
		delay_r = SDRAM_TRP_CYCLES;
	end
	
	STATE_REFRESH: begin
		// tRFC
		delay_r = SDRAM_TRFC_CYCLES;
	end
	
	STATE_DELAY: begin
		delay_r = delay_q - 4'd1;  
	end
	
	default: begin
		delay_r = {DELAY_W{1'b0}};
	end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		delay_q <= {DELAY_W{1'b0}};
	else
		delay_q <= delay_r;
end


//-----------------------------------------------------------------
// Refresh counter
//-----------------------------------------------------------------
localparam REFRESH_CNT_W = 17;

reg                     refresh_req;
reg [REFRESH_CNT_W-1:0] refresh_timer;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		refresh_timer <= SDRAM_START_DELAY;
	else if(refresh_timer == {REFRESH_CNT_W{1'b0}})
		refresh_timer <= SDRAM_REFRESH_CYCLES;
	else
		refresh_timer <= refresh_timer - 1;
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		refresh_req <= 1'b0;
	else if(refresh_timer == {REFRESH_CNT_W{1'b0}})
		refresh_req <= 1'b1;
	else if(state_r == STATE_REFRESH)
		refresh_req <= 1'b0;
end


//-----------------------------------------------------------------
// Command Output
//-----------------------------------------------------------------
integer i;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		cke_r      <= 1'b0;
		cmd_r      <= CMD_NOP;
		addr_r     <= {SDRAM_ROW_W{1'b0}};
		bank_r     <= {SDRAM_BANK_W{1'b0}};
		data_r     <= 16'b0;
		dmsk_r     <= {SDRAM_DQM_W{1'b0}};
		io_read_en <= 1'b1;

		dmsk_buf_r <= {SDRAM_DQM_W{1'b0}};

		row_open_r <= {SDRAM_BANKS{1'b0}};

		for(i = 0; i < SDRAM_BANKS; i = i+1)
			row_used_r[i] <= {SDRAM_ROW_W{1'b0}};
	end
	else begin
		case(state_r)
		//-----------------------------------------
		// STATE_IDLE / Default (delays)
		//-----------------------------------------
		default: begin
			cmd_r      <= CMD_NOP;
			addr_r     <= {SDRAM_ROW_W{1'b0}};
			bank_r     <= {SDRAM_BANK_W{1'b0}};
			io_read_en <= 1'b1;
		end
		
		STATE_INIT: begin
			if(refresh_timer == 50) begin
				// Assert CKE after 100uS
				cke_r  <= 1'b1;
			end
			else if(refresh_timer == 40) begin
				// Precharge all banks
				cmd_r  <= CMD_PRECHARGE;
				addr_r[ALL_BANKS] <= 1'b1;
			end
			else if(refresh_timer == 20 || refresh_timer == 30) begin
				// 2 x REFRESH (with at least tREF wait)
				cmd_r  <= CMD_REFRESH;
			end
			else if(refresh_timer == 10) begin
				// Load mode register
				cmd_r  <= CMD_LOAD_MODE;
				addr_r <= MODE_REG;
			end
			else begin
				cmd_r  <= CMD_NOP;
				addr_r <= {SDRAM_ROW_W{1'b0}};
				bank_r <= {SDRAM_BANK_W{1'b0}};
			end
		end
		
		STATE_ACTIVATE: begin
			// Select a row and activate it
			cmd_r  <= CMD_ACTIVE;
			addr_r <= addr_row_w;
			bank_r <= addr_bank_w;

			row_open_r[addr_bank_w] <= 1'b1;
			row_used_r[addr_bank_w] <= addr_row_w;
		end
		
		STATE_READ0: begin
			cmd_r  <= CMD_READ;
			addr_r <= addr_col_w;
			bank_r <= addr_bank_w;
			// Read mask (all bytes in burst)
			dmsk_r <= {SDRAM_DQM_W{1'b0}};

			// Disable auto precharge (auto close of row)
			addr_r[AUTO_PRECHARGE] <= 1'b0;
		end
		
		STATE_WRITE0: begin
			cmd_r  <= CMD_WRITE;
			addr_r <= addr_col_w;
			bank_r <= addr_bank_w;
			data_r <= mem_wdata[15:0];
			dmsk_r <= ~mem_wstrb[1:0];

			dmsk_buf_r <= ~mem_wstrb[3:2];

			io_read_en <= 1'b0;

			// Disable auto precharge (auto close of row)
			addr_r[AUTO_PRECHARGE] <= 1'b0;
		end
		
		STATE_WRITE1: begin
			// Burst continuation
			cmd_r  <= CMD_NOP;
			data_r <= data_buf_r;
			dmsk_r <= dmsk_buf_r;

			// Disable auto precharge (auto close of row)
			addr_r[AUTO_PRECHARGE] <= 1'b0;			
		end

		STATE_PRECHARGE: begin
			if(target_state_r == STATE_REFRESH) begin
				// Precharge due to refresh, close all banks
				cmd_r             <= CMD_PRECHARGE;
				addr_r[ALL_BANKS] <= 1'b1;

				row_open_r <= {SDRAM_BANKS{1'b0}};
			end
			else begin
				// Precharge specific banks
				cmd_r             <= CMD_PRECHARGE;
				addr_r[ALL_BANKS] <= 1'b0;
				bank_r            <= addr_bank_w;

				row_open_r[addr_bank_w] <= 1'b0;
			end
		end
		
		STATE_REFRESH: begin
			// Auto refresh
			cmd_r  <= CMD_REFRESH;
			addr_r <= {SDRAM_ROW_W{1'b0}};
			bank_r <= {SDRAM_BANK_W{1'b0}};        
		end
		endcase
	end
end


//-----------------------------------------------------------------
// Read step
//-----------------------------------------------------------------
reg [SDRAM_READ_LATENCY+1:0] read_step_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		read_step_r <= {(SDRAM_READ_LATENCY+2){1'b0}};
	else
		read_step_r <= {read_step_r[SDRAM_READ_LATENCY:0], (state_r == STATE_READ0)};
end


//-----------------------------------------------------------------
// Input sampling
//-----------------------------------------------------------------
reg [SDRAM_DATA_W-1:0] data_smp_r;

always @(posedge clk or negedge rst_n)
if(~rst_n)
	data_smp_r <= {SDRAM_DATA_W{1'b0}};
else
	data_smp_r <= sdram_data;

//-----------------------------------------------------------------
// Data Buffer
//-----------------------------------------------------------------
always @(posedge clk or negedge rst_n)
if(~rst_n)
	data_buf_r <= 16'b0;
else if(state_r == STATE_WRITE0)
	data_buf_r <= mem_wdata[31:16];			// buffer upper 16-bits of write data
else if(read_step_r[SDRAM_READ_LATENCY-1])
	data_buf_r <= sdram_data;			// buffer lower 16-bits of read  data

assign mem_rdata = {data_smp_r, data_buf_r};


//-----------------------------------------------------------------
// ACK
//-----------------------------------------------------------------
reg ready_r;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		ready_r <= 1'b0;
	else begin
		if(state_r == STATE_WRITE0)
			ready_r <= 1'b1;
		else if(read_step_r[SDRAM_READ_LATENCY])
			ready_r <= 1'b1;
		else
			ready_r <= 1'b0;
	end
end

assign mem_ready = ready_r;


//-----------------------------------------------------------------
// SDRAM I/O
//-----------------------------------------------------------------
assign sdram_clk   = ~clk;
assign sdram_cke   = cke_r;
assign sdram_cs    = cmd_r[3];
assign sdram_ras   = cmd_r[2];
assign sdram_cas   = cmd_r[1];
assign sdram_we    = cmd_r[0];
assign sdram_addr  = addr_r;
assign sdram_ba    = bank_r;
assign sdram_data  = io_read_en ? 16'bz : data_r;
assign sdram_dqm   = dmsk_r;


//-----------------------------------------------------------------
// Debug
//-----------------------------------------------------------------
reg [63:0] cmd_name;

always @(*) begin
 	if(cmd_r == CMD_NOP)       cmd_name = "NOP";
 	if(cmd_r == CMD_ACTIVE)    cmd_name = "ACTIVE";
 	if(cmd_r == CMD_READ)      cmd_name = "READ";
 	if(cmd_r == CMD_WRITE)     cmd_name = "WRITE";
 	if(cmd_r == CMD_TERMINATE) cmd_name = "TERMINAT";
 	if(cmd_r == CMD_PRECHARGE) cmd_name = "PRECHARG";
 	if(cmd_r == CMD_REFRESH)   cmd_name = "REFRESH";
 	if(cmd_r == CMD_LOAD_MODE) cmd_name = "LOADMODE";
 end 

reg [63:0] state_name;

always @(*) begin
	if(state_r == STATE_INIT)      state_name = "INIT";
	if(state_r == STATE_DELAY)     state_name = "DELAY";
	if(state_r == STATE_IDLE)      state_name = "IDLE";
	if(state_r == STATE_ACTIVATE)  state_name = "ACTIVATE";
	if(state_r == STATE_READ0)     state_name = "READ0";
	if(state_r == STATE_READ1)     state_name = "READ1";
	if(state_r == STATE_WRITE0)    state_name = "WRITE0";
	if(state_r == STATE_WRITE1)    state_name = "WRITE1";
	if(state_r == STATE_PRECHARGE) state_name = "PRECHARG";
	if(state_r == STATE_REFRESH)   state_name = "REFRESH";
end

endmodule
