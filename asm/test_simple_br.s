_start:
    addi x1, x0, 10
    addi x2, x1, 0       # x2 = x1 (data dependency)
    beq x1, x2, success  
    addi x10, x0, 999    
    j end
success:
    addi x10, x0, 111    
end:
    nop
