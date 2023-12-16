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


;------ valores Generales ----------------------------------------

MODO_LIBRE:                EQU $C0
MODO_CONFIGURAR:        EQU $40
MODO_COMPETENCIA:        EQU $C0

FS_Pot:                        EQU $FF
Max_Brillo:                EQU 100

CERO_8_BITS:               EQU $00
CERO_16_BITS:              EQU $0000
CONVERSOR_VELOC:           EQU 1980 ;55 * 36
CONVERSOR_PANT_ON:         EQU 7200 ;200 * 36
CONVERSOR_PANT_OFF:        EQU 10800 ;300 * 36
INF:                       EQU $FF
;*******************************************************************
;                     Estructuras de Datos
;*******************************************************************

;--------------------- Tarea_Teclado -------------------------------
                        org $1000

MAX_TCL:               dB $06       ;Valor maximo del arreglo (1-6)
Tecla:                 ds 1         ;Variable retorno de sr Leer Teclado
Tecla_IN:              ds 1         ;Variable temp para validez de tecla pulsada
Cont_TCL:              ds 1         ;Ofset del arreglo resultado
Patron:                ds 1         ;Patron de lectura/escritura del puerto A
Est_Pres_TCL:          ds 2         ;Variable de estado para teclado
Num_Array:             ds 9         ;Arreglo de resultado 

tSupRebTCL:           EQU 10    ;Timer de sup rebotes para TCL, 10ms


;--------------------- Tarea_PantallaMUX ---------------------------
                        org $1020

Est_Pres_PantallaMUX:   ds 2
Dsp1:                   ds 1
Dsp2:                   ds 1
Dsp3:                   ds 1
Dsp4:                   ds 1
LEDS:                   ds 1
Cont_Dig:               ds 1
Brillo:                 ds 1
 ;BIN1:                   ds 1 ;BORRAR, NO NESESARIA
 ;BIN2:                   ds 1 ;BORRAR, NO NESESARIA


tTimerDigito:           EQU 2
MaxCountTicks:          EQU 100
GUIONES:                EQU $AA
OFF:                    EQU $BB

;--------------- Sub Rutinas de Conversion -------------------------
                        org $1029
        

BCD:                    ds 1
Cont_BCD:               ds 1
BCD1:                   ds 1
BCD2:                   ds 1


;---------------------- Tarea LCD ----------------------------------
                        org $102D

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

EOB:                    EQU $FF
Clear_LCD:              EQU $01
ADD_L1:                 EQU $80
ADD_L2:                 EQU $C0


;---------------------- Tarea_LeerPBn -------------------------------
                        org $103D

Est_Pres_LeerPB1:       ds 2         ;Variable de estado para Leer PB        
Est_Pres_LeerPB2:        ds 2

PortPB:                 EQU PTH ;Etiqueta para el puerto H
MaskPB1:                EQU $08 ;Mascara para push button PH0
MaskPB2:                EQU $01 ;Mascara para push button PH3

tSupRebPB:              EQU 10
tShortP:                EQU 25
tLongP:                 EQU 3

;-------------------- Tarea Configurar -----------------------------
                        org $1041
Est_Pres_TConfig:        ds 2
ValorVueltas:                ds 1
NumVueltas:                ds 1

LDConfig:                EQU $02
MinNumVueltas:                EQU 3
MaxNumVueltas:                EQU 25        

;----------------------- Tarea Libre -------------------------------
LDLibre:                EQU $01

;----------------------- Tarea Competencia -------------------------
                        org $1045

Est_Pres_TComp:                ds 2
Vueltas:                ds 1
DeltaT:                        ds 1
Veloc:                        ds 1

LDComp:                        EQU $04
tTimerVel:                EQU 100 ;
tTimerError:                EQU 30 ;3 segundos
VelocMin:                EQU 45 ;km/h 
VelocMax:                EQU 95 ;km/h

;--------------------- Tarea Brillo --------------------------------
                        org $104A
Est_Pres_TBrillo:        ds 2

tTimerBrillo:           EQU 4
MaskSCF:                EQU $80

;---------------------- Banderas -----------------------------------
                        org $1070

Banderas_1:             ds 1
ShortP1:                EQU $01      ;Bandera para short press1
LongP1:                 EQU $02      ;Bandera para long press
ShortP2:                EQU $04
LongP2:                        EQU $08
ARRAY_OK:               EQU $10      ;Bandera para arreglo listo

Banderas_2:             ds 1
RS:                     EQU $01
LCD_OK:                 EQU $02
FinSendLCD:             EQU $04
Second_Line:            EQU $08

;---------------------- Generales ----------------------------------
                        org $1080

LED_Testigo:                ds 1

tTimerLDTst:            EQU 1     ;Tiempo de parpadeo de LED testigo en segundos
Carga_TC5:                EQU 480


;tMinutosTCM:            EQU 2 ;BORRAR NO SE OCUPA
;tSegundosTCM:           EQU 20 ;BORRAR NO SE OCUPA
;BienvenidaLD:           EQU $55 ;BORRAR NO SE OCUPA
;TransitorioLD:          EQU $AA ;BORRAR NO SE OCUPA

