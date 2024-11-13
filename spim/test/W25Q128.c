/*******************************************************************************************************************************
* @brief	W25Q128 driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "spim_drv.h"
#include "W25Q128.h"


static uint32_t AddressSize;


/*******************************************************************************************************************************
* @brief	SPI Flash driver init
* @param	chip_size is SPI Flash chip size in Mbits
* @return
*******************************************************************************************************************************/
void W25_Init(uint32_t chip_size)
{
	SPIM_Init(SPIM, SPIM_CPHA1_CPOL1, 4);
	
	if(chip_size > 128)
		AddressSize = SPIM_PhaseSize_32bit;
	else
		AddressSize = SPIM_PhaseSize_24bit;
}


/*******************************************************************************************************************************
* @brief	SPI Flash erase
* @param	cmd is the erase command to use, can be W25_CMD_ERASE_SECTOR, W25_CMD_ERASE_BLOCK32KB, or W25_CMD_ERASE_BLOCK64KB
* @param	addr is the SPI Flash address to erase
* @param	wait: 1 wait for erase operation done, 0 send out erase command, and then immediately return.
* @return
*******************************************************************************************************************************/
void W25_Erase(uint8_t cmd, uint32_t addr, uint8_t wait)
{
	SPIM_CmdStructure cmdStruct;
	SPIM_CmdStructInit(&cmdStruct);
	
	cmdStruct.InstructionMode 	 = SPIM_PhaseMode_1bit;
	cmdStruct.Instruction 		 = cmd;
	cmdStruct.AddressMode 		 = SPIM_PhaseMode_1bit;
	cmdStruct.AddressSize		 = AddressSize;
	cmdStruct.Address			 = addr;
	cmdStruct.AlternateBytesMode = SPIM_PhaseMode_None;
	cmdStruct.DummyCycles 		 = 0;
	cmdStruct.DataMode 			 = SPIM_PhaseMode_None;
	
	W25_WriteEnable();
	
	SPIM_Command(SPIM, SPIM_IndirectWrite, &cmdStruct);
	
	while(SPIM_Busy(SPIM)) {}
	
	if(wait)
		while(W25_FlashBusy()) {}
}


/*******************************************************************************************************************************
* @brief	SPI Flash write
* @param	addr is the SPI Flash address to write
* @param	buff is the data to be written to SPI Flash
* @param	nbyte is the number of byte to write, max to 256
* @param	data_width is number of data line to use in data phsase, can be 1 or 4
* @return
*******************************************************************************************************************************/
void W25_Write_(uint32_t addr, uint8_t buff[], uint32_t nbyte, uint8_t data_width)
{
	SPIM_CmdStructure cmdStruct;
	SPIM_CmdStructInit(&cmdStruct);
	
	uint8_t instruction, dataMode;
	switch(data_width)
	{
	case 1:
		instruction = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_PAGE_PROGRAM      : W25_CMD_PAGE_PROGRAM;
		dataMode 	= SPIM_PhaseMode_1bit;
		break;
	
	case 4:
		instruction = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_PAGE_PROGRAM_4bit : W25_CMD_PAGE_PROGRAM_4bit;
		dataMode 	= SPIM_PhaseMode_4bit;
		break;
	}
	
	cmdStruct.InstructionMode 	 = SPIM_PhaseMode_1bit;
	cmdStruct.Instruction 		 = instruction;
	cmdStruct.AddressMode 		 = SPIM_PhaseMode_1bit;
	cmdStruct.AddressSize 		 = AddressSize;
	cmdStruct.Address 			 = addr;
	cmdStruct.AlternateBytesMode = SPIM_PhaseMode_None;
	cmdStruct.DummyCycles 		 = 0;
	cmdStruct.DataMode 			 = dataMode;
	cmdStruct.DataCount 		 = nbyte;
	
	W25_WriteEnable();
	
	SPIM_Command(SPIM, SPIM_IndirectWrite, &cmdStruct);
	
	for(int i = 0; i < nbyte; i++)
	{
		while(SPIM_FIFOSpace(SPIM) < 1) {}
		
		SPIM->DRB = buff[i];
	}
	
	while(SPIM_Busy(SPIM)) {}
	
	while(W25_FlashBusy()) {}
}


