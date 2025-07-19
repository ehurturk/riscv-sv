.section __TEXT,__text
.globl _main
.extern _putchar

fib:
    movl $1, %eax
    cmpl $1, %edi
    jle .L1

    pushq %r14
    pushq %rbx
    pushq %rdi

    movl %edi, %ebx
    
    leal -1(%rdi), %edi
    call fib

    movl %eax, %r14d
    leal -2(%rbx), %edi
    call fib

    addl %eax, %r14d
    movl %r14d, %eax

    popq %rdi
    popq %rbx
    popq %r14
    ret

.L1:
    ret

_main:
    pushq %rbp
    movq %rsp, %rbp 

    pushq %rbx
    pushq %rdi

    movl $4, %edi
    call fib

    movl %eax, %ebx
    addl $'0', %ebx

    movl %ebx, %edi   # print result into stdout
    call _putchar

    movl $'\n', %edi  #  print '\n'
    call _putchar
    
    popq %rdi
    popq %rbx
    popq %rbp
    
    movq $0x2000001, %rax
    movq $0, %rdi

    syscall