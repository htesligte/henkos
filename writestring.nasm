WriteString:
	lodsb ; load byte at ds:si into al (advancing si)
	or al,al ; test if character is 0 (end)
	jz WriteString_done ; jump to end if 0
	mov ah,0eh
	mov bx,9 ; set bh (page number to 0) and bl (attribute) to white (9)
	int 10h ; call bios interrupt
	xchg bx,bx
	jmp WriteString ; continue next character

WriteString_done:
 	ret