;MinutosTCM:             ds 1 ;BORRAR NO SE OCUPA
;Est_Pres_TCM:           ds 2 ;BORRAR NO SE OCUPA


;---------------------- Tablas  ----------------------------------
                        org $1100

SEGMENT:        dB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00 ;Tabla codigos segmentos 

                        org $1110

Teclas:         dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$00,$0E,$0B ;Tabla TCL (MOVER)


;---------------------- Mensajes -----------------------------------
                        org $1200

Mensaje_Modo_Libre_L1:        FCC "  RUN METER 623 "
                        dB EOB
Mensaje_Modo_Libre_L2:        FCC "  MODO  LIBRE   "
                        dB EOB

Mensaje_Configurar_L1:        FCC " MODO CONFIGURAR"
                        dB EOB
Mensaje_Configurar_L2:        FCC " NUMERO VUELTAS "
                        dB EOB

Mensaje_Inicial_L1:        FCC "  RUN METER 623 "
                        dB EOB
Mensaje_Inicial_L2:        FCC "  ESPERANDO...  "
                        dB EOB

Mensaje_Competencia_L1: FCC "MOD. COMPETENCIA"
                        dB EOB
Mensaje_Competencia_L2:        FCC "VUELTA     VELOC"
                        dB EOB

Mensaje_Calculando_L1:        FCC "  RUN METER 623 "
                        dB EOB
Mensaje_Calculando_L2:        FCC "  CALCULANDO... "
                        dB EOB

Mensaje_de_Alerta_L1:        FCC "** VELOCIDAD ** "
                        dB EOB
Mensaje_de_Alerta_L2:        FCC "*FUERA DE RANGO*"
                        dB EOB

Mensaje_Fin_Comp_L1: FCC "FIN  COMPETENCIA"
                        dB EOB
Mensaje_Fin_Comp_L2:        FCC "VUELTA     VELOC"
                        dB EOB


;Mensaje_BienvenidaL1:   FCC "   ESCUELA DE   "
;                        dB EOB
;Mensaje_BienvenidaL2:   FCC " ING. ELECTRICA "
;                        db EOB

;Mensaje_TransitorioL1:  FCC "  uPROCESADORES "
;                        dB EOB
;Mensaje_TransitorioL2:  FCC "     IE0263     "
;                        dB EOB

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
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
Timer_RebPB1    ds 1    ;Timer supresion rebotes Leer PB
Timer_RebPB2    ds 1    ;Timer supresion rebotes Leer PB
Timer_RebTCL    ds 1    ;Timer de supresion de rebotes teclado


Fin_Base1mS      dB $FF

Tabla_Timers_Base10mS:

Timer100mS       ds 1    ;Timer para generar la base de tiempo de 100 mS
Timer_SHP1       ds 1    ;Timer para short press sensor 1
Timer_SHP2         ds 1    ;Timer para short press sensor 2
 
Fin_Base10ms     dB $FF

Tabla_Timers_Base100mS:

Timer1S          ds 1    ;Timer para generar la base de tiempo de 1 Seg.
TimerVel          ds 1
TimerError         ds 1
TimerPant         ds 1
TimerFinPant     ds 1
TimerBrillo         ds 1

Fin_Base100mS    dB $FF

Tabla_Timers_Base1S:


Timer_LP1         ds 1  ;Timer para long press
Timer_LP2         ds 1  ;Timer para long press
 ;SegundosTCM       ds 1
Timer_LED_Testigo ds 1  ;Timer para parpadeo de led testigo
Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================

                               Org $2000
;----------------- Leds y Y 7 Segmentos ----------------------------- 

        Bset DDRB,$FF     ;Habilitacion de puerto B como salida
        Bset DDRJ,$02     ;Habilitacion de puerto J.1 como salida
        BClr PTJ,$02      ;Salida J.1 como cero

;------------------- Led Testigo ---------------------------------------

        movb #$FF,DDRP    ;Habilitacion del led testigo tricolor
        bset PTP,$2F      ;Inicializacion del led testigo en azul

;------------------- Teclado Matricial ----------------------------------
        
        movb #$F0,DDRA    ;Define el puerto A como salida y entrada p/teclado
        bset PUCR,$01     ;Activa las resistencias de pullup del puerto A

;-------------------- Base de Tiempos Output Compare 4 --------------------

        movb #$90,TSCR1   ;Timer enable & Fast flag clear all
        movb #$00,TSCR2   ;Prescaler de 16

        movb #$10,TIOS    ;Timer Input Output set enable canal4
        movb #$10,TIE     ;Timer Interrutp enable canal4

        movb #$01,TCTL1   ;Toggle, bit de control canal4

        ldd TCNT
        addd #480        ;Interrupcion configurada para 20uS
        std TC4

;----------------- Inicializacion ATD (Potenciometro) -----------------------

        movb #$80,ATD0CTL2 ;Enciende ATD, No AFFC
        ldaa #160          ;Tiempo encendido, 10uS

Tiempo_Encendido:          ;Bucle para llegar a 10uS, tres ciclos de 
        deca               ;relog de 48MHz, 160 veces
        tsta
        bne Tiempo_Encendido

        movb #$10,ATD0CTL3 ;Dos muestras, no FIFO
        movb #$B3,ATD0CTL4 ;SMPn = 01, 4 ciclos de sample
                           ;SRES8 = 1, resoluc. 8 bits
                              ;PRS = 19 = $13, 600kHz

