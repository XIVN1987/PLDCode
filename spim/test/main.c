#include <stdint.h>

#include "helper.h"

#include "W25Q128.h"


#define N_RW  12

uint8_t rdbuf[48];
uint8_t wrbuf[48] = {
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F,
	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F
};


int main(void)
{
	int i;
	
	iputs("\n--- main ---\n");

	W25_Init(128);	// Mbits
	
	int id = W25_ReadJEDEC();	
	
	W25_QuadSwitch(1);
	
	
	W25_Erase(0x010000, 1);
	
	W25_Read(0x010000, rdbuf, N_RW);

	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != 0xFF)  break;

	if(i == N_RW)
		iputs("\nW25Q128 Erase Test Pass.\n");
	else
		iputs("\nW25Q128 Erase Test Fail.\n");
	
	
	W25_Write(0x010000, wrbuf, N_RW);
	
	W25_Read(0x010000, rdbuf, N_RW);
	
	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nW25Q128 Write Test Pass.\n");
	else
		iputs("\nW25Q128 Write Test Fail.\n");
	
	
	W25_Read_2bit(0x010000, rdbuf, N_RW);
	
	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nW25Q128 Dual Read Test Pass.\n");
	else
		iputs("\nW25Q128 Dual Read Test Fail.\n");
	
	
	W25_Read_IO2bit(0x010000, rdbuf, N_RW);
	
	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nW25Q128 Dual IO Read Test Pass.\n");
	else
		iputs("\nW25Q128 Dual IO Read Test Fail.\n");
	
	
	W25_Erase(0x010000, 1);
	W25_Write_4bit(0x010000, wrbuf, N_RW);
	
	W25_Read_4bit(0x010000, rdbuf, N_RW);
	
	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nW25Q128 Quad Read Test Pass.\n");
	else
		iputs("\nW25Q128 Quad Read Test Fail.\n");
	
	
	W25_Read_IO4bit(0x010000, rdbuf, N_RW);
	
	for(i = 0; i < N_RW; i++)
		if(rdbuf[i] != wrbuf[i])  break;

	if(i == N_RW)
		iputs("\nW25Q128 Quad IO Read Test Pass.\n");
	else
		iputs("\nW25Q128 Quad IO Read Test Fail.\n");
	
	finish();

	while(1==1)
	{
	}
}
