.text
.globl main

main:
    lw $t0, 0x24($zero)
    lw $t1, 0x28($zero)
    nop
    nop
    nop
    nop
    nop
    add $t2, $t0, $t1
    sub $t3, $t0, $t1