;------------------ Pantalla LCD e Inicializacion ----------------------------

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

        movb #$FF,Tecla      ;Inicializa el valor de tecla
        movb #$FF,Tecla_IN   ;Inicializa el valor de tecla_in
        movb #$00,Cont_TCL   ;Inicializa offset en cero
        movb #$00,Patron     ;Inicializa patron del lectura teclado
        movb #1,Cont_Dig     ;Digito de multiplexacion
        movb #$00,LEDS       ;Inicializa leds en cero
        movb #10,NumVueltas  ;Inicializa vueltas en 10

;        ldx #Num_Array     ;Inicializa el array con FF para los primeros
;        movb #$09,Cont_TCL ;9 valores.
;for:    movb #$FF,1,x+
;        dec Cont_TCL
;        bne for
;        movb #$00,Cont_TCL ;Fin de inicializacion de array

        Jsr Borrar_NumArray

        Lds #$3BFF                          ;Define puntero de pila
        Cli                                 ;Habilita interrupciones
        Clr Banderas_1                        ;Limpia las banderas
        Clr Banderas_2
        Movw #LeerPB1_Est1,Est_Pres_LeerPB1   ;Inicializa estado1 LeerPB1
         Movw #LeerPB2_Est1,Est_Pres_LeerPB2   ;Inicializa estado1 LeerPB2
        Movw #Teclado_Est1,Est_Pres_TCL     ;Inicializa estado1 Teclado
        Movw #PantallaMUX_Est1,Est_Pres_PantallaMUX ;init est1 pantallamux
        ;Movw #TCM_Est1,Est_Pres_TCM
        Movw #TareaLCD_Est1,EstPres_TareaLCD
        Movw #TareaBrillo_Est1,Est_Pres_TBrillo
        Movw #TConfig_Est1,Est_Pres_TConfig
        Movw #TComp_Est1,Est_Pres_TComp


        movb #90,Brillo
        ;movw #Mensaje_BienvenidaL1,Msg_L1
        ;movw #Mensaje_BienvenidaL2,Msg_L2
        bclr Banderas_2,LCD_OK

Despachador_Tareas


        Jsr Tarea_Modo_Libre
        Jsr Tarea_Configurar
        Jsr Tarea_Modo_Competencia
        Jsr Tarea_Brillo
        Jsr Tarea_Teclado
        Jsr Tarea_Led_Testigo
        Jsr Tarea_Leer_PB1
        Jsr Tarea_Leer_PB2
        Jsr Tarea_PantallaMUX

        brset Banderas_2,LCD_OK,No_Msg
        Jsr Tarea_LCD
No_Msg:


        ;Jsr Tarea_Conversion
        ;Jsr Tarea_TCM
        ;Jsr Tarea_Borra_TCL

        Bra Despachador_Tareas


;******************************************************************************
;                             TAREA MODO LIBRE
;******************************************************************************

Tarea_Modo_Libre:
                        brclr PTH,$C0,Ejecutar_Modo_Libre
                        bra Fin_Modo_Libre
Ejecutar_Modo_Libre:
                        brset LEDS,LDLibre,Modo_Libre_Ejecutado

                        movb #LDLibre,LEDS
                        
                        movb #OFF,BCD1
                        movb #OFF,BCD2

                        jsr BCD_7Seg

                        movw #Mensaje_Modo_Libre_L1,MSG_L1
                        movw #Mensaje_Modo_Libre_L2,MSG_L2

                        bclr Banderas_2,LCD_OK
Fin_Modo_Libre:
Modo_Libre_Ejecutado:
                        rts 

;******************************************************************************
;                             TAREA CONFIGURAR
;******************************************************************************

Tarea_Configurar:
                        ldx Est_Pres_TConfig
                        jsr 0,x
                        rts

;---------------------- TConfig Est1 --------------------------------------

TConfig_Est1:
                        ldaa PTH
                        anda #$C0
                        cmpa #MODO_CONFIGURAR
                        bne Fin_TConfig_Est1

                        movw #Mensaje_Configurar_L1,MSG_L1
                        movw #Mensaje_Configurar_L2,MSG_L2
                        bclr Banderas_2,LCD_OK

                        ldaa NumVueltas
                        jsr BIN_BCD_MUXP
                        movb BCD,BCD1

                        movb #OFF,BCD2

                        jsr BCD_7Seg
                        movb #LDConfig,LEDS

                        jsr Borrar_NumArray

                        movw #TConfig_Est2,Est_Pres_TConfig
Fin_TConfig_Est1:
                        rts

;---------------------- TConfig Est2 -----------------------------------------

TConfig_Est2:
                        ldaa PTH
                        anda #$C0
                        cmpa #MODO_CONFIGURAR
                        bne Out_TConfig

                        brclr Banderas_1,Array_OK,Fin_TConfig_Est2
                        
                        jsr BCD_BIN
                
                        ldaa ValorVueltas
                        cmpa #MinNumVueltas
                        blo TConfig_BArray
                        cmpa #MaxNumVueltas
                        bhi TConfig_BArray

                        jsr BIN_BCD_MUXP
                        movb BCD,BCD1
                        movb #OFF,BCD2

                        jsr BCD_7Seg
                        ;movb #LDConfig,LEDS
                        
                        movb ValorVueltas,NumVueltas
                        bra TConfig_BArray
