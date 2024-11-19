#include <stdint.h>
#include <stdarg.h>

#include "helper.h"


#define	 ADDR_FINISH	0x80000000
#define	 ADDR_OUTPUT	0x90000000


//-----------------------------------------------------------------------------
extern int main(void);

__attribute__((section(".text.entry")))
void entry(void)
{
	extern uint32_t _bss;
	extern uint32_t _ebss;

	for(uint32_t *dst = &_bss; dst < &_ebss; dst++)
		*dst = 0;

	main();
}


//-----------------------------------------------------------------------------
void finish(void)
{
	*((volatile uint32_t *)ADDR_FINISH) = 1;
}


//-----------------------------------------------------------------------------
void iputc(int c)
{
	*((volatile uint32_t *)ADDR_OUTPUT) = c;
}

//-----------------------------------------------------------------------------
void iputs(char *s)
{
	while(*s)
		iputc(*s++);
}

//-----------------------------------------------------------------------------
void iprintf(const char *fmt, ...)
{
	char str[200];
	va_list ap;

	va_start(ap, fmt);
//	vsprintf(str, fmt, ap);
	va_end(ap);

	iputs(str);
}
