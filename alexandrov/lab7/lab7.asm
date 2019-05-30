ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

DATA SEGMENT
	CANT_FREE			db 'Error when freeing memory: $'
	BAD_MCB 				db 'MCB is destroyed$'
	NOT_ENOUGH_MEM 			db 'Not enough memory for function processing$'
	BAD_ADRESS 		db 'Wrong addres of memory block$'
	UNKNOWN_ERROR			db 'Unknown error$'
	END_LINE 				db 13,10,'$'
	PATH_OVLS   				db 64	dup (0), '$'
	DTA_BUF       				db 43 DUP (?)
	SAVE_PSP  				dw 0
	PATH_TO   				db 'Path to the called file: ','$'
	NOT_FOUND_FILE    db 'The file was not found!',13,10,'$'
	NOT_FOUND_ROUTE	db 'The route was not found!',13,10,'$'
	BAD_ALLOC 			db 'Failed to allocate memory to load overlay!',13,10,'$'
	BLOCK_ADDR    			dw 0
	CALL_ADDR	  			dd 0
	BAD_LOAD_OVL			db 'The overlay was not been loaded: '
	NOT_EXIST_FUNC    db 'A non-existent function',13,10,'$'
	A_LOT_OF_FILES    db 'too many open files',13,10,'$'
	NO_ACESS    		db 'No access',13,10,'$'
	LOW_MEMORY    	db 'Low memory',13,10,'$'
	BAD_ENV   		db 'Incorrect environment',13,10,'$'
	OVL1	  				db 'modFirst.ovl',0
	OVL2	  				db 'modSecond.ovl',0	
DATA ENDS

CODE SEGMENT

PRINT_ANSWER PROC NEAR 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_ANSWER ENDP

FREE_MEM PROC 
	mov bx,ss
	add bx,10h
	mov ax,es
	sub bx, ax
	mov ah,4ah
	int 21h
	jnc FREED_MEM	
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
	je FREE_MEM_PRINT_ERROR
	mov dx,offset UNKNOWN_ERROR	
		
FREE_MEM_PRINT_ERROR:
	call PRINT_ANSWER
	mov dx,offset END_LINE
	call PRINT_ANSWER

	xor AL,AL
	mov AH,4Ch
	int 21H
	
FREED_MEM:
	ret
FREE_MEM ENDP

FIND_PATH PROC 
	push ds
	push dx
	mov dx, seg DTA_BUF 
	mov ds, dx
	mov dx,offset DTA_BUF 
	mov ah,1Ah 
	int 21h 
	pop dx
	pop ds
	push es 
	push dx
	push ax
	push bx
	push cx
	push di
	push si
	mov es, SAVE_PSP 
	mov ax, es:[2Ch] 
	mov es, ax
	xor bx, bx 
COPY_CONT: 
	mov al, es:[bx] 
	cmp al, 0h 
	je	END_FROM_CONT 
	inc bx	
	jmp COPY_CONT
END_FROM_CONT:
	inc bx	
	cmp byte ptr es:[bx], 0h 
	jne COPY_CONT 
	add bx, 3h 
	mov si, offset PATH_OVLS
COPY_PATH: 
	mov al, es:[bx] 
	mov [si], al 
	inc si 
	cmp al, 0h 
	je	END_FROM_COPY
	inc bx 
	jmp COPY_PATH
END_FROM_COPY:	
	sub si, 9h 
	mov di, bp 
ENTRY_WAY: 
	mov ah, [di] 
	mov [si], ah 
	cmp ah, 0h 
	je	STOP_ENTRY_WAY 
	inc di
	inc si
	jmp ENTRY_WAY
STOP_ENTRY_WAY:
	mov dx, offset PATH_TO
	call PRINT_ANSWER
	mov dx, offset PATH_OVLS
	call PRINT_ANSWER
	mov dx, offset END_LINE
	call PRINT_ANSWER
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	pop dx
	pop es
	ret
FIND_PATH ENDP

