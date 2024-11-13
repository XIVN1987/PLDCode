/*******************************************************************************************************************************
* @brief	SPI Master driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "spim_drv.h"


/*******************************************************************************************************************************
* @brief	SPIM init
* @param	SPIMx is the SPIM to init
* @param	clkmode: SPIM_CPHA0_CPOL0, SPIM_CPHA1_CPOL0, SPIM_CPHA0_CPOL1, or SPIM_CPHA1_CPOL1
* @param	clkdiv is clock division value
* @return
*******************************************************************************************************************************/
void SPIM_Init(SPIM_TypeDef * SPIMx, uint8_t clkmode, uint8_t clkdiv)
{
	SPIMx->CR = (clkmode 	  << SPIM_CR_CPHA_Pos)  |
				(0			  << SPIM_CR_BIDI_Pos)  |
				((clkdiv - 1) << SPIM_CR_CKDIV_Pos) |
				(3			  << SPIM_CR_CSHMIN_Pos);
	
	SPIMx->CR |= SPIM_CR_ENA_Msk;
}


/*******************************************************************************************************************************
* @brief	SPIM command send
* @param	SPIMx is the SPIM to use
* @param	cmdMode: SPIM_IndirectWrite, SPIM_IndirectRead, or SPIM_MemoryMapped
* @param	cmdStruct contains command to send
* @return
*******************************************************************************************************************************/
void SPIM_Command(SPIM_TypeDef * SPIMx, uint8_t cmdMode, SPIM_CmdStructure * cmdStruct)
{
	if(cmdStruct->AlternateBytesMode != SPIM_PhaseMode_None)
		SPIMx->ABR = cmdStruct->AlternateBytes;
	
	if(cmdStruct->DataMode != SPIM_PhaseMode_None)
		SPIMx->DLR = cmdStruct->DataCount - 1;
	
	SPIMx->CCR = (cmdStruct->Instruction		<< SPIM_CCR_ICODE_Pos)  |
				 (cmdStruct->InstructionMode	<< SPIM_CCR_IMODE_Pos)  |
				 (cmdStruct->AddressMode		<< SPIM_CCR_AMODE_Pos)  |
				 (cmdStruct->AddressSize		<< SPIM_CCR_ASIZE_Pos)  |
				 (cmdStruct->AlternateBytesMode	<< SPIM_CCR_ABMODE_Pos) |
				 (cmdStruct->AlternateBytesSize	<< SPIM_CCR_ABSIZE_Pos) |
				 (cmdStruct->DummyCycles		<< SPIM_CCR_DUMMY_Pos)  |
				 (cmdStruct->DataMode			<< SPIM_CCR_DMODE_Pos)  |
				 (cmdMode						<< SPIM_CCR_MODE_Pos);
	
	if(cmdStruct->AddressMode != SPIM_PhaseMode_None)
		SPIMx->AR = cmdStruct->Address;
}


/*******************************************************************************************************************************
* @brief	SPIM_CmdStructure instance init
* @param	cmdStruct is the instance to init
* @return
*******************************************************************************************************************************/
void SPIM_CmdStructInit(SPIM_CmdStructure * cmdStruct)
{
	cmdStruct->Instruction		  = 0;
	cmdStruct->InstructionMode	  = 0;
	cmdStruct->Address 			  = 0;
	cmdStruct->AddressMode		  = 0;
	cmdStruct->AddressSize		  = 0;
	cmdStruct->AlternateBytes 	  = 0;
	cmdStruct->AlternateBytesMode = 0;
	cmdStruct->AlternateBytesSize = 0;
	cmdStruct->DummyCycles		  = 0;
	cmdStruct->DataMode			  = 0;
	cmdStruct->DataCount		  = 0;
}
