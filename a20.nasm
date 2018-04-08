EnableA20:
    call CheckA20
    cmp ax,0 ; if ax is 0 a20 is enabled
    jne .done
    call SetA20BIOS
    call CheckA20
    cmp ax,0
    jne .done
    call SetA20Keyboard
    call CheckA20
    cmp ax,0
    jne .done
    call A20FastGate
    call CheckA20
    cmp ax,0
    jne .done
    .fail:
        lea si, [a20error] ; show message that the user has an ancient pc without a20
        call WriteString ; of course this should never happen on any modern pc
        call Reboot
    .done:
        lea si, [a20loaded]
        call WriteString
        ret

CheckA20:
    xchg bx,bx
    pushf ; save all registers that we are going to overwrite
    push ds
    push es
    push di
    push si
    
    cli ; prevent interrupts

    xor ax,ax ; set es:di = 0000:0500
    mov es,ax
    mov di,500h

    mov al,byte [es:di] ; save byte at es:di on the stack
    push ax

    not ax ; set ds:si = ffff:510
    mov ds,ax
    mov si,510h

    mov al,byte [ds:si] ; save byte at ds:si on stack
    push ax

    mov byte [es:di],0h ; [es:di] = 0x00
    mov byte [ds:si],0ffh ; [ds:si] = 0xff

    cmp byte [es:di],0ffh ; if the value on [es:di] changed, a20 is not enabled

    pop ax ; restore all data
    mov byte [ds:si],al
    pop ax
    mov byte [es:di],al
    
    mov ax,0 
    je .exit ; return 0 when a20 is not enabled
    
    mov ax,1 ; return 1 when a20 is enabled

    .exit:
        pop si
        pop di
        pop es
        pop ds
        popf
        ret

SetA20BIOS:
    xchg bx,bx
    ret

SetA20Keyboard:
    xchg bx,bx
    ret

A20FastGate:
    xchg bx,bx
    ret



