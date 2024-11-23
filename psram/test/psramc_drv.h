#ifndef __PSRAMC_DRV_H__
#define __PSRAMC_DRV_H__

#include <stdbool.h>

typedef struct {
	volatile uint32_t CR;
	
	volatile uint32_t SR;

	volatile uint32_t TR;

	/* HyperRAM registers defined in Register Space */
	volatile uint32_t ID0;

	volatile uint32_t ID1;

	volatile uint32_t CR0;

	volatile uint32_t CR1;
} PSRAMC_TypeDef;


#define PSRAMC_CR_ENA_Pos				0		// write 1 to read back HyperRAM registers defined in Register Space
												// 0-to-1 perform a HyperRAM hardware reset, and then read back HyperRAM registers
#define PSRAMC_CR_ENA_Msk				(0x01 << PSRAMC_CR_ENA_Pos)
#define PSRAMC_CR_CKDIV_Pos				4		// fPSRAM_CK = fSYS_CK / (CKDIV + 1)
#define PSRAMC_CR_CKDIV_Msk				(0x0F << PSRAMC_CR_CKDIV_Pos)

#define PSRAMC_SR_READY_Pos				0		// clear when hardware reset, set when HyperRAM registers read back without error
#define PSRAMC_SR_READY_Msk				(0x01 << PSRAMC_SR_READY_Pos)
#define PSRAMC_SR_ERROR_Pos				1		// clear when hardware reset, set when HyperRAM read time-out
#define PSRAMC_SR_ERROR_Msk				(0x01 << PSRAMC_SR_ERROR_Pos)

#define PSRAMC_TR_TSYS_Pos				0		// tSYS, system clock period in ns
#define PSRAMC_TR_TSYS_Msk				(0xFF << PSRAMC_TR_TSYS_Pos)
#define PSRAMC_TR_TRP_Pos				8		// tRP, RESET# Pulse Width in us
#define PSRAMC_TR_TRP_Msk				(0x0F << PSRAMC_TR_TRP_Pos)
#define PSRAMC_TR_TRH_Pos				12		// tRH, Time between RESET# (High) and CS# (Low) in us
#define PSRAMC_TR_TRH_Msk				(0x0F << PSRAMC_TR_TRH_Pos)
#define PSRAMC_TR_TRWR_Pos				16		// tRWR, Read-Write Recovery Time in ns
#define PSRAMC_TR_TRWR_Msk				(0xFF << PSRAMC_TR_TRWR_Pos)
#define PSRAMC_TR_TCSM_Pos				24		// tCSM, Chip Select Maximum Low Time in us
#define PSRAMC_TR_TCSM_Msk				(0x0F << PSRAMC_TR_TCSM_Pos)

#define PSRAMC_CR0_BurstLength_Pos		0
#define PSRAMC_CR0_BurstLength_Msk		(0x03 << PSRAMC_CR0_BurstLength_Pos)
#define PSRAMC_CR0_HybridBurst_Pos		2
#define PSRAMC_CR0_HybridBurst_Msk		(0x01 << PSRAMC_CR0_HybridBurst_Pos)
#define PSRAMC_CR0_FixedLatency_Pos		3
#define PSRAMC_CR0_FixedLatency_Msk		(0x01 << PSRAMC_CR0_FixedLatency_Pos)
#define PSRAMC_CR0_InitialLatency_Pos	4
#define PSRAMC_CR0_InitialLatency_Msk	(0x0F << PSRAMC_CR0_InitialLatency_Pos)

#define PSRAMC_CR1_ClockType_Pos		6		// 0 Differential, 1 Single Ended
#define PSRAMC_CR1_ClockType_Msk		(0x01 << PSRAMC_CR1_ClockType_Pos)


#define PSRAMC	((PSRAMC_TypeDef *)((3 << 28) + (1 << 27)))



#define PSRAMC_BurstLength_128B			0
#define PSRAMC_BurstLength_64B			1
#define PSRAMC_BurstLength_16B			2
#define PSRAMC_BurstLength_32B			3

#define PSRAMC_InitialLatency_5			0
#define PSRAMC_InitialLatency_6			1
#define PSRAMC_InitialLatency_7			2
#define PSRAMC_InitialLatency_3		   14
#define PSRAMC_InitialLatency_4		   15


#define PSRAMC_RES_OK	0
#define PSRAMC_RES_ERR	1


uint32_t PSRAMC_Init(uint8_t clkdiv, uint8_t tRWR, uint8_t tACC);
uint32_t PSRAMC_ReadHyperRAMRegs(void);

void PSRAMC_SetBurstLength(uint8_t v);
void PSRAMC_SetInitialLatency(uint8_t v, bool fixed_latency);

#endif
