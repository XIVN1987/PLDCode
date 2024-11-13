#include <stdint.h>

#include "helper.h"

#include "AT24C04.h"

#define N_RW	3

uint8_t rdbuf[32];
uint8_t wrbuf[32] = {
	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F
};

int main(void)
{
	uint32_t res, i;

	iputs("\n--- main ---\n");

	AT24_Init();


	iputs("\nEEPROM aligned Read/Write Test.\n");

	res = AT24_Write(0, wrbuf, N_RW);
	if(res != AT24_RES_OK)
		goto error_0;

	res = AT24_Read(0, rdbuf, N_RW);
	if(res != AT24_RES_OK)
		goto error_0;

	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nEEPROM aligned Read/Write Test Pass.\n");
	else
error_0:
		iputs("\nEEPROM aligned Read/Write Test Fail.\n");


	iputs("\nEEPROM unaligned Read/Write Test.\n");

	res = AT24_Write(3, wrbuf, N_RW);
	if(res != AT24_RES_OK)
		goto error_3;

	res = AT24_Read(0, rdbuf, N_RW);
	if(res != AT24_RES_OK)
		goto error_3;

	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nEEPROM unaligned Read/Write Test Pass.\n");
	else
error_3:
		iputs("\nEEPROM unaligned Read/Write Test Fail.\n");
	
	
	finish();

	while(1)
	{
	}
}
