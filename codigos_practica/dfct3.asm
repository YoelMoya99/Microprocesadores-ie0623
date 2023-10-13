;---------------------------------------------------------------------;
;--------------------------- Encabezado ------------------------------;
;---------------------------------------------------------------------;

; Estudiante: Yoel Moya Carmona
; Carne: B75262

;---------------------------------------------------------------------;
;----------------------- Estructuras de Datos ------------------------;
;---------------------------------------------------------------------;

                        org $1000
BCD:                        dW $9999
NUM_BIN:                ds 2

                        org $1010
COUNT:                        ds 1

                        org $1020
TEMP1:                        ds 2
BIN_Hi:                        ds 1
BIN_Lo:                        ds 1
BCDptr:                        EQU #TEMP1

;---------------------------------------------------------------------;
;----------------------- Programa Principal --------------------------;
;---------------------------------------------------------------------;

                        org $2000
                        bclr BIN_Hi,$FF
                        bclr BIN_Lo,$FF
                        movb #13, COUNT
                        movw BCD,TEMP1
                        dec COUNT


for_loop:                ldx #TEMP1
                        lsr 0,x
                        ror 1,x
                        ror BIN_Hi
                        ror BIN_Lo
                        

                        ldaa 0,x
                        anda #$F0
			ldab #$F0
                        cmpa #$80
                        blo Hi_No_Sub_30
                        suba #$30
Hi_No_Sub_30:                
                        andb #$0F
                        cmpb #$08
                        blo Hi_No_Sub_03
                        subb #$30                
Hi_No_Sub_03:
                        aba
                        staa 0,x

                        
                        ldaa 1,x
                        anda #$F0
			ldab 1,x
                        cmpa #$80
                        blo Hi_No_Sub_30
                        suba #$30
Lo_No_Sub_30:                
                        andb #$0F
                        cmpb #$08
                        blo Hi_No_Sub_03
                        subb #$30                
Lo_No_Sub_03:
                        aba
                        staa 1,x

                        dec COUNT
                        ldaa COUNT
                        cmpa #$00
                        bne for_loop
                        
                        movb #3,COUNT

Optimizacion:                lsr 0,x
				ror 1,x
                        ror BIN_Hi
                        ror BIN_Lo
                        
                        dec COUNT
                        ldaa COUNT
                        cmpa #$00
                        bne Optimizacion
                        
                        movb TEMP1,NUM_BIN

                        bra *
