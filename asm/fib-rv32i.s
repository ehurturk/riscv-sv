.section .text
.globl _start
.extern putchar

fib:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw a0, 0(sp)

    li t0, 1
    ble a0, t0, .Lbase

    mv s0, a0
    addi a0, s0, -1
    call fib
    mv s1, a0

    addi a0, s0, -2
    call fib
    add a0, a0, s1

    j .Ldone

.Lbase:
    li a0, 1

.Ldone:
    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

_start:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)

    li a0, 4
    call fib

    addi a0, a0, 48
    call putchar

    li a0, 10
    call putchar

    li a0, 0
    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret
