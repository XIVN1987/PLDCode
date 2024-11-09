/*******************************************************************************************************************************
* @brief	I2C master driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "i2cm_drv.h"


/*******************************************************************************************************************************
* @brief	I2CM init
* @param	I2CMx is the I2CM to init
* @param	clkdiv is clock division value
* @return
*******************************************************************************************************************************/
void I2CM_Init(I2CM_TypeDef * I2CMx, uint32_t clkdiv)
{
	I2CMx->CR = 0;

	I2CMx->CR = (1		<< I2CM_CR_ENA_Pos) |
				(clkdiv << I2CM_CR_CKDIV_Pos);
}


/*******************************************************************************************************************************
* @brief	generate I2C start signal and then send slave address
* @param	I2CMx is the I2CM to use
* @param	slv_addr is the slave address and read/write control bit
* @return	I2CM_RES_OK, I2CM_RES_NAK, I2CM_RES_ERR
*******************************************************************************************************************************/
uint32_t I2CM_Start(I2CM_TypeDef * I2CMx, uint8_t slv_addr)
{
	I2CMx->DATA = slv_addr;
	I2CMx->CMD = (1 << I2CM_CMD_START_Pos) |
				 (1 << I2CM_CMD_WRITE_Pos);
	
	while(I2CMx->CMD & I2CM_CMD_WRITE_Msk) {}	// wait for sending to complete
	
	if(I2CMx->SR & I2CM_SR_ERR_Msk)
		return I2CM_RES_ERR;

	if(I2CMx->SR & I2CM_SR_RXACK_Msk)
		return I2CM_RES_NAK;

	return I2CM_RES_OK;
}


/*******************************************************************************************************************************
* @brief	generate I2C stop signal
* @param	I2CMx is the I2CM to use
* @return	I2CM_RES_OK, I2CM_RES_ERR
*******************************************************************************************************************************/
uint32_t I2CM_Stop(I2CM_TypeDef * I2CMx)
{
	I2CMx->CMD = (1 << I2CM_CMD_STOP_Pos);
	
	while(I2CMx->CMD & I2CM_CMD_STOP_Msk) {}

	if(I2CMx->SR & I2CM_SR_ERR_Msk)
		return I2CM_RES_ERR;

	return I2CM_RES_OK;
}


/*******************************************************************************************************************************
* @brief	send 1 byte data
* @param	I2CMx is the I2CM to use
* @param	data is the byte to send
* @return	I2CM_RES_OK, I2CM_RES_NAK, I2CM_RES_ERR
*******************************************************************************************************************************/
uint32_t I2CM_Write(I2CM_TypeDef * I2CMx, uint8_t data)
{
	I2CMx->DATA = data;
	I2CMx->CMD = (1 << I2CM_CMD_WRITE_Pos);
	
	while(I2CMx->CMD & I2CM_CMD_WRITE_Msk) {}
	
	if(I2CMx->SR & I2CM_SR_ERR_Msk)
		return I2CM_RES_ERR;

	if(I2CMx->SR & I2CM_SR_RXACK_Msk)
		return I2CM_RES_NAK;

	return I2CM_RES_OK;
}


/*******************************************************************************************************************************
* @brief	receive 1 byte data
* @param	I2CMx is the I2CM to use
* @param	data is used to save received byte
* @param	ack is ACK bit level to send after data received
* @return	I2CM_RES_OK, I2CM_RES_ERR
*******************************************************************************************************************************/
uint32_t I2CM_Read(I2CM_TypeDef * I2CMx, uint8_t *data, uint8_t ack)
{
	I2CMx->CMD = (1 << I2CM_CMD_READ_Pos) | (ack << I2CM_CMD_TXACK_Pos);
	
	while(I2CMx->CMD & I2CM_CMD_READ_Msk) {}

	if(I2CMx->SR & I2CM_SR_ERR_Msk)
		return I2CM_RES_ERR;

	*data = I2CMx->DATA;

	return I2CM_RES_OK;
}
