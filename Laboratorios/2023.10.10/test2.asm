;Estructuras de datos
#include registers.inc

;programa principal
		org $2000
                movb #$00,DDRH
                movb #$FF,DDRB
                bset DDRJ,#$02
                bclr PTJ,#$02
                
loop:           ldaa PTH
                staa PORTB
                bra loop
                