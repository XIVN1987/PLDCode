#include <stdint.h>
#include <string.h>

#include "helper.h"

#include "uart_drv.h"


char txstr[] = "Hi from picorv32 over uart!\n";
char rxbuf[128] = {0};
uint8_t rxindex = 0;


int main(void)
{
	iputs("\n--- main ---\n");

	UART_Init(UART, 115200, 8, UART_RX_HalfFull | UART_RX_Timeout);

	irq_enable();

	for(int i = 0; i < sizeof(txstr); i++)
	{
		while(UART_TxFull(UART)) {}
		
		UART_Write(UART, txstr[i]);
	}

	while(UART_TxBusy(UART)) {}

	while(1)
	{
	}
}


uint32_t *irq_handler_C(uint32_t *regs, uint32_t irqs)
{
	if(irqs & (1 << 4))
	{
		if(UART_IntStat(UART, UART_RX_HalfFull | UART_RX_Timeout))
		{
			while(!UART_RxEmpty(UART))
			{
				char c = UART_Read(UART);

				if(rxindex < sizeof(rxbuf))
					rxbuf[rxindex++] = c;
			}

			if(UART_IntStat(UART, UART_RX_Timeout))
			{
				UART_IntClr(UART, UART_RX_Timeout);

				if(strcmp(rxbuf, txstr) == 0)
					iputs("\nUART TX/RX test Pass!\n");
				else
					iputs("\nUART TX/RX test Fail!\n");
				
				finish();
			}
		}
	}

	return regs;
}
