.text
.globl main
main:
    # Step 1: Store the 4-byte data (0x11, 0x22, 0x33, 0x44) to 0x800
    # Construct the word: 0x44332211 (so that in little-endian memory it becomes [0x11,0x22,0x33,0x44])
    ori $t9, $zero, 0x2211      # low 16 bits
    ori $t8, $zero, 0x4433      # high 16 bits
    sll $t8, $t8, 16            # shift high to upper half
    or  $t7, $t8, $t9           # combine: 0x44332211

    # Construct address 0x800 (no lui needed)
    ori $t0, $zero, 0x800       # $t0 = 0x800

    # Store the word to 0x800
    sw $t7, 0($t0)              # writes 0x11,0x22,0x33,0x44 to 0x800~0x803

    # Step 2: Set up for checksum
    add $a0, $zero, $t0         # $a0 = 0x800 (data base)
    addi $a1, $zero, 4          # length = 4 bytes
    add $v0, $zero, $zero       # sum = 0
    add $t1, $zero, $zero       # i = 0

loop:
    # Load word containing byte i
    srl $t2, $t1, 2             # word_index = i / 4
    sll $t3, $t2, 2             # offset = word_index * 4
    addu $t4, $a0, $t3          # addr = base + offset
    lw $t5, 0($t4)              # load word

    # Extract byte i
    andi $t6, $t1, 3            # offset_in_word = i % 4
    sll $t6, $t6, 3             # bit_shift = offset * 8
    srlv $t7, $t5, $t6          # shift target byte to LSB
    andi $t7, $t7, 0xFF         # mask to 8 bits

    # Add to sum
    add $v0, $v0, $t7

    # i++
    addi $t1, $t1, 1

    # Loop if i < length
    beq $t1, $a1, done
    j loop

done:
    # Result is in $v0 = 0x11 + 0x22 + 0x33 + 0x44 = 0xAA (170)
j done                      # infinite loop