/*******************************************************************************************************************************
* @brief	SPI Flash read
* @param	addr is the SPI Flash address to read
* @param	buff is the buffer used to save read data
* @param	nbyte is the number of byte to read
* @param	addr_width is number of data line to use in address phase, can be 1, 2 or 4
* @param	data_width is number of data line to use in data phsase, can be 1, 2 or 4
* @return
*******************************************************************************************************************************/
void W25_Read_(uint32_t addr, uint8_t buff[], uint32_t nbyte, uint8_t addr_width, uint8_t data_width)
{
	SPIM_CmdStructure cmdStruct;
	SPIM_CmdStructInit(&cmdStruct);
	
	uint8_t instruction, addressMode, dataMode, dummyCycles;
	uint8_t alternateBytesMode, alternateBytesSize, alternateBytes;
	switch((addr_width << 4) | data_width)
	{
	case 0x11:
		instruction 	   = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_FAST_READ        : W25_CMD_FAST_READ;
		addressMode 	   = SPIM_PhaseMode_1bit;
		alternateBytesMode = SPIM_PhaseMode_None;
		alternateBytesSize = 0;
		dummyCycles        = 8;
		dataMode 		   = SPIM_PhaseMode_1bit;
		break;
	
	case 0x12:
		instruction 	   = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_FAST_READ_2bit   : W25_CMD_FAST_READ_2bit;
		addressMode 	   = SPIM_PhaseMode_1bit;
		alternateBytesMode = SPIM_PhaseMode_None;
		alternateBytesSize = 0;
		dummyCycles        = 8;
		dataMode 		   = SPIM_PhaseMode_2bit;
		break;
	
	case 0x22:
		instruction 	   = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_FAST_READ_IO2bit : W25_CMD_FAST_READ_IO2bit;
		addressMode 	   = SPIM_PhaseMode_2bit;
		alternateBytesMode = SPIM_PhaseMode_2bit;
		alternateBytesSize = SPIM_PhaseSize_8bit;
		alternateBytes     = 0xFF;
		dummyCycles        = 0;
		dataMode 		   = SPIM_PhaseMode_2bit;
		break;
	
	case 0x14:
		instruction 	   = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_FAST_READ_4bit   : W25_CMD_FAST_READ_4bit;
		addressMode 	   = SPIM_PhaseMode_1bit;
		alternateBytesMode = SPIM_PhaseMode_None;
		alternateBytesSize = 0;
		dummyCycles        = 8;
		dataMode 		   = SPIM_PhaseMode_4bit;
		break;
	
	case 0x44:
		instruction 	   = (AddressSize == SPIM_PhaseSize_32bit) ? W25_C4B_FAST_READ_IO4bit : W25_CMD_FAST_READ_IO4bit;
		addressMode 	   = SPIM_PhaseMode_4bit;
		alternateBytesMode = SPIM_PhaseMode_4bit;
		alternateBytesSize = SPIM_PhaseSize_8bit;
		alternateBytes     = 0xFF;
		dummyCycles        = 4;
		dataMode 		   = SPIM_PhaseMode_4bit;
		break;
	}
	
	cmdStruct.InstructionMode 	 = SPIM_PhaseMode_1bit;
	cmdStruct.Instruction 		 = instruction;
	cmdStruct.AddressMode 		 = addressMode;
	cmdStruct.AddressSize 		 = AddressSize;
	cmdStruct.Address 			 = addr;
	cmdStruct.AlternateBytesMode = alternateBytesMode;
	cmdStruct.AlternateBytesSize = alternateBytesSize;
	cmdStruct.AlternateBytes 	 = alternateBytes;
	cmdStruct.DummyCycles 		 = dummyCycles;
	cmdStruct.DataMode 			 = dataMode;
	cmdStruct.DataCount 		 = nbyte;
	
	SPIM_Command(SPIM, SPIM_IndirectRead, &cmdStruct);
	
	for(int i = 0; i < nbyte; i++)
	{
		while(SPIM_FIFOCount(SPIM) < 1) {}
		
		buff[i] = SPIM->DRB;
	}
}


