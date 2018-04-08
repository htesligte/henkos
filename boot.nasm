[ORG 0x7c00]

LOAD_SEGMENT equ 01000h
FAT_SEGMENT equ 0ee0h

[SECTION .text]
    global main

main:
	jmp short start
	nop

%include "bootsector.nasm"
%include "fat.nasm"

hang:
	jmp hang

start:
	cli
    xchg bx,bx
	mov [BootDrive],dl ; save what drive we booted from (should be 0x0)
	mov ax,cs ; cs = 0x0, that's where the boot sector is (0x07c00)
	mov ds,ax ; ds = cs = 0x0
	mov es,ax ; es = cs = 0x0
	mov ss,ax ; ss = cs = 0x0
	mov sp,7c00h ; stack grows down from offset 0x7c00 toward 0x0000
	sti

	; display "loading" message
	mov si,loadmsg
	call WriteString
	
	;  reset disk system
	; jump to BootFailure on error
    mov dl,[BootDrive] ; drive to reset
	xor ax,ax ; subfunction 0
	int 13h ; call interrupt 13h
	jc BootFailure ; display error if carry set (error)
	FindFile twostagefile,LOAD_SEGMENT
    ReadFAT FAT_SEGMENT
    ReadFile LOAD_SEGMENT,FAT_SEGMENT
	
    mov ax,word LOAD_SEGMENT
    mov es,ax
    mov ds,ax
    jmp LOAD_SEGMENT:0

	; end of loader for now, reboot
	call Reboot

BootFailure:
	mov si,diskerror
	call WriteString
	call Reboot

ReadSector:
    xor cx,cx ; set try count to 0
    
    .readsect:
        push ax ; store logical block
        push cx ; store try number
        push bx ; store data buffer offset

        ; calculate cylinder, head and sector
        ; cylinder = (LBA / SectorsPerTrack) / NumHeads
        ; Sector = (LBA mod SectorsPerTrack) + 1
        ; Head = (LBA / SectorsPerTrack) mod NumHeads
        mov bx,[SectorsPerTrack] ; get sectors per track
        xor dx,dx ; empty dx
        div bx  ; divide (dx:ax/bx to ax,dx)
                ; Quotient (ax) = LBA / SectorsPerTrack
                ; Remainder (dx) = LBA mod SectorsPerTrack

        inc dx ; Add 1 to remainder because sector (sector = (LBA mod SectorsPerTrack)+1)
        mov cl,dl ; store result in cl for int13h call

        mov bx,[NumHeads] ; get the number of heads
        xor dx,dx ; empty dx
        div bx  ; Divide (dx:ax/bx to ax,dx)
                ; Quotient (ax) = Cylinder
                ; Remainder (dx) = Head

        mov ch,al ; ch = cylinder
        xchg dh,dl ; dh = head number

        ; Call interrupt 13h, subfunction 2 to actually
        ; read the sector
        ; al = number of sectors
        ; ah = subfunction 2
        ; cx = sector number
        ; dh = head number
        ; dl = drive number
        ; es:bx = data buffer
        ; if it fails, the carry flag is set
        mov ax,0201h ; subfunction 2, read 1 sector
        mov dl,[BootDrive] ; from this drive
        pop bx ; restore data buffer offset
        int 013h
        jc .readfail

        ; on success, return to caller
        pop cx ; discard try number
        pop ax ; get logical block from stack   
        ret

    .readfail: ; read has failed, retry 4 times, then jump to boot failure
        pop cx ; get try number
        inc cx ; next try
        cmp cx, 4 ; stop at 4 tries
        je BootFailure

        ; reset disk system
        xor ax,ax
        int 013h

        ; get logical block from stack and retry
        pop ax
        jmp .readsect

%include "writestring.nasm"
%include "reboot.nasm"

loadmsg: db "Loading OS...",13,10,0
diskerror: db "Disk error. ",0
rebootmsg: db "Press any key to reboot.",13,10,0
twostagefile: db "2NDSTAGEBIN",0

times 510-($-$$) db 1
BootMagic: dw 0AA55h
