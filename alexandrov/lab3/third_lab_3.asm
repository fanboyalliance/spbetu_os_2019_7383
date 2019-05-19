TESTPC SEGMENT	
    ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
    ORG	100H
START: jmp BEGIN
	
HEADER		db	'  ADDR SIZE    NAME                 ',13,10,36
MCB_BLOCK	db	'0 0000 0000000                      ',13,10,36
FREE_MEM		db	'Free memory:             bytes ',13,10,'$'
EXPND_MEM		db	'Expanded memory:       KB   ',13,10,'$'

PRINT proc near
	mov AH,09h
	int 21h
	ret
PRINT endp

TETR_TO_HEX	PROC near
	and al,0Fh
	cmp al,09
	jbe NEXT
	add al,07
NEXT:
	add al,30h
	ret
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC near 
	push cx
	mov ah,al
	call TETR_TO_HEX
	xchg al,ah
	mov cl,4
	shr al,cl
	call TETR_TO_HEX  
	pop cx
	ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX PROC	near 
	push bx
	mov bh,ah
	call BYTE_TO_HEX
	mov [di],ah
	dec di
	mov [di],al
	dec di
	mov al,bh
	call BYTE_TO_HEX
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC	PROC near 
	push cx
	push dx
	xor ah,ah
	xor dx,dx
	mov cx,10
loop_bd: 
	div cx
	or dl,30h
	mov [si],dl
	dec si
	xor	dx,dx
	cmp ax,10
	jae loop_bd
	cmp al,00h
	je end_l
	or al,30h
	mov [si],al
end_l:	
	pop dx
	pop cx
	ret
BYTE_TO_DEC	ENDP

WRD_TO_DEC PROC near		
	push CX
	push DX
	mov CX,10
loop_b:
	div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX,DX
	cmp AX, 10
	jae loop_b
	cmp AL, 00h
	je endl
	or AL, 30h
	mov [SI], AL
endl:
	pop DX
	pop CX
	ret
WRD_TO_DEC ENDP

EXTENDED_MEMORY PROC near
	mov AL, 30h
	out 70h, AL
	in AL, 71h
	mov BL, AL
	mov AL, 31h
	out 70h, AL
	in AL, 71h
	mov bh, al
	mov ax, bx
	mov si, offset EXPND_MEM
	add si, 21
	mov dx, 0
	call WRD_TO_DEC
	mov dx, offset EXPND_MEM
	call PRINT
	ret
EXTENDED_MEMORY ENDP

FREE_MEMORY PROC near
	push es
	mov ah, 4ah
    mov bx, 0ffffh
	int 21h
	mov ax, bx
	mov si, offset FREE_MEM
	add si, 23
	mov dx, 0
	mov bx, 16
	mul bx
	call WRD_TO_DEC
	mov dx, offset FREE_MEM
	call PRINT
	pop es
	ret
FREE_MEMORY ENDP 

MCB PROC near 
	push es
    call CLEAR_ALLOC
	mov dx, offset HEADER
	call PRINT
    mov	cx, 48
    mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	mov bx, es
start_c:
	inc cl
	cmp cl, 60
	je end_c
	mov ax, es:[1]
    mov di, offset MCB_BLOCK
    mov [di], cl
	add di, 5
	call WRD_TO_HEX
	mov dx,0
	mov ax, es:[3]
    mov si, offset MCB_BLOCK
    add si,13
	mov dx,16
	mul dx
    call WRD_TO_DEC
    mov di, offset MCB_BLOCK
    add di, 15
    mov ax, es:[8]
    mov [di], ax
    mov ax, es:[10]
    mov [di+2], ax
    mov ax, es:[12]
    mov [di+4], ax
    mov ax, es:[14]
    mov [di+6], ax
    mov dx, offset MCB_BLOCK
	call PRINT
	mov ah, 5ah
	cmp es:[0], ah
	je end_c
	inc bx
	add bx, es:[3]
	mov es, bx
	jmp start_c
end_c:
	pop es
ret
MCB ENDP

CLEAR_ALLOC PROC near
	push bx
	push ax
	mov bx, offset f
	sar bx, 1
	sar bx, 1
	sar bx, 1
	sar bx, 1
	add bx, 20h
	mov ah, 4ah
	int 21h
	mov bx,1000h
	mov ah,48h
	int 21h
	pop ax
	pop bx
	ret
CLEAR_ALLOC ENDP

BEGIN:
	call FREE_MEMORY
	call EXTENDED_MEMORY
	call MCB
	xor al, al
	mov ah, 4ch
	int 21h
	
f:
TESTPC 	ENDS
END START
