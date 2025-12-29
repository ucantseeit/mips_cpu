        .text
        .globl main

main:
        li   $6, 0               # error flag

        jal  test_jal

        la   $t0, test_jalr
        jalr $ra, $t0

        la   $t1, target_jr
        jr   $t1

        li   $6, 1

target_jr:
        # All tests passed
        j    test_done

test_jal:
        # Verify $ra is "somewhere ahead" (not zero, not obviously wrong)
        beq  $ra, $zero, fail
        jr   $ra

test_jalr:
        beq  $ra, $zero, fail
        jr   $ra

fail:
        li   $6, 1
        j    test_done

test_done:
        li   $v0, 10
        # syscall
