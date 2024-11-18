#include <stdint.h>

#include "helper.h"

#include "uart_drv.h"


char txstr[] = "Hi from picorv32 over uart!\n";
char rxbuf[128] = {0};


int main(void)
{
	int i;

	iputs("\n--- main ---\n");

	UART_Init(UART, 115200, 8, 0);

	for(i = 0; i < sizeof(txstr); i++)
	{
		while(UART_TxFull(UART)) {}
		
		UART_Write(UART, txstr[i]);
	}

	while(UART_TxBusy(UART)) {}

	for(i = 0; i < sizeof(txstr); i++)
	{
		while(UART_RxEmpty(UART)) {}

		rxbuf[i] = UART_Read(UART);
	}

	for(i = 0; i < sizeof(txstr); i++)
		if(rxbuf[i] != txstr[i])
			break;

	if(i == sizeof(txstr))
		iputs("\nUART TX/RX test Pass!\n");
	else
		iputs("\nUART TX/RX test Fail!\n");
	
	finish();

	while(1==1)
	{
	}
}
