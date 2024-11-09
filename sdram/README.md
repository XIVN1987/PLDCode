## half-word write vs word write

### word write

``` C
((volatile uint32_t *)SDRAM_BASE) = 0x11112222;
```

![](./sdramc_write_word.png)

### half-word write

``` C
((volatile uint16_t *)SDRAM_BASE) = 0x1111;
```

![](./sdramc_write_half.png)

On sdramc control signals, the only difference is that sdram_dqm becomes 11 on sdram_we rising edge.
