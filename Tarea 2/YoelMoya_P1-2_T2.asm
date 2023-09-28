;******** ENCABEZADO ********;
;
; Estudiante: Yoel Moya Carmona
; Carne: B75262
; 
;******** DESCRIBCION GENERAL ********;
;
; Se implemento el algoritmo de multiplicacion y suma, para
; realizar el cambio de numeros expresados en BCD a numero
; en binario.
; Este algoritmo toma cada decada de la menos significativa
; hasta la mas significativa, y multiplica esta por 10^n,
; donde n es la posicion donde se encuentra el digito en
; decimal. Una vez que realiza esta multiplicacion, suma
; todos los resultados con suma parcial mas llevo. El resul-
; tado final es el numero expresado en binario.
; Para realizar menos iteraciones se tomo la primera decada
; y se asigno a la variable de resultado, ya que esta siempre
; sera multiplicada por 1. 
; Seguido de esto, en cada iteracion, luego de realizar la
; multiplicacion, se suma el resultado anterior al resultado
; presente. Al terminar el algoritmo, todas las sumas ya fueron
; realizadas
;
;******** ESTRUCTURAS DE DATOS ********;

                org $1002
BCD:            dW  $3742

                org $1020
NUM_BIN:        ds  2      ;Variable, guarda resultado final

                org $1030
BCD_TEMP:       ds  2      ;Variable, guarda decadas que faltan de iterar
MULT:           ds  2      ;Variable, multiplicador 10^n
COUNT:          ds  1      ;Variable, contador de iteraciones faltantes


;******** PROGRAMA PRINCIPAL ********;

                org $2000

                ldd #$000A
                std MULT     ;Inicializa multiplicador
                ldaa #3
                staa COUNT   ;Inicializa contador iteraciones

                ldd BCD
                std BCD_TEMP ;Guarda decadas faltantes

                anda #$00    ; aisla la primera decada
                andb #$0F    ; con una mascara

                std NUM_BIN  ;guarda primer num binario

FOR_LOOP:       ldx #$0010
                ldd BCD_TEMP

                idiv         ;Desecha decada menos significativa
                xgdx
                std BCD_TEMP ;Guarda decadas faltantes

                anda #$00    ;Aisla siguiente decada
                andb #$0F    ;a multiplicar

                ldy MULT
                emul         ;decada * 10^n

                addd NUM_BIN ;Suma result presente a result anterior
                std NUM_BIN  ;Guarda resultado binario parcial

                ldy #$000A
                ldd MULT
                emul         ;Aumenta el n del multiplicador

                std MULT     ;Guarda prox multiplicador

                ldaa COUNT
                suba #1
                staa COUNT

                cmpa #$00    ;Revisa si faltan iteraciones
                bne FOR_LOOP

END:                bra END