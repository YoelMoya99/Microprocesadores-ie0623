 ;******************************************************************************
 ;                              ENCABEZADO DEL PROGRAMA
 ;******************************************************************************
 ; Estudiante: Yoel Moya Carmona
 ; Carne: B75262
 ;------------------- Describcion general del codigo --------------------------
 ;
 ; Se implemento una tarea la cual es la encargada de realizar la lectura de
 ; los valores que se ingresan del teclado, unicamente de las primeras 3
 ; columnas completas, tomando los botones *, 0 y # como los botones cero,
 ; borrado y enter respectivamente.
 ; El programa consta de las siguientes tareas:
 ;      1. Led Testigo
 ;      2. Teclado
 ;      3. Leer PB
 ;      4. Borra TCL
 ; Las cuales se encargan de: verificar que la maquina de tiempos sobre la
 ; cual se construye todo el programa se encuentra funcionando. Leer
 ; constantemente los valores ingresados por el teclado e ingresarlos en un
 ; arreglo de resultado, asi como validar la finalizacion de este arreglo
 ; por medio de una bandera. Leer el boton pulsador asociado a la posicion
 ; 0 del puerto B, y borrar el arreglo entero al recibir un long press.
 ;-----------------------------------------------------------------------------

#include registers.inc
 ;******************************************************************************
 ;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
 ;******************************************************************************
                                Org $3E66 ;OutputCompare (OC) maquina de tiempos
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers de la aplicacion ----

tTimer20uS:           EQU 1     ;Base tiempo 20uS, freq interrupcion
tTimer1mS:            EQU 50    ;Base de tiempo de 1 mS (100 uS x 10)
tTimer10mS:           EQU 10    ;Base de tiempo de 10 mS (1 mS x 10)
tTimer100mS:          EQU 10    ;Base de tiempo de 100 mS (10 mS x 100)
tTimer1S:             EQU 10    ;Base de tiempo de 1 segundo (100 mS x 10)


;*******************************************************************
;                     Estructuras de Datos
;*******************************************************************


;--------------------- Tarea_PantallaMUX ---------------------------
                        org $1020
;-------------------------------------------------------------------

Est_Pres_PantallaMUX:   ds 2
Dsp1:                   ds 1
Dsp2:                   ds 1
Dsp3:                   ds 1
Dsp4:                   ds 1
LEDS:                   ds 1
Cont_Dig:               ds 1
Brillo:                 ds 1
BIN1:                   ds 1
BIN2:                   ds 1
BCD:                    ds 1
Cont_BCD:               ds 1
BCD1:                   ds 1
BCD2:                   ds 1

tTimerDigito:           EQU 2
MaxCountTicks:          EQU 100

;---------------------- Tarea LCD ----------------------------------
                        org $102F
;-------------------------------------------------------------------
EOB:                    EQU $FF

IniDsp:                 dB $28 ;Function set
                        dB $28 ;Function set 2
                        dB $06 ;Entry Mode set
                        dB $0C ;Display ON, Cursor OFF, No Blinking
                        dB $FF ;End Of table

Punt_LCD:               ds 2
CharLCD:                ds 1
Msg_L1:                 ds 2
Msg_L2:                 ds 2
EstPres_SendLCD:        ds 2
EstPres_TareaLCD:       ds 2

tTimer2mS:              EQU 2
tTimer260uS:            EQU 13
tTimer40uS:             EQU 2

Clear_LCD:              EQU $01
ADD_L1:                 EQU $80
ADD_L2:                 EQU $C0



;---------------------- Banderas -----------------------------------
                        org $1070
;-------------------------------------------------------------------

Banderas_1:             ds 1
Prcnt_15:               EQU $01
Prcnt_90:               EQU $02
Mensage:                EQU $04
Clear:                  EQU $08 

Banderas_2:             ds 1
RS:                     EQU $01
LCD_OK:                 EQU $02
FinSendLCD:             EQU $04
Second_Line:            EQU $08

