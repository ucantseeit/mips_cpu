.data
# 预定义矩阵维度 (Row, Col)
m0_rows: .word 3
m0_cols: .word 4
m1_rows: .word 2
m1_cols: .word 3
input_rows: .word 4
input_cols: .word 1

# 预定义矩阵数据 (示例数据)
m0:      .word 1, -1, 2, 0,  0, 2, -1, 1,  1, 0, 1, -2
m1:      .word 1, 2, -1,  0, 1, 1
input_v: .word 1, 2, 3, 4

# 预留中间结果和输出空间 (不再使用 malloc)
# h = m0 * input -> (3x4) * (4x1) = (3x1)
h:       .space 12   # 3 * 1 * 4 bytes
# o = m1 * h -> (2x3) * (3x1) = (2x1)
o:       .space 8    # 2 * 1 * 4 bytes

.text
.globl main

main:
    # --- Prologue ---
	la   $sp, 0x00003ffc
    addi $sp, $sp, -32
    sw   $ra, 28($sp)
    sw   $s0, 24($sp)
    sw   $s1, 20($sp)
    sw   $s2, 16($sp)

    # --- Step 1: Compute h = matmul(m0, input) ---
    la   $a0, m0           # 矩阵 m0 地址
    lw   $a1, m0_rows      # m0 行数
    lw   $a2, m0_cols      # m0 列数
    la   $a3, input_v      # input 地址
    # 模拟 MIPS 扩展参数传递 (使用临时寄存器或约定)
    lw   $t0, input_rows   # input 行数
    lw   $t1, input_cols   # input 列数
    la   $t2, h            # 结果存储地址 h
    
    jal  matmul

    # --- Step 2: Compute h = relu(h) ---
    la   $a0, h            # 数组地址
    lw   $t0, m0_rows
    lw   $t1, input_cols
    mul  $a1, $t0, $t1     # 元素个数 = m0_rows * input_cols
    
    jal  relu

    # --- Step 3: Compute o = matmul(m1, h) ---
    la   $a0, m1           # 矩阵 m1 地址
    lw   $a1, m1_rows
    lw   $a2, m1_cols
    la   $a3, h            # 输入地址为上一步的结果 h
    lw   $t0, m0_rows      # h 的行数
    lw   $t1, input_cols   # h 的列数
    la   $t2, o            # 结果存储地址 o
    
    jal  matmul

    # --- Step 4: Compute result = argmax(o) ---
    la   $a0, o            # 数组地址
    lw   $t0, m1_rows
    lw   $t1, input_cols
    mul  $a1, $t0, $t1     # 元素个数
    
    jal  argmax
    
    # 最终结果已经在 $v0 中
    # --- Epilogue ---
    lw   $s2, 16($sp)
    lw   $s1, 20($sp)
    lw   $s0, 24($sp)
    lw   $ra, 28($sp)
    addi $sp, $sp, 32
    jr   $ra               # 程序结束，结果在 $v0

# =========================================================
# 辅助函数实现 (简易版)
# =========================================================

# --- matmul(a0, a1, a2, a3, t0, t1, t2) ---
# a0:A, a1:rA, a2:cA, a3:B, t0:rB, t1:cB, t2:D
matmul:
    li   $t3, 0            # i = 0 (row index A)
loop_i:
    beq  $t3, $a1, end_i
    li   $t4, 0            # j = 0 (col index B)
loop_j:
    beq  $t4, $t1, end_j
    li   $t5, 0            # k = 0 (dot product index)
    li   $t6, 0            # sum = 0
loop_k:
    beq  $t5, $a2, end_k
    
    # 计算 A[i][k] 地址: (i * cA + k) * 4
    mul  $t7, $t3, $a2
    add  $t7, $t7, $t5
    sll  $t7, $t7, 2
    add  $t7, $t7, $a0
    lw   $t8, 0($t7)       # t8 = A[i][k]
    
    # 计算 B[k][j] 地址: (k * cB + j) * 4
    mul  $t7, $t5, $t1
    add  $t7, $t7, $t4
    sll  $t7, $t7, 2
    add  $t7, $t7, $a3
    lw   $t9, 0($t7)       # t9 = B[k][j]
    
    mul  $t7, $t8, $t9
    add  $t6, $t6, $t7     # sum += A*B
    
    addi $t5, $t5, 1
    j    loop_k
end_k:
    # 存入 D[i][j]: (i * cB + j) * 4
    mul  $t7, $t3, $t1
    add  $t7, $t7, $t4
    sll  $t7, $t7, 2
    add  $t7, $t7, $t2
    sw   $t6, 0($t7)
    
    addi $t4, $t4, 1
    j    loop_j
end_j:
    addi $t3, $t3, 1
    j    loop_i
end_i:
    jr   $ra

# --- relu(a0:addr, a1:length) ---
relu:
    li   $t0, 0
relu_loop:
    beq  $t0, $a1, relu_end
    sll  $t1, $t0, 2
    add  $t1, $t1, $a0
    lw   $t2, 0($t1)
    bgez $t2, relu_skip
    li   $t2, 0            # if x < 0, x = 0
    sw   $t2, 0($t1)
relu_skip:
    addi $t0, $t0, 1
    j    relu_loop
relu_end:
    jr   $ra

# --- argmax(a0:addr, a1:length) -> v0:index ---
argmax:
    lw   $t1, 0($a0)       # max_val = arr[0]
    li   $v0, 0            # max_idx = 0
    li   $t0, 1            # i = 1
argmax_loop:
    beq  $t0, $a1, argmax_end
    sll  $t2, $t0, 2
    add  $t2, $t2, $a0
    lw   $t3, 0($t2)
    ble  $t3, $t1, argmax_skip
    move $t1, $t3          # update max_val
    move $v0, $t0          # update max_idx
argmax_skip:
    addi $t0, $t0, 1
    j    argmax_loop
argmax_end:
    jr   $ra