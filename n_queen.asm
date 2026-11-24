section .data
    msg_read_n db "Enter you'r n*n board: "
    msg_value_to_big db "You'r value enter is too big pls max 9 digits"
    msg_allocation_fail db "Pls retry allocation failed"
    
    n dq 0
    queen_array dq 0

    line dq 0
    column dq 0
    num_solve dq 0

section .bss
    read_buff resb 10 
    
section .text
    global _start
    
_start:
    call read_input
    call allocation

    ; Init R10 = index
    mov r10, 0
    mov r8, [queen_array]
    call setup_array_queen

    ; setup column rax
    ; setup param n
    mov rdi, [n]
    mov rax, 0
    call run

    ; print num_solve
    mov rax, [num_solve]
    call print_number
    
    ; END
    call exit

read_input:
    ; Print msg_read_n
    mov rdi, 1
    mov rsi, msg_read_n
    mov rdx, 23
    call print

    ; Syscall read get n
    mov rax, 0
    mov rdi, 0
    mov	rsi, read_buff
    mov	rdx, 10
    syscall

    ; Convert buff char* to int
    mov r8, 0
    mov r10, 0
    call convert_buff_int
    ret

convert_buff_int:
    cmp r8, 10
    je print_to_big_buff
    
    ; Get one char read_buff convert to int 
    mov r9b, [read_buff + r8]
    sub r9b, '0'
    imul r10, 10
    
    ; Convert reg 9 to dq registre 64 bits
    movzx r9, r9b
    add r10, r9
    inc r8
    
    ; Verif if read_buff is end
    cmp byte [read_buff + r8], 10
    jne convert_buff_int

    mov [n], r10
    ret
    
print_to_big_buff:
    mov rdi, 2
    mov rsi, msg_value_to_big
    mov rdx, 45

    call print
    call exit
    
print:
    ; Print value in rsi and rdx size
    mov rax, 1
    syscall
    ret

print_number:
    ; rax number input
    cmp rax, 10
    jge .divide

    add rax, '0'
    push rax ; set on the top of stack 
    
    mov rdi, 1
    mov rsi, rsp ; get the address on the stop of stack for print
    mov rdx, 1
    call print

    pop rax
    ret

    .divide:
    mov rdx, 0
    mov rbx, 10
    div rbx

    push rdx
    call print_number
    pop rsi

    add rsi, '0'
    push rsi ; set on the top of stack 
    mov rsi, rsp ; get the address on the stop of stack for print

    mov rdi, 1
    mov rdx, 1
    call print

    pop rsi
    ret

setup_array_queen:  
    ; r10 = index
    ; r11 = ptr my_array
    mov dword [r8 + r10 * 4], -1
    add r10, 1

    cmp r10, [n]
    jne setup_array_queen
    ret
    
allocation: 
    ; Get current break address with brk syscall
    mov rax, 12
    mov rdi, 0
    syscall

    mov r9, rax
    
    ; Allocate n memory for queen_array
    mov r10, [n]
    imul r10, 4
    add rax, r10
    mov rdi, rax
    mov rax, 12
    syscall

    ; Verif if allocation fail & exit program
    cmp r10, rax
    je allocation_fail

    ; Set new ptr on my queen array
    mov [queen_array], r9    
    ret

allocation_fail:
    mov rdi, 1
    mov rsi, msg_allocation_fail
    mov rdx, 27
    
    call exit

run:
    ; rax column
    ; rdi n
    ; rsi line
    cmp rax, rdi
    jge add_solve

    mov rsi, -1

    ; test all line one by one on n
    .run_loop:
    inc rsi
    cmp rsi, rdi
    ; end loop
    jge .done

    ; verif if on specific column and line another queen block
    call verif
    cmp r9, 0
    je .run_loop

    ; create new queen with line stock in registry rsi and get in 32 bits
    mov dword [r8 + rax * 4], esi

    ; push value on the top of the stack for keep integrity of recursion
    push rax
    push rsi

    inc rax
    call run

    ; get the saved value on the top of the stack is rsi because is the last add
    pop rsi
    pop rax

    ; redifine last queen empty
    mov dword [r8 + rax * 4], -1
    
    jmp .run_loop

    .done:
    ret

verif:
    ; r8 queen
    ; rax column
    ; rsi line
    ; rdx all other column < column
    ; r9 result verif

    mov rdx, -1
    
    .verif_loop:
    inc rdx

    ; test if loop finish if finish return 1 no queen block
    cmp rdx, rax
    jge .verif_yes 

    ; condition if no queen on this colmun
    mov r10d, dword [r8 + rdx * 4]
    cmp r10d, -1
    je .verif_loop

    ; condition if one queen on this colmun
    cmp r10d, esi
    je .verif_no

    ; condition if one queen in the diagonal
    mov r10d, dword [r8 + rdx * 4]
    mov r11d, esi
    sub r11d, r10d
    cmp r11d, 0
    jge .positif1
    neg r11d
    .positif1
    mov r10d, r11d

    mov r11, rax
    sub r11, rdx
    cmp r11, 0
    jge .positif
    neg r11
    .positif

    ; if queen in diagonal return 0
    cmp r11, r10
    je .verif_no

    ; continue loop
    jmp .verif_loop

    .verif_no
        mov r9, 0
        ret
    .verif_yes:
        mov r9, 1
        ret

add_solve:
    inc qword [num_solve]
    ret

exit:
    mov rax, 60
    mov rdi, 0
    syscall