;---------------------- Generales ----------------------------------
                        org $1080
;-------------------------------------------------------------------

tTimerLDTst:            EQU 1     ;Tiempo de parpadeo de LED testigo en segundos
BienvenidaLD:           EQU $55
TransitorioLD:          EQU $AA

Est_Pres_TCM:           ds 2


;---------------------- Tablas  ----------------------------------
                        org $1100
;-------------------------------------------------------------------

SEGMENT:        dB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F ;Tabla codigos segmentos 


;---------------------- Mensajes -----------------------------------
                        org $1200
;-------------------------------------------------------------------
CR:                        EQU $0D
LF:                        EQU $0A
FF:                        EQU $0C
BS:                           EQU $08

Mensaje_BienvenidaL1:   FCC "   ESCUELA DE   "
                        dB EOB
Mensaje_BienvenidaL2:   FCC " ING. ELECTRICA "
                        db EOB

Mensaje_TransitorioL1:  FCC "  uPROCESADORES "
                        dB EOB
Mensaje_TransitorioL2:  FCC "     IE0263     "
                        dB EOB

MSG_Encabezado:         dB FF
                        FCC "       Universidad de Costa Rica"
                        dB CR,LF
                        FCC "     Escuela de Ingenieria Electrica"
                        dB CR,LF
                        FCC "           Microprocesadores"
                        dB CR,LF
                        FCC "                IE0623"
                        dB CR,LF,CR,LF 
                        dB EOB

MSG_Normal:             db CR
                        FCC "VOLUMEN CALCULADO: ("
ASCII_Volumen:          ds 2
                        FCC ")"
                        dB EOB
                        
MSG_Tanq_lleno:         dB CR,LF,CR,LF
                        FCC "Vaciando Tanque, Bomba Apagada "
                        dB CR,BS,CR,BS,CR
                        db EOB

MSG_Alarma:             dB CR,LF,CR,LF
                        FCC "Alarma: El Nivel Esta Bajo     "
                        dB CR,BS,CR,BS,CR
                        db EOB

MSG_Clear:              dB CR,LF,CR,LF
                        FCC "                               "
			dB CR,BS,CR,BS,CR
                        db EOB
;---------------------------- CAD (ATD) ---------------------------------
                                org $1500
;------------------------------------------------------------------------
tTimerATD:                EQU 5
NivelProm:                dS 2
Nivel:                    ds 1
Volumen:                  ds 1
Est_Pres_ATD:             ds 2

;------------------------------ SCI ---------------------------------
                                org $1550
;------------------------------------------------------------------------
tTimerTerminal:           EQU 1
Est_Pres_Terminal:        ds 2
MSG_ptr:                  ds 2

;------------------------------ UC ---------------------------------
                                org $1600
;------------------------------------------------------------------------
tTimer_Tanq_lleno:        EQU 5
Est_Pres_UC:              ds 2
Data_Terminal:            ds 2


;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1700 ;Cambio de org de tarea5
Tabla_Timers_BaseT:

Timer20uS       ds 1   ;Timer 20uS con base tiempo de interrupcion
Timer40uS       ds 1
Timer260uS      ds 1
Fin_BaseT       db $FF

Tabla_Timers_Base20uS:

Timer1mS        ds 1    ;Timer 1mS para generar la base tiempo 1mS
Counter_Ticks   ds 1

Fin_Base20uS:    db $FF

Tabla_Timers_Base1mS:

Timer10mS       ds 1    ;Timer para generar la base de tiempo 10 mS
Timer2mS        ds 1
TimerDigito     ds 1    ;Timer de digito de pantalla MUX


Fin_Base1mS      dB $FF

Tabla_Timers_Base10mS:

Timer100mS       ds 1    ;Timer para generar la base de tiempo de 100 mS

Fin_Base10ms     dB $FF

