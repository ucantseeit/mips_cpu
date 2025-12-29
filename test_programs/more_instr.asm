        .text
        .globl main

main:
        li   $6, 0               # error flag: 0 = OK, 1 = error
        li   $8, -5              # $t0 = -5
        li   $9, 0               # $t1 = 0
        li   $10, 7              # $t2 = 7
        li   $11, 7              # $t3 = 7 (same as $t2)
        
lui_test:
        lui  $1, 0x1234          # $1 = 0x12340000

        # ##################################################
        # bne TESTS (Branch if Not Equal)
        # ##################################################

        # (1) bne $t0, $t2 (-5 vs 7) �� not equal �� should branch
        bne  $8, $10, bne_1_ok
        li   $6, 1
        j    test_done
bne_1_ok:
        # (2) bne $t2, $t3 (7 vs 7) �� equal �� should NOT branch
        bne  $10, $11, bne_2_fail
        # fall through = OK
        j    bne_3_test
bne_2_fail:
        li   $6, 1
        j    test_done

        # (3) bne $t2, $zero (7 vs 0) �� not equal �� should branch (bnez style)
bne_3_test:
        bne  $10, $zero, bne_3_ok
        li   $6, 1
        j    test_done
bne_3_ok:
        # (4) bne $t1, $zero (0 vs 0) �� equal �� should NOT branch
        bne  $9, $zero, bne_4_fail
        # fall through = OK
        j    blez_1_test
bne_4_fail:
        li   $6, 1
        j    test_done

        # ##################################################
        # blez TESTS (Branch if <= 0)
        # ##################################################

blez_1_test:
        # (5) blez $t0 (-5) should branch
        blez $8, blez_1_ok
        li   $6, 1
        j    test_done
blez_1_ok:
        # (6) blez $t1 (0) should branch
        blez $9, blez_2_ok
        li   $6, 1
        j    test_done
blez_2_ok:
        # (7) blez $t2 (7) should NOT branch
        blez $10, blez_3_fail
        j    blez_4_test          # success path
blez_3_fail:
        li   $6, 1
        j    test_done

        # (8) blez $zero (0) should branch
blez_4_test:
        blez $zero, blez_4_ok
        li   $6, 1
        j    test_done
blez_4_ok:

        # ##################################################
        # bgtz TESTS (Branch if > 0)
        # ##################################################

        # (9) bgtz $t2 (7) should branch
        bgtz $10, bgtz_9_ok
        li   $6, 1
        j    test_done
bgtz_9_ok:
        # (10) bgtz $t1 (0) should NOT branch
        bgtz $9, bgtz_10_fail
        j    bgtz_11_test        # success path
bgtz_10_fail:
        li   $6, 1
        j    test_done

        # (11) bgtz $t0 (-5) should NOT branch
bgtz_11_test:
        bgtz $8, bgtz_11_fail
        j    bgtz_12_test        # success path
bgtz_11_fail:
        li   $6, 1
        j    test_done

        # (12) bgtz $zero (0) should NOT branch
bgtz_12_test:
        bgtz $zero, bgtz_12_fail
        j    lui_test            # success path
bgtz_12_fail:
        li   $6, 1
        j    test_done

test_done:
        li   $v0, 10             # exit syscall
        syscall
