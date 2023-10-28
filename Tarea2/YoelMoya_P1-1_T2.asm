;******** INICIO DE ENCABEZADO ********;
;
; Estudiante: Yoel Moya Carmona
; Carne: B75262
;
;******** DESCRIBCION GENERAL ********;
;
; Se implemento el algoritmo XS3 para realizar la conversion
; de un numero binario a BCD.
; Este algoritmo al ser implementado para numeros binarios de
; 12 bits, se inicia realizando 4 desplazamientos hacia la
; izquierda, con el objetivo de deshacerce de los 4 bits mas
; significativos, ya que en este caso, son numeros de relleno.
; Se realizan dos desplazamientos antes de ingresar al ciclo
; FOR_LOOP, con el objetivo de realizar menos iteraciones, ya
; que los primeros dos desplazamientos son siempre menores que
; 5.
; Se utilizara la abreviacion dec para la palabra decadas, con
; el objetivo de ahorrar espacio entre comentarios.
;
;******** ESTRUCTURAS DE DATOS *******;

                org $1000
BIN:            dW  $0F0F

                org $1010
NUM_BCD:        ds  $2

                org $1030
BCD_1:                ds  1 ;guarda dec mas significativas
BCD_2:                ds  1 ;guarda dec menos significativas
TEMP1:                ds  2 ;guarda num bin entre iteraciones
COUNT:                ds  1 ;contador de iteraciones/despl

;******** PROGRAMA PRINCIPAL ********;

                org $2000

                bclr BCD_1, $FF ;Inicializa variables
                bclr BCD_2, $FF
                ldaa #9         ;Inicializa contador
                staa COUNT
                ldd BIN         ;Carga num binario

                asld            ;Elimina bit 16
                asld            ;Elimina bit 15
                asld            ;Elimina bit 14
                asld            ;Elimina bit 13

                asld            ;despl 1, optimizacion
                rol BCD_2
                rol BCD_1
                asld            ;despl 2 optimizacion
                rol BCD_2
                rol BCD_1

                std TEMP1

FOR_LOOP:       ldd TEMP1
                asld          ;Despl. Luego de esto sigue
                rol BCD_2     ;a comparar las decadas por
                rol BCD_1     ;separado

                std TEMP1
                ldaa BCD_1    ;carga las 2 dec mas signifi-
                ldab BCD_1    ;cativas a A y B
                anda #$F0     ;Separa dec mas significativa 
                andb #$0F     ;Separa dec menos significativa
                cmpb #$05     ;dec menos signif. <5
                blo Menor_5_3_Dec

                addb #$03     ;suma 3 si es >= que 5

Menor_5_3_Dec:  aba           ;Une las decadas mas signif.
                staa BCD_1    ;guarda decadas mas signif.

                ldaa BCD_2    ;carga decadas menos signif-
                ldab BCD_2    ;icativas a A y B
                anda #$F0     ;separa dec mas signif.
                andb #$0F     ;separa dec menos signif.

                cmpa #$50     ; dec mas signif < 5
                blo Menor_5_2_Dec

                adda #$30     ;suma 3 si es >= 5

Menor_5_2_Dec:  cmpb #$05     ;dec menos signif < 5
                blo Menor_5_1_Dec

                addb #$03     ;suma 3 si es >= 5

Menor_5_1_Dec:  aba           ;une las decadas
                staa BCD_2    ;guarda las decadas

                ldab COUNT    ;carga contador
                subb #1       ;resta la iteracion hecha
                stab COUNT    ;guarda nuevo contador

                cmpb #$00     ;si quedan iteraciones, siga
                bne FOR_LOOP

Ultimo_Despl:   ldd TEMP1     ;carga ultimo valor a ser despl
                asld          ;realiza despl final
                rol BCD_2
                rol BCD_1

                ldaa BCD_1    ;carga 2 digitos mas signif en BCD
                ldab BCD_2    ;carga 2 digitos menos signif en BCD
                std NUM_BCD   ;guarda numero BCD

END:            bra END
