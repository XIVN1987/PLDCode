#include <stdint.h>

#include "helper.h"

#include "uart_drv.h"


char txstr[] = "Hi from picorv32 over uart!\n";
char rxbuf[128] = {0};


int main(void)
{
	iputs("\n--- main ---\n");

	UART_Init(UART, 115200, 8, 0);

	for(int i = 0; i < sizeof(txstr); i++)
	{
		while(UART_TxFull(UART)) {}
		
		UART_Write(UART, txstr[i]);
	}

	while(UART_TxBusy(UART)) {}
	
	finish();

	while(1==1)
	{
	}
}