Out_TConfig:
                        movw #TConfig_Est1,Est_Pres_TConfig
                        movb #10,ValorVueltas

TConfig_BArray:
                        jsr Borrar_NumArray

Fin_TConfig_Est2:
                        rts

;******************************************************************************
;                          TAREA MODO COMPETENCIA
;******************************************************************************

Tarea_Modo_Competencia:
                        ldx Est_Pres_TComp
                        jsr 0,x
                        rts

;---------------------- TComp Est1 ------------------------------------------
TComp_Est1:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est1
                        bra Fin_TComp_Est1
Ejecutar_TComp_Est1:

                        ldaa Vueltas
                        cmpa NumVueltas
                        beq Pasa_TComp_Est3
        
                        movw #Mensaje_Inicial_L1,MSG_L1
                        movw #Mensaje_Inicial_L2,MSG_L2
                        bclr Banderas_2,LCD_OK
                        
                        movb #LDComp,LEDS
                        movb #OFF,BCD1
                        movb #OFF,BCD2

                        jsr BCD_7Seg

                        movw #TComp_Est2,Est_Pres_TComp
                        bra Fin_TComp_Est1

Pasa_TComp_Est3:
                        movw #Mensaje_Fin_Comp_L1,MSG_L1
                        movw #Mensaje_Fin_Comp_L2,MSG_L2
                        bclr Banderas_2,LCD_OK
                        movw #TComp_Est3,Est_Pres_TComp

Fin_TComp_Est1:
                        rts
                        
;---------------------- TComp Est2 -------------------------------------------
TComp_Est2:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est2
                        bra Out_TComp_Est2
Ejecutar_TComp_Est2:
                        brclr Banderas_1,ShortP1,Fin_TComp_Est2
                        bclr Banderas_1,ShortP1
                        
                        movw #Mensaje_Calculando_L1,MSG_L1
                        movw #Mensaje_Calculando_L2,MSG_L2
                        bclr Banderas_2,LCD_OK

                        movb #tTimerVel,TimerVel
                        movw #TComp_Est4,Est_Pres_TComp
                        bra Fin_TComp_Est2
Out_TComp_Est2:
                        movw #TComp_Est1,Est_Pres_TComp
                        clr Vueltas
Fin_TComp_Est2:
                        rts

;--------------------- TComp_Est3 --------------------------------------------
TComp_Est3:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est3
                        bra Out_TComp_Est3
Ejecutar_TComp_Est3:
                        brclr Banderas_1,LongP1,Fin_TComp_Est3
                        bclr Banderas_1,LongP1
                        
Out_TComp_Est3:
                        movw #TComp_Est1,Est_Pres_TComp
                        clr Vueltas
Fin_TComp_Est3:
                        rts

;--------------------- TComp Est4 --------------------------------------------

TComp_Est4:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est4
                        bra Out_TComp_Est4
Ejecutar_TComp_Est4:
                        brclr Banderas_1,ShortP2,Fin_TComp_Est4
                        bclr Banderas_1,ShortP2
                        
                        jsr Calcula

                        ldaa Veloc
                        cmpa #VelocMax
                        bhi  Fuera_De_Rango
                        cmpa #VelocMin
                        blo Fuera_De_Rango

                        inc Vueltas
                        movw #TComp_Est5,Est_Pres_TComp
                        bra Fin_TComp_Est4

Out_TComp_Est4:        
                        movw #TComp_Est1,Est_Pres_TComp
                        clr Vueltas
                        bra Fin_TComp_Est4
Fuera_De_Rango:
                        
                        movw #Mensaje_de_Alerta_L1,MSG_L1
                        movw #Mensaje_de_Alerta_L2,MSG_L2
                        bclr Banderas_2,LCD_OK
                        
                        movb #GUIONES,BCD1
                        movb #GUIONES,BCD2

                        jsr BCD_7Seg

                        movb #tTimerError,TimerError
                        movw #TComp_Est6,Est_Pres_TComp
Fin_TComp_Est4:
                        rts

;---------------------- TComp Est5 ----------------------------------------
TComp_Est5:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est5
                        bra Out_TComp_Est5
Ejecutar_TComp_Est5:

                        tst TimerPant
                        bne Fin_TComp_Est5
                        
                        movw #Mensaje_Competencia_L1,MSG_L1
                        movw #Mensaje_Competencia_L2,MSG_L2
                        bclr Banderas_2,LCD_OK

                        ldaa Vueltas
                        jsr BIN_BCD_MUXP
                        movb BCD,BCD2

                        ldaa Veloc
                        jsr BIN_BCD_MUXP
                        movb BCD,BCD1

                        jsr BCD_7Seg

                        movw #TComp_Est7,Est_Pres_TComp
                        bra Fin_TComp_Est5
Out_TComp_Est5:
                        movw #TComp_Est1,Est_Pres_TComp
                        clr Vueltas
Fin_TComp_Est5:
                        rts

;---------------------- TComp Est 6 ----------------------------------------
TComp_Est6:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est6

                        clr Vueltas
                        bra To_State1_TComp_Est6