Tabla_Timers_Base100mS:

Timer1S          ds 1    ;Timer para generar la base de tiempo de 1 Seg.
TimerATD          ds 1    ;Timer CAD(ATD) de 500mS

Fin_Base100mS    dB $FF

Tabla_Timers_Base1S:

Timer_LED_Testigo ds 1  ;Timer para parpadeo de led testigo
TimerTerminal     ds 1
Timer_Tanq_lleno  ds 1

Fin_Base1S        dB $FF


;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================

                               Org $2000

        Bset DDRB,$FF     ;Habilitacion de puerto B como salida
        Bset DDRJ,$02     ;Habilitacion de PB
        BClr PTJ,$02

        movb #$FF,DDRP    ;Habilitacion del led testigo tricolor
        bset PTP,$2F      ;Inicializacion del led testigo en azul
        
;-----------------------------------------------------------------------------
        movb #$90,TSCR1   ;Timer enable & Fast flag clear all
        movb #$00,TSCR2   ;Prescaler de 16

        movb #$10,TIOS    ;Timer Input Output set enable canal4
        movb #$10,TIE     ;Timer Interrutp enable canal4

        movb #$01,TCTL1   ;Toggle, bit de control canal4

        ldd TCNT
        addd #480        ;Interrupcion configurada para 20uS
        std TC4
;-----------------------------------------------------------------------------

        ;Inicializacion de la pantalla LCD, Hardware
        movb #$FF,DDRK
        movb #tTimer20uS,Timer20uS
        movb #tTimer1mS,Timer1mS
        movw #SendLCD_Est1,EstPres_SendLCD
        movw #IniDsp,Punt_LCD
        ldy Punt_LCD
        Clr Banderas_2
        Cli

Send_IniDsp:
        ldy Punt_LCD
        movb 1,y+,CharLCD
        sty Punt_LCD
        
        brset CharLCD,$FF,Send_Clear
        
Loop1_Tarea_SendLCD:
        jsr Tarea_SendLCD
        
        brclr Banderas_2,FinSendLCD,Loop1_Tarea_SendLCD
        
        bclr Banderas_2,FinSendLCD
        bra Send_IniDsp

Send_Clear:
        movb #Clear_LCD,CharLCD
        
Loop2_Tarea_SendLCD:

        jsr Tarea_SendLCD
        
        brclr Banderas_2,FinSendLCD,Loop2_Tarea_SendLCD
        
        bclr Banderas_2,FinSendLCD
        movb #tTimer2mS,Timer2mS
        
Dos_mS_Wait:
        tst Timer2mS
        bne Dos_mS_Wait

;----------------------- Inicializacion de CAD (ATD) -------------------------

        movb #$80,ATD0CTL2 ;Enciende CAD, No AFFC
        ldaa 160 ;Tiempo de Encendido, 10uS

Tiempo_De_Encendido: 
        deca
        tsta
        bne Tiempo_De_Encendido

        movb #$20,ATD0CTL3 ;4 conversiones x ciclo, No FIFO
        movb #$10,ATD0CTL4 ;Prescaler 16 para 705kHz
        
;--------------------- Inicializacion Terminal SCI ---------------------------

        movb #$00,SC1BDH
        movb #$27,SC1BDL
        movb #$00,SC1CR1
        movb #$08,SC1CR2
        ldaa SC1CR1
        movb #$00,SC1DRL
        
        Movw #Tarea_Terminal_Est1,Est_Pres_Terminal
        movb #0,TimerTerminal
        movw #MSG_Encabezado,MSG_ptr
Init_Terminal:
        jsr Tarea_Terminal
        brset SC1CR2,$08,Init_Terminal

;-------------------- Inicializacion de microrele ---------------------------
        bset DDRE,$04



