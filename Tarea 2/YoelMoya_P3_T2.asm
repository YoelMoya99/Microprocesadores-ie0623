;******** ENCABEZADO ********;
;
; Estudiante: Yoel Moya Carmona
; Carne: B75262
;
;******** DESCRIBCION GENERAL ********;
;
; Se implemento un programa que recorre una tabla de tamaño 
; menor a 255.
; Se realiza una comparacion con cero a los valores de la tabla
; para determinar si son negativos o no. Seguidamemte se
; utiliza la mascara $03 con una instruccion and, lo que
; permite evaluar si el numero es divisible por 4 o no.
; En todos los casos que los numeros de la tabla cumplen las
; condiciones especificadas, estos son guardados en un array.
; se sustituye el ofset utilizado para iterar sobre DATOS, por
; el utilizado para iterar sobre DIV4.
; luego de guardar el valor, este offset se le suma 1 y se
; guarda en la variable CANT4, la cual contiene la cantidad
; de datos del array o el ofset que apunta al siguiente campo
; vacio, dependiendo del lugar donde sea llamado.
;
;******** ESTRUCTURAS DE DATOS ********;

                org $1000
L:              db $06
CANT4:          ds 1
TEMP:           ds 1

                org $1100
DATOS:          db $03, $04, $68, $9C, $EE, $99

                org $1200
DIV4:           ds 255  

;******** PROGRAMA PRINCIPAL ********;

                org $2000

                ldx #DATOS        ;Carga puntero a Datos
                ldy #DIV4         ;Carga puntero a DIV4
                bclr CANT4, $FF   ;Inicializa ofset/contador de DIV4

                ldab #0           ;Inicializa contador de DATOS
                
FOR_LOOP:       cmpb L            ;Pregunta por final de DATOS
                beq END           ;Salta si llego al final

                ldaa b,X          ;trae dato de DATOS
                cmpa #0           ;Pregunta >= que cero
                bge NO_NEG_OR_MULT;Si no, es negativo, continua

                anda #$03         
                cmpa #0           ;Pregunta por multiplo de 4
                bne NO_NEG_OR_MULT;Si es, continua

                ldaa b,X          ;Carga mismo valor
                stab TEMP         ;Intercambia offset de DATOS
                ldab CANT4        ;Por el de DIV4

                staa b,Y          ;Guarda valor en DIV4
                addb #1           ;Incrementa offset de DIV4
                stab CANT4        ;Y lo guarda

                ldab TEMP         ;Carga offset de DATOS

NO_NEG_OR_MULT: addb #1           ;Incrementa offset
                bra FOR_LOOP      ;Continua iterando
                
END:            bra END
