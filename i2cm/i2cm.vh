
// bit-field for register CMD
localparam CMD_START_Pos = 0;
localparam CMD_START_Msk = (1 << CMD_START_Pos);
localparam CMD_WRITE_Pos = 1;
localparam CMD_WRITE_Msk = (1 << CMD_WRITE_Pos);
localparam CMD_READ_Pos  = 2;
localparam CMD_READ_Msk  = (1 << CMD_READ_Pos);
localparam CMD_TXACK_Pos = 3;
localparam CMD_TXACK_Msk = (1 << CMD_TXACK_Pos);
localparam CMD_STOP_Pos  = 4;
localparam CMD_STOP_Msk  = (1 << CMD_STOP_Pos);

localparam CMD_START	 = CMD_START_Msk;
localparam CMD_WRITE	 = CMD_WRITE_Msk;
localparam CMD_READ		 = CMD_READ_Msk;
localparam CMD_STOP		 = CMD_STOP_Msk;
