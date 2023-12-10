#include registers.inc
;Relocalizacion del vector de interrupciones
                org $3E54 ;$FFD4 ;$3E54
                dW SC1_ISR
;Estructuras de datos

                org $1000
Contador:       ds 1
EOM:            EQU $FF
Puntero:        ds 2
MSG:            FCC "Hola, si funciona!" ;18
                dB EOM



                
;Programa Principal
                org $2000
                
Com_Serie:
                clr Contador
                
                movb #$FF,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                
                movw #39,SC1BDH
                movb #$00,SC1CR1
                movb #$88,SC1CR2
                
                ldaa SC1SR1
                movb #$00,SC1DRL
                
                lds #$3BFF
                Cli
                ldx #MSG
                stx Puntero
                
                ldaa SC1SR1
                movb #$0C,SC1DRL
                
                bra *
                
SC1_ISR:

                movb #$FF,PORTB
                inc Contador

		ldaa SC1SR1
                ldx Puntero
                
                ldaa 1,x+
                
                cmpa #EOM
                beq Final_De_MSG      ; cambio
                
                staa SC1DRL
                stx Puntero
                bra Retornar
Final_De_MSG:
                bclr SC1CR2,$08
                
Retornar:
                rti