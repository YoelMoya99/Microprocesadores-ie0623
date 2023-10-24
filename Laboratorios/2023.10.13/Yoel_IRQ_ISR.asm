#include registers.inc
; relocalizacion del vector de interrrupciones
                org $FFF2
                dW IRQ_ISR
                
; configuracion del hardware

                org $2000
                
                bset DDRB,$01
                bset DDRJ,$02
                bclr PTJ, $02
                movb #$C0,IRQCR
                
; Programa principal

                lds #$4000
                cli
                bra *
                
; Subrutina IRQ_ISR

IRQ_ISR:        ldaa PORTB
                eora #$01
                staa PORTB
                rti