FIND_OVL_SIZE PROC
	push ds
	push dx
	push cx
	xor cx, cx 
	mov dx, seg PATH_OVLS 
	mov ds, dx
	mov dx, offset PATH_OVLS
	mov ah,4Eh 
	int 21h 
	jnc FILE_FOUND
	cmp ax,3
	je Error3
	mov dx, offset NOT_FOUND_FILE 
	jmp EXIT_FILE_ERROR
Error3:
	mov dx, offset NOT_FOUND_ROUTE 
EXIT_FILE_ERROR:
	call PRINT_ANSWER
	pop cx
	pop dx
	pop ds
	xor al,al
	mov ah,4Ch
	int 21H
	
FILE_FOUND: 
	push es
	push bx
	mov bx, offset DTA_BUF 
	mov dx,[bx+1Ch] 
	mov ax,[bx+1Ah] 
	mov cl,4h 
	shr ax,cl
	mov cl,12 
	sal dx, cl 
	add ax, dx 
	inc ax 
	mov bx,ax 
	mov ah,48h 
	int 21h 
	jnc SUCSESS_ALLOC 
	mov dx, offset BAD_ALLOC 
	call PRINT_ANSWER
	xor al,al
	mov ah,4Ch
	int 21h
SUCSESS_ALLOC:
	mov BLOCK_ADDR, ax 
	pop bx
	pop es
	pop cx
	pop dx
	pop ds
	ret
FIND_OVL_SIZE ENDP

CALL_OVL PROC 
	push dx
	push bx
	push ax
	mov bx, seg BLOCK_ADDR 
	mov es, bx
	mov bx, offset BLOCK_ADDR
	mov dx, seg PATH_OVLS 
	mov ds, dx	
	mov dx, offset PATH_OVLS	

	mov ax, 4B03h 
	int 21h
	push dx
	jnc OVL_NO_ERROR 
	mov dx, offset BAD_LOAD_OVL
	call PRINT_ANSWER
	cmp ax, 1 
	mov dx, offset NOT_EXIST_FUNC
	je OVL_ERROR_PRINT
	cmp ax, 2 
	mov dx, offset NOT_FOUND_FILE
	je OVL_ERROR_PRINT
	cmp ax, 3 
	mov dx, offset NOT_FOUND_ROUTE
	je OVL_ERROR_PRINT
	cmp ax, 4 
	mov dx, offset A_LOT_OF_FILES
	je OVL_ERROR_PRINT
	cmp ax, 5 
	mov dx, offset NO_ACESS
	je OVL_ERROR_PRINT
	cmp ax, 8 
	mov dx, offset LOW_MEMORY
	je OVL_ERROR_PRINT
	cmp ax, 10 
	mov dx, offset BAD_ENV
	je OVL_ERROR_PRINT
	mov dx, offset UNKNOWN_ERROR
OVL_ERROR_PRINT:
	call PRINT_ANSWER
	jmp OVL_RET
OVL_NO_ERROR:
	mov AX,DATA 
	mov DS,AX
	mov ax, BLOCK_ADDR
	mov word ptr CALL_ADDR+2, ax
	call CALL_ADDR 
	mov ax, BLOCK_ADDR
	mov es, ax
	mov ax, 4900h 
	int 21h
	mov AX,DATA 
	mov DS,AX
OVL_RET:
	pop dx
	mov es, SAVE_PSP
	pop ax
	pop bx
	pop dx
	ret
CALL_OVL ENDP

MAIN PROC FAR
	mov ax,DATA
	mov ds,ax
	mov SAVE_PSP, ES
	call FREE_MEM 
	mov bp, offset OVL1
	call FIND_PATH
	call FIND_OVL_SIZE 
	call CALL_OVL 
	mov bp, offset OVL2
	call FIND_PATH
	call FIND_OVL_SIZE 
	call CALL_OVL 
	xor al,al
	mov ah,4Ch 
	int 21h
MAIN ENDP
CODE ENDS
ASTACK SEGMENT STACK
	DW 80h DUP (?)
ASTACK ENDS
END MAIN