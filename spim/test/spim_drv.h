#ifndef __SPIM_DRV_H__
#define __SPIM_DRV_H__


typedef struct {
	volatile uint32_t CR;
	
	volatile uint32_t SR;

	volatile uint32_t AR;

	volatile uint32_t ABR;		// Alternate Bytes Register
	
	volatile uint32_t DLR;		// Data Length Register

	volatile uint32_t CCR;		// Communication Configuration Register
	
	union {
		volatile uint32_t DRW;
		
		volatile uint16_t DRH;
		
		volatile uint8_t  DRB;
	};
} SPIM_TypeDef;


#define SPIM_CR_ENA_Pos				0
#define SPIM_CR_ENA_Msk				(0x01 << SPIM_CR_ENA_Pos)
#define SPIM_CR_CPHA_Pos			1		// Clock Phase, 0 sample on first edge, 1 sample on second edge
#define SPIM_CR_CPHA_Msk			(0x01 << SPIM_CR_CPHA_Pos)
#define SPIM_CR_CPOL_Pos			2		// Clock Polarity, 0 low level when idle, 1 high level when idle
#define SPIM_CR_CPOL_Msk			(0x01 << SPIM_CR_CPOL_Pos)
#define SPIM_CR_BIDI_Pos			3		// Single line bidirectional mode: 0 IO0 as output, IO1 as input; 1 IO0 as input and output
#define SPIM_CR_BIDI_Msk			(0x01 << SPIM_CR_BIDI_Pos)
#define SPIM_CR_CKDIV_Pos			8		// fSPIM_CK = fSYSCLK / (CKDIV + 1)
#define SPIM_CR_CKDIV_Msk			(0xFF << SPIM_CR_CKDIV_Pos)
#define SPIM_CR_CSHMIN_Pos			16		// nCS stay high for at least (CSHMIN + 1) cycles between commands
#define SPIM_CR_CSHMIN_Msk			(0x07 << SPIM_CR_CSHMIN_Pos)

#define SPIM_SR_ERR_Pos				0
#define SPIM_SR_ERR_Msk				(0x01 << SPIM_SR_ERR_Pos)
#define SPIM_SR_BUSY_Pos			1
#define SPIM_SR_BUSY_Msk			(0x01 << SPIM_SR_BUSY_Pos)
#define SPIM_SR_FFLVL_Pos			8		// FIFO Level
#define SPIM_SR_FFLVL_Msk			(0x3F << SPIM_SR_FFLVL_Pos)

#define SPIM_CCR_ICODE_Pos			0		// Insruction Code
#define SPIM_CCR_ICODE_Msk			(0xFF << SPIM_CCR_ICODE_Pos)
#define SPIM_CCR_IMODE_Pos			8		// 0 No instruction, 1 Instruction on D0, 2 on D0-1, 3 on D0-3
#define SPIM_CCR_IMODE_Msk			(0x03 << SPIM_CCR_IMODE_Pos)
#define SPIM_CCR_AMODE_Pos			10		// 0 No address, 1 Address on D0, 2 on D0-1, 3 on D0-3
#define SPIM_CCR_AMODE_Msk			(0x03 << SPIM_CCR_AMODE_Pos)
#define SPIM_CCR_ASIZE_Pos			12		// Address size, 0 8-bit, 1 16-bit, 2 24-bit, 3 32-bit
#define SPIM_CCR_ASIZE_Msk			(0x03 << SPIM_CCR_ASIZE_Pos)
#define SPIM_CCR_ABMODE_Pos			14		// 0 No alternate bytes, 1 Alternate bytes on D0, 2 on D0-1, 3 on D0-3
#define SPIM_CCR_ABMODE_Msk			(0x03 << SPIM_CCR_ABMODE_Pos)
#define SPIM_CCR_ABSIZE_Pos			16		// Alternate bytes size, 0 8-bit, 1 16-bit, 2 24-bit, 3 32-bit
#define SPIM_CCR_ABSIZE_Msk			(0x03 << SPIM_CCR_ABSIZE_Pos)
#define SPIM_CCR_DUMMY_Pos			18		// Number of dummy cycles
#define SPIM_CCR_DUMMY_Msk			(0x1F << SPIM_CCR_DUMMY_Pos)
#define SPIM_CCR_DMODE_Pos			24		// 0 No Data, 1 Data on D0, 2 on D0-1, 3 on D0-3
#define SPIM_CCR_DMODE_Msk			(0x03 << SPIM_CCR_DMODE_Pos)
#define SPIM_CCR_MODE_Pos			26		// 0 Indirect write mode, 1 Indirect read mode, 3 Memory-mapped mode
#define SPIM_CCR_MODE_Msk			(0x03 << SPIM_CCR_MODE_Pos)


