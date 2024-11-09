#ifndef __I2CM_DRV_H__
#define __I2CM_DRV_H__


typedef struct {
	volatile uint32_t CR;
	volatile uint32_t SR;
	volatile uint32_t CMD;
	volatile uint32_t DATA;
} I2CM_TypeDef;


#define I2CM_CR_ENA_Pos			0		// 0: reset internal state, 1: normal operation
#define I2CM_CR_ENA_Msk			(0x01 << I2CM_CR_ENA_Pos)
#define I2CM_CR_CKDIV_Pos		8
#define I2CM_CR_CKDIV_Msk		(0xFFF<< I2CM_CR_CKDIV_Pos)

#define I2CM_SR_ERR_Pos			0
#define I2CM_SR_ERR_Msk			(0x01 << I2CM_SR_ERR_Pos)
#define I2CM_SR_RXACK_Pos		1		// ACK bit level received as a tramsmiter, 1 meaning NAK
#define I2CM_SR_RXACK_Msk		(0x01 << I2CM_SR_RXACK_Pos)

#define I2CM_CMD_START_Pos		0		// write 1 to generate start signal, automatically clear to zero after completion
#define I2CM_CMD_START_Msk		(0x01 << I2CM_CMD_START_Pos)
#define I2CM_CMD_WRITE_Pos		1
#define I2CM_CMD_WRITE_Msk		(0x01 << I2CM_CMD_WRITE_Pos)
#define I2CM_CMD_READ_Pos		2
#define I2CM_CMD_READ_Msk		(0x01 << I2CM_CMD_READ_Pos)
#define I2CM_CMD_TXACK_Pos		3		// ACK bit level to send as a receiver, 1 meaning NAK
#define I2CM_CMD_TXACK_Msk		(0x01 << I2CM_CMD_TXACK_Pos)
#define I2CM_CMD_STOP_Pos		4
#define I2CM_CMD_STOP_Msk		(0x01 << I2CM_CMD_STOP_Pos)


#define I2CM	((I2CM_TypeDef *)((5 << 28) + 0x000000))


#define I2CM_RES_OK		0	// operation done successfully and ACK received (if ACK bit level checking needed)
#define I2CM_RES_NAK	1
#define I2CM_RES_ERR	2


void I2CM_Init(I2CM_TypeDef * I2CMx, uint32_t clkdiv);
uint32_t I2CM_Start(I2CM_TypeDef * I2CMx, uint8_t slv_addr);
uint32_t I2CM_Stop(I2CM_TypeDef * I2CMx);
uint32_t I2CM_Write(I2CM_TypeDef * I2CMx, uint8_t data);
uint32_t I2CM_Read(I2CM_TypeDef * I2CMx, uint8_t *data, uint8_t ack);


static inline uint32_t I2CM_Busy(I2CM_TypeDef * I2CMx)
{
	return (I2CMx->CMD != 0);
}


#endif