;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movb #tTimer20uS,Timer20uS
        Movb #tTimer1mS,Timer1mS
        Movb #tTimer10mS,Timer10mS         ;Inicia los timers de bases de tiempo
        Movb #tTimer100mS,Timer100mS
        Movb #tTimer1S,Timer1S
        Movb #tTimerLDTst,Timer_LED_Testigo  ;inicia timer parpadeo led testigo
        Movb #tTimerDigito,TimerDigito  ;Inicia timer de digito pantallaMUX
        Movb #tTimerTerminal,TimerTerminal ;Inicia timer de terminal

        movb #1,Cont_Dig   ;Digito de multiplexacion
        movb #BienvenidaLD,LEDS     ;Inicializa leds en pares


        Lds #$3BFF                          ;Define puntero de pila
        Cli                                 ;Habilita interrupciones
        Clr Banderas_2
        Movw #PantallaMUX_Est1,Est_Pres_PantallaMUX ;init est1 pantallamux
        Movw #TCM_Est1,Est_Pres_TCM
        Movw #TareaLCD_Est1,EstPres_TareaLCD
        Movw #Tarea_ATD_Est1,Est_Pres_ATD
        Movw #Tarea_Terminal_Est1,Est_Pres_Terminal
        Movw #Tarea_UC_Est1,Est_Pres_UC

        movb #90,Brillo
        movw #Mensaje_BienvenidaL1,Msg_L1
        movw #Mensaje_BienvenidaL2,Msg_L2
        bclr Banderas_2,LCD_OK
        
        movw #$3030,ASCII_Volumen

Despachador_Tareas

;        brset Banderas_2,LCD_OK,No_Msg
;        Jsr Tarea_LCD
;No_Msg:

        Jsr Tarea_Led_Testigo
;        Jsr Tarea_Conversion
;        Jsr Tarea_PantallaMUX
;        Jsr Tarea_TCM

        Jsr Tarea_ATD
        Jsr Tarea_Unidad_Controladora
        Jsr Tarea_Terminal
;        Jsr Tarea_Terminal

        Bra Despachador_Tareas


;******************************************************************************
;                             TAREA Unidad Controladora
;******************************************************************************

Tarea_Unidad_Controladora:
                        ldx Est_Pres_UC
                        jsr 0,x
                        rts

;------------------------- Tarea UC Est1 -------------------------------------
Tarea_UC_Est1:
                        Clr Banderas_1
                        ldaa Nivel
                        cmpa #2
                        ble MenosDe15Porciento

                        cmpa #12
                        blo Fin_Tarea_UC_Est1 ;Menos del 90 porciento

                        bset Banderas_1,Prcnt_90
                        bset Banderas_1,Mensage
                        movb #tTimer_Tanq_lleno,Timer_Tanq_lleno
                        movw #MSG_Tanq_lleno,Data_Terminal
                        bclr PORTE,$04
                        bra Fin_Tarea_UC_Est1
                        
MenosDe15Porciento:     bset Banderas_1,Prcnt_15
                        bset Banderas_1,Mensage
                        movw #MSG_Alarma,Data_Terminal
                        bset PORTE,$04
                        
Fin_Tarea_UC_Est1:
                        movw #Tarea_UC_Est2,Est_Pres_UC
                        rts

;---------------------------- Tarea UC Est2 --------------------------------

Tarea_UC_Est2:
                        brset SC1CR2,$08,Fin_Tarea_UC_Est2
                        brclr Banderas_1,Mensage,Go_To_UC_Est1

                        bclr Banderas_1,Mensage
                        movw Data_Terminal,MSG_ptr
                        
                        brclr Banderas_1,Clear,Go_To_UC_Est3
Go_To_UC_Est1:
                        movw #Tarea_UC_Est1,Est_Pres_UC
                        bra Fin_Tarea_UC_Est2
Go_To_UC_Est3:
                        movw #Tarea_UC_Est3,Est_Pres_UC

Fin_Tarea_UC_Est2:
                        rts

