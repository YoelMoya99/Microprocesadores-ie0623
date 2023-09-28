;******** ENCABEZADO ********;
;
; Estudiante: Yoel Moya Carmona
; Carne: B75262
;
;******** DESCRIBCION GENERAL ********;
;
; Se itera primero sobre una tabla que contiene datos,
; conociendo que esta termina con el dato $80. Se modifica
; El puntero que contiene la direccion efectiva de la tabla
; hasta que el dato traido coincide con el dato de fin, y
; seguidamente se itera hacia atras trayendo cada uno de los
; datos de esta y realizando una O-Exclusiva con las mascaras
; de la segunda tabla.
; Se revisa el caracter de inicio de datos, y se utiliza este
; como caracter de fin. 
; En cada iteracion, si el resultado de la O-Exclusiva es
; negativo, se cambia de puntero y se guarda el resultado 
; en un array. En dado caso de suceder esto, luego de guardar
; el valor se reestablece el puntero a el puntero de la tabla
; de mascaras y se guarda el puntero del array de datos ne-
; gativos hasta la siguiente iteracion.
;
;******** ESTRUCTURAS DE DATOS ********;

                org $1000
NEG_P:          ds  2
MASK_P:         ds  2
DATOS_END:      ds  1

                org $1050
DATOS:          db  $55, $FF, $0F, $F0, $88, $97, $80
 
                org $1150
MASCARAS:       db $00, $AA, $37, $18, $10, $F0, $F1, $FE

                org $1300
NEGAT:          ds  $0400

;******** PROGRAMA PRINCIPAL ********;

                org $2000

                ldx #DATOS    ;Puntero de Datos
                ldy #NEGAT    ;Puntero de array, negativos

                sty NEG_P     ;Guarda puntero en variable
                ldy #MASCARAS ;Carga puntero de mascaras y
                sty MASK_P    ;lo guarda en variable

                ldaa DATOS    ;Condicion de paro de Tabla datos
                sta DATOS_END

                cmpa #$80     ;Si no hay datos, finalice
                beq END

DATA_PT:        ldaa 1,+X     ;Cargue valor
                cmpa #$80     ;Compare con fin.
                bne DATA_PT   ;Si no es fin, siga iterando

XOR_LOOP:       ldab 0,Y     ;Carga primer valor de mascara
                cmpb #$FE     ;Revisa tabla mask vacia
                beq END       ;Si vacia, finalice

                ldaa 1,-X     ;Traiga dato
                cmpa DATOS_END;Revise condicion de fin
                bne SIGA      ;Si no es fin, siga

                ldab #$80     ;Si es fin, establezca criterio
                stab DATOS_END;Para salir del XOR_LOOP

SIGA:           eora 1,Y+     ;Realice la XOR
                cmpa #0       ;Revise valor negativo
                bge NO_NEG    ;Si positivo o cero salte

                sty MASK_P    ;Cambie puntero de Mascaras por
                ldy NEG_P     ;Puntero de negativos

                sta 1,Y+      ;Guarda valor negativo
                sty NEG_P     ;Reestablezca el puntero de
                ldy MASK_P    ;mascaras, y guarde punt negativo

                ldab DATOS_END;Compare condicion de paro esta-
                cmpb #$80     ;blecida arriba, si no, 
NO_NEG:         bne XOR_LOOP  ;siga iterando


END:                bra END