Ejecutar_TComp_Est6:
                        tst TimerError
                        bne Fin_TComp_Est6
                                        
To_State1_TComp_Est6:
                        movw #TComp_Est1,Est_Pres_TComp
Fin_TComp_Est6:
                        rts

;---------------------- TComp Est 7 -----------------------------------------
TComp_Est7:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est7

                        clr Vueltas
                        bra To_State1_TComp_Est7

Ejecutar_TComp_Est7:
                        tst TimerFinPant
                        bne Fin_TComp_Est7
                                        
To_State1_TComp_Est7:
                        movw #TComp_Est1,Est_Pres_TComp
Fin_TComp_Est7:
                        rts


;******************************************************************************
;                               TAREA BRILLO
;******************************************************************************

Tarea_Brillo:

                        ldx Est_Pres_TBrillo
                        jsr 0,x
                        rts

;---------------------- TareaBrillo Est1 ------------------------------------

TareaBrillo_Est1:
                        movb #tTimerBrillo,TimerBrillo
                        movw #TareaBrillo_Est2,Est_Pres_TBrillo

                        rts

;---------------------- TareaBrillo Est2 ------------------------------------

TareaBrillo_Est2:
                        tst TimerBrillo
                        bne Fin_TareaBrillo_Est2

                        movb #$87,ATD0CTL5
                        movw #TareaBrillo_Est3,Est_Pres_TBrillo

Fin_TareaBrillo_Est2:
                        rts

;---------------------- TareaBrillo Est3 ------------------------------------

TareaBrillo_Est3:
                        brclr ATD0STAT0,MaskSCF,Fin_TareaBrillo_Est3

                        ldd ADR00H   ;Primera Conversion
                        addd ADR01H ;Segunda Conversion

                        lsrd ;Division por 2, Promedio

                        ldy #Max_Brillo
                        emul ;Max_Brillo x Potenciometro
                        ldx #FS_Pot
                        ediv

                        tfr y,d
                        stab Brillo

                        movw #TareaBrillo_Est1,Est_Pres_TBrillo

Fin_TareaBrillo_Est3:
                        rts


;******************************************************************************
;                               TAREA TECLADO
;******************************************************************************

Tarea_Teclado:
                        ldx Est_Pres_TCL
                        jsr 0,x
                        rts

;------------------------------ Teclado Est1 ---------------------------------

Teclado_Est1:           jsr Leer_Teclado
                        
                        ldaa #$FF            ;Revisa si tecla pulsada es valida
                        cmpa Tecla           ;y si lo es:
                        beq Fin_Teclado_Est1

                        movb #tSupRebTCL,Timer_RebTCL  ;Carga supresion rebotes
                        movw #Teclado_Est2,Est_Pres_TCL ;Proximo estado
                        movb Tecla,Tecla_IN  ;variable temp tecla

Fin_Teclado_Est1:        rts

;---------------------------- Teclado Est2 -----------------------------------

Teclado_Est2:           tst Timer_RebTCL     ;Revisa si la sup de rebotes ya
                        bne Fin_Teclado_Est2 ;Termino.

                        jsr Leer_Teclado

                        ldaa Tecla_IN ;Utiliza la tecla presionada en est1
                        cmpa Tecla    ;y compara con tecla leida en est2
                        beq Next_TCL_Est_3

                        movw #Teclado_Est1,Est_Pres_TCL ;si no es la misma
                        bra Fin_Teclado_Est2            ;fue ruido y
                                                        ;pasa a est1
Next_TCL_Est_3:
                        movw #Teclado_Est3,Est_Pres_TCL ;Si es la misma pasa
                                                        ;de estado
Fin_Teclado_Est2:       rts


;--------------------------- Teclado Est 3 ----------------------------------

Teclado_Est3:           jsr Leer_Teclado
                        
                        ldaa Tecla_IN ;utiliza tecla presionada en estado1
                        cmpa Tecla    ;para ver si sigue presionada
                        beq Sigue_Presionada

                        movw #Teclado_Est4,Est_Pres_TCL ;si fue soltada, pasa
                        movw Tecla_IN,Tecla             ;al 4to estado
                        bra Fin_Teclado_Est3

Sigue_Presionada:
                        movw #Teclado_Est3,Est_Pres_TCL ;si si, se devuelve al
                                                        ;mismo estado
Fin_Teclado_Est3:        rts

;---------------------------- Teclado Est 4 --------------------------------

Teclado_Est4:           ldaa Cont_TCL ;Revisa si ya se llego al valor maximo
                        cmpa MAX_TCL  ;de datos ingresados.
                        bhs Long_Max

No_Long_Max:            tst Cont_TCL   ;si no se llego al val max, se prueba si
                        beq Array_Zero ;el valor es cero

Array_No_Zero:          ldaa #$0E             ;Si no es cero, se revisa si la
                        cmpa Tecla            ;tecla es enter o borrar y se
                        beq Borrar_Valor      ;decide terminar num array o
                        ldaa #$0B             ;borrarlo segun lo que llega.
                        cmpa Tecla            ;Como se puede ver los valores
                        beq Finalizar_Array   ;que se evaluan estan alrevez,
                        bra Agregar_Valor     ;esto es intencional y explicado
                                              ;a detalle en el informe.
