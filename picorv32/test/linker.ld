MEMORY
{
	mem (rwx) : ORIGIN = 0x00000000, LENGTH = 0x4000 /* 16k */
}

ENTRY(entry)

SECTIONS
{
	.text ALIGN(16) :
	{
		*(.text.entry)
		. = 0x100;
		*(.text.irq)
		*(.text*)
		*(.rodata)
		*(.rodata.*)
	} > mem

	.data ALIGN(16) :
	{
		*(.data)
		*(.data.*)
		*(.sdata)
		*(.sdata.*)
	} > mem

	.bss  ALIGN(16) :
	{
		_bss = .;
		*(.bss*)
		*(.sbss*)
		*(COMMON)
		_ebss = ALIGN(16);
	} > mem

	PROVIDE(_stack_top = ORIGIN(mem) + LENGTH(mem));
}
