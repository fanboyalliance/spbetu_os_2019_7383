ASTACK SEGMENT STACK
	dw 100h dup (?)
ASTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

DATA SEGMENT
	SET_INTERRUPT db 'Setup interrupt','$'
	DEL_INTERRUPT db 'Uninstall interrupt',0DH,0AH,'$'
	ALREADY_SET db 'Interrupt is already set',0DH,0AH,'$'
	NOT_SET db 'Interrupt is not set',0DH,0AH,'$'
DATA ENDS

ROUT PROC FAR
	jmp nextJump
	SIGNATURE dw 0ABCDh
	SAVE_PSP dw 0 
	SAVE_IP dw 0 
	SAVE_CS dw 0
	COUNT dw 0 
	OUTPUT db 0
	SAVE_SS DW 0
	SAVE_AX DW ?
	SAVE_SP DW 0
	INT_STACK DW 100 dup (?)
nextJump:
	mov SAVE_SS,SS
	mov SAVE_SP,SP
	mov SAVE_AX,AX
	mov AX,seg INT_STACK
	mov SS,AX
	mov SP,0
	mov AX,SAVE_AX
	
	push ax
	push bp
	push es
	push ds
	push dx
	push di
	
	mov ax,cs
	mov ds,ax 
	mov es,ax 
	mov ax,CS:COUNT
	add ax,1
	mov CS:COUNT,ax
	mov di,offset OUTPUT+34
	call WRD_TO_HEX
	mov bp,offset OUTPUT
	call outputBP
	
	pop di
	pop dx
	pop ds
	pop es
	pop bp
	mov al,20h
	out 20h,al
	pop ax
	mov AX,SAVE_SS
	mov SS,AX
	mov AX,SAVE_AX
	mov SP,SAVE_SP
	iret
ROUT ENDP 

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: 
	add AL,30h
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

outputBP PROC near
	push ax
	push bx
	push dx
	push cx
	mov ah,13h
	mov al,0
	mov bl,09h
	mov bh,0
	mov dh,4
	mov dl,22
	mov cx,35
	int 10h  
	pop cx
	pop dx
	pop bx
	pop ax
	ret
outputBP ENDP

LAST_BYTE:
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP

CHECK_ROUT PROC
	mov ah,35h
	mov al,1ch
	int 21h
	mov si,offset SIGNATURE
	sub si,offset ROUT
	mov ax,0ABCDh
	cmp ax,ES:[BX+SI]
	je ROUT_EST
	call SET_ROUT
	jmp CHECK_END
ROUT_EST:
	call REMOVE_ROUT
CHECK_END:
	ret
CHECK_ROUT ENDP

SET_ROUT PROC
	mov ax,SAVE_PSP 
	mov es,ax 
	cmp byte ptr es:[80h],0
		je UST
	cmp byte ptr es:[82h],'/'
		jne UST
	cmp byte ptr es:[83h],'u'
		jne UST
	cmp byte ptr es:[84h],'n'
		jne UST
	mov dx,offset NOT_SET
	call PRINT
	ret
	
UST:
	call SAVE_OLD_INTR	
	mov dx,offset SET_INTERRUPT
	call PRINT
	push ds
	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	pop ds
	mov dx,offset LAST_BYTE
	mov cl,4
	shr dx,cl
	add dx,1
	add dx,20h
	xor AL,AL
	mov ah,31h
	int 21h
	xor AL,AL
	mov AH,4Ch
	int 21H
SET_ROUT ENDP

REMOVE_ROUT PROC
	push dx
	push ax
	push ds
	push es

	mov ax,SAVE_PSP 
	mov es,ax
	cmp byte ptr es:[80h],0
		je REMOVE_LAST
	cmp byte ptr es:[82h],'/'
		jne REMOVE_LAST
	cmp byte ptr es:[83h],'u'
		jne REMOVE_LAST
	cmp byte ptr es:[84h],'n'
		jne REMOVE_LAST
	mov dx,offset DEL_INTERRUPT
	call PRINT
	mov ah,35h
	mov al,1ch
	int 21h
	mov si,offset SAVE_IP
	sub si,offset ROUT
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	mov ax,es:[bx+si-2] 
	mov es,ax
	mov ax,es:[2ch]
	push es
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	mov ah,49h
	int 21h
	jmp REMOVE_LAST_2
REMOVE_LAST:
	mov dx,offset ALREADY_SET
	call PRINT
REMOVE_LAST_2:
	
	pop es
	pop ds
	pop ax
	pop dx
	ret
REMOVE_ROUT ENDP

SAVE_OLD_INTR PROC
	push ax
	push bx
	push es
	mov ah,35h
	mov al,1ch
	int 21h 
	mov SAVE_CS, ES
	mov SAVE_IP, BX
	pop es
	pop bx
	pop ax
	ret
SAVE_OLD_INTR ENDP

BEGIN:
	mov ax,DATA
	mov ds,ax
	mov SAVE_PSP, es
	call CHECK_ROUT
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
END BEGIN