;---------------------------------------------------------------------;
;--------------------------- Encabezado ------------------------------;
;---------------------------------------------------------------------;

; Estudiante: Yoel Moya Carmona
; Carne: B75262

;---------------------------------------------------------------------;
;----------------------- Estructuras de Datos ------------------------;
;---------------------------------------------------------------------;

                        org $1000
BCD:                    dW $9999
Num_BIN:                ds 2

                        org $1010
COUNT:                  ds 1

                        org $1020
Temp:                   ds 2
;---------------------------------------------------------------------;
;----------------------- Programa Principal --------------------------;
;---------------------------------------------------------------------;

                        org $2000
                        ldx #Temp
                        ldy #Num_BIN
                        
                        bclr 0,y,$FF ;No es nesesario del todo, agregado
                        bclr 1,y,$FF ;Como extra para leer mejor valores

                        movb #13,COUNT ;Inicializacion Contador Principal
                        movw BCD,Temp  ;Carga valor a Rotar en variable temp




for_loop:               lsr 0,x ;Rotacion hacia la derecha de valor BCD y
                        ror 1,x ;Num_BIN. Rotacion conjunta de 2 words,
                        ror 0,y ;desplazando con cero entrante y rotanto con
                        ror 1,y ;carry los 3 bytes restantes
                        
                        ;PARA LAS DOS DECADAS MAS SIGNIFICATIVAS
                        ldd #$F00F ;Carga mascara para aislar DEC alta y baja
                        anda 0,x   ;Aisla decada alta
                        andb 0,x   ;Aisla decada baja

                        ;RESTA 30 SI DEC ALTA MAYOR O IGUAL QUE 80
                        cmpa #$80
                        blo Hi_No_Sub_30
                        suba #$30
Hi_No_Sub_30:
                        ;RESTA 3 SI DEC BAJA MAYOR O IGUAL QUE 8
                        cmpb #$08
                        blo Hi_No_Sub_03
                        subb #$03
Hi_No_Sub_03:
                        aba ;Une las decadas filtradas
                        staa 0,x ;guarda las decadas filtradas

                        ;PARA LAS DOS DECADAS MENOS SIGNIFICATIVAS
                        ldd #$F00F ;Carga mascara denuevo
                        anda 1,x ;Aisla decada mas significativa
                        andb 1,x ;Aisla decada menos significativa

                        ;RESTA 30 SI LA DEC ALTA MAYOR O IGUAL QUE 80
			cmpa #$80
                        blo Lo_No_Sub_30
                        suba #$30
Lo_No_Sub_30:
                        ;RESTA 3 SI LA DEC BAJA MAYOR O IGUAL QUE 8
                        cmpb #$08
                        blo Lo_No_Sub_03
                        subb #$03
Lo_No_Sub_03:
                        aba ;Une las decadas filtradas
                        staa 1,x ;Guarda las decadas filtradas


                        dec COUNT ;Falta un desplazamiento con comparacion
                        tst COUNT ;menos. Si no hemos terminado, salte
                        bne for_loop
                        
                        movb #3,COUNT ;Carga segundo contador para los
                                      ;desplazamientos sin comparacion

                        ;DESPLAZAMIENTOS SIN COMPARACION:
Optimizacion:           lsr 0,x
                        ror 1,x
                        ror 0,y
                        ror 1,y
                        
                        dec COUNT ;Falta un despl sin comparacion menos
                        tst COUNT ;Si no hemos terminado, salte
                        bne Optimizacion
                        
                        bra * ; Ya termino, revisar resultado en $1002