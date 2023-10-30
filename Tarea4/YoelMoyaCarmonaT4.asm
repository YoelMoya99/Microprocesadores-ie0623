 ;******************************************************************************
 ;                              MAQUINA DE TIEMPOS
 ;                                     (RTI)
 ;******************************************************************************
#include registers.inc
 ;******************************************************************************
 ;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
 ;******************************************************************************
                                Org $3E70
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers de la aplicacion ----

tSupRebPB:        EQU 10
tSupRebTCL:          EQU 10    ;Timer de sup rebotes para TCL, 10ms
tShortP:          EQU 25
tLongP:           EQU 3
tTimer1mS:        EQU 1     ;Base de tiempo de 1 mS (1 ms x 1)
tTimer10mS:       EQU 10    ;Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:      EQU 10    ;Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:         EQU 10    ;Base de tiempo de 1 segundo (100 mS x 10)
tTimerLDTst       EQU 1     ;Tiempo de parpadeo de LED testigo en segundos

PortPB            EQU PTH
MaskPB            EQU $01

                                Org $1000

;Aqui se colocan las estructuras de datos de la aplicacion
MAX_TCL:          dB $04
Tecla:            ds 1
Tecla_IN:         ds 1
Cont_TCL:         ds 1
Patron:           ds 1
Est_Pres_TCL:     ds 2
Est_Pres_LeerPB:  ds 2

Banderas_PB:      ds 1
ShortP:           EQU $01
LongP:            EQU $02
ARRAY_OK:          EQU $04

                  org $1010
Num_Array:        ds 10

                  org $1020
Teclas:           dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$00,$0E,$0B

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1040
Tabla_Timers_BaseT:

Timer1mS        ds 1       ;Timer 1 ms con base a tiempo de interrupcion

Fin_BaseT       db $FF

Tabla_Timers_Base1mS

Timer10mS:      ds 1       ;Timer para generar la base de tiempo 10 mS
Timer1_Base1:   ds 1       ;Ejemplos de timers de aplicacion con BaseT
Timer2_Base1:   ds 1
Timer_RebPB:    ds 1
Timer_RebTCL:        ds 1        ;Timer de supresion de rebotes

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer100mS:     ds 1       ;Timer para generar la base de tiempo de 100 mS
Timer1_Base10:  ds 1       ;Ejemplos de timers de aplicacion con base 10 mS
Timer2_Base10:  ds 1
Timer_SHP:      ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1S:        ds 1       ;Timer para generar la base de tiempo de 1 Seg.
Timer1_Base100  ds 1       ;Ejemplos de timers de aplicacpon con base 100 mS
Timer2_Base100  ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LED_Testigo ds 1   ;Timer para parpadeo de led testigo
Timer1_Base1S:    ds 1   ;Ejemplos de timers de aplicacion con base 1 seg.
Timer2_Base1S:    ds 1
Timer_LP:         ds 1

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================

                               Org $2000

        Bset DDRB,$FF     ;Habilitacion del LED Testigo cambioxxxx 80
        Bset DDRJ,$02     ;como comprobacion del timer de 1 segundo
        BClr PTJ,$02      ;haciendo toogle
        
        Movb #$0F,DDRP    ;bloquea los display de 7 Segmentos
        Movb #$0F,PTP
        
        movb #$F0,DDRA    ;Define el puerto A como salida y entrada p/teclado
        bset PUCR,$01     ;Activa las resistencias de pullup del puerto A

        Movb #$17,RTICTL   ;Se configura RTI con un periodo de 1 mS
        Bset CRGINT,$80
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movb #tTimer1mS,Timer1mS
        Movb #tTimer10mS,Timer10mS         ;Inicia los timers de bases de tiempo
        Movb #tTimer100mS,Timer100mS
        Movb #tTimer1S,Timer1S
        Movb #tTimerLDTst,Timer_LED_Testigo  ;inicia timer parpadeo led testigo

        movb #$FF,Tecla    ;Inicializa el valor de tecla
        movb #$FF,Tecla_IN ;Inicializa el valor de tecla_in
        movb #$00,Cont_TCL ;Inicializa offset en cero
        movb #$00,Patron   ;Inicializa patron del lectura teclado

        ldx #Num_Array
        movb #$09,Cont_TCL
for:    movb #$FF,1,x+
        dec Cont_TCL
        bne for
        movb #$00,Cont_TCL

        Lds #$3BFF
        Cli
        Clr Banderas_PB
        Movw #LeerPB_Est1,Est_Pres_LeerPB
        Movw #Teclado_Est1,Est_Pres_TCL

Despachador_Tareas

        Jsr Tarea_Led_Testigo
        ; Aqui se colocan todas las tareas del programa de aplicacion
        Jsr Tarea_Teclado
        Jsr Tarea_Leer_PB
        Jsr Tarea_LED_PB
        
        Bra Despachador_Tareas
       

