%macro FindFile 2
    ; %1 = Filename, %2 = Load Segment
    ;push bp
    ;mov bp,sp
    ;push ax
    ; The root directory will be loaded in a higher segment.
    ; Set ES to this segment.
    mov ax,%2 ; load segment in ax
    mov es,ax
  
    ; the number of sectors that the root directory occupies
    ; is equal to its max number of entries, times 32 bytes
    ; per entry, divided by sector size
    ; eg (32 * RootSize) / 512
    ; this normally yields 14 sectors on a fat12 disk
    ; we calculate this total, then store it in cx for later use in a loop
    
    mov ax,32
    xor dx,dx
    mov bx,[RootSize]
    mul bx
    mov bx,[SectSize]
    div bx ; divide (dx:ax,sectsize) to (ax,dx)
    mov cx,ax
    mov [RootSectors],cx ; store number of sectors in RootSectors

    ; Calculate start sector root directory
    ; RootStart = number of FAT tables * sectors per FAT
    ;           + number of hidden sectors
    ;           + number of reserved sectors
    xor ax,ax ; find the root directory
    mov al,[FATCount] ; ax = number of fat tables
    mov bx,[FATSize] ; bx = sectors per fat
    mul bx ; ax = # FAT's * sectors per FAT
    add ax,[HiddenSect] ; add hidden sectors to ax
    adc ax,[HiddenSect+2] ; ???
    add ax,[ReservedSectors] ; add reserved sectors to ax
    mov [RootStart],ax ; RootStart is now the number of the first root sector

    ; Load a sector from the root directory
    ; If sector reading fails, a reboot will occur
    %%read_next_sector:
        push cx
        push ax
        xor bx,bx
        call ReadSector

    %%check_entry:
        mov cx,11 ; directory entry filenames are 11 bytes
        mov di,bx ; es:di = Directory entry address
        mov si,%1 ; ds:si = address of filename we are looking for
        repz cmpsb ; compare filename to memory
        je %%found_file ; if found, jump to file_found
        add bx,32h ; move to entry, entries are 32 bytes
        cmp bx,[SectSize] ; have we moved out of the sector yet?
        jne %%check_entry

        pop ax
        inc ax ; check next sector when we loop again
        pop cx
        loopnz %%read_next_sector
        jmp BootFailure
    
    %%found_file:
        ; the directory entry stores the first cluster number of the file
        ; at byte 26 (1ah). BX is still pointing to the address of the start
        ; of the directory entry, so we will go on from there
        ; read cluster number from memory:
        mov ax,[es:bx+01ah]
        mov [FileStart],ax
    %endmacro

    %macro ReadFAT 1
        ; The FAT will be loaded in a special segment
        ; set ES to this segment
        mov ax,%1
        mov es,ax

        ; calculate offset of FAT
        mov ax,[ReservedSectors] ; add reserved sectors to ax
        add ax,[HiddenSect] ; add hidden sectors to ax
        adc ax,[HiddenSect+2] ; I realy don't know what this does - seems to do something with a 32 bit value
        
        ; read all FAT sectors into memory
        mov cx,[FATSize] ; number of sectors in FAT
        xor bx,bx ; memory offset to read into (es:bx)

        %%read_next_fat_sector:
            push cx
            push ax
            call ReadSector
            pop ax
            pop cx
            inc ax
            add bx,[SectSize]
            loopnz %%read_next_fat_sector
    %endmacro

    ; 1 = LoadSegment; 2 = FATSegment
    %macro ReadFile 2
        mov ax,%1 ; 1000h
        mov es,ax

        ; Set memmory offset for loading to 0
        xor bx,bx ; so buffer address is 1000:0

        ; Set memory segment for FAT
        mov cx,[FileStart]

        %%read_file_next_sector:
            ; locate sector
            mov ax,cx ; sector to read is equal to current FAT entry
            add ax,[RootStart] ; plus the start of the root directory
            add ax,[RootSectors] ; plus the size of the root directory
            sub ax,2 ; but minus 2 ??

            ; read sector
            push cx ; read a sector from disk, but save cx - it contains our FAT entry
            call ReadSector
            pop cx
            add bx,[SectSize] ; move memory pointer to next location

            ; get next sector from FAT
            push ds ; make DS:SI point to fat table in memory
            mov dx,%2
            mov ds,dx

            mov si,cx ; make SI point to the current FAT entry
            mov dx,cx ; (offset is entry value * 1.5 bytes)
            shr dx,1
            add si,dx

            mov dx,[ds:si] ; read the FAT entry from memory
            test cx,1 ; see which way to shift, see if current cluster is odd
            jnz %%read_next_cluster_odd 
            and dx,0fffh ; if not, mask out upper 4 bits
            jmp %%read_next_file_cluster_done
            
        %%read_next_cluster_odd: ; if it is odd, shift the new cluster 4 to the right
            shr dx,4

        %%read_next_file_cluster_done:
            pop ds ; restore ds to the normal data segment
            mov cx,dx ; store the new FAT entry in CX
            cmp cx,0ff8h ; if the next FAT entry is greater or equal
            jl %%read_file_next_sector ; to 0xff8, then we have reached end-of-file
    %endmacro

SectorsPerTrack dw 9
NumHeads dw 2
SectSize dw 0200h
RootSize dw 224
RootSectors dw 0
RootStart dw 0
FileStart dw 0
FATCount db 2
FATSize dw 9
HiddenSect dd 0
ReservedSectors dw 1