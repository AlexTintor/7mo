TITLE ORDENA_MAYOR_MENOR - Alex Fernando Bojorquez Rojas 22170581
; Autor: Alex Fernando Bojorquez Rojas 22170581
.MODEL SMALL
.STACK 100h
.DATA
    ; Arreglos de ejemplo para verificar el procedimiento
    ARR1 DW 3541, 200, 150, 375, 820
    ARR2 DW 88, 90, 1583, 24, -35, -12321, 8421, 6
    MSG DB 'Arreglos ordenados de Mayor a Menor. Presiona una tecla para salir.$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; Llamada para ARR1 (5 elementos)
    MOV CX, 5
    LEA BX, ARR1
    CALL ORDENA

    ; Llamada para ARR2 (8 elementos)
    MOV CX, 8
    LEA BX, ARR2
    CALL ORDENA
    
    ; Solo para indicar que terminó la ejecución
    LEA DX, MSG
    MOV AH, 9
    INT 21h

    ; Esperar una tecla antes de salir
    MOV AH, 00H
    INT 16H
    
    MOV AH, 4Ch
    INT 21h
MAIN ENDP

; Procedimiento ORDENA: Recibe BX (direccion del arreglo), CX (cantidad de elementos)
; Ordena elementos de WORD de mayor a menor (descendente)
ORDENA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    DEC CX ; n-1 iteraciones externas

EXTERNO:
    MOV SI, BX  ; SI apunta al inicio del arreglo
    MOV DI, CX  ; Contador del bucle interno

INTERNO:
    MOV AX, [SI]
    CMP AX, [SI+2]
    JGE NO_INTERCAMBIO 

    XCHG AX, [SI+2]
    MOV [SI], AX

NO_INTERCAMBIO:
    ADD SI, 2   
    DEC DI
    JNZ INTERNO

    LOOP EXTERNO 

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ORDENA ENDP

END MAIN
