;----------------- ENCABEZADO ----------------------------;

;----------------- ESTRUCTURAS DE DATOS ------------------;
CR:                EQU $0D
LF:                EQU $0A
PrintF:                EQU $EE88
GetChar:        EQU $EE84
PutChar:        EQU $EE86
FINMSG:                EQU $0

                org $1000
CANT:           ds 1


                org $1030
MSG_INICIAL:    FCC "INGRESE EL VALOR DE CANT (ENTRE 1 Y 25): "
                dB FINMSG
                
MSG_ENTER:      FCC " "
                db CR,LF
                db FINMSG

;----------------- PROGRAMA PRINCIPAL --------------------;

                org $2000

                jsr GET_CANT
                bra *

;---------------------------------------------------------;
;----------------- SUBRUTINA GET CANT --------------------;
;---------------------------------------------------------;

GET_CANT:
                bclr CANT,$FF

                ldd #MSG_INICIAL
                ldx #$0000

                jsr [PrintF,x]

Char_decenas:        ldx #$0000
                jsr [GetChar,x]

                cmpb #$30
                beq valid_decenas
                cmpb #$31
                beq valid_decenas
                cmpb #$32
                bne Char_decenas

valid_decenas:        ldaa #$00
                ldx #$0000
                
                jsr [PutChar,x]

                ldaa #$0A
                subb #$30
                mul
                stab CANT

Char_unidades:        ldx #$0000
                jsr [GetChar,x]

                tba
                subb #$30
                addb CANT
                
                cmpb #1
                blo Char_unidades
                cmpb #25
                bhi Char_unidades

                stab CANT

                tab
                ldaa #$00
                ldx #$0000
                jsr [PutChar,x]

                ldd #MSG_ENTER
                ldx #$0000
                jsr [PrintF,x]

                rts

                
