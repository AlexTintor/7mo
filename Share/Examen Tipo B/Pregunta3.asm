TITLE MACRO_RESTORE_REGS - Alex Fernando Bojorquez Rojas 22170581
; Autor: Alex Fernando Bojorquez Rojas 22170581
.MODEL SMALL
.STACK 100h

RESTORE_REGS MACRO LISTA_REGS:VARARG
    .NOCREF 
    NUM_REGS = 0
    IRPC REG, <LISTA_REGS>
        NUM_REGS = NUM_REGS + 1
    ENDM
    
    PUSH_MACRO MACRO REG_NAME
        PUSH REG_NAME
    ENDM
    
    IRPC REG, <LISTA_REGS>
        PUSH_MACRO REG
    ENDM
    
    REPT NUM_REGS
        POP %&LAST_MACRO_PARAM 
    ENDM
    
    .NOCREF 
ENDM

.DATA
    MSG DB 'Registros empujados y restaurados de la pila. Presiona una tecla para salir.$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    MOV AX, 1111H
    MOV BX, 2222H
    MOV CX, 3333H
    
    PUSH CX
    PUSH BX
    PUSH AX
    
    MOV AX, 0000H
    MOV BX, 0000H
    MOV CX, 0000H

    RESTORE_REGS <CX, BX, AX>
    
    LEA DX, MSG
    MOV AH, 09H
    INT 21H

    MOV AH, 00H
    INT 16H
    
    MOV AH, 4CH
    INT 21H
MAIN ENDP

END MAIN