Array_Zero:             ldaa #$0E
                        cmpa Tecla            ;Si el array es cero, se deben
                        beq Reestablecer      ;ignorar las teclas borrar y
                        ldaa #$0B             ;enter.
                        cmpa Tecla
                        beq Reestablecer
                        bra Agregar_Valor

Long_Max:               ldaa #$0E            ;Si ya se llego a la longitud max
                        cmpa Tecla           ;las unicas teclas validas son
                        beq Borrar_Valor     ;borrar y enter, por lo que se
                        ldaa #$0B            ;ignoran todas las demas
                        cmpa Tecla
                        beq Finalizar_Array
                        bra Reestablecer
                        
Agregar_Valor:          ldab Cont_TCL        ;Si en la evaluacion de teclas
                        ldy #Num_Array       ;oprimidas y estado del array
                        movb Tecla,b,y       ;se considera valido agregar un
                        inc Cont_TCL         ;valor, se agrega el valor y se
                        bra Reestablecer     ;Incrementa el offset.
                        
Borrar_Valor:           dec Cont_TCL         ;Si se tiene que borrar una tecla
                        ldab Cont_TCL        ;este bloque de codigo realiza
                        ldy #Num_Array       ;la accion decrementando el cont
                        movb #$FF,b,y        ;y sustituyendo por el valor FF
                        bra Reestablecer

Finalizar_Array:        bclr Cont_TCL,#$FF     ;Para finalizar arreglo se lev-
                        bset Banderas_1,ARRAY_OK ;anta bandera y borra offset

Reestablecer:           movw #Teclado_Est1,Est_Pres_TCL ;siempre se regresa al
                        bset Tecla,#$FF                 ;1st estado y se borran
                        bset Tecla_IN,#$FF              ;las variables de tecla

Fin_Teclado_Est4:       rts

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
;                               TAREA LEER PB1
;******************************************************************************

Tarea_Leer_PB1:
                        ldx Est_Pres_LeerPB1
                        jsr 0,x
                        rts
                        

; ---------------------------- Leer PB1 Estado 1 -----------------------------

LeerPB1_Est1:
                        brset PortPB,MaskPB1,PB1Est1_Retornar

                        movb #tSupRebPB,Timer_RebPB1
                        movb #tShortP,Timer_SHP1
                        movb #tLongP,Timer_LP1
                        
                        movw #LeerPB1_Est2,Est_Pres_LeerPB1
                        

PB1Est1_Retornar:        rts

; ----------------------------- LeerPB1_Est2 ----------------------------------

LeerPB1_Est2:
                        tst Timer_RebPB1
                        bne PB1Est2_Retornar
                        
                        brset PortPB,MaskPB1,Label1_21
                        
                        movw #LeerPB1_Est3,Est_Pres_LeerPB1
                        bra PB1Est2_Retornar
                        
Label1_21:               movw #LeerPB1_Est1,Est_Pres_leerPB1

PB1Est2_Retornar:        rts

; ----------------------------- LeerPB1_Est3 ----------------------------------

LeerPB1_Est3:
                        tst Timer_SHP1
                        bne PB1Est3_Retornar

                        brset PortPB,MaskPB1,Label1_31
                        
                        movw #LeerPB1_Est4,Est_Pres_LeerPB1
                        bra PB1Est3_Retornar
                        
Label1_31:               bset Banderas_1,ShortP1
                        movw #LeerPB1_Est1,Est_Pres_LeerPB1
                        
PB1Est3_Retornar:        rts

; ------------------------------ LeerPB1_Est4 ---------------------------------

LeerPB1_Est4:
                        tst Timer_LP1
                        bne Label1_Short
                        
                        brclr PortPB,MaskPB1,PB1Est4_Retornar
                        bset Banderas_1,LongP1
                        bra PB1Est4_State1
                        
Label1_Short:            brclr PortPB,MaskPB1,PB1Est4_Retornar
                        bset Banderas_1,ShortP1

PB1est4_State1:          movw #LeerPB1_Est1,Est_Pres_LeerPB1

PB1Est4_Retornar:        rts

;******************************************************************************
;                               TAREA LEER PB2
;******************************************************************************

Tarea_Leer_PB2:
                        ldx Est_Pres_LeerPB2
                        jsr 0,x
                        rts
                        

; ---------------------------- Leer PB Estado 1 -----------------------------

LeerPB2_Est1:
                        brset PortPB,MaskPB2,PB2Est1_Retornar

                        movb #tSupRebPB,Timer_RebPB2
                        movb #tShortP,Timer_SHP2
                        movb #tLongP,Timer_LP2
                        
                        movw #LeerPB2_Est2,Est_Pres_LeerPB2
                        

PB2Est1_Retornar:        rts

; ----------------------------- LeerPB_Est2 ----------------------------------

LeerPB2_Est2:
                        tst Timer_RebPB2
                        bne PB2Est2_Retornar
                        
                        brset PortPB,MaskPB2,Label2_21
                        
                        movw #LeerPB2_Est3,Est_Pres_LeerPB2
                        bra PB2Est2_Retornar
                        
Label2_21:               movw #LeerPB2_Est1,Est_Pres_leerPB2

