#include <stdint.h>

#include "helper.h"


#define SDRAM_BASE  (3 << 28)

#define SDRAM_W		((volatile uint32_t *)SDRAM_BASE)
#define SDRAM_H		((volatile uint16_t *)SDRAM_BASE)
#define SDRAM_B		((volatile uint8_t  *)SDRAM_BASE)

uint32_t DataW[] =	{0x11112222, 0x11223344, 0x12345678, 0xEDCBA987};
uint16_t DataH[] =	{0x1111,     0x1122,     0x1234,     0xEDCB    };
uint8_t  DataB[] =	{0x11,       0x22,       0x12,       0xED      };


int main(void)
{
	int i;

	for(i = 0; i < 100 / 16 * 200; i++) {}	// wait for SDRAM init done, 200uS

	iputs("\n--- main ---\n");


	iputs("\nSDRAM Word Read/Write Test.\n");

	for(i = 0; i < 4; i++) SDRAM_W[i] = DataW[i];

	for(i = 0; i < 4; i++)
		if(SDRAM_W[i] != DataW[i])	break;

	if(i == 4)
		iputs("\nSDRAM Word Read/Write Test Pass.\n");
	else
		iputs("\nSDRAM Word Read/Write Test Fail.\n");


	iputs("\nSDRAM Half Read/Write Test.\n");

	for(i = 0; i < 4; i++) SDRAM_H[i] = DataH[i];

	for(i = 0; i < 4; i++)
		if(SDRAM_H[i] != DataH[i])	break;

	if(i == 4)
		iputs("\nSDRAM Half Read/Write Test Pass.\n");
	else
		iputs("\nSDRAM Half Read/Write Test Fail.\n");


	iputs("\nSDRAM Byte Read/Write Test.\n");

	for(i = 0; i < 4; i++) SDRAM_B[i] = DataB[i];

	for(i = 0; i < 4; i++)
		if(SDRAM_B[i] != DataB[i])	break;

	if(i == 4)
		iputs("\nSDRAM Byte Read/Write Test Pass.\n");
	else
		iputs("\nSDRAM Byte Read/Write Test Fail.\n");
	
	
	finish();

	while(1)
	{
	}
}
