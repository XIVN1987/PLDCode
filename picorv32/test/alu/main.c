#include <stdint.h>

#include "helper.h"


void test_add(void);

int main(void)
{
	iputs("\n--- main ---\n");

	test_add();

	finish();

	return 0;
}


void test_add(void)
{
	volatile int a = 3;
	volatile int b = 4;

	int c = a + b;

	if(c == 7)
		iputs("\n--- add pass ---\n");
	else
		iputs("\n--- add fail ---\n");
}
