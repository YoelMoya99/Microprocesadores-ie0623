                        org $1000
Cont_BCD:                ds 1
BCD:                     ds 1


                        org $2000
                        lds #$3BFF
                        bclr BCD,$FF
                        ldaa #$63

BIN_BCD_MUXP:
                        bclr BCD,$FF
                        movb #$05,Cont_BCD
                        lsla
                        rol BCD
                        lsla
                        rol BCD

                        psha

bin_BCD_loop:
                        pula
                        lsla
                        rol BCD
                        psha

                        ldd #$F00F
                        anda BCD
                        andb BCD

                        cmpa #$50
                        blo no_add_30
                        adda #$30
no_add_30:
                        cmpb #$05
                        blo no_add_03
                        addb #$03
no_add_03:
                        aba 
                        staa BCD

                        dec Cont_BCD
                        tst Cont_BCD
                        bne bin_BCD_loop

                        pula
                        lsla
                        rol BCD
Fin_BIN_BCD_MUXP:
                        bra *