;---------------------- Tarea UC Est3 ----------------------------------------
Tarea_UC_Est3:
                        brset Banderas_1,Prcnt_15,Tst_30_Porciento
                        brset Banderas_1,Prcnt_90,Tst_90_Porciento
                        bra Fin_Tarea_UC_Est3
		        
Tst_90_Porciento:
                        tst Timer_Tanq_lleno
                        bne Fin_Tarea_UC_Est3
                        bra Clear_Terminal

Tst_30_Porciento:        ldaa Nivel
                        cmpa #4
                        blo Fin_Tarea_UC_Est3

                        bclr Banderas_1,Prcnt_15

Clear_Terminal:         bset Banderas_1,Mensage
                        bset Banderas_1,Clear
                        movw #MSG_Clear,Data_Terminal

                        movw #Tarea_UC_Est2,Est_Pres_UC

Fin_Tarea_UC_Est3:      rts
                        
;******************************************************************************
;                             TAREA TERMINAL
;******************************************************************************

Tarea_Terminal:
                        ldx Est_Pres_Terminal
                        jsr 0,x
                        rts

;------------------------- Tarea_Terminal_Est1 -----------------------------
Tarea_Terminal_Est1:
                        tst TimerTerminal
                        bne Fin_Tarea_Terminal_Est1

                        movb #tTimerTerminal,TimerTerminal
                        movb #$08,SC1CR2
                        ldaa SC1CR1
                        movb #$00,SC1DRL
                        movw #Tarea_Terminal_Est2,Est_Pres_Terminal
                        bset PORTB,$01
                        jsr Tarea_BIN_ASCII
                        
Fin_Tarea_Terminal_Est1:
                        rts

;----------------------- Tarea_Terminal_Est2 ----------------------------
Tarea_Terminal_Est2:
                        brclr SC1SR1,$80,Fin_Tarea_Terminal_Est2

                        ldaa SC1SR1
                        ldx MSG_ptr
                        ldaa 1,x+
                        
                        cmpa #EOB
                        beq Final_Trama

                        staa SC1DRL
                        stx MSG_ptr
                        
                        bra Fin_Tarea_Terminal_Est2

Final_Trama:                
                        bclr SC1CR2,$08
                        movw #Tarea_Terminal_Est1,Est_Pres_Terminal
                        movw #MSG_Normal,MSG_ptr
                        bclr PORTB,$01

Fin_Tarea_Terminal_Est2:
                        rts

;******************************************************************************
;                             TAREA ATD
;******************************************************************************
Tarea_ATD:
                        ldx Est_Pres_ATD
                        jsr 0,x
                        rts

;-------------------------- Tarea_ATD_Est1 -----------------------------------
Tarea_ATD_Est1:
                        tst TimerATD
                        bne Fin_Tarea_ATD_Est1

                        movb #$87,ATD0CTL5 ;Inicia ciclo de conversion
                        movw #Tarea_ATD_Est2,Est_Pres_ATD
                        movb #tTimerATD,TimerATD

Fin_Tarea_ATD_Est1:
                        rts


;-------------------------- Tarea ATD Est 2 ----------------------------------
Tarea_ATD_Est2:
                        brclr ATD0STAT0,$80,Fin_Tarea_ATD_Est2
                        
                        jsr Calcula

                        movw #Tarea_ATD_Est1,Est_Pres_ATD
Fin_Tarea_ATD_Est2:
                        rts

;******************************************************************************
;                             TAREA LCD
;******************************************************************************
Tarea_LCD:
                        ldx EstPres_TareaLCD
                        jsr 0,x
                        rts

;---------------------------- TareaLCD Est1 ----------------------------------

TareaLCD_Est1:
                        bclr Banderas_2,FinSendLCD
                        bclr Banderas_2,RS

                        brset Banderas_2,Second_Line,Load_Second_Line
