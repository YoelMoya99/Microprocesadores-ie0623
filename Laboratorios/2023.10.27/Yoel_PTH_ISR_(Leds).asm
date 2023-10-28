#include registers.inc
; RELOCALIZACION DEL VECTOR DE INTERRUPCIONES
                org $3E4C
                dW PTH_ISR
                
                org $1000
Leds:           ds 1
;Cont_TOI:       ds 1

; CONFIGURACION DE HARDWARE

                org $2000
                movb #$FF,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                
                movb #$0F,DDRP
                movb #$0F,PTP
                
                ;movb #$80,TSCR1
                ;movb #$82,TSCR2
                bset PIEH,$01
                bset PPSH,$01   ; bit set to clear flank
                
                lds #$3BFF
                cli
                movb #$01,Leds
                ;movb #25,Cont_TOI
                
                bra *
                
; SUBRUTINA RTI_ISR
PTH_ISR:
                bset PIFH,$01
                ;dec Cont_TOI
                ;tst Cont_TOI
                ;bne RETORNAR
                
                ;movb #25,Cont_TOI
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