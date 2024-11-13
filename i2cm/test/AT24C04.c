/*******************************************************************************************************************************
* @brief	AT24C04 driver
*
*
*******************************************************************************************************************************/
#include <stdint.h>

#include "i2cm_drv.h"
#include "AT24C04.h"


#define DEV_ADDR	0x50


#define SIZE_AT24C01	(1024 * 1 / 8)
#define SIZE_AT24C02	(1024 * 2 / 8)
#define SIZE_AT24C04	(1024 * 4 / 8)
#define SIZE_AT24C08	(1024 * 4 / 8)
#define SIZE_AT24C16	(1024 * 4 / 8)

#define SIZE_USE		SIZE_AT24C04


#define ADDR_LIMIT		(SIZE_USE - 1)

#if (SIZE_USE == SIZE_AT24C01) || (SIZE_USE == SIZE_AT24C02)
#define PAGE_SIZE	 		8
#define DEV_ADDR_P(addr)	(DEV_ADDR)
#else
#define PAGE_SIZE			16
#define DEV_ADDR_P(addr)	(DEV_ADDR | (addr >> 8))
#endif


/*******************************************************************************************************************************
* @brief	AT24 driver init
* @param
* @return
*******************************************************************************************************************************/
void AT24_Init(void)
{
	I2CM_Init(I2CM, 1000);
}


/*******************************************************************************************************************************
* @brief	write data at same page to AT24C04
* @param	addr is memory address data written to, 0--511 for AT24C04
* @param	data is the bytes to write
* @param	nbyte is the number of byte to write, up to 16 for AT24C04
* @return	AT24_RES_OK, AT24_RES_ERR
* @note		After this call, the EEPROM enters an internally timed write cycle (tWR, 5ms max) to the nonvolatile memory.
* 			All inputs are disabled during this write cycle and the EEPROM will not respond until the write is complete.
* 			You can use AT24_Busy() to query whether nonvolatile write complete.
*******************************************************************************************************************************/
uint32_t AT24_WriteOnePage(uint16_t addr, uint8_t data[], uint8_t nbyte)
{
	uint32_t res;

	if(addr + nbyte > ADDR_LIMIT)	// out of range
		return AT24_RES_ERR;

	if(addr / PAGE_SIZE != (addr + nbyte - 1) / PAGE_SIZE)	// corss page
		return AT24_RES_ERR;

	res = I2CM_Start(I2CM, (DEV_ADDR_P(addr) << 1) | 0);
	if(res != I2CM_RES_OK)
		goto error;

	res = I2CM_Write(I2CM, addr);
	if(res != I2CM_RES_OK)
		goto error;

	for(int i = 0; i < nbyte; i++)
	{
		res = I2CM_Write(I2CM, data[i]);
		if(res != I2CM_RES_OK)
			goto error;
	}

	res = I2CM_Stop(I2CM);
	if(res != I2CM_RES_OK)
		goto error;

	return AT24_RES_OK;

error:
	I2CM_Stop(I2CM);

	return AT24_RES_ERR;
}


/*******************************************************************************************************************************
* @brief	write data to AT24C04
* @param	addr is memory address data written to, 0--511 for AT24C04
* @param	data is the bytes to write
* @param	nbyte is the number of byte to write
* @return	AT24_RES_OK, AT24_RES_ERR
*******************************************************************************************************************************/
uint32_t AT24_Write(uint16_t addr, uint8_t data[], uint16_t nbyte)
{
	uint32_t res;
	uint8_t * pdata = data;

	if(addr + nbyte > ADDR_LIMIT)	// out of range
		return AT24_RES_ERR;
	
	if(addr % PAGE_SIZE)
	{
#define MIN(a, b)	a < b ? a : b;
		int n = MIN(nbyte, PAGE_SIZE - addr % PAGE_SIZE)

		res = AT24_WriteOnePage(addr, pdata, n);
		if(res != AT24_RES_OK)
			return res;

		res = AT24_BusyWait();
		if(res != AT24_RES_OK)
			return res;

		addr  += n;
		pdata += n;
		nbyte -= n;
	}

	while(nbyte >= PAGE_SIZE)
	{
		res = AT24_WriteOnePage(addr, pdata, PAGE_SIZE);
		if(res != AT24_RES_OK)
			return res;

		res = AT24_BusyWait();
		if(res != AT24_RES_OK)
			return res;

		addr  += PAGE_SIZE;
		pdata += PAGE_SIZE;
		nbyte -= PAGE_SIZE;
	}
	
	if(nbyte)
	{
		res = AT24_WriteOnePage(addr, pdata, nbyte);
		if(res != AT24_RES_OK)
			return res;

		res = AT24_BusyWait();
		if(res != AT24_RES_OK)
			return res;
	}

	return AT24_RES_OK;
}


/*******************************************************************************************************************************
* @brief	read data from AT24C04
* @param	addr is memory address data read from, 0--511 for AT24C04
* @param	buff is used to save read data
* @param	nbyte is the number of byte to read
* @return	AT24_RES_OK, AT24_RES_ERR
*******************************************************************************************************************************/
uint32_t AT24_Read(uint16_t addr, uint8_t buff[], uint8_t nbyte)
{
	uint32_t res, i;

	if(addr + nbyte > ADDR_LIMIT)	// out of range
		return AT24_RES_ERR;

	res = I2CM_Start(I2CM, (DEV_ADDR_P(addr) << 1) | 0);
	if(res != I2CM_RES_OK)
		goto error;

	res = I2CM_Write(I2CM, addr);
	if(res != I2CM_RES_OK)
		goto error;

	res = I2CM_Start(I2CM, (DEV_ADDR_P(addr) << 1) | 1);	// re-start for read
	if(res != I2CM_RES_OK)
		goto error;

	for(i = 0; i < nbyte - 1; i++)
	{
		res = I2CM_Read(I2CM, &buff[i], 0);		// send ACK
		if(res != I2CM_RES_OK)
			goto error;
	}

	res = I2CM_Read(I2CM, &buff[i], 1);			// send NAK
	if(res != I2CM_RES_OK)
		goto error;

	res = I2CM_Stop(I2CM);
	if(res != I2CM_RES_OK)
		goto error;

	return AT24_RES_OK;

error:
	I2CM_Stop(I2CM);

	return AT24_RES_ERR;
}


/*******************************************************************************************************************************
* @brief	AT24C04 nonvolatile write busy query
* 			Once the internally timed write cycle has started and the EEPROM inputs are disabled, ACK polling can be initiated.
* 			This involves sending a start followed by the device address word. Only if the internal write cycle has completed 
* 			will the EEPROM respond with a zero.
* @param
* @return	1: busy for nonvolatile write, 0: nonvolatile write complete
*******************************************************************************************************************************/
uint32_t AT24_Busy(void)
{
	uint32_t res;

	res = I2CM_Start(I2CM, (DEV_ADDR_P(0) << 1) | 1);

	I2CM_Stop(I2CM);

	return (res != I2CM_RES_OK);
}


/*******************************************************************************************************************************
* @brief	wait until AT24_Busy() clear or time-out
* @param
* @return	AT24_RES_OK, AT24_RES_ERR
*******************************************************************************************************************************/
uint32_t AT24_BusyWait(void)
{
	for(int i = 0; i < 5000 * 50 / 4 / 2; i++) {}	// when fCPU = 50MHz
		return AT24_RES_OK;

	for(int i = 0; i < 5000; i++)	// AT24_Busy() consumes 2 SCL clock cycle, 1us per cycle at min
		if(AT24_Busy() == 0)
			return AT24_RES_OK;

	return AT24_RES_ERR;			// time-out
}
