#include <stdint.h>

#include "helper.h"


int main(void)
{
	iputs("\n--- main ---\n");

	timer_start(1000);

	irq_enable();

	while(1) {}

	return 0;
}


uint32_t *irq_handler_C(uint32_t *regs, uint32_t irqs)
{
	if(irqs & (1 << 0))
	{
		iputs("\n--- TIMER IRQ ---\n");

		finish();
	}

	if(irqs & (1 << 4))
	{
		iputs("\n--- EXTI4 IRQ ---\n");
	}

	return regs;
}