/*******************************************************************************************************************************
* @brief	SPI Flash register write
* @param	cmd is the command used to write SPI Flash register
* @param	data is the data to be written to SPI Flash register, MSB
* @param	nbyte is the number of byte to write, can be 1, 2, 3, 4, or 0 (execute instruction without data)
* @return
*******************************************************************************************************************************/
void W25_WriteReg(uint8_t cmd, uint32_t data, uint8_t nbyte)
{
	SPIM_CmdStructure cmdStruct;
	SPIM_CmdStructInit(&cmdStruct);
	
	cmdStruct.InstructionMode 	 = SPIM_PhaseMode_1bit;
	cmdStruct.Instruction 		 = cmd;
	cmdStruct.AddressMode 		 = SPIM_PhaseMode_None;
	cmdStruct.AlternateBytesMode = SPIM_PhaseMode_None;
	cmdStruct.DummyCycles 		 = 0;
	cmdStruct.DataMode 			 = nbyte ? SPIM_PhaseMode_1bit : SPIM_PhaseMode_None;
	cmdStruct.DataCount 		 = nbyte;
	
	SPIM_Command(SPIM, SPIM_IndirectWrite, &cmdStruct);
	
	for(int i = nbyte; i > 0; i--)
		SPIM->DRB = ((uint8_t *)&data)[i-1];
	
	while(SPIM_Busy(SPIM)) {}
}


/*******************************************************************************************************************************
* @brief	SPI Flash register read
* @param	cmd is the command used to read SPI Flash register
* @param	nbyte is the number of byte to read, can be 1, 2, 3, or 4
* @return	the data read from SPI Flash, MSB
*******************************************************************************************************************************/
uint32_t W25_ReadReg(uint8_t cmd, uint8_t nbyte)
{
	SPIM_CmdStructure cmdStruct;
	SPIM_CmdStructInit(&cmdStruct);
	
	cmdStruct.InstructionMode 	 = SPIM_PhaseMode_1bit;
	cmdStruct.Instruction 		 = cmd;
	cmdStruct.AddressMode 		 = SPIM_PhaseMode_None;
	cmdStruct.AlternateBytesMode = SPIM_PhaseMode_None;
	cmdStruct.DummyCycles 		 = 0;
	cmdStruct.DataMode 			 = SPIM_PhaseMode_1bit;
	cmdStruct.DataCount 		 = nbyte;
	
	SPIM_Command(SPIM, SPIM_IndirectRead, &cmdStruct);
	
	while(SPIM_FIFOCount(SPIM) < nbyte) {}
	
	uint32_t data = 0;
	for(int i = nbyte; i > 0; i--)
		((uint8_t *)&data)[i-1] = SPIM->DRB;
	
	return data;
}


/*******************************************************************************************************************************
* @brief	SPI Flash busy query
* @param
* @return	1 SPI Flash is busy for internal erase or write, 0 SPI Flash internal operation done
*******************************************************************************************************************************/
uint32_t W25_FlashBusy(void)
{
	uint16_t reg = W25_ReadReg(W25_CMD_READ_STATUS_REG1, 1);
	
	return reg & (1 << W25_STATUS_REG1_BUSY_Pos) ? 1 : 0;
}


/*******************************************************************************************************************************
* @brief	SPI Flash quad mode switch
* @param	on/off
* @return
*******************************************************************************************************************************/
void W25_QuadSwitch(uint8_t on)
{
	uint8_t reg = W25_ReadReg(W25_CMD_READ_STATUS_REG2, 1);
	
	if(on)
		reg |=  (1 << W25_STATUS_REG2_QUAD_Pos);
	else
		reg &= ~(1 << W25_STATUS_REG2_QUAD_Pos);
	
	W25_WriteEnable();
	
	W25_WriteReg(W25_CMD_WRITE_STATUS_REG2, reg, 1);
	
	while(W25_FlashBusy()) {}
}
