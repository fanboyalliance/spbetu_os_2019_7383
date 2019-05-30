INT_STACK SEGMENT
	DW 100h DUP(?)
INT_STACK ENDS

CODE SEGMENT	
ASSUME CS:CODE, DS:DATA, SS:ASTACK

ASTACK SEGMENT STACK
	DW 100h DUP(?)
ASTACK ENDS

DATA SEGMENT
	SET_INTERRUPT db 'Setup interrupt',13,10,36
	DEL_INTERRUPT db 'Uninstall interrupt',13,10,36
	ALREADY_SET db 'Interrupt is already set',13,10,36
	NOT_SET db 'Interrupt is not set',13,10,36
DATA ENDS

INTER PROC FAR
	jmp start
	SIGNATURE db 'KEYWRD'
	SAVE_IP DW 0
	SAVE_CS DW 0
	SAVE_PSP DW 0
	SAVE_SS dw 0
	SAVE_SP dw 0
	SAVE_AX dw 0
start:
	mov SAVE_AX, AX
	mov SAVE_SS,ss
	mov SAVE_SP,sp
	mov ax, seg INT_STACK
	mov ss, AX
	mov sp, 100h
	mov ax,SAVE_AX
	push ax
	push dx
	push ds
	push es
	in al,60h
	cmp al,01h
	je key
	pushf
	call dword ptr CS:SAVE_IP
	jmp ROUT_END
key:
	push ax
	in AL,61h 
	mov ah,al 
	or al,80h 
	out 61h,al 
	xchg ah,al 
	out 61h,al 
	mov al,20h 
	out 20h,al 
	pop ax
	
IN_BUFFER:
	mov ah,05h
	mov cl,'X'
	mov ch,00h
	int 16h
	or al,al
	jz ROUT_END
	
	CLI
	mov ax,es:[1Ah] 
	mov es:[1Ch], AX 
	STI 
	jmp IN_BUFFER 
	
ROUT_END:
	pop es
	pop ds
	pop dx
	pop ax 
	mov ss, SAVE_SS
	mov sp, SAVE_SP
	mov al,20h
	out 20h,al
	iret
F_ROUT:
INTER ENDP

SET_ROUT PROC near
	push ax
	push cx
	push bx
	push dx
	push ds
	mov ah, 35h
    mov al, 09h
    int 21h
    
    mov SAVE_IP, bx
    mov SAVE_CS, ES
	mov ax, SEG INTER
	mov dx, OFFSET INTER
	mov ds, AX
	mov ah, 25h
    mov al, 09h
    int 21h
    
    mov dx, OFFSET F_ROUT
    mov cl,4
    shr dx,cl
    inc dx
    add dx, CODE
    sub dx, SAVE_PSP
    mov ah, 31h
    int 21h
    pop ds
	pop dx
	pop bx
	pop cx
	pop ax
	ret
SET_ROUT ENDP

CHECK_FOR_DEL PROC near
	push di
	mov di, 81h
	cmp byte ptr [di+0], ' '
	jne UST
	cmp byte ptr [di+1], '/'
	jne UST
  	cmp byte ptr [di+2], 'u'
 	jne UST
  	cmp byte ptr [di+3], 'n'
  	jne UST
  	cmp byte ptr [di+4], 0Dh
  	jne UST
  	cmp byte ptr [di+5], 0h
  	jne UST
	pop di
	mov al,1
	ret
UST:
	pop di
	mov al,0
	ret
CHECK_FOR_DEL ENDP

CHECK_FOR_SET PROC near
	push ax
	push bx
	push es
	mov ah, 35h
    mov al, 09h
    int 21h	
    mov ax, OFFSET SIGNATURE
    sub ax, OFFSET INTER
	add bx, AX
	mov si, bx
	push ds 
	mov ax,es
	mov ds, AX
	cmp [si], 'EK'
    jne false
    add si,2
    cmp [si],  'WY'
    jne false
    add si,2
    cmp [si], 'DR'
    jne false
    pop ax
    mov ds, AX
    pop es
    pop bx
	pop ax
	mov al, 1
	ret
false:
	pop ax
    mov ds, AX
    pop es
    pop bx
	pop ax
	mov al, 0
	ret
CHECK_FOR_SET ENDP

DEL_ROUT PROC near
	push ax
	push dx
	mov ah, 35h
    mov al, 09h
    int 21h
    cli
    push ds
    mov dx, ES:SAVE_IP
    mov ax, ES:SAVE_CS
	mov ds, AX
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds
	mov es, ES:SAVE_PSP
	push es
    mov es, ES:[2Ch] 
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

	sti	
	pop dx
	pop ax
	ret
DEL_ROUT ENDP

MAIN PROC FAR
	push ds
    sub ax, AX
    push ax
    mov cs:SAVE_PSP, ES
	
	call CHECK_FOR_SET
	cmp al, 1
	je ROUT_SET
	
	call CHECK_FOR_DEL
	cmp al, 1
	je ROUT_NOT_SET
	mov dx, offset SET_INTERRUPT
	mov ax,DATA
    mov ds, AX
	mov ah, 9
	int 21h
	call SET_ROUT
	jmp FINISH
	
ROUT_NOT_SET:
	mov dx, offset NOT_SET
	mov ax,DATA
    mov ds, AX
	mov ah, 9
	int 21h
	jmp FINISH
	
ROUT_SET:
	call CHECK_FOR_DEL
	cmp al, 1
	je TO_DEL_ROUT
	
	mov dx, offset ALREADY_SET
	mov ax,DATA
    mov ds, AX
	mov ah, 9
	int 21h
	jmp FINISH
	
TO_DEL_ROUT:
	call DEL_ROUT
	mov dx, offset DEL_INTERRUPT
	mov ax, DATA
    mov ds, AX
	mov ah, 9
	int 21h
	jmp FINISH	
	
FINISH:	
	xor al,al
	mov ah,4ch
	int 21h

MAIN ENDP	
CODE ENDS
END MAIN