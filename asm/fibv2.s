.text
.globl _start

_start:
    # Initialize memory pointer using LUI (Load Upper Immediate)
    lui s0, 0x10000           # s0 = 0x10000000 (data section base)
    
    # Store first two Fibonacci numbers (F0=0, F1=1)
    addi t1, zero, 0          # t1 = F0 = 0
    addi t2, zero, 1          # t2 = F1 = 1
    sw t1, 0(s0)              # Store F0 at [0x10000000]
    sw t2, 4(s0)              # Store F1 at [0x10000004]
    
    # Setup loop variables
    addi s1, s0, 8            # s1 = current storage pointer (s0 + 8)
    addi t0, zero, 8           # t0 = loop counter (8 iterations)
    
    # Call Fibonacci function using JAL
    jal ra, fib_loop          # Jump to fib_loop, save return address in ra
    
    # Infinite loop using AUIPC/JALR for control flow test
finish:
    auipc ra, 0               # ra = PC (current instruction address)
    jalr zero, ra, 0          # Jump to self (PC + 0) - tests AUIPC/JALR

# Fibonacci computation loop
fib_loop:
    add t3, t1, t2            # t3 = F(n-2) + F(n-1)
    sw t3, 0(s1)              # Store new Fibonacci number
    addi t1, t2, 0            # Update F(n-2) = F(n-1)
    addi t2, t3, 0            # Update F(n-1) = F(n)
    addi s1, s1, 4            # Increment memory pointer
    addi t0, t0, -1           # Decrement loop counter
    
    # Branch instruction test
    bne t0, zero, fib_loop    # Loop if counter != 0
    
    # Return using JALR
    jalr zero, ra, 0          # Return to caller