;******************************************************************************
;                               TAREA TECLADO
;******************************************************************************

Tarea_Teclado:
                        ldx Est_Pres_TCL
                        jsr 0,x
                        rts

;------------------------------ Teclado Est1 ---------------------------------

Teclado_Est1:           bclr PORTB,$6E
			bset PORTB,$02 ;Comprobacionestado1
                        jsr Leer_Teclado
                        
                        ldaa #$FF
                        cmpa Tecla
                        beq Fin_Teclado_Est1

                        movb #tSupRebTCL,Timer_RebTCL
                        movw #Teclado_Est2,Est_Pres_TCL
                        movb Tecla,Tecla_IN

Fin_Teclado_Est1:        rts

;---------------------------- Teclado Est2 -----------------------------------

Teclado_Est2:           bclr PORTB,$6E ;Comprobacion estado2
                        bset PORTB,$04
                        tst Timer_RebTCL
                        bne Fin_Teclado_Est2

                        jsr Leer_Teclado

                        ldaa Tecla_IN
                        cmpa Tecla
                        beq Next_TCL_Est_3

                        movw #Teclado_Est1,Est_Pres_TCL
                        bra Fin_Teclado_Est2

Next_TCL_Est_3:
                        movw #Teclado_Est3,Est_Pres_TCL

Fin_Teclado_Est2:        rts


;--------------------------- Teclado Est 3 ----------------------------------

Teclado_Est3:           bclr PORTB,$6E
                        bset PORTB,$08
                        jsr Leer_Teclado
                        
                        ldaa Tecla_IN
                        cmpa Tecla
                        beq Sigue_Presionada

                        movw #Teclado_Est4,Est_Pres_TCL
                        movw Tecla_IN,Tecla
                        bra Fin_Teclado_Est3

Sigue_Presionada:
                        movw #Teclado_Est3,Est_Pres_TCL

Fin_Teclado_Est3:        rts

;---------------------------- Teclado Est 4 --------------------------------

Teclado_Est4:           bclr PORTB,$6E
			bset PORTB,$10 ;Hecho para ver transicino de estados
                        ldaa Cont_TCL
                        cmpa MAX_TCL
                        bhi Long_Max

No_Long_Max:            tst Cont_TCL
                        beq Array_Zero

Array_No_Zero:          ldaa #$0B
                        cmpa Tecla
                        beq Borrar_Valor
                        ldaa #$0E
                        cmpa Tecla
                        beq Finalizar_Array
                        bra Agregar_Valor

Array_Zero:             ldaa #$0B
                        cmpa Tecla
                        beq Reestablecer
                        ldaa #$0E
                        cmpa Tecla
                        beq Reestablecer
                        bra Agregar_Valor

Long_Max:               ldaa #$0B
                        cmpa Tecla
                        beq Borrar_Valor
                        ldaa #$0E
                        cmpa Tecla
                        beq Finalizar_Array
                        bra Reestablecer
                        
Agregar_Valor:          ldab Cont_TCL
                        ldy #Num_Array
                        movb Tecla,b,y
                        inc Cont_TCL
                        bra Reestablecer
                        
Borrar_Valor:           dec Cont_TCL
                        ldab Cont_TCL
                        ldy #Num_Array
                        movb #$FF,b,y
                        bra Reestablecer

Finalizar_Array:        bclr Cont_TCL,#$FF
                        bset Banderas_PB,ARRAY_OK

Reestablecer:           movw #Teclado_Est1,Est_Pres_TCL
                        bset Tecla,#$FF
                        bset Tecla_IN,#$FF

Fin_Teclado_Est4:       rts

;******************************************************************************
;                               TAREA LEER PB
;******************************************************************************

Tarea_Leer_PB:
                        ldx Est_Pres_LeerPB
                        jsr 0,x
                        rts
                        

; ---------------------------- Leer PB Estado 1 -----------------------------

LeerPB_Est1:
                        brset PortPB,MaskPB,PBEst1_Retornar

                        movb #tSupRebPB,Timer_RebPB
                        movb #tShortP,Timer_SHP
                        movb #tLongP,Timer_LP
                        
                        movw #LeerPB_Est2,Est_Pres_LeerPB
                        

PBEst1_Retornar:        rts

; ----------------------------- LeerPB_Est2 ----------------------------------

LeerPB_Est2:
                        tst Timer_RebPB
                        bne PBEst2_Retornar
                        
                        brset PortPB,MaskPB,Label_21
                        
                        movw #LeerPB_Est3,Est_Pres_LeerPB
                        bra PBEst2_Retornar
                        
Label_21:               movw #LeerPB_Est1,Est_Pres_leerPB

PBEst2_Retornar:        rts

