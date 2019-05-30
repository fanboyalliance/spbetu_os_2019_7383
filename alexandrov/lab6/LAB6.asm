
ASTACK SEGMENT STACK
	dw 80h dup (?) 
ASTACK ENDS

DATA SEGMENT
	CANT_FREE		db 'Error when freeing memory: $'
	BAD_MCB 			db 'MCB is destroyed$'
	NOT_ENOUGH_MEM 		db 'Not enough memory for function processing$'
	BAD_ADRESS 	db 'Wrong addres of memory block$'
	UNKNOWN_ERROR		db 'Unknown error$'
		
	BAD_NUM			db 'Function number is wrong$'
	NOT_FOUND_FILE	db 'File is not found$'
	BAD_DISK				db 'Disk error$'
	NOT_ENOUGH_MEM2			db 'Not enough memory$'
	BAD_ENV			db 'Wrong environment string$'
	BAD_FORMAT		db 'Wrong format$'

	NORMAL_END	db 'Normal end$'
	HOTKEY_END	db 'End by Ctrl-C$'
	ERROR_END	db 'End by device error$'
	FUNC_END		db 'End by 31h function$'
	UNKNOWN_END	db 'End by unknown reason$'
	CODE_END	db 'End code: $'
		
	END_LINE db 13,10,'$'
	P_BLOCK 	dw 0 
				dd ? 
				dd 0 
				dd 0 
	PATH	db 20h dup(0)
	SAVE_SS dw 0
	SAVE_SP dw 0
DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

PRINT_ANSWER PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT_ANSWER ENDP

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

FREE_MEM PROC
		mov ax,ASTACK 
		mov bx,es
		sub ax,bx 
		add ax,10h 
		mov bx,ax
		mov ah,4Ah
		int 21h
		jnc MEM_FREED	

		mov dx,offset CANT_FREE
		call PRINT_ANSWER
		cmp ax,7
		mov dx,offset BAD_MCB
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset NOT_ENOUGH_MEM
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset BAD_ADRESS
		
		FREE_MEM_PRINT_ERROR:
		call PRINT_ANSWER
		mov dx,offset END_LINE
		call PRINT_ANSWER
	
		xor AL,AL
		mov AH,4Ch
		int 21H
	
	MEM_FREED:
	ret
FREE_MEM ENDP

MAKE_BLOCK PROC
	mov ax, es:[2Ch]
	mov P_BLOCK,ax 
	mov P_BLOCK+2,es 
	mov P_BLOCK+4,80h 
	ret
MAKE_BLOCK ENDP

START_PROGRAM PROC
	mov dx,offset END_LINE
	call PRINT_ANSWER
	mov es,es:[2ch]
	mov si,0
next1:
	mov dl,es:[si]
	cmp dl,0
	je end_path
	inc si
	jmp next1
	
end_path:
	inc si
	mov dl,es:[si]
	cmp dl,0
	jne next1
	add si,3
	lea di,PATH
	
next2:
	mov dl, es:[si]
	cmp dl,0
	je end_copy
	mov [di],dl
	inc di
	inc si
	jmp next2
	
end_copy:
	sub di,8
	mov [di], byte ptr 'l'	
	mov [di+1], byte ptr 'a'
	mov [di+2], byte ptr 'b'
	mov [di+3], byte ptr '2'
	mov [di+4], byte ptr '.'
	mov [di+5], byte ptr 'c'
	mov [di+6], byte ptr 'o'
	mov [di+7], byte ptr 'm'
	mov dx,offset PATH
	mov SAVE_SP, sp
	mov SAVE_SS, ss
	mov ax,ds
	mov es,ax
	mov bx,offset P_BLOCK
	mov ax,4b00h
	int 21h
	jnc NO_ERRORS
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov SS,SAVE_SS
	mov SP,SAVE_SP
	cmp ax,1
	mov dx,offset BAD_NUM
	je PRINT_ERR
	cmp ax,2
	mov dx,offset NOT_FOUND_FILE
	je PRINT_ERR
	cmp ax,5
	mov dx,offset BAD_DISK
	je PRINT_ERR
	cmp ax,8
	mov dx,offset NOT_ENOUGH_MEM2
	je PRINT_ERR
	cmp ax,10
	mov dx,offset BAD_ENV
	je PRINT_ERR
	cmp ax,11
	mov dx,offset BAD_FORMAT	
	je PRINT_ERR
	mov dx,offset UNKNOWN_ERROR
PRINT_ERR:
	call PRINT_ANSWER
	mov dx,offset END_LINE
	call PRINT_ANSWER
	xor al,al
	mov ah,4Ch
	int 21H
NO_ERRORS:
	mov ax,4d00h
	int 21h
	cmp ah,0
	mov dx,offset NORMAL_END
	je PRINT_NORMAL_END
	cmp ah,1
	mov dx,offset HOTKEY_END
	je PRINT_NORMAL_END
	cmp ah,2
	mov dx,offset ERROR_END
	je PRINT_NORMAL_END
	cmp ah,3
	mov dx,offset FUNC_END
	je PRINT_NORMAL_END
	mov dx,offset UNKNOWN_END
PRINT_NORMAL_END:
	call PRINT_ANSWER
	mov dx,offset END_LINE
	call PRINT_ANSWER

	mov dx,offset CODE_END
	call PRINT_ANSWER
	call BYTE_TO_HEX
	push ax
	mov ah,2
	mov dl,al
	int 21h
	pop ax
	xchg ah,al
	mov ah,2
	mov dl,al
	int 21h
	mov dx,offset END_LINE
	call PRINT_ANSWER
	ret
START_PROGRAM ENDP

MAIN PROC FAR
	mov ax,data
	mov ds,ax
	call FREE_MEM
	call MAKE_BLOCK
	call START_PROGRAM
	xor al,al
	mov ah,4Ch
	int 21H
	ret
MAIN ENDP
CODE ENDS

END MAIN
