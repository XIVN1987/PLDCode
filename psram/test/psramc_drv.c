/*******************************************************************************************************************************
* @brief	PSRAM (HyperRAM) Controller driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "psramc_drv.h"


/*******************************************************************************************************************************
* @brief	PSRAM (HyperRAM) Controller init, and then perform a HyperRAM hardware reset
* @param	clkdiv: fPSRAM_CK = fSYS_CK / clkdiv
* @param	tRWR: Read-Write Recovery Time in ns
* @param	tACC: Read/Write Initial Access Time in ns
* @return	PSRAMC_RES_OK or PSRAMC_RES_ERR
*******************************************************************************************************************************/
uint32_t PSRAMC_Init(uint8_t clkdiv, uint8_t tRWR, uint8_t tACC)
{
	uint16_t period = 1000000000 / SYS_FREQ;

	PSRAMC->TR = ((clkdiv - 1)	<< PSRAMC_TR_CKDIV_Pos) |
				 (period		<< PSRAMC_TR_CKiNS_Pos) |
				 (2				<< PSRAMC_TR_TRP_Pos)   |
				 (2				<< PSRAMC_TR_TRH_Pos)   |
				 (tRWR			<< PSRAMC_TR_TRWR_Pos)  |
				 (4				<< PSRAMC_TR_TCSM_Pos);

	if(PSRAMC_Reset() != PSRAMC_RES_OK)
		return PSRAMC_RES_ERR;

	/* The number of latency clocks needed to satisfy tACC depends on the HyperBus frequency */
	uint8_t initial_latency = tACC / (period * clkdiv) + 1;
	switch(initial_latency)
	{
	case 1:
	case 2:
	case 3:  initial_latency = PSRAMC_InitialLatency_3; break;
	case 4:  initial_latency = PSRAMC_InitialLatency_4; break;
	case 5:  initial_latency = PSRAMC_InitialLatency_5; break;
	case 6:  initial_latency = PSRAMC_InitialLatency_6; break;
	case 7:  
	default: initial_latency = PSRAMC_InitialLatency_7; break;
	}

	PSRAMC_SetInitialLatency(initial_latency);

	return PSRAMC_RES_OK;
}


/*******************************************************************************************************************************
* @brief	perform a HyperRAM hardware reset
* @param
* @return	PSRAMC_RES_OK or PSRAMC_RES_ERR
*******************************************************************************************************************************/
uint32_t PSRAMC_Reset(void)
{
	PSRAMC->CR &=~PSRAMC_CR_ENA_Msk;

	return PSRAMC_ReadHyperRAMRegs();
}


/*******************************************************************************************************************************
* @brief	read HyperRAM registers defined in Register Space
* @param
* @return	PSRAMC_RES_OK or PSRAMC_RES_ERR
*******************************************************************************************************************************/
uint32_t PSRAMC_ReadHyperRAMRegs(void)
{
	PSRAMC->CR |= PSRAMC_CR_ENA_Msk;

	while((PSRAMC->SR & (PSRAMC_SR_READY_Msk | PSRAMC_SR_ERROR_Msk)) == 0) {}

	if(PSRAMC->SR & PSRAMC_SR_ERROR_Msk)
		return PSRAMC_RES_ERR;

	return PSRAMC_RES_OK;
}


/*******************************************************************************************************************************
* @brief	change HyperRAM's Burst Length
* @param	v can be PSRAMC_BurstLength_16B, PSRAMC_BurstLength_32B, PSRAMC_BurstLength_64B, or PSRAMC_BurstLength_128B
* @return
*******************************************************************************************************************************/
void PSRAMC_SetBurstLength(uint8_t v)
{
	uint16_t reg = PSRAMC->CR0;

	reg &= ~PSRAMC_CR0_BurstLength_Msk;
	reg |= (v << PSRAMC_CR0_BurstLength_Pos);

	PSRAMC->CR0 = reg | (~reg);
}


/*******************************************************************************************************************************
* @brief	change HyperRAM's Initial Latency
* @param	v can be PSRAMC_InitialLatency_3, PSRAMC_InitialLatency_4, ..., PSRAMC_InitialLatency_6, or PSRAMC_InitialLatency_7
* @return
*******************************************************************************************************************************/
void PSRAMC_SetInitialLatency(uint8_t v)
{
	uint16_t reg = PSRAMC->CR0;

	reg &= ~PSRAMC_CR0_InitialLatency_Msk;
	reg |= (v << PSRAMC_CR0_InitialLatency_Pos);

	PSRAMC->CR0 = reg | (~reg);
}
