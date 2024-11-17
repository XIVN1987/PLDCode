/*******************************************************************************************************************************
* @brief	UART driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "uart_drv.h"


/*******************************************************************************************************************************
* @brief	UART init
* @param	UARTx is the UART to init
* @param	baudrate specify uart working baud rate
* @param	nbit specify number of data bits, can be 8 or 9
* @param	it is interrupt type, can be UART_TX_HalfEmpty, UART_RX_HalfFull, or UART_RX_Timeout and their '|' operation
* @return
*******************************************************************************************************************************/
void UART_Init(UART_TypeDef * UARTx, uint32_t baudrate, uint8_t nbit, uint32_t it)
{
	UARTx->CR = ((nbit == 9)  << UART_CR_DATA9b_Pos) |
				(1			  << UART_CR_STOP2b_Pos) |
				(100		  << UART_CR_TOTIME_Pos);	// about 10 characters time
	
	UARTx->CKDIV = SYS_FREQ / baudrate;
	
	UARTx->CR |= UART_CR_ENA_Msk;

	UART_IntClr(UARTx, it);
	UART_IntEn(UARTx, it);
}


/*******************************************************************************************************************************
* @brief	UART interrupt enable
* @param	UARTx is the UART to set
* @param	it is interrupt type, can be UART_TX_HalfEmpty, UART_RX_HalfFull, or UART_RX_Timeout and their '|' operation
* @return
*******************************************************************************************************************************/
void UART_IntEn(UART_TypeDef * UARTx, uint32_t it)
{
	UARTx->CR |= it;
}

/*******************************************************************************************************************************
* @brief	UART interrupt disable
* @param	UARTx is the UART to set
* @param	it is interrupt type, can be UART_TX_HalfEmpty, UART_RX_HalfFull, or UART_RX_Timeout and their '|' operation
* @return
*******************************************************************************************************************************/
void UART_IntDis(UART_TypeDef * UARTx, uint32_t it)
{
	UARTx->CR &= ~it;
}

/*******************************************************************************************************************************
* @brief	UART interrupt flag clear
* @param	UARTx is the UART to clear
* @param	it is interrupt type, can be UART_RX_Timeout
* @return
*******************************************************************************************************************************/
void UART_IntClr(UART_TypeDef * UARTx, uint32_t it)
{
	UARTx->SR |= it;
}

/*******************************************************************************************************************************
* @brief	UART interrupt state query
* @param	UARTx is the UART to query
* @param	it is interrupt type, can be UART_TX_HalfEmpty, UART_RX_HalfFull, or UART_RX_Timeout and their '|' operation
* @return	true: interrupt happened, false: interrupt not happened
*******************************************************************************************************************************/
bool UART_IntStat(UART_TypeDef * UARTx, uint32_t it)
{
	return UARTx->SR & it;
}
