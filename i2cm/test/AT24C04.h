#ifndef __AT24C04_H__
#define __AT24C04_H__


#define AT24_RES_OK		0
#define AT24_RES_ERR	1


void AT24_Init(void);

uint32_t AT24_WriteOnePage(uint16_t addr, uint8_t data[], uint8_t nbyte);
uint32_t AT24_Write(uint16_t addr, uint8_t data[], uint16_t nbyte);
uint32_t AT24_Read(uint16_t addr, uint8_t buff[], uint8_t nbyte);

uint32_t AT24_Busy(void);
uint32_t AT24_BusyWait(void);


#endif
