Reboot:
	mov si,rebootmsg; load address of reboot message into si
	call WriteString ; display message on screen
	xor ax,ax ; subfunction 0
	int 16h ; call bios to wait for key
	jmp word 0FFFFh:0000 ; reboot
	ret