Load_First_Line:
                        movb #ADD_L1,CharLCD
                        movw Msg_L1,Punt_LCD
                        bra Load_TLCD_Est2
Load_Second_LIne:
                        movb #ADD_L2,CharLCD
                        movw Msg_L2,Punt_LCD
Load_TLCD_Est2:
                        jsr Tarea_SendLCD

                        movw #TareaLCD_Est2,EstPres_TareaLCD

                        rts

;---------------------- TareaLCD Est2 ----------------------------------------
TareaLCD_Est2:
                        brclr Banderas_2,FinSendLCD,Call_Send_LCD

                        bclr Banderas_2,FinSendLCD
                        bset Banderas_2,RS

                        ldy Punt_LCD
                        movb 1,y+,CharLCD
                        sty Punt_LCD

                        brset CharLCD,EOB,ToggleLine_EndMsg

Call_Send_LCD:
                        jsr Tarea_SendLCD
                        bra Fin_TareaLCD_Est2

ToggleLine_EndMsg:
                        brset Banderas_2,Second_Line,EndMsg 
                        
                        bset Banderas_2,Second_Line
                        bra Load_TareaLCD_Est1
EndMsg:
                        bclr Banderas_2,Second_Line
                        bset Banderas_2,LCD_OK
                        
Load_TareaLCD_Est1:
                        movw #TareaLCD_Est1,EstPres_TareaLCD

Fin_TareaLCD_Est2:      rts

;******************************************************************************
;                            TAREA SEND LCD
;******************************************************************************

Tarea_SendLCD:
                        ldx EstPres_SendLCD
                        jsr 0,x
                        rts

;-------------------------- SendLCD_Est1 -------------------------------------

SendLCD_Est1:
                        ldaa #$F0
                        anda CharLCD
                        lsra
                        lsra
                        staa PORTK

                        brclr Banderas_2,RS,ComandoLCD_Est1
                        bset PORTK,$01
                        bra No_ComandoLCD_Est1
ComandoLCD_Est1:
                        bclr PORTK,$01
No_ComandoLCD_Est1:
                        bset PORTK,$02
                        movb #tTimer260uS,Timer260uS
                        movw #SendLCD_Est2,EstPres_SendLCD

Fin_SendLCD_Est1:       rts

;----------------------- SendLCD_Est2 ----------------------------------------

SendLCD_Est2:
                        tst Timer260uS
                        bne Fin_SendLCD_Est2

                        bclr PORTK,$02

                        ldaa #$0F
                        anda CharLCD
                        lsla
                        lsla
                        staa PORTK

                        brclr Banderas_2,RS,ComandoLCD_Est2

                        bset PORTK,$01
                        bra No_ComandoLCD_Est2
ComandoLCD_Est2:
                        bclr PORTK,$01
No_ComandoLCD_Est2:
                        bset PORTK,$02
                        movb #tTimer260uS,Timer260uS
                        movw #SendLCD_Est3,EstPres_SendLCD

Fin_SendLCD_Est2:
                        rts

;---------------------- SendLCD_Est3 -----------------------------------------

SendLCD_Est3:
                        tst Timer260uS
                        bne Fin_SendLCD_Est3

                        bclr PORTK,$02
                        movb #tTimer40uS,Timer40uS
                        movw #SendLCD_Est4,EstPres_SendLCD

Fin_SendLCD_Est3:       rts

;---------------------- SendLCD_Est4 -----------------------------------------

SendLCD_Est4:
                        tst Timer40uS
                        bne Fin_SendLCD_Est4
                        bset Banderas_2,FinSendLCD
                        movw #SendLCD_Est1,EstPres_SendLCD
                        
Fin_SendLCD_Est4:       rts

;******************************************************************************
;                                   TAREA TCM
;******************************************************************************
Tarea_TCM:
                        ldx Est_Pres_TCM
                        jsr 0,x
                        rts

;------------------------------ TCM Est1 -------------------------------------

