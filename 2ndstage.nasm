[ORG 0x0]

[SECTION .data]

[SECTION .text]
    global main

    main:
        mov ds,ax ; restore DS
        lea si,[msg]
        call WriteString
        call Reboot

    hang:
        jmp hang

    BootFailure:
        mov si,diskerror
        call WriteString
        call Reboot

    msg: db "2nd stage bootloader!",13,10,0
    rebootmsg: db "Press any key to reboot",0
    diskerror: db "Disk Error",13,10,0

%include "writestring.nasm"
%include "reboot.nasm"



times 1024 db 1