[ORG 0x7c00]

SECTION .bss
	iBootDrive resb 0

SECTION .text
	global main

main:
	jmp short start
	nop

WriteString:
	lodsb ; load byte at ds:si into al (advancing si)
	or al,al ; test if character is 0 (end)
	jz WriteString_done ; jump to end if 0
	mov ah,0eh
	mov bx,9 ; set bh (page number to 0) and bl (attribute) to white (9)
	int 10h ; call bios interrupt
	jmp WriteString ; continue next character

WriteString_done:
 	ret
hang:
	jmp hang

Reboot:
	mov si,rebootmsg; load address of reboot message into si
	call WriteString ; display message on screen
	xor ax,ax ; subfunction 0
	int 16h ; call bios to wait for key
	jmp word 0FFFFh:0000 ; reboot
	ret

start:
	cli
	mov [iBootDrive],dl ; save what drive we booted from (should be 0x0)
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
 	mov dl,[iBootDrive] ; drive to reset
	xor ax,ax ; subfunction 0
	int 13h ; call interrupt 13h
	jc BootFailure ; display error if carry set (error)
	
	; end of loader for now, reboot
	call Reboot

BootFailure:
	mov si,diskerror
	call WriteString
	call Reboot


loadmsg: db "Loading OS...",13,10,0
diskerror: db "Disk error. ",0
rebootmsg: db "Press any key to reboot.",13,10,0
times 510-($-$$) db 0
BootMagic: dw 0AA55h