TCM_Est1:
                        ;movb #tMinutosTCM,MinutosTCM
                        ;movb #tSegundosTCM,SegundosTCM
                        ;movb #tMinutosTCM,BIN2
                        ;movb #tSegundosTCM,BIN1

                        ;brclr Banderas_1,ShortP,Fin_TCM_Est1
                        ;movb #TransitorioLD,LEDS

                        ;movw #Mensaje_TransitorioL1,Msg_L1
                        ;movw #Mensaje_TransitorioL2,Msg_L2
                        ;bclr Banderas_2,LCD_OK
                        
                        ;movw #TCM_Est2,Est_Pres_TCM
                        

Fin_TCM_Est1:           ;     rts

;----------------------------- TCM Est2 --------------------------------------

TCM_Est2:
                        ;movb MinutosTCM,BIN2
                        ;ldaa SegundosTCM
                        ;deca
                        ;staa BIN1
                        
                        ;tst SegundosTCM
                        ;bne Fin_TCM_Est2

                        ;tst MinutosTCM
                        ;bne Continue_TCM

                        ;movb #tMinutosTCM,MinutosTCM
                        ;movb #tSegundosTCM,SegundosTCM

                        ;movb #tMinutosTCM,BIN2
                        ;movb #tSegundosTCM,BIN1

                        ;movb #BienvenidaLD,LEDS
                        ;movw #Mensaje_BienvenidaL1,Msg_L1
                        ;movw #Mensaje_BienvenidaL2,Msg_L2
                        ;bclr Banderas_2,LCD_OK

                        ;movw #TCM_Est1,Est_Pres_TCM
                        ;bra Fin_TCM_Est2

Continue_TCM:
                        ;dec MinutosTCM
                        ;movb #60,SegundosTCM
Fin_TCM_Est2:
                        ;rts
;******************************************************************************
;                               TAREA PANTALLA MUX
;******************************************************************************

Tarea_PantallaMUX:
                        ldx Est_Pres_PantallaMUX
                        jsr 0,x
                        rts

;------------------------------ PantallaMUX Est1 ---------------------------------

PantallaMUX_Est1:  
                        tst TimerDigito
                        bne Fin_PantallaMUX_Est1
                        
                        movb #tTimerDigito,TimerDigito
                        ldaa Cont_Dig
                        
                        cmpa #1
                        beq Display_1

                        cmpa #2
                        beq Display_2

                        cmpa #3
                        beq Display_3

                        cmpa #4
                        beq Display_4
Display_LEDS:
                        bclr PTJ,$02
                        movb LEDS,PORTB
                        movb #01,Cont_Dig
                        bra Cambio_Estado
                        
Display_1:
                        bclr PTP,$01
                        movb Dsp1,PORTB
                        inc Cont_Dig
                        bra Cambio_Estado
Display_2:
                        bclr PTP,$02
                        movb Dsp2,PORTB
                        bset PORTB,$80
                        inc Cont_Dig
                        bra Cambio_Estado
Display_3:
                        bclr PTP,$04
                        movb Dsp3,PORTB
                        bset PORTB,$80
                        inc Cont_Dig
                        bra Cambio_Estado
Display_4:
                        bclr PTP,$08
                        movb Dsp4,PORTB
                        inc Cont_Dig

Cambio_Estado:
                        movb #MaxCountTicks,Counter_Ticks
                        movw #PantallaMUX_Est2,Est_Pres_PantallaMUX

Fin_PantallaMUX_Est1:   rts


;------------------------------ PantallaMUX Est2 ---------------------------------

PantallaMUX_Est2:  
                        ldaa #MaxCountTicks
                        suba Counter_Ticks
                        
                        cmpa Brillo
                        blo Fin_PantallaMUX_Est2
                        
                        bset PTP,$0F
                        bset PTJ,$02

                        movw #PantallaMUX_Est1,Est_Pres_PantallaMUX
                        
