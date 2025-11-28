TITLE MACRO_INIT_ARR - Alex Fernando Bojorquez Rojas 22170581
; Autor: Alex Fernando Bojorquez Rojas 22170581
.MODEL SMALL
.STACK 100h

INIT_ARR MACRO NOMBRE, N, INICIO, INCREMENTO
    LOCAL BUCLE_GEN
    LOCAL FIN_MACRO
    
    .DATA 
NOMBRE DB INICIO
    REPT N-1
        DB INICIO + 1 
    ENDM
    
    .CODE 
    PUSH AX 
    PUSH BX 
    PUSH CX 
    
    MOV AX, INICIO
    MOV CX, N
    MOV BX, OFFSET NOMBRE
    
BUCLE_GEN:
    MOV [BX], AL 
    ADD AX, INCREMENTO 
    ADD BX, 1 
    LOOP BUCLE_GEN
    
    POP CX 
    POP BX 
    POP AX 
    
    JMP FIN_MACRO 
    
    .DATA 
FIN_MACRO:
ENDM

.DATA
    INIT_ARR ARRAY1, 10, 1, 1
    INIT_ARR ARRAY2, 100, 200, -2
    
    MSG DB 'Arreglos inicializados con INIT_ARR. Presiona una tecla para salir.$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    LEA DX, MSG
    MOV AH, 09H
    INT 21H

    MOV AH, 00H
    INT 16H
    
    MOV AH, 4CH
    INT 21H
MAIN ENDP

END MAIN
