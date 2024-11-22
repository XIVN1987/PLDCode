/*******************************************************************************************************************************
* @brief	PSRAM (HyperRAM) Controller driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "psramc_drv.h"


/*******************************************************************************************************************************
* @brief	perform a HyperRAM hardware reset
* @param
* @return	PSRAMC_RES_OK or PSRAMC_RES_ERR
*******************************************************************************************************************************/
uint32_t PSRAMC_Reset(void)
{
	PSRAMC->CR &=~PSRAMC_CR_ENA_Msk;

	PSRAMC->CR |= PSRAMC_CR_ENA_Msk;

	while((PSRAMC->SR & (PSRAMC_SR_READY_Msk | PSRAMC_SR_ERROR_Msk)) == 0) {}

	if(PSRAMC->SR & PSRAMC_SR_ERROR_Msk)
		return PSRAMC_RES_ERR;

	return PSRAMC_RES_OK;
}


/*******************************************************************************************************************************
* @brief	change HyperRAM Controller's timing parameter
* @param	clkdiv: fPSRAM_CK = fSYS_CK / clkdiv
* @param	tRP: RESET# Pulse Width in us
* @param	tRH: Time between RESET# (High) and CS# (Low) in us
* @param	tRWR: Read-Write Recovery Time in ns
* @return
*******************************************************************************************************************************/
void PSRAMC_SetTiming(uint8_t clkdiv, uint8_t tRP, uint8_t tRH, uint8_t tRWR)
{
	uint16_t period = 1000000000 / SYS_FREQ;

	PSRAMC->TR = ((clkdiv - 1)	<< PSRAMC_TR_CKDIV_Pos) |
				 (period 		<< PSRAMC_TR_CKiNS_Pos) |
				 (tRP	 		<< PSRAMC_TR_TRP_Pos)   |
				 (tRH	 		<< PSRAMC_TR_TRH_Pos)   |
				 (tRWR	 		<< PSRAMC_TR_TRWR_Pos);
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