Fin_PantallaMUX_Est2:   rts


;*****************************************************************************
;                               TAREA BIN ASCII
;*****************************************************************************

Tarea_BIN_ASCII:
                        ldaa Volumen
                        jsr BIN_BCD_General

                        ldaa BCD
                        ldab BCD

                        andb #$0F
                        addb #$30

                        lsra
                        lsra
                        lsra
                        lsra

                        adda #$30

                        std ASCII_Volumen

                        rts

;*****************************************************************************
;                               TAREA Calcula
;*****************************************************************************

Calcula:

                        ldd ADR00H  ;Primera Conversion
                        addd ADR01H ;Segunda Conversion
                        addd ADR02H ;Tercera Conversion
                        addd ADR03H ;Cuarta Conversion
                        
                        lsrd ;Division por 4
                        lsrd

                        std NivelProm ;Guarda nivel Promedio

                        ldy #20 ;Se carga valor maximo 20m
                        emul ;20 x (Potenciometro)
                        ldy #$0000
                        ldx #$03FF ;Valor_MAX_Potenciometro
                        ediv ; 20 * (Potenciometro) / V_MAX_Potenc.

                        pshy
                        tfr y,d

                        stab Nivel ;Guarda Nivel en metros (byte)

                        puly ;Trae Valor completo de Nivel
                        ldd #$0007 ;pi * (1.5)^2 =~ 7 m^2 (Area)
                        emul ; (~Area) x Nivel
                        
                        cmpb #91
                        blo Continuar
                        ldab #91
Continuar:
                        stab Volumen 

                        rts

;*****************************************************************************
;                               TAREA CONVERSION
;*****************************************************************************

Tarea_Conversion:
                        ldaa BIN1
                        jsr BIN_BCD_General
                        movb BCD,BCD1

                        ldaa BIN2
                        jsr BIN_BCD_General
                        movb BCD,BCD2

                        jsr BCD_7Seg

                        rts


;*****************************************************************************
;                  SUB RUTINA GENERAL BIN BCD
;*****************************************************************************
BIN_BCD_General:
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
                        rts

;*****************************************************************************
;                  SUB RUTINA GENERAL BCD - 7 SEG
;*****************************************************************************

BCD_7Seg:
                        
                        ldy #BCD2
                        ldx #SEGMENT
SegundoDisplay:
                        ldd #$F00F
                        anda 0,y
                        lsra
                        lsra
                        lsra
                        lsra
                        andb 0,y

                        cpy #BCD1
                        beq Display34
Display12:
                        movb a,x,Dsp1
                        movb b,x,Dsp2
                        ldy #BCD1
                        bra SegundoDisplay
Display34:                
                        movb a,x,Dsp3
                        movb b,x,Dsp4
                
Fin_BCD_7Seg:                rts

;******************************************************************************
;                        TAREA LED TESTIGO
;******************************************************************************
Tarea_Led_Testigo:
                tst Timer_LED_Testigo
                bne FinLedTest

                brset PTP,$20,Green
                brset PTP,$40,Blue
Red:
                bclr PTP,$10
                bset PTP,$20
                bra Init_Timer_LED
Green:
                bclr PTP,$20
                bset PTP,$40
                bra Init_Timer_LED
Blue:
                bclr PTP,$40
                bset PTP,$10
                
Init_Timer_LED:
                Movb #tTimerLDTst,Timer_LED_Testigo

FinLedTest      Rts

;******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;******************************************************************************

Maquina_Tiempos:

                ldd TCNT
                addd #480        ;Interrupcion configurada para 20uS
                std TC4

                ldx #Tabla_Timers_BaseT
               
                jsr Decre_Timers
              
                tst Timer20uS
                bne Retornar

                movb #tTimer20uS,Timer20uS
                ldx #Tabla_Timers_Base20uS

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

Retornar:        Rti
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