#ifndef __HELPER_H__
#define __HELPER_H__


void finish(void);


void iputs(char *s);
void iprintf(const char *fmt, ...);


void irq_enable(void);

/* count down to 0 and stop, triggering an interrupt request. */
void timer_start(int cycles);


#endif
