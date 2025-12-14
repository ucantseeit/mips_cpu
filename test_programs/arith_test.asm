.text
.globl main

main:
    # 初始化测试值
    li $t0, 10          # $8  = 10
    li $t1, 20          # $9  = 20
    li $s0, 3           # $16 = 3
    li $a0, 3           # $4  = 3
    li $a1, -1          # $5  = 0xFFFFFFFF

    # ------- I-type -------
    addi $t2, $t0, 20   # $10 = 10 + 20 = 30        (for add later)
    addi $t3, $t1, -4   # $11 = 20 - 4 = 16
    addi $t4, $t0, -20  # $12 = 10 - 20 = -10       (subi simulation)
    
    # ------- R-type ALU -------
    add  $s4, $t0, $t1  # $20 = 10 + 20 = 30
    addu $s5, $t0, $t1  # $21 = 10 + 20 = 30 (same, no overflow)
    sub  $s6, $t0, $t1  # $22 = 10 - 20 = -10
    subu $s7, $t0, $t1  # $23 = 10 - 20 = 0xFFFFFFF6 (unsigned, but same bits)

    # slt / sltu
    slt  $t6, $t0, $zero   # $14 = (10 < 0) ? 1 : 0 → 0
    sltu $t7, $t0, $zero   # $15 = (10 < 0) as unsigned? → 0 (since 10 > 0)
    slt  $k0, $t0, $t1     # $26 = (10 < 20) → 1
    sltu $k1, $a0, $a1     # $27 = (3 < 0xFFFFFFFF) → 1 (unsigned compare)

    # ------- Shifts -------
    sll  $s1, $t0, 3       # $17 = 10 << 3 = 80
    srl  $s2, $s0, 1       # $18 = 3 >> 1 = 1 (logical)
    sra  $s3, $s0, 1       # $19 = 3 >>> 1 = 1 (arithmetic, same for positive)
    sllv $at, $t0, $s0     # $1  = 10 << 3 = 80  (but we avoid $at; use $v0 instead)
    # So redo with safe reg:
    sllv $v0, $t0, $s0     # $2 = 10 << 3 = 80

    # ------- Final exit -------
    li $v0, 10
    syscall