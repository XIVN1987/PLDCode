#ifndef __UART_DRV_H__
#define __UART_DRV_H__

#include <stdbool.h>


typedef struct {
	volatile uint32_t CR;
	
	volatile uint32_t SR;

	volatile uint32_t DR;

	volatile uint32_t CKDIV;
} UART_TypeDef;


#define UART_CR_ENA_Pos				0
#define UART_CR_ENA_Msk				(0x01 << UART_CR_ENA_Pos)
#define UART_CR_DATA9b_Pos			1		// number of data bit, 0 8-bit, 1 9-bit
#define UART_CR_DATA9b_Msk			(0x01 << UART_CR_DATA9b_Pos)
#define UART_CR_STOP2b_Pos			2		// number of stop bit, 0 1-bit, 1 2-bit, only for TX, RX always working with 1 stop bit
#define UART_CR_STOP2b_Msk			(0x01 << UART_CR_STOP2b_Pos)
#define UART_CR_TOTIME_Pos			8		// number of bit time for triggering timeout interrupt.
											// when set to 0, a timeout interrupt is generated whenever RX FIFO is not empty
#define UART_CR_TOTIME_Msk			(0xFF << UART_CR_TOTIME_Pos)
#define UART_CR_IETXHF_Pos			16		// interrupt enable for TX FIFO exceeding half empty (number of data in TX FIFO < 16)
#define UART_CR_IETXHF_Msk			(0x01 << UART_CR_IETXHF_Pos)
#define UART_CR_IERXHF_Pos			17		// interrupt enable for RX FIFO exceeding half full (number of data in RX FIFO > 16)
#define UART_CR_IERXHF_Msk			(0x01 << UART_CR_IERXHF_Pos)
#define UART_CR_IERXTO_Pos			18		// interrupt enable for RX timeout (trigger when no new data was received within CR.TOTIME)
#define UART_CR_IERXTO_Msk			(0x01 << UART_CR_IERXTO_Pos)

#define UART_SR_ERR_Pos				0
#define UART_SR_ERR_Msk				(0x01 << UART_SR_ERR_Pos)
#define UART_SR_TXBUSY_Pos			1		// TX busy, clear when both TX FIFO and TX shifter are empty
#define UART_SR_TXBUSY_Msk			(0x01 << UART_SR_TXBUSY_Pos)
#define UART_SR_TXFULL_Pos			2		// TX FIFO Full
#define UART_SR_TXFULL_Msk			(0x01 << UART_SR_TXFULL_Pos)
#define UART_SR_RXEMPTY_Pos			3		// RX FIFO Empty
#define UART_SR_RXEMPTY_Msk			(0x01 << UART_SR_RXEMPTY_Pos)
#define UART_SR_IFTXHF_Pos			16		// interrupt flag for TX FIFO exceeding half empty (number of data in TX FIFO < 16)
#define UART_SR_IFTXHF_Msk			(0x01 << UART_SR_IFTXHF_Pos)
#define UART_SR_IFRXHF_Pos			17		// interrupt flag for RX FIFO exceeding half full (number of data in RX FIFO > 16)
#define UART_SR_IFRXHF_Msk			(0x01 << UART_SR_IFRXHF_Pos)
#define UART_SR_IFRXTO_Pos			18		// interrupt flag for RX timeout, clear by writing 1 to this bit
#define UART_SR_IFRXTO_Msk			(0x01 << UART_SR_IFRXTO_Pos)


#define UART	((UART_TypeDef *)((5 << 28) + 0x000000))



#define UART_TX_HalfEmpty	UART_SR_IFTXHF_Msk
#define UART_RX_HalfFull	UART_SR_IFRXHF_Msk
#define UART_RX_Timeout		UART_SR_IFRXTO_Msk



void UART_Init(UART_TypeDef * UARTx, uint32_t baudrate, uint8_t nbit, uint32_t it);


static inline void UART_Write(UART_TypeDef * UARTx, uint32_t data)
{
	UARTx->DR = data;
}

static inline uint32_t UART_Read(UART_TypeDef * UARTx)
{
	return UARTx->DR;
}

static inline bool UART_TxBusy(UART_TypeDef * UARTx)
{
	return UARTx->SR & UART_SR_TXBUSY_Msk;
}

static inline bool UART_TxFull(UART_TypeDef * UARTx)
{
	return UARTx->SR & UART_SR_TXFULL_Msk;
}

static inline bool UART_RxEmpty(UART_TypeDef * UARTx)
{
	return UARTx->SR & UART_SR_RXEMPTY_Msk;
}


void UART_IntEn(UART_TypeDef * UARTx, uint32_t it);
void UART_IntDis(UART_TypeDef * UARTx, uint32_t it);
void UART_IntClr(UART_TypeDef * UARTx, uint32_t it);
bool UART_IntStat(UART_TypeDef * UARTx, uint32_t it);

#endif