#define SPIM	((SPIM_TypeDef *)((5 << 28) + 0x010000))



typedef struct {
	uint8_t  Instruction;
	uint8_t  InstructionMode;		// SPIM_PhaseMode_None, SPIM_PhaseMode_1bit, SPIM_PhaseMode_2bit, SPIM_PhaseMode_4bit
	uint32_t Address;
	uint8_t  AddressMode;			// SPIM_PhaseMode_None, SPIM_PhaseMode_1bit, SPIM_PhaseMode_2bit, SPIM_PhaseMode_4bit
	uint8_t  AddressSize;			// SPIM_PhaseSize_8bit, SPIM_PhaseSize_16bit, SPIM_PhaseSize_24bit, SPIM_PhaseSize_32bit
	uint32_t AlternateBytes;
	uint8_t  AlternateBytesMode;	// SPIM_PhaseMode_None, SPIM_PhaseMode_1bit, SPIM_PhaseMode_2bit, SPIM_PhaseMode_4bit
	uint8_t  AlternateBytesSize;	// SPIM_PhaseSize_8bit, SPIM_PhaseSize_16bit, SPIM_PhaseSize_24bit, SPIM_PhaseSize_32bit
	uint8_t  DummyCycles;			// 0--31
	uint8_t  DataMode;				// SPIM_PhaseMode_None, SPIM_PhaseMode_1bit, SPIM_PhaseMode_2bit, SPIM_PhaseMode_4bit
	uint32_t DataCount;				// number of Bytes to read/write
} SPIM_CmdStructure;

#define SPIM_PhaseMode_None		0	// there is no this phase
#define SPIM_PhaseMode_1bit		1	// 1-line transfer
#define SPIM_PhaseMode_2bit		2	// 2-line transfer
#define SPIM_PhaseMode_4bit		3	// 4-line transfer

#define SPIM_PhaseSize_8bit		0
#define SPIM_PhaseSize_16bit	1
#define SPIM_PhaseSize_24bit	2
#define SPIM_PhaseSize_32bit	3

#define SPIM_IndirectWrite		0
#define SPIM_IndirectRead		1
#define SPIM_MemoryMapped		3

#define SPIM_CPHA0_CPOL0		0
#define SPIM_CPHA1_CPOL0		1
#define SPIM_CPHA0_CPOL1		2
#define SPIM_CPHA1_CPOL1		3



void SPIM_Init(SPIM_TypeDef * SPIMx, uint8_t clkmode, uint8_t clkdiv);

void SPIM_Command(SPIM_TypeDef * SPIMx, uint8_t cmdMode, SPIM_CmdStructure * cmdStruct);
void SPIM_CmdStructInit(SPIM_CmdStructure * cmdStruct);


static inline uint32_t SPIM_Busy(SPIM_TypeDef * SPIMx)
{
	return SPIMx->SR & SPIM_SR_BUSY_Msk;
}

static inline uint32_t SPIM_FIFOCount(SPIM_TypeDef * SPIMx)
{
	return (SPIMx->SR & SPIM_SR_FFLVL_Msk) >> SPIM_SR_FFLVL_Pos;
}

static inline uint32_t SPIM_FIFOSpace(SPIM_TypeDef * SPIMx)
{
	return 32 - SPIM_FIFOCount(SPIMx);
}

static inline uint32_t SPIM_FIFOEmpty(SPIM_TypeDef * SPIMx)
{
	return SPIM_FIFOCount(SPIMx) == 0;
}

#endif
