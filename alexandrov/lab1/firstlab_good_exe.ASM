AStack    SEGMENT  STACK
          DW 12 DUP(?)    ; Отводится 12 слов памяти
AStack    ENDS

; Данные программы

DATA      SEGMENT
PC_TYPE db 0Dh, 0Ah, 'PC type: $'

ifPC db 'PC$' ; FF
ifPC_XT db 'PC/XT$' ; FE, FB
ifPC_AT db 'AT$' ; FC
ifPS2_30 db 'PS2 model 30$' ; FA
ifPS2_50_60 db 'PS2 model 50 or 60$' ; FC
ifPS2_80 db 'PS2 model 80$' ; F8
ifPC_jr db 'PSjr$' ; FD
ifPC_Conv db 'PC Convertible$' ; F9

isVer db 0Dh, 'Version:  . $'
isOem db 0Dh, 0Ah, 'OEM:     $'
isSerial db 0Dh, 0Ah, 'Serial number:        $'
DATA      ENDS

; Код программы

CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack

; Процедура печати строки
WriteMsg  PROC  NEAR
          mov   AH,9
          int   21h  ; Вызов функции DOS по прерыванию
          ret
WriteMsg  ENDP

; Головная процедура
Main      PROC  FAR
          push  DS       ;\  Сохранение адреса начала PSP в стеке
          sub   AX,AX    ; > для последующего восстановления по
          push  AX       ;/  команде ret, завершающей процедуру.
          mov   AX,DATA             ; Загрузка сегментного
          mov   DS,AX               ; регистра данных.
        ;  lea dx, isVer
      ;    call WriteMsg
      ;    lea dx, isSerial
      ;    call WriteMsg
      ;    lea dx, isOem
      ;    call WriteMsg
          call OSVER
        call PCTYPE
; Выход в DOS
           xor     AL,AL
           mov     AH,4Ch
           int     21H                          ; находящейся в 1-ом слове PSP.
          ret                       ; Выход в DOS по команде,
Main      ENDP

PRINT PROC near
            mov ah, 09h
            int 21h
            ret
PRINT ENDP
OSVER PROC near
            push ax
            xor ax, ax
            mov ah, 30h
            int 21h
                        ; в регистре AL - номер основной версии ms dos,
                        ; в AH - модификация версии ms dos, в BH - серийник OEM, 
                        ; в BL:CX - 24-битовый серийный номер пользователя
            
            lea si, isVer
            add si, 10
            call BYTE_TO_DEC
            lea si, isVer
            add si, 12
            mov al, ah
            call BYTE_TO_DEC
            lea dx, isVer
            call PRINT
            
            lea si, isOem
            mov al, bh
            add si, 9
            call BYTE_TO_DEC
            lea dx, isOem
            call WriteMsg
            
            lea di, isSerial
            add di, 22
            mov ax, cx
            call WRD_TO_HEX
            mov al, bl
            call BYTE_TO_HEX
            sub di, 2
            mov [di], ax
            lea dx, isSerial
            call PRINT
            pop ax
            ret
OSVER ENDP
PCTYPE PROC near
            mov bx, 0f000h
            mov es, bx
            mov al, es:[0fffeh]
            lea dx, PC_TYPE
            call PRINT
            cmp al, 0FFh
            jz PC
            cmp al, 0FEh
            jz PC_XT
            cmp al, 0FBh
            jz PC_XT
            cmp al, 0FCh
            jz PC_AT
            cmp al, 0FAh
            jz PS2_30
            cmp al, 0FCh
            jz PS2_50_60
            cmp al, 0F8h
            jz PS2_80
            cmp al, 0FDh
            jz PC_jr
            cmp al, 0F9h
            jz PC_Conv
            PC:
                lea dx, ifPC
                jmp PRINT
            PC_XT:
                lea dx, ifPC_XT
                jmp PRINT
            PC_AT:
                lea dx, ifPC_AT
                jmp PRINT
            PS2_30:
                lea dx, ifPS2_30
                jmp PRINT
            PS2_50_60:
                lea dx, ifPS2_50_60
                jmp PRINT
            PS2_80:
                lea dx, ifPS2_80
                jmp PRINT
            PC_jr:
                lea dx, ifPC_jr
                jmp PRINT
            PC_Conv:
                lea dx, ifPC_Conv
                jmp PRINT
            ret
PCTYPE ENDP
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; перевод в 10с/с, SI - адрес поля младшей цифры
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
           dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
           
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP

CODE      ENDS
          END Main
