#ifndef __W25Q128_H__
#define __W25Q128_H__


#define W25_CMD_READ_JEDEC			0x9F
#define W25_CMD_FAST_READ			0x0B
#define W25_CMD_FAST_READ_2bit		0x3B
#define W25_CMD_FAST_READ_IO2bit	0xBB
#define W25_CMD_FAST_READ_4bit		0x6B
#define W25_CMD_FAST_READ_IO4bit	0xEB
#define W25_CMD_WRITE_ENABLE		0x06
#define W25_CMD_WRITE_DISABLE		0x04
#define W25_CMD_PAGE_PROGRAM		0x02
#define W25_CMD_PAGE_PROGRAM_4bit	0x32
#define W25_CMD_ERASE_CHIP			0x60
#define W25_CMD_ERASE_SECTOR 		0x20
#define W25_CMD_ERASE_BLOCK32KB		0x52
#define W25_CMD_ERASE_BLOCK64KB		0xD8
#define W25_CMD_READ_STATUS_REG1	0x05
#define W25_CMD_READ_STATUS_REG2	0x35
#define W25_CMD_READ_STATUS_REG3	0x15
#define W25_CMD_WRITE_STATUS_REG1	0x01
#define W25_CMD_WRITE_STATUS_REG2	0x31
#define W25_CMD_WRITE_STATUS_REG3	0x11
#define W25_CMD_WRITE_EXT_ADDR		0xC5	// Write Extended Address Register
#define W25_CMD_READ_EXT_ADDR		0xC8
#define W25_CMD_4BYTE_ADDR_ENTER	0xB7
#define W25_CMD_4BYTE_ADDR_EXIT		0xE9

/* Command with 4-byte address */
#define W25_C4B_FAST_READ			0x0C
#define W25_C4B_FAST_READ_2bit		0x3C
#define W25_C4B_FAST_READ_IO2bit	0xBC
#define W25_C4B_FAST_READ_4bit		0x6C
#define W25_C4B_FAST_READ_IO4bit	0xEC
#define W25_C4B_PAGE_PROGRAM		0x12
#define W25_C4B_PAGE_PROGRAM_4bit	0x34
#define W25_C4B_ERASE_SECTOR 		0x21
#define W25_C4B_ERASE_BLOCK64KB		0xDC


#define W25_STATUS_REG1_BUSY_Pos	0
#define W25_STATUS_REG2_QUAD_Pos	1
#define W25_STATUS_REG3_ADS_Pos		0		// Current Address Mode, Status Only
#define W25_STATUS_REG3_ADP_Pos		1		// PowerUp Address Mode, Non-Volatile Writable



void W25_Init(uint32_t chip_size);

void W25_Erase(uint8_t cmd, uint32_t addr, uint8_t wait);

void W25_Write_(uint32_t addr, uint8_t buff[], uint32_t nbyte, uint8_t data_width);
#define W25_Write(addr, buff, nbyte)		W25_Write_((addr), (buff), (nbyte), 1)
#define W25_Write_4bit(addr, buff, nbyte)	W25_Write_((addr), (buff), (nbyte), 4)

void W25_Read_(uint32_t addr, uint8_t buff[], uint32_t nbyte, uint8_t addr_width, uint8_t data_width);
#define W25_Read(addr, buff, nbyte)			W25_Read_((addr), (buff), (nbyte), 1, 1)
#define W25_Read_2bit(addr, buff, nbyte)	W25_Read_((addr), (buff), (nbyte), 1, 2)
#define W25_Read_4bit(addr, buff, nbyte)	W25_Read_((addr), (buff), (nbyte), 1, 4)
#define W25_Read_IO2bit(addr, buff, nbyte)	W25_Read_((addr), (buff), (nbyte), 2, 2)
#define W25_Read_IO4bit(addr, buff, nbyte)	W25_Read_((addr), (buff), (nbyte), 4, 4)


uint32_t W25_ReadReg(uint8_t cmd, uint8_t nbyte);
void W25_WriteReg(uint8_t cmd, uint32_t data, uint8_t nbyte);

uint32_t W25_FlashBusy();
void W25_QuadSwitch(uint8_t on);

#define W25_ReadJEDEC()				W25_ReadReg(W25_CMD_READ_JEDEC, 3)
#define W25_WriteEnable()			W25_WriteReg(W25_CMD_WRITE_ENABLE, 0, 0)
#define W25_WriteDisable()			W25_WriteReg(W25_CMD_WRITE_DISABLE, 0, 0)
#define W25_4ByteAddrEnable()		W25_WriteReg(W25_CMD_4BYTE_ADDR_ENTER, 0, 0)
#define W25_4ByteAddrDisable()		W25_WriteReg(W25_CMD_4BYTE_ADDR_EXIT, 0, 0)

#endif