; ----------------------------- LeerPB_Est3 ----------------------------------

LeerPB_Est3:
                        tst Timer_SHP
                        bne PBEst3_Retornar

                        brset PortPB,MaskPB,Label_31
                        
                        movw #LeerPB_Est4,Est_Pres_LeerPB
                        bra PBEst3_Retornar
                        
Label_31:               bset Banderas_PB,ShortP
                        movw #LeerPB_Est1,Est_Pres_LeerPB
                        
PBEst3_Retornar:        rts

; ------------------------------ LeerPB_Est4 ---------------------------------

LeerPB_Est4:
                        tst Timer_LP
                        bne Label_Short
                        
                        brclr PortPB,MaskPb,PBEst4_Retornar
                        bset Banderas_PB,LongP
                        bra PBEst4_State1
                        
Label_Short:            brclr PortPB,MaskPB,PBEst4_Retornar
                        bset Banderas_PB,ShortP

PBest4_State1:          movw #LeerPB_Est1,Est_Pres_LeerPB

PBEst4_Retornar:        rts


;*****************************************************************************
;                      SUB RUTINA GENERAL LEER TECLADO
;*****************************************************************************

Leer_Teclado:
                        ldab #$00
                        movb #$EF,Patron

Next_Row:
                        movb Patron,PORTA
                        nop
                        nop
                        nop

                        brclr PORTA,$01,Column_1
                        brclr PORTA,$02,Column_2
                        brclr PORTA,$04,Column_3
                        cmpb #$09
                        beq No_Valor
                        bra Prep_Next_Row
Column_1:
                        ldy #Teclas
                        movb b,y,Tecla
                        bra End_Leer_Teclado
Column_2:
                        ldy #Teclas
                        addb #$01
                        movb b,y,Tecla
                        bra End_Leer_Teclado
Column_3:
                        ldy #Teclas
                        addb #$02
                        movb b,y,Tecla
                        bra End_Leer_Teclado
Prep_Next_Row:
                        rol Patron
                        addb #$03
                        bra Next_Row
No_Valor:
                        movb #$FF,Tecla 

End_Leer_Teclado:        rts

;*****************************************************************************
;                              TAREA LED PB
;*****************************************************************************

Tarea_LED_PB:
                        BrSet Banderas_PB,ShortP,ON
                        BrSet Banderas_PB,LongP,OFF
                        Bra FIN_Led
ON:                     BClr Banderas_PB,ShortP
                        Bset PORTB,$01
                        Bra FIN_Led
OFF:                    BClr Banderas_PB,LongP
                        BClr PORTB,$01

FIN_Led:                Rts
;******************************************************************************
;                               TAREA LED TESTIGO
;******************************************************************************

Tarea_Led_Testigo
                Tst Timer_LED_Testigo
                Bne FinLedTest
                Movb #tTimerLDTst,Timer_LED_Testigo
                Ldaa PORTB
                Eora #$80
                Staa PORTB
FinLedTest      Rts

;******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;******************************************************************************

Maquina_Tiempos:
               ;{COLOCAR EL CODIGO DE LA SUBRUTINA QUE IMPLEMENTA LA
               ; MAQUINA DE TIEMPOS }
               ldx #Tabla_Timers_BaseT
               
               jsr Decre_Timers
               
               
               
               tst Timer1mS
               bne Retornar
               
               movb #tTimer1mS,Timer1mS
               ldx #Tabla_Timers_Base1mS
               
               jsr Decre_Timers
               
               
               
               
               tst Timer10mS
               bne Retornar

               movb #tTimer10mS,Timer10mS
               ldx #Tabla_Timers_Base10mS

               jsr Decre_Timers
               
               
               
               
               
               tst Timer100mS
               bne Retornar

               movb #tTimer100mS,Timer100mS
               ldx #Tabla_Timers_Base100mS

               jsr Decre_Timers
               
               
               
               
               tst Timer1S
               bne Retornar

               movb #tTimer1S,Timer1S
               ldx #Tabla_Timers_Base1S

               jsr Decre_Timers
               

               
Retornar:
                bset CRGFLG,$80
                Rti
;===============================================================================
;                     SUBRUTINA DECREMETE TIMERS
; Esta subrutina decrementar los timers colocados en un arreglo apuntado por X,
; que es el unico parametro que recibe. Los timers son de 1 byte y son decremen-
; tados si su contenido es cero. Se utiliza el marcador $FF como fin del arreglo
;===============================================================================
Decre_Timers:

                ldaa 0,x
                cmpa #$00
                bne Label2        ;Salta si es diferente de cero

                inx
                
                bra Decre_Timers

Label2:
                cmpa #$FF
                beq FinDecreTimers
                
                dec 1,x+


                bra Decre_Timers

FinDecreTimers: Rts