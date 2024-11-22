#include <stdint.h>

#include "helper.h"

#include "psramc_drv.h"


#define PSRAM_BASE  (3 << 28)

#define PSRAM_W		((volatile uint32_t *)PSRAM_BASE)
#define PSRAM_H		((volatile uint16_t *)PSRAM_BASE)
#define PSRAM_B		((volatile uint8_t  *)PSRAM_BASE)

uint32_t DataW[] =	{0x11112222, 0x11223344, 0x12345678, 0xEDCBA987};
uint16_t DataH[] =	{0x1111,     0x1122,     0x1234,     0xEDCB    };
uint8_t  DataB[] =	{0x11,       0x22,       0x12,       0xED      };


int main(void)
{
	int i;

	iputs("\n--- main ---\n");

	for(int i = SYS_FREQ/1000000 * 200 / 4 * 2; i > 0; i--) {}	// wait for HyperRAM Power-Up Initialization done

	int res = PSRAMC_Reset();
	if(res != PSRAMC_RES_OK)
	{
		iputs("\nPSRAM initialize Fail.\n");

		goto exit;
	}


	iputs("\nPSRAM Word Read/Write Test.\n");

	for(i = 0; i < 4; i++) PSRAM_W[i] = DataW[i];

	for(i = 0; i < 4; i++)
		if(PSRAM_W[i] != DataW[i])	break;

	if(i == 4)
		iputs("\nPSRAM Word Read/Write Test Pass.\n");
	else
		iputs("\nPSRAM Word Read/Write Test Fail.\n");


	iputs("\nPSRAM Half Read/Write Test.\n");

	for(i = 0; i < 4; i++) PSRAM_H[i] = DataH[i];

	for(i = 0; i < 4; i++)
		if(PSRAM_H[i] != DataH[i])	break;

	if(i == 4)
		iputs("\nPSRAM Half Read/Write Test Pass.\n");
	else
		iputs("\nPSRAM Half Read/Write Test Fail.\n");


	iputs("\nPSRAM Byte Read/Write Test.\n");

	for(i = 0; i < 4; i++) PSRAM_B[i] = DataB[i];

	for(i = 0; i < 4; i++)
		if(PSRAM_B[i] != DataB[i])	break;

	if(i == 4)
		iputs("\nPSRAM Byte Read/Write Test Pass.\n");
	else
		iputs("\nPSRAM Byte Read/Write Test Fail.\n");
	
exit:
	finish();

	while(1)
	{
	}
}
