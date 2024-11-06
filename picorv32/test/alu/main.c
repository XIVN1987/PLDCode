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
	int a = 3;
	int b = 4;

	int c = a + b;

	iprintf("%d + %d = %d\n\n", a, b, c);
}
