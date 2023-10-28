#include registers.inc
; RELOCALIZACION DEL VECTOR DE INTERRUPCIONES
                org $3E64
                dW OC5_ISR
                
                org $1000
Leds:           ds 1
Cont_OC:        ds 1

; CONFIGURACION DE HARDWARE

                org $2000
                movb #$FF,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                
                movb #$0F,DDRP
                movb #$0F,PTP
                
                ;movb #$80,TSCR1
                ;movb #$82,TSCR2
                movb #$90,TSCR1
                movb #$04,TSCR2
                movb #$20,TIOS
                movb #$20,TIE
                movb #$04,TCTL1
                
                ldaa TCNT
                addd #1500
                std TC5
                
                
                lds #$3BFF
                cli
                movb #$01,Leds
                movb #25,Cont_OC
                
                bra *
                
; SUBRUTINA RTI_ISR
OC5_ISR:
                bset TFLG2,$80
                dec Cont_OC
                tst Cont_OC
                bne RETORNAR
                
                movb #25,Cont_OC
                movb Leds,PORTB
                
                ldaa Leds
                cmpa #$80
                bne ROTE

                movb #$01,Leds
                bra NO_ROTE
ROTE:
                lsl Leds
NO_ROTE:

                
RETORNAR:
                ldd TCNT
                addd #1500
                std TC5
                
		rti