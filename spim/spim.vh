localparam PhaseMode_None	= 0;	// there is no this phase
localparam PhaseMode_1bit	= 1;	// 1-line transfer on D0
localparam PhaseMode_2bit	= 2;	// 2-line transfer on D0, and D1
localparam PhaseMode_4bit	= 3;	// 4-line transfer on D0, D1, D2, and D3

localparam PhaseSize_8bit	= 0;
localparam PhaseSize_16bit	= 1;
localparam PhaseSize_24bit	= 2;
localparam PhaseSize_32bit	= 3;

localparam Oper_None  = 0;
localparam Oper_Read  = 1;
localparam Oper_Write = 2;
localparam Oper_Dummy = 3;