PB2Est2_Retornar:        rts

; ----------------------------- LeerPB_Est3 ----------------------------------

LeerPB2_Est3:
                        tst Timer_SHP2
                        bne PB2Est3_Retornar

                        brset PortPB,MaskPB2,Label2_31
                        
                        movw #LeerPB2_Est4,Est_Pres_LeerPB2
                        bra PB2Est3_Retornar
                        
Label2_31:               bset Banderas_1,ShortP2
                        movw #LeerPB2_Est1,Est_Pres_LeerPB2
                        
PB2Est3_Retornar:        rts

; ------------------------------ LeerPB_Est4 ---------------------------------

LeerPB2_Est4:
                        tst Timer_LP2
                        bne Label2_Short
                        
                        brclr PortPB,MaskPB2,PB2Est4_Retornar
                        bset Banderas_1,LongP2
                        bra PB2Est4_State1
                        
Label2_Short:            brclr PortPB,MaskPB2,PB2Est4_Retornar
                        bset Banderas_1,ShortP2

PB2est4_State1:          movw #LeerPB2_Est1,Est_Pres_LeerPB2

PB2Est4_Retornar:        rts


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



;*****************************************************************************
;                  SUB RUTINA GENERAL BCD_BIN
;*****************************************************************************

BCD_BIN:
        		ldx #Num_Array
			ldaa 1,x+
			ldab #16
			
			mul ;Resultado R1:R2
			
			ldaa 0,x

			aba
			staa BCD

                        ldx #BCD
                        ldy #ValorVueltas
                        
                        Clr ValorVueltas ;No es nesesario del todo, agregado
                                         ;para visualizar resultados.

                        movb #5,Cont_BCD ;Inicializacion Contador Principal

for_loop:               lsr 0,x ;Rotacion hacia la derecha de valor BCD y
                        ;ror 1,x ;Num_BIN. Rotacion conjunta de 2 words,
                        ror 0,y ;desplazando con cero entrante y rotanto con
                        ;ror 1,y ;carry los 3 bytes restantes
                        
                        ;PARA LAS DOS DECADAS MAS SIGNIFICATIVAS
                        ldd #$F00F ;Carga mascara para aislar DEC alta y baja
                        anda 0,x   ;Aisla decada alta
                        andb 0,x   ;Aisla decada baja

                        ;RESTA 30 SI DEC ALTA MAYOR O IGUAL QUE 80
                        cmpa #$80
                        blo Hi_No_Sub_30
                        suba #$30
Hi_No_Sub_30:
                        ;RESTA 3 SI DEC BAJA MAYOR O IGUAL QUE 8
                        cmpb #$08
                        blo Hi_No_Sub_03
                        subb #$03
Hi_No_Sub_03:
                        aba ;Une las decadas filtradas
                        staa 0,x ;guarda las decadas filtradas

                        ;PARA LAS DOS DECADAS MENOS SIGNIFICATIVAS
                        ldd #$F00F ;Carga mascara denuevo
                        anda 1,x ;Aisla decada mas significativa
                        andb 1,x ;Aisla decada menos significativa

                        ;RESTA 30 SI LA DEC ALTA MAYOR O IGUAL QUE 80
                        cmpa #$80
                        blo Lo_No_Sub_30
                        suba #$30
Lo_No_Sub_30:
                        ;RESTA 3 SI LA DEC BAJA MAYOR O IGUAL QUE 8
                        cmpb #$08
                        blo Lo_No_Sub_03
                        subb #$03
Lo_No_Sub_03:
                        aba ;Une las decadas filtradas
                        staa 1,x ;Guarda las decadas filtradas


                        dec Cont_BCD ;Falta un desplazamiento con comparacion
                        tst Cont_BCD ;menos. Si no hemos terminado, salte
                        bne for_loop
                        
                        movb #3,Cont_BCD ;Carga segundo contador para los
                                      ;desplazamientos sin comparacion

                        ;DESPLAZAMIENTOS SIN COMPARACION:
Optimizacion:           lsr 0,x
                        ;ror 1,x
                        ror 0,y
                        ;ror 1,y
                        
                        dec Cont_BCD ;Falta un despl sin comparacion menos
                        tst Cont_BCD ;Si no hemos terminado, salte
                        bne Optimizacion

			rts

;*****************************************************************************
;                  SUB RUTINA GENERAL BCD_BIN
;*****************************************************************************

Calcula:
			ldab #tTimerVel
			subb TimerVel
			cmpb #CERO_8_BITS
			beq Velocidad_Infinita

			stab DeltaT
			
			clra
			tfr d,x
			ldy #CERO_16_BITS
			ldd #CONVERSOR_VELOC
			ediv
		
			tfr y,d
			stab Veloc

			tfr d,x
			ldy #CERO_16_BITS
			ldd #CONVERSOR_PANT_ON
			ediv

			tfr y,d
			stab TimerPant

			ldab Veloc
			clra
			tfr d,x
			ldy #CERO_16_BITS
			ldd #CONVERSOR_PANT_OFF
			ediv

			tfr y,d
			stab TimerFinPant
			
			bra Fin_Calcula
			
Velocidad_Infinita:
			movb #INF,Veloc	
