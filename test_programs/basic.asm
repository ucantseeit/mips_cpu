.text
.globl main

main:
    lw $t0, 0x14($zero)
    lw $t1, 0x18($zero)
    
    add $t2, $t0, $t1
    sub $t3, $t0, $t1