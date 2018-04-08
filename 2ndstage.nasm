[ORG 0x0]

[SECTION .text]
    LOAD_SEGMENT equ 02000h
    FAT_SEGMENT equ 0ee0h
    
    global main

    main:
        jmp short start
        nop

    kernelfile: db "KERNEL  BIN"
    rebootmsg: db "Press any key to reboot",13,10,0
    diskerror: db "Disk Error",13,10,0
    a20error: db "Please buy a pc that isn't older than 25 years",13,10,0
    a20loaded: db "A20 is enabled"
    idt:
        dw 2048 ; size of idt (256 entries of 8 bytes)
        dd 0h ; linear address of idt
    
    gdt:
        dw 24 ; size of gdt: 3 entries of 8 bytes 
        dd 2048 ; linear address of gdt

    start:
        call EnableA20
        call WriteString
        call Reboot
        ; FindFile kernelfile, LOAD_SEGMENT

    hang:
        jmp hang

    BootFailure:
        mov si,diskerror
        call WriteString
        call Reboot

%include "writestring.nasm"
%include "reboot.nasm"
%include "a20.nasm"
%include "fat.nasm"


times 1024 db 1