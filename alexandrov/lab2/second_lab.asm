TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	JMP BEGIN
	
EOL	EQU '$'
eolf db 0DH,0AH,EOL
Not_Av_Memory db 'Adress of a segment with the first bye of inaccessible memory byte:', EOL
Not_Av_Memory_NL db '     ',EOL
Env_Adress db 'Address of an environment segment:',EOL
Env_Adress_NL db '    ',EOL
Tail db 'Tail:',EOL
Tail_NL db 64 DUP(' '),EOL
No_Tail db 'Has no tail',EOL
Main_Content db 'The environment content:',0DH,0AH,EOL
Loaded_Module_Path db 'The loaded module path:',0DH,0AH,EOL

PRINT proc near
	mov AH,09h
	int 21h
	ret
PRINT endp

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

;перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: 
	div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: 
	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

PRINT_MEMORY_STATEMENT proc near
	push ax
	push di
	push dx
	
	mov ax,ss:[2]
	mov di, offset Not_Av_Memory_NL+3
	call WRD_TO_HEX
	mov dx, offset Not_Av_Memory
	call PRINT
	mov dx, offset eolf
	call PRINT
	mov dx , offset Not_Av_Memory_NL
	call PRINT
	mov dx, offset eolf
	call PRINT
	
	pop dx
	pop di
	pop ax
	ret
PRINT_MEMORY_STATEMENT ENDP

SHOW_ENVIRONMENT_ADDRES PROC near
	push ax
	push di
	push dx
	
	mov ax,ss:[2Ch]
	mov di, offset Env_Adress_NL+3
	call WRD_TO_HEX
	mov dx, offset Env_Adress
	call PRINT
	mov dx, offset eolf
	call PRINT
	mov dx, offset Env_Adress_NL
	call PRINT
	mov dx, offset eolf
	call PRINT
	
	pop dx
	pop di
	pop ax
	ret
SHOW_ENVIRONMENT_ADDRES ENDP

PRINT_CL PROC near
	push cx
	push dx
	push bx
	
	xor ch,ch
	mov cl,ss:[80h]
	cmp cl,0
	jne CL_Tail
	mov dx, offset No_Tail
	call PRINT
	mov dx, offset eolf
	call PRINT
	pop bx
	pop dx
	pop cx
	ret
CL_Tail:
	mov dx, offset Tail
	call PRINT	
	mov bp, offset Tail_NL
	PRINT_SYMBOL:
		mov di,cx
		mov bl,ds:[di+80h]
		mov ds:[bp+di-2],bl
	loop PRINT_SYMBOL
	mov dx, offset Tail_NL
	call PRINT
	pop bx
	pop dx
	pop cx
	ret

PRINT_CL ENDP

SHOW_ENVIRONMENT PROC near
	push ax
	push es
	push bp
	push dx

	mov ax,ss:[44]
	mov es,ax
	xor bp,bp
ENV_FIRST:
	cmp word ptr es:[bp],1
	je PE_exit1
	cmp byte ptr es:[bp],0
	jne ENV_SECOND
	mov dx, offset eolf
	call PRINT
	inc bp
ENV_SECOND:
	mov dl,es:[bp]
	mov ah,2
	int 21h
	inc bp
	jmp ENV_FIRST
	PE_exit1:
	add bp,2
	mov dx, offset eolf
	call PRINT
	mov dx, offset Loaded_Module_Path
	call PRINT
ENV_THIRD:
	cmp byte ptr es:[bp],0
	je ENV_FINISH
	mov dl,es:[bp]
	mov ah,2
	int 21h
	inc bp
	jmp ENV_THIRD	
ENV_FINISH:
	pop dx
	pop bp
	pop es
	pop ax
	ret
SHOW_ENVIRONMENT ENDP

BEGIN:
	mov dx, offset eolf
	call PRINT
	call PRINT_MEMORY_STATEMENT
	mov dx, offset eolf
	call PRINT	
	call SHOW_ENVIRONMENT_ADDRES
	mov dx, offset eolf
	call PRINT	
	call PRINT_CL
	mov dx, offset eolf
	call PRINT
	mov dx, offset Main_Content
	call PRINT
	call SHOW_ENVIRONMENT
	mov dx, offset eolf
	call PRINT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START