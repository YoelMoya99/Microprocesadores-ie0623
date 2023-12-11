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
;---------------------------- CAD (ATD) ---------------------------------
                                org $1000
;------------------------------------------------------------------------
tTimerATD:                EQU 5
NivelProm:                dS 2
Nivel:                    ds 1
Volumen:                  ds 1
Est_Pres_ATD:             ds 2

BCD:                      ds 1
Cont_BCD:                 ds 1

;------------------------------ SCI ---------------------------------
                                org $1020
;------------------------------------------------------------------------
tTimerTerminal:           EQU 1
Est_Pres_Terminal:        ds 2
MSG_ptr:                  ds 2

;------------------------------ UC ---------------------------------
                                org $1040
;------------------------------------------------------------------------
tTimer_Tanq_lleno:        EQU 5
Est_Pres_UC:              ds 2
Data_Terminal:            ds 2


;---------------------- Banderas -----------------------------------
                        org $1070
;-------------------------------------------------------------------

Banderas_1:             ds 1
Prcnt_15:               EQU $01
Prcnt_90:               EQU $02
Mensage:                EQU $04
Clear:                  EQU $08 

;---------------------- Generales ----------------------------------
                        org $1080
;-------------------------------------------------------------------

tTimerLDTst:            EQU 1     ;Tiempo de parpadeo de LED testigo en segundos

;---------------------- Mensajes -----------------------------------
                        org $1200
;-------------------------------------------------------------------
EOB:                       EQU $FF
CR:                        EQU $0D
LF:                        EQU $0A
FF:                        EQU $0C
BS:                        EQU $08


MSG_Encabezado:         dB FF
                        FCC "       UNIVERSIDAD DE COSTA RICA "
                        dB CR,LF
                        FCC "     ESCUELA DE INGENIERIA ELECTRICA"
                        dB CR,LF
                        FCC "           MICROPROCESADORES"
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

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500 ;Cambio de org de tarea5
Tabla_Timers_BaseT:

Timer20uS       ds 1   ;Timer 20uS con base tiempo de interrupcion

Fin_BaseT       db $FF

Tabla_Timers_Base20uS:

Timer1mS        ds 1    ;Timer 1mS para generar la base tiempo 1mS

Fin_Base20uS:    db $FF

Tabla_Timers_Base1mS:

Timer10mS       ds 1    ;Timer para generar la base de tiempo 10 mS

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

        ;Bset DDRB,$FF     ;Habilitacion de puerto B como salida
        ;Bset DDRJ,$02     ;Habilitacion de PB
        ;BClr PTJ,$02

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
        Movb #tTimerTerminal,TimerTerminal ;Inicia timer de terminal

        Lds #$3BFF                          ;Define puntero de pila
        Cli                                 ;Habilita interrupciones

        Movw #Tarea_ATD_Est1,Est_Pres_ATD
        Movw #Tarea_Terminal_Est1,Est_Pres_Terminal
        Movw #Tarea_UC_Est1,Est_Pres_UC

Despachador_Tareas

        Jsr Tarea_Led_Testigo
        Jsr Tarea_ATD
        Jsr Tarea_Unidad_Controladora
        Jsr Tarea_Terminal

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