.section .text
.global _start
_start:

    # Set up a base memory address using LUI + ADDI
    lui x1, 0x0001         # x1 = 0x10000000
    addi x1, x1, 4          # x1 = 0x10000000

    # AUIPC test
    auipc x2, 0             # x2 = current PC (used for checking)

    # ADDI
    addi x3, x0, 42         # x3 = 42

    # SLTI
    slti x4, x3, 100        # x4 = 1

    # ANDI, ORI, XORI
    andi x5, x3, 0x0F       # x5 = 42 & 0x0F = 10
    ori  x6, x3, 0xF0       # x6 = 42 | 0xF0 = 0xFA
    xori x7, x3, 0xFF       # x7 = 42 ^ 0xFF = 0xD5

    # SLLI, SRLI, SRAI
    slli x8, x3, 2          # x8 = 42 << 2 = 168
    srli x9, x3, 1          # x9 = 42 >> 1 = 21
    srai x10, x3, 1         # x10 = 42 >> 1 = 21 (signed)

    # ADD, SUB, AND, OR, XOR
    add x11, x5, x6         # x11 = 10 + 250 = 260
    sub x12, x6, x5         # x12 = 250 - 10 = 240
    and x13, x6, x7         # x13 = x6 & x7 = 0xd0
    or  x14, x6, x7         # x14 = x6 | x7
    xor x15, x6, x7         # x15 = x6 ^ x7

    # SLT, SLTU
    slt x16, x6, x7         # signed
    sltu x17, x6, x7        # unsigned

    # Store/Load
    sw x3, 0(x1)            # Mem[0x10000000] = 42
    lw x18, 0(x1)           # x18 = Mem[0x10000000]

    # Branch (BEQ), using known value in x3, x18
    beq x3, x18, label1

    # If not branched, store 0xdead into Mem[4]
    addi x19, x0, 0xAD
    sw x19, 4(x1)

label1:
    jal x20, label2         # Jump over next store

    # Should be skipped
    addi x21, x0, 0xFF
    sw x21, 8(x1)

label2:
    # JALR back to x2 (return to auipc point + offset)
    addi x22, x2, 16
    jalr x0, 0(x22)         # PC = x22 (jump to PC+16)