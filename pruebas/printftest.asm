CR:                EQU $0D
LF:                EQU $0A
printf:            EQU $EE88
getchar:           EQU $EE84
putchar:           EQU $EE86
FINMSG:            EQU $0

                org $1000
MSG1:                FCC "Ingrese un valor entre 0 y9: "
                dB CR,CR,LF
                dB FINMSG

MSG2:                FCC "El -valor ingresado en Hex es %x"
                dB CR,CR,LF
                dB FINMSG
                
MSG3:           FCC "El numero ingresado fue:"
                dB CR,CR,LF
                dB FINMSG
;Programa

                org $2000
                lds #$3BFF
                ldx #$0
                ldd #MSG1
                jsr [printf,x]

                ldx #$0
                jsr [getchar,x]

                ;ldaa #$0
                ;ldx #$0
                ;jsr [putchar,x]

                subb #$30
                negb
                sex b,d

                pshd
                ldx #$0000
                ldd #MSG2
                jsr [printf,x]

END:                bra END