#include registers.inc
; RELOCALIZACION DEL VECTOR DE INTERRUPCIONES
                org $3E70
                dW RTI_ISR
                
                org $1000
Leds:           ds 1
Cont_RTI:       ds 1

; CONFIGURACION DE HARDWARE

                org $2000
                movb #$FF,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                
                movb #$0F,DDRP
                movb #$0F,PTP
                
                bset CRGINT,$80
                movb #$23,RTICTL
                
                lds #$3BFF
                cli
                movb #$01,Leds
                movb #250,Cont_RTI
                
                bra *
                
; SUBRUTINA RTI_ISR
RTI_ISR:
                bset CRGFLG,$80
                dec Cont_RTI
                tst Cont_RTI
                bne RETORNAR
                
                movb #250,Cont_RTI
                movb Leds,PORTB
                
                ldaa Leds
                cmpa #$80
                bne ROTE

                movb #$01,Leds
                bra NO_ROTE
ROTE:
                lsl Leds
NO_ROTE:

                
RETORNAR:       rti