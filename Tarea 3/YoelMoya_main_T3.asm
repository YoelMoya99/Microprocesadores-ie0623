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
CONT:                ds 1
Offset:                ds 1
ACC:                ds 2


                org $1030
MSG_INICIAL:    FCC "INGRESE EL VALOR DE CANT (ENTRE 1 Y 25): "
                dB FINMSG
                
MSG_ENTER:      FCC " "
                db CR,LF
                db FINMSG


                org $1500
Datos_IoT:        fcc "0129"
                fcc "0749"
                fcc "3854"
                fcc "1975"
                fcc "0077"
                
                fcc "1346"
                fcc "5343"
                fcc "2575"
                fcc "2023"
                fcc "0398"

                fcc "0000"
                fcc "1239"
                fcc "1873"
                fcc "0005"
                fcc "2084"

                fcc "0064"
                fcc "0128"
                fcc "0256"
                fcc "0512"
                fcc "4095"


                org $1600
Datos_BIN:        ds 25

;----------------- PROGRAMA PRINCIPAL --------------------;

                org $2000
                lds #$3BFF

                jsr GET_CANT

                leas -2,sp

                ldab #$00
                pshb

                ldd #Datos_BIN
                pshd

                ldd #Datos_IoT
                pshd

                leas 7,sp
                jsr ASCII_BIN                

                bra *



;---------------------------------------------------------;
;----------------- SUBRUTINA ASCII BIN -------------------;
;---------------------------------------------------------;

ASCII_BIN:
                leas -5,sp

                bclr CONT,$FF
                bclr Offset,$FF

ascii_loop:        pulx

Decada_4:        ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00
                ldy #1000
                emul

                std ACC

Decada_3:        ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00
                ldy #100
                emul

                addd ACC
                std ACC
        
Decada_2:        ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00
                ldy #10
                emul

                addd ACC
                std ACC

Decada_1:        ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00

                addd ACC
                std ACC

guarda_val:        pshx
                leas 2,sp

                puly
                pulb

                ldx ACC
                stx b,y

                addb #$02
                pshb
                pshy

                leas -2,sp
                inc CONT
                ldaa CONT

                cmpa CANT
                bne ascii_loop

                leas 5,sp
                rts

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

                