Fin_Calcula:
			rts

;*****************************************************************************
;                  SUB RUTINA GENERAL BIN BCD MUXP
;*****************************************************************************
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
;                                   TAREA TCM
;******************************************************************************
;Tarea_TCM:
 ;                       ;ldx Est_Pres_TCM
 ;                       jsr 0,x
 ;                       rts

;------------------------------ TCM Est1 -------------------------------------

;TCM_Est1:
 ;                       movb #tMinutosTCM,MinutosTCM
 ;                       movb #tSegundosTCM,SegundosTCM
 ;                       movb #tMinutosTCM,BIN2
 ;                       movb #tSegundosTCM,BIN1
 ;
 ;                       brclr Banderas_1,ShortP,Fin_TCM_Est1
 ;                       movb #TransitorioLD,LEDS
 ;
 ;                       movw #Mensaje_TransitorioL1,Msg_L1
 ;                       movw #Mensaje_TransitorioL2,Msg_L2
 ;                       bclr Banderas_2,LCD_OK
 ;
 ;                       movw #TCM_Est2,Est_Pres_TCM
 ;
 ;
;Fin_TCM_Est1:                rts

;----------------------------- TCM Est2 --------------------------------------

;TCM_Est2:
 ;                       movb MinutosTCM,BIN2
 ;                       ldaa SegundosTCM
 ;                       deca
 ;                       staa BIN1
 ;
 ;                       tst SegundosTCM
 ;                       bne Fin_TCM_Est2
 ;
 ;                       tst MinutosTCM
 ;                       bne Continue_TCM
  ;
  ;                      movb #tMinutosTCM,MinutosTCM
  ;                      movb #tSegundosTCM,SegundosTCM
  ;
  ;                      movb #tMinutosTCM,BIN2
  ;                      movb #tSegundosTCM,BIN1
  ;
  ;                      movb #BienvenidaLD,LEDS
  ;                      movw #Mensaje_BienvenidaL1,Msg_L1
  ;                      movw #Mensaje_BienvenidaL2,Msg_L2
  ;                      bclr Banderas_2,LCD_OK
  ;
  ;                      movw #TCM_Est1,Est_Pres_TCM
  ;                      bra Fin_TCM_Est2
  ;
;Continue_TCM:
;                        dec MinutosTCM
;                        movb #60,SegundosTCM
;Fin_TCM_Est2:
;                        rts


;*****************************************************************************
;                               TAREA CONVERSION
;*****************************************************************************

;Tarea_Conversion:
;                        ldaa BIN1
;                        jsr BIN_BCD_MUXP
;                        movb BCD,BCD1
;
;                        ldaa BIN2
;                        jsr BIN_BCD_MUXP
;                        movb BCD,BCD2
;
;                        jsr BCD_7Seg
;
;                        rts

;*****************************************************************************
;                TAREA BORRA TCL (anterior TAREA LED PB)
;*****************************************************************************

Borrar_NumArray:   
                        ldx #Num_Array      ;se utiliza el mismo ciclo
                        movb #$08,Cont_TCL  ;implementado en el main, para
forCLR:                 movb #$FF,1,x+      ;limpiar el arreglo. Y se agrega
                        dec Cont_TCL        ;poner la bandera array en cero.
                        bne forCLR
                        movb #$00,Cont_TCL
                        bclr Banderas_1,ARRAY_OK

FIN_Led:                Rts

;*****************************************************************************
;                  SUB RUTINA GENERAL LEER TECLADO
;*****************************************************************************

Leer_Teclado:
                        ldab #$00        ;Inicializa offset de filas
                        movb #$EF,Patron ;Inicializa patron de lectura portA

Next_Row:
                        movb Patron,PORTA ;Se carga patron en puerto A y se
                        nop               ;espera a que las capacitancias no
                        nop               ;causen problemas en la lectura de
                        nop               ;valores.

                        brclr PORTA,$01,Column_1 ;Salta al valor leido en una
                        brclr PORTA,$02,Column_2 ;columna de la respectiva fila
                        brclr PORTA,$04,Column_3 ;y si no se lee ningun valor
                        cmpb #$09                ;se revisa que no se encuentra
                        beq No_Valor             ;en la ultima fila y
                        bra Prep_Next_Row        ;se cambia a la sigte fila
Column_1:
                        ldy #Teclas          ;para columna 1, solo se ocupa el
                        movb b,y,Tecla       ;offset de la fila en la que se
                        bra End_Leer_Teclado ;encuentra.
Column_2:
                        ldy #Teclas          ;se suma el valor del offset de la
                        addb #$01            ;columna al de la fila sobre el
                        movb b,y,Tecla       ;mismo acumulador.
                        bra End_Leer_Teclado
Column_3:
                        ldy #Teclas          ;solo se ocupa sumar el offset
                        addb #$02            ;para las primeras tres columnas
                        movb b,y,Tecla
                        bra End_Leer_Teclado
Prep_Next_Row:
                        rol Patron   ;si no se encuentra un valor, se rota el
                        addb #$03    ;patron y se incrementa en uno el offset
                        bra Next_Row ;de la fila.
No_Valor:
                        movb #$FF,Tecla ;si no se lee nada, se retorna con FF

End_Leer_Teclado:        rts


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