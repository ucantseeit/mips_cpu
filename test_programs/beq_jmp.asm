# 仅使用 beq 和 j 指令
# 不依赖延迟槽，所有赋值在安全位置

.text
.globl main

main:
    # 初始化测试值
    li $t0, 5        # $8  = 5
    li $t1, 5        # $9  = 5  → 用于 beq taken
    li $t2, 10       # $10 = 10 → 用于 beq not-taken

    # 初始化结果寄存器为 0
    li $s0, 0        # $16 → beq taken 标志
    li $s1, 0        # $17 → beq not-taken 标志
    li $s2, 0        # $18 → j 成功标志
    li $s3, 0        # $19 → 未执行路径标志（应保持 0）

    beq $t0, $t1, beq_taken   # 应该跳转
    j beq_not_taken_fallback  # 若未跳转，会到这里（错误路径）

beq_taken:
    li $s0, 42                # ✅ 执行：beq taken 成功
    j after_beq_tests         # 跳过 not-taken 测试的赋值

beq_not_taken_fallback:
    li $s3, 999               # 不应执行（如果执行，说明 beq failed）

after_beq_tests:
    beq $t0, $t2, skip_beq_not_taken  # 5 == 10? 否 → 不跳转
    li $s1, 88                        # ✅ 执行：beq not-taken 成功

skip_beq_not_taken:
    j jump_target
    li $s3, 999   # 冗余，再次确保 $s3 被设为 999（但不应执行）

jump_target:
    li $s2, 77    # ✅ 执行：j 成功

    li $v0, 10
    syscall