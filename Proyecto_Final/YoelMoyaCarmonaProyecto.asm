 ;******************************************************************************
 ;                              ENCABEZADO DEL PROGRAMA
 ;******************************************************************************
 ; Estudiante: Yoel Moya Carmona
 ; Carne: B75262
 ;------------------- Describcion general del codigo --------------------------
 ;
 ; Este es el codigo de la aplicacion del runmeter-623, el cual depende del 
 ; codigo desarrollado en las tareas 2, 4, y 5. Estos codigos realizan una 
 ; conversion de BCD a binario, implementan la lectura de teclado multiplexado
 ; exactamente a como se definio en el enunciado de la tarea 4, y la 
 ; implementacion de pantallas multiplexadas de siete segmentos junto con la
 ; implementacion de la pantalla LCD, exactamente a como se define en la tarea
 ; 5.
 ;
 ; El programa utiliza tres tareas principales para definir tres modos de
 ; funcionamiento: Modo Libre, Modo Configurar, y Modo Competencia, los cuales
 ; definen un modo defalult donde el sistema no realiza ninguna tarea, un
 ; un modo configurar, el cual define la cantidad de vueltas que un ciclista 
 ; desea realizar, y un Modo Competencia, donde se cuenta la cantidad de vueltas
 ; y la velocidad promedio con la que el ciclista completo dicha vuelta.
 ;
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

;---------------------- Inicializacion de Hardware -------------------------
INIT_PORTB:		EQU $FF ;
INIT_PORTJ:		EQU $02 ;
SALIDA_PORTJ:		EQU $02 ;

INIT_PORTP:		EQU $FF ;Valor para inicializar puerto P como salida
SALIDA_PORTP:           EQU $2F ;

INIT_PORTA:		EQU $F0 ;
PULLUP_EN_A:		EQU $01 ;

ENABLE_AND_FLAG:	EQU $90 ; 
OC4_PRS:		EQU $00 ;
TIMER_CHANNEL:		EQU $10 ;
INTERRUPT_ENABLE:	EQU $10 ;
TOGGLE_BIT:		EQU $01 ;

ATD_ENABLE_AND_FLAG:	EQU $80 ;
ESPERA_10uS:		EQU 160 ;
MUESTRAS_Y_FIFO:	EQU $10 ;
SAMPLE_8BITS_PRS:	EQU $B3 ;

INIT_PORTK:		EQU $FF ;

;--------------------------- valores Para Modo -------------------------------

MODO_LIBRE:                EQU $C0
MODO_CONFIGURAR:           EQU $40
MODO_COMPETENCIA:          EQU $C0
EVALUAR_MODO_MSK:	   EQU $C0

;------------------------ Valores para LED Testigo ---------------------------

RED_COLOR:		EQU $20 ;Mascara para poner color rojo en led
GREEN_COLOR:		EQU $40 ;mascara para poner color verde en led
BLUE_COLOR:		EQU $10 ;Mascara para poner color azul en led

;------------------------- Valores para Potenciometro ------------------------

FS_Pot:                    EQU $FF
Max_Brillo:                EQU 100

;-------------------------- Valores para Tarea Calcula -----------------------

CERO_8_BITS:               EQU $00   ;Valor poner en cero acumuladores A, B
CERO_16_BITS:              EQU $0000 ;Valor poner en cero acumulador D,X,Y
CONVERSOR_VELOC:           EQU 1980  ;55 * 36 Factor de conversion para pasar
                                      ; obtener velocidad en Km/h
CONVERSOR_PANT_ON:         EQU 7200  ;200 * 36 Factor de conversion para
                                     ;obtener el tiempo de encendido pantalla
CONVERSOR_PANT_OFF:        EQU 10800 ;300 * 36 Factor de conversion para
                                     ;obtener el tiempo de apagado de pantalla 
INF:                       EQU $FF   ;Valor utilizado si el tiempo promedio es
                                     ;cero para evitar division por cero.

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

Est_Pres_PantallaMUX:   ds 2 ;Variable de estado para las pantallas
                             ;Multiplexadas
Dsp1:                   ds 1 ;MSB para pantalla de 7 segmentos
Dsp2:                   ds 1 ;2do MSB para pantalla de 7 segmentos
Dsp3:                   ds 1 ;2do LSB para pantalla de 7 segmentos
Dsp4:                   ds 1 ;LSB para pantalla de 7 segmentos
LEDS:                   ds 1 ;Variable que contiene patron de leds
Cont_Dig:               ds 1 ;digito proximo a encender en el
                             ;algoritmo de multiplexacion
Brillo:                 ds 1 ;Brillo de los leds y 7 segmentos 


tTimerDigito:           EQU 2   ;Tiempo max de encendido para digito
MaxCountTicks:          EQU 100 ;Cantidad max de grados de brillo
GUIONES:                EQU $AA ;Guiones para veloc fuera de rango,
                                ;Offset de tabla SEGMENT
OFF:                    EQU $BB ;Pantallas 7 Seg apagadas, offset de
                                ;tabla SEGMENT

;--------------- Sub Rutinas de Conversion -------------------------
                        org $1029
        
BCD:                    ds 1 ;Numero resultado en BCD para BIN->BCD
Cont_BCD:               ds 1 ;Contador para iteraciones de conversion
                             ;del XS3 y DFCT3
BCD1:                   ds 1 ;Offset de tabla SEGMENT para numeros en
                             ;DSP3 y 4
BCD2:                   ds 1 ;Offset de tabla SEGMENT para numeros en
                             ;DSP1 y 2

;---------------------- Tarea LCD ----------------------------------
                        org $102D

IniDsp:                 dB $28 ;Function set
                        dB $28 ;Function set 2
                        dB $06 ;Entry Mode set
                        dB $0C ;Display ON, Cursor OFF, No Blinking
                        dB $FF ;End Of table

Punt_LCD:               ds 2 ;Puntero de la siguiente posicion de memoria
                             ;que contiene el Byte a enviar
CharLCD:                ds 1 ;Byte a enviar a pantalla
Msg_L1:                 ds 2 ;Puntero de la dir. base de la linea 1 a enviar
Msg_L2:                 ds 2 ;Puntero de la dir. base de la linea 2 a enviar
EstPres_SendLCD:        ds 2 ;Variable de estado para sendLCD
EstPres_TareaLCD:       ds 2 ;Variable de estado para TareaLCD

tTimer2mS:              EQU 2  ;Timer para realizar clear en la init de
                               ;Hardware de Pantalla LCD
tTimer260uS:            EQU 13 ;Tiempo de duracion para el pulso de enable
tTimer40uS:             EQU 2  ;tiempo de procesamiento de un byte

EOB:                    EQU $FF ;END OF BLOCK, define final de mensajes
Clear_LCD:              EQU $01 ;Comando para realizar clr a LCD
ADD_L1:                 EQU $80 ;Dir. linea 1 de memoria p/ mensaje a LCD
ADD_L2:                 EQU $C0 ;Dir. linea 2 de memoria p/ mensaje a LCD


;---------------------- Tarea_LeerPBn -------------------------------
                        org $103D

Est_Pres_LeerPB1:       ds 2 ;Variable de estado para Leer PB1 (Sensor1 PH3)        
Est_Pres_LeerPB2:       ds 2 ;Variable de estado para leer PB2 (Sensor2 PH0)

PortPB:                 EQU PTH ;Etiqueta para el puerto H
MaskPB1:                EQU $08 ;Mascara para push button PH3
MaskPB2:                EQU $01 ;Mascara para push button PH0

tSupRebPB:              EQU 10 ;10mS para supresion de rebotes
tShortP:                EQU 25 ;250mS para short press
tLongP:                 EQU 3  ;3S para long press

;-------------------- Tarea Configurar -----------------------------
                        org $1041

Est_Pres_TConfig:       ds 2 ;Variable de estado para tarea configurar
ValorVueltas:           ds 1 ;Variable temporar para vueltas
NumVueltas:             ds 1 ;Variable que contiene valor max de vueltas

LDConfig:               EQU $02 ;Patron de leds para modo config
MinNumVueltas:          EQU 3   ;Minima cantidad de vueltas permitida
MaxNumVueltas:          EQU 25  ;Maxima cantidad de vueltas permitida        

;----------------------- Tarea Libre -------------------------------
LDLibre:                EQU $01 ;Patron de Leds para modo libre

;----------------------- Tarea Competencia -------------------------
                        org $1045

Est_Pres_TComp:         ds 2 ;Variable de estado para tarea competencia
Vueltas:                ds 1 ;Variable contadora de vueltas dadas
DeltaT:                 ds 1 ;Tiempo transcurrido entre sensores
Veloc:                  ds 1 ;Velocidad promedio del ciclista

LDComp:                 EQU $04 ;Patron de leds para tarea competencia
tTimerVel:              EQU 100 ;Timer para medir tiempo entre sensores
tTimerError:            EQU 30  ;3 segundos display mensaje de error
VelocMin:               EQU 45  ;Velocidad minima permitida en km/h 
VelocMax:               EQU 95  ;Velocidad maxima permitida en km/h

;--------------------- Tarea Brillo --------------------------------
                        org $104A

Est_Pres_TBrillo:       ds 2    ;Variable de estado de tarea brillo
tTimerBrillo:           EQU 4   ;400mS entre conversiones del ATD
MaskSCF:                EQU $80 ;Mascara para evaluar el fin de ciclo
                                ;de conversiones

;---------------------- Banderas -----------------------------------
                        org $1070

Banderas_1:             ds 1
ShortP1:                EQU $01 ;Bandera para short press1
LongP1:                 EQU $02 ;Bandera para long press1
ShortP2:                EQU $04 ;Bandera para short press2
LongP2:                 EQU $08 ;Bandera para long press2
ARRAY_OK:               EQU $10 ;Bandera para arreglo listo, de teclado

Banderas_2:             ds 1
RS:                     EQU $01 ;Para determinar si es comando o dato (LCD)
LCD_OK:                 EQU $02 ;Evaluar si LCD esta enviando mensaje o libre
FinSendLCD:             EQU $04 ;Evaluar si SendLCD termino de enviar 1 byte
Second_Line:            EQU $08 ;Bandera para enviar la segunda linea a LCD

;---------------------- Generales ----------------------------------
                        org $1080

LED_Testigo:            ds 1 ;Variable para led testigo

tTimerLDTst:            EQU 1   ;Tiempo de parpadeo de LED testigo en segundos
Carga_TC5:              EQU 480 ;Tiempo de carga del output compare

;---------------------- Tablas  ----------------------------------
                        org $1100

SEGMENT:        dB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00 ;Tabla codigos segmentos 
                                                                   ;Ultimos dos valores son
                                                                   ;Guiones y apagado
                                                                   ;Respectivamente
                        org $1110

Teclas:         dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$00,$0E,$0B ;Tabla TCL


;---------------------- Mensajes -----------------------------------
                        org $1200

Mensaje_Modo_Libre_L1:  FCC "  RUN METER 623 "
                        dB EOB
Mensaje_Modo_Libre_L2:  FCC "  MODO  LIBRE   "
                        dB EOB

Mensaje_Configurar_L1:  FCC " MODO CONFIGURAR"
                        dB EOB
Mensaje_Configurar_L2:  FCC " NUMERO VUELTAS "
                        dB EOB

Mensaje_Inicial_L1:     FCC "  RUN METER 623 "
                        dB EOB
Mensaje_Inicial_L2:     FCC "  ESPERANDO...  "
                        dB EOB

Mensaje_Competencia_L1: FCC "MOD. COMPETENCIA"
                        dB EOB
Mensaje_Competencia_L2: FCC "VUELTA     VELOC"
                        dB EOB

Mensaje_Calculando_L1:  FCC "  RUN METER 623 "
                        dB EOB
Mensaje_Calculando_L2:  FCC "  CALCULANDO... "
                        dB EOB

Mensaje_de_Alerta_L1:   FCC "** VELOCIDAD ** "
                        dB EOB
Mensaje_de_Alerta_L2:   FCC "*FUERA DE RANGO*"
                        dB EOB

Mensaje_Fin_Comp_L1:    FCC "FIN  COMPETENCIA"
                        dB EOB
Mensaje_Fin_Comp_L2:    FCC "VUELTA     VELOC"
                        dB EOB


;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:

Timer20uS           ds 1 ;Timer 20uS con base tiempo de interrupcion
Timer40uS           ds 1 ;Timer de procesamiento de 1 byte por LCD 
Timer260uS          ds 1 ;Tiempo de ancho de pulso del strobe para LCD

Fin_BaseT:  db EOB

Tabla_Timers_Base20uS:

Timer1mS            ds 1 ;Timer 1mS para generar la base tiempo 1mS
Counter_Ticks       ds 1 ;Tiempo de brillo de leds y 7 segmentos

Fin_Base20uS:  db EOB

Tabla_Timers_Base1mS:

Timer10mS          ds 1 ;Timer para generar la base de tiempo 10 mS
Timer2mS           ds 1 ;Tiempo de espera para clr de LCD 
TimerDigito        ds 1 ;Timer de digito de pantalla MUX
Timer_RebPB1       ds 1 ;Timer supresion rebotes Leer PB1
Timer_RebPB2       ds 1 ;Timer supresion rebotes Leer PB2
Timer_RebTCL       ds 1 ;Timer de supresion de rebotes teclado

Fin_Base1mS:  dB EOB

Tabla_Timers_Base10mS:

Timer100mS         ds 1 ;Timer para generar la base de tiempo de 100 mS
Timer_SHP1         ds 1 ;Timer para short press sensor 1
Timer_SHP2         ds 1 ;Timer para short press sensor 2
 
Fin_Base10ms:  dB EOB

Tabla_Timers_Base100mS:

Timer1S             ds 1 ;Timer para generar la base de tiempo de 1 Seg.
TimerVel            ds 1 ;Time para medir tiempo entre sensores
TimerError          ds 1 ;Tiempo de duracion de msg de error en pantalla
TimerPant           ds 1 ;Tiempo desde sensor 2 hasta encendido de pantalla
TimerFinPant        ds 1 ;Tiempo de apagado de pantalla
TimerBrillo         ds 1 ;Tiempo de calculo de conversion de ATD para brillo

Fin_Base100mS:  dB EOB

Tabla_Timers_Base1S:

Timer_LP1          ds 1  ;Timer para long press1
Timer_LP2          ds 1  ;Timer para long press2
Timer_LED_Testigo  ds 1  ;Timer para parpadeo de led testigo

Fin_Base1S:     dB EOB

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================

                               Org $2000
;----------------- Leds y Y 7 Segmentos ----------------------------- 

        Bset DDRB,INIT_PORTB     ;Habilitacion de puerto B como salida
        Bset DDRJ,INIT_PORTJ     ;Habilitacion de puerto J.1 como salida
        BClr PTJ,SALIDA_PORTJ      ;Salida J.1 como cero

;------------------- Led Testigo ---------------------------------------

        movb #INIT_PORTP,DDRP    ;Habilitacion del led testigo tricolor
        bset PTP,SALIDA_PORTP    ;Inicializacion del led testigo en azul

;------------------- Teclado Matricial ----------------------------------
        
        movb #INIT_PORTA,DDRA    ;Define el puerto A como salida y entrada p/teclado
        bset PUCR,PULLUP_EN_A     ;Activa las resistencias de pullup del puerto A

;-------------------- Base de Tiempos Output Compare 4 --------------------

        movb #ENABLE_AND_FLAG,TSCR1   ;Timer enable & Fast flag clear all
        movb #OC4_PRS,TSCR2   ;Prescaler de 16

        movb #TIMER_CHANNEL,TIOS    ;Timer Input Output set enable canal4
        movb #INTERRUPT_ENABLE,TIE     ;Timer Interrutp enable canal4

        movb #TOGGLE_BIT,TCTL1   ;Toggle, bit de control canal4

        ldd TCNT
        addd #Carga_TC5        ;Interrupcion configurada para 20uS
        std TC4

;----------------- Inicializacion ATD (Potenciometro) -----------------------

        movb #ATD_ENABLE_AND_FLAG,ATD0CTL2 ;Enciende ATD, No AFFC
        ldaa #ESPERA_10uS          ;Tiempo encendido, 10uS

Tiempo_Encendido:          ;Bucle para llegar a 10uS, tres ciclos de 
        deca               ;relog de 48MHz, 160 veces
        tsta
        bne Tiempo_Encendido

        movb #MUESTRAS_Y_FIFO,ATD0CTL3 ;Dos muestras, no FIFO
        movb #SAMPLE_8BITS_PRS,ATD0CTL4 ;SMPn = 01, 4 ciclos de sample
                           ;SRES8 = 1, resoluc. 8 bits
                              ;PRS = 19 = $13, 600kHz

;------------------ Pantalla LCD e Inicializacion ----------------------------

        ;Inicializacion de la pantalla LCD, Hardware
        movb #INIT_PORTK,DDRK                       ;Define el puerto K como salida
        movb #tTimer20uS,Timer20uS           ;Inicia timers para maq tiempos
        movb #tTimer1mS,Timer1mS
        movw #SendLCD_Est1,EstPres_SendLCD   ;inicia maq estados para enviar a LCD
        movw #IniDsp,Punt_LCD                ;Inicia puntero de tabla de init
        ldy Punt_LCD
        Clr Banderas_2                       ;Borra banderas a usar por LCD
        Cli                                      ;Enciende maq tiempos

 ; Bucle 1: Carga datos de la tabla e incrementa punteros. Revisa si
 ; ya se llego al final de la tabla antes de enviarlo a LCD
Send_IniDsp:
        ldy Punt_LCD
        movb 1,y+,CharLCD
        sty Punt_LCD
        
        brset CharLCD,EOB,Send_Clear
        
 ; Bucle 2: para que la maquina que envia datos a LCD evolucione. Cuando
 ; Esta termina, se carga un siguiente dato en el bucle anterior. 
Loop1_Tarea_SendLCD:
        jsr Tarea_SendLCD
        
        brclr Banderas_2,FinSendLCD,Loop1_Tarea_SendLCD
        
        bclr Banderas_2,FinSendLCD
        bra Send_IniDsp

 ; Bucle 3: Una vez que se termina de enviar la tabla de datos de init
 ; Se realiza el clear de la pantalla, donde se debe esperar 2mS
Send_Clear:
        movb #Clear_LCD,CharLCD
        
Loop2_Tarea_SendLCD:

        jsr Tarea_SendLCD
        
        brclr Banderas_2,FinSendLCD,Loop2_Tarea_SendLCD
        
        bclr Banderas_2,FinSendLCD
        movb #tTimer2mS,Timer2mS

 ;Tiempo de espera para que LCD procese el clear:        
Dos_mS_Wait:
        tst Timer2mS
        bne Dos_mS_Wait


;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movb #tTimer20uS,Timer20uS          ;Inicia Base tiempos de Maq Tiempos
        Movb #tTimer1mS,Timer1mS            ;Inicia base tiempos de 1 mS
        Movb #tTimer10mS,Timer10mS          ;Inicia los timers de bases de tiempo
        Movb #tTimer100mS,Timer100mS        ;Inicia base tiempos de 100mS
        Movb #tTimer1S,Timer1S              ;Inicia base tiempos 1S
        Movb #tTimerLDTst,Timer_LED_Testigo ;inicia timer parpadeo led testigo
        Movb #tTimerDigito,TimerDigito      ;Inicia timer de digito pantallaMUX

        movb #$FF,Tecla      ;Inicializa el valor de tecla
        movb #$FF,Tecla_IN   ;Inicializa el valor de tecla_in
        movb #$00,Cont_TCL   ;Inicializa offset en cero
        movb #$00,Patron     ;Inicializa patron del lectura teclado
        movb #1,Cont_Dig     ;Digito de multiplexacion
        movb #$00,LEDS       ;Inicializa leds en cero
        movb #10,NumVueltas  ;Inicializa vueltas en 10
        movb #90,Brillo
        
        Jsr Borrar_NumArray ;Inicializa el array en $FF

        Lds #$3BFF     ;Define puntero de pila
        Cli            ;Habilita interrupciones
        Clr Banderas_1 ;Limpia las banderas
        Clr Banderas_2

        Movw #LeerPB1_Est1,Est_Pres_LeerPB1         ;Inicializa est1 LeerPB1
        Movw #LeerPB2_Est1,Est_Pres_LeerPB2         ;Inicializa est1 LeerPB2
        Movw #Teclado_Est1,Est_Pres_TCL             ;Inicializa est1 Teclado
        Movw #PantallaMUX_Est1,Est_Pres_PantallaMUX ;Inicializa est1 PantMUX
        Movw #TareaLCD_Est1,EstPres_TareaLCD        ;Inicializa est1 tareaLCD
        Movw #TareaBrillo_Est1,Est_Pres_TBrillo     ;Inicializa est1 TBrillo
        Movw #TConfig_Est1,Est_Pres_TConfig         ;Inicializa est1 TConfig
        Movw #TComp_Est1,Est_Pres_TComp             ;inicializa est1 TComp

        bclr Banderas_2,LCD_OK ;Clear para que las tareas Modo puedan
                               ;asignar mensajes a LCD en la primer pasada

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
        Bra Despachador_Tareas


;******************************************************************************
;                             TAREA MODO LIBRE
;******************************************************************************

Tarea_Modo_Libre:
                        brclr PTH,MODO_LIBRE,Ejecutar_Modo_Libre ;Switch en modo
                        bra Fin_Modo_Libre			 ;libre?
Ejecutar_Modo_Libre:
                        brclr Banderas_2,LCD_OK,Fin_Modo_Libre ;LCD Esta ocupado?
                        brset LEDS,LDLibre,Modo_Libre_Ejecutado ;Ya fue asignado
								;Modo Libre antes?

                        movb #LDLibre,LEDS ;Asigna patron de leds
                        
                        movb #OFF,BCD1 ;Asigna Ofset para 7 seg apagados
                        movb #OFF,BCD2

                        jsr BCD_7Seg ;Pone dsp1 a 4 apagados

                        movw #Mensaje_Modo_Libre_L1,MSG_L1 ;Asigna mensajes de modo
                        movw #Mensaje_Modo_Libre_L2,MSG_L2 ;libre a LCD
                        bclr Banderas_2,LCD_OK ;enciende LCD
                        
                        bra Modo_Libre_Ejecutado
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
                        ldaa PTH               ;Switches en modo Configuracion?
                        anda #EVALUAR_MODO_msk ;Aisla 2 MSB y
                        cmpa #MODO_CONFIGURAR  ;Los compara
                        bne Out_TConfig_Est1
                        
                        brclr Banderas_2,LCD_OK,Fin_TConfig_Est1 ;LCD esta libre?

                        movw #Mensaje_Configurar_L1,MSG_L1 ;Asignar mensajes a
                        movw #Mensaje_Configurar_L2,MSG_L2 ;LCD
                        bclr Banderas_2,LCD_OK             ;Habilita LCD

                        ldaa NumVueltas   ;Envia NumVueltas (Default o asignado)
                        jsr BIN_BCD_MUXP  ;A 7 Segmentos
                        movb BCD,BCD1

                        movb #OFF,BCD2 ;Apaga 7 Seg mas significativos

                        jsr BCD_7Seg ;Asigna valores a pantalla
                        movb #LDConfig,LEDS ;Asigna patron de leds del modo

                        jsr Borrar_NumArray ;Borra arreglo de numeros por si
					    ;Ya fue asignado antes

                        movw #TConfig_Est2,Est_Pres_TConfig
                        bra Fin_TConfig_Est1
Out_TConfig_Est1:

Fin_TConfig_Est1:
                        rts

;---------------------- TConfig Est2 -----------------------------------------

TConfig_Est2:
                        ldaa PTH               ;Switches en modo configuracion?
                        anda #EVALUAR_MODO_msk ;Aisla 2 MSB y
                        cmpa #MODO_CONFIGURAR  ;los compara
                        bne Out_TConfig_Est2

                        brclr Banderas_1,Array_OK,Fin_TConfig_Est2 ;Arreglo listo?
                        
                        jsr BCD_BIN ;Pasa NumArray a ValorVueltas
                
                        ldaa ValorVueltas   ;Evalua si las vueltas ingresadas son
                        cmpa #MinNumVueltas ;Un numero que se encuentra dentro del
                        blo TConfig_BArray  ;rango valido, mayor o igual a 3 y 
                        cmpa #MaxNumVueltas ;menor o igual a 25
                        bhi TConfig_BArray

                        jsr BIN_BCD_MUXP ;Pasa valor en A (ValorVueltas) a BCD
                        movb BCD,BCD1    ;Coloca valor en BCD para DSP 2,3
                        movb #OFF,BCD2   ;Apaga MSB de 7 segmentos

                        jsr BCD_7Seg ;Envia valores a pantalla 7 segmentos
                        
                        movb ValorVueltas,NumVueltas ;Guarda valor ingresado
                        bra TConfig_BArray
Out_TConfig_Est2:
                        movw #TConfig_Est1,Est_Pres_TConfig ;Si modo no config
                        movb #10,ValorVueltas               ;Volver a 1st estado

TConfig_BArray:
                        jsr Borrar_NumArray ;Borra arreglo de numeros

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
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est1 ;Modo Comp?
                        bra Out_TComp_Est1 ;Si no, salga sin realizar nada!
Ejecutar_TComp_Est1:
                        brclr Banderas_2,LCD_OK,Fin_TComp_Est1 ;LCD Ocupado?

                        ldaa Vueltas        ;Evalua si ya se llego al valor max
                        cmpa NumVueltas     ;de vueltas definido
                        beq Pasa_TComp_Est3 
        
                        movw #Mensaje_Inicial_L1,MSG_L1 ;Mensaje inicial de Comp
                        movw #Mensaje_Inicial_L2,MSG_L2 ;Linea 1 y 2
                        bclr Banderas_2,LCD_OK          ;Habilita LCD
                        
                        movb #LDComp,LEDS ;Inicializa modo de leds
                        movb #OFF,BCD1 ;Inicializa 7 seg apagados
                        movb #OFF,BCD2 ;Inicializa 7 seg apagados

                        jsr BCD_7Seg ;Pone valores en pant. Mux

                        movw #TComp_Est2,Est_Pres_TComp
                        bra Fin_TComp_Est1

Pasa_TComp_Est3:
                        movw #Mensaje_Fin_Comp_L1,MSG_L1 ;Mensaje final
                        movw #Mensaje_Fin_Comp_L2,MSG_L2 ;cuando termina vueltas
                        bclr Banderas_2,LCD_OK ;Habilita LCD
                        
                        movw #TComp_Est3,Est_Pres_TComp
                        bra Fin_TComp_Est1
Out_TComp_Est1:
Fin_TComp_Est1:
                        rts
                        
;---------------------- TComp Est2 -------------------------------------------
TComp_Est2:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est2 ;Modo Comp?
                        bra Out_TComp_Est2
Ejecutar_TComp_Est2:
                        brclr Banderas_1,ShortP1,Fin_TComp_Est2 ;Sensor 1 activo?
                        bclr Banderas_1,ShortP1 ;Borrar bandera del sensor
                        
                        movw #Mensaje_Calculando_L1,MSG_L1 ;Mensaje calculando a LCD
                        movw #Mensaje_Calculando_L2,MSG_L2 ;Mensaje calculando a LCD
                        bclr Banderas_2,LCD_OK ;Habilita LCD
 
                        movb #tTimerVel,TimerVel ;Inicia medicion de tiemp de veloc
                        movw #TComp_Est4,Est_Pres_TComp
                        bra Fin_TComp_Est2
Out_TComp_Est2:
                        movw #TComp_Est1,Est_Pres_TComp ;Regresa al estado1
                        clr Vueltas ;Borra Vueltas
Fin_TComp_Est2:
                        rts

;--------------------- TComp_Est3 --------------------------------------------
TComp_Est3:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est3 ;Modo Comp?
                        bra Out_TComp_Est3
Ejecutar_TComp_Est3:
                        brclr Banderas_1,LongP1,Fin_TComp_Est3 ;Inicia nueva comp?
                        bclr Banderas_1,LongP1 ;Borra bandera del reinicio
                        
Out_TComp_Est3:
                        movw #TComp_Est1,Est_Pres_TComp ;Pasa a estado1
                        clr Vueltas ;Borra vueltas
Fin_TComp_Est3:
                        rts

;--------------------- TComp Est4 --------------------------------------------

TComp_Est4:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est4 ;Modo Comp?
                        bra Out_TComp_Est4
Ejecutar_TComp_Est4:
                        brclr Banderas_1,ShortP2,Fin_TComp_Est4 ;Sensor2 activado?
                        bclr Banderas_1,ShortP2 ;Borra bandera del sensor
                        
                        jsr Calcula ;Calcula velocidad

                        ldaa Veloc          ;Evalua si la velocidad
                        cmpa #VelocMax      ;Se encuentra dentro del rango
                        bhi  Fuera_De_Rango ;Deseado, mayor a 45km/h y menor
                        cmpa #VelocMin      ;a 95 km/h
                        blo Fuera_De_Rango

                        inc Vueltas                     ;Si dentro del rango,
                        movw #TComp_Est5,Est_Pres_TComp ;aumenta vueltas
                        bra Fin_TComp_Est4

Out_TComp_Est4:        
                        movw #TComp_Est1,Est_Pres_TComp ;Si no en modo Comp
                        clr Vueltas                     ;Borra vueltas y regresa
                        bra Fin_TComp_Est4              ;A est1
Fuera_De_Rango:
                        
                        movw #Mensaje_de_Alerta_L1,MSG_L1 ;MSG_Alerta a LCD
                        movw #Mensaje_de_Alerta_L2,MSG_L2 ;para veloc fuera de
                        bclr Banderas_2,LCD_OK            ;rango
                        
                        movb #GUIONES,BCD1 ;Envia guiones a pantallas de
                        movb #GUIONES,BCD2 ;7 seg si veloc fuera de rango

                        jsr BCD_7Seg ;Con offset anterior cargado, pone valores

                        movb #tTimerError,TimerError    ;inicia 3 segundos de
                        movw #TComp_Est6,Est_Pres_TComp ;mensaje de error
Fin_TComp_Est4:
                        rts

;---------------------- TComp Est5 ----------------------------------------
TComp_Est5:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est5 ;Modo Comp?
                        bra Out_TComp_Est5
Ejecutar_TComp_Est5:

                        tst TimerPant       ;Es hora de encender la pantalla?
                        bne Fin_TComp_Est5
                        
                        movw #Mensaje_Competencia_L1,MSG_L1 ;Si si, enviar msg a 
                        movw #Mensaje_Competencia_L2,MSG_L2 ;LCD
                        bclr Banderas_2,LCD_OK

                        ldaa Vueltas     ;Mostrar valor de vueltas en DSP 1 y 2
                        jsr BIN_BCD_MUXP
                        movb BCD,BCD2

                        ldaa Veloc       ;Mostrar valor de veloc en DSP 3 y 4
                        jsr BIN_BCD_MUXP ;en km/h
                        movb BCD,BCD1

                        jsr BCD_7Seg ;Pone valores en pant mux

                        movw #TComp_Est7,Est_Pres_TComp
                        bra Fin_TComp_Est5
Out_TComp_Est5:
                        movw #TComp_Est1,Est_Pres_TComp ;Si no modo Comp
                        clr Vueltas                     ;Borrar vueltas
Fin_TComp_Est5:
                        rts

;---------------------- TComp Est 6 ----------------------------------------
TComp_Est6:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est6 ;Modo comp?

                        clr Vueltas ;Si no, borrar Vueltas

                        bra To_State1_TComp_Est6

Ejecutar_TComp_Est6:
                        tst TimerError     ;Termino el tiempo de error?
                        bne Fin_TComp_Est6 
                                        
To_State1_TComp_Est6:
                        movw #TComp_Est1,Est_Pres_TComp ;Regresar a estado 1
Fin_TComp_Est6:
                        rts

;---------------------- TComp Est 7 -----------------------------------------
TComp_Est7:
                        brset PTH,MODO_COMPETENCIA,Ejecutar_TComp_Est7 ;Modo Comp?

                        clr Vueltas ;Borrar Vueltas

                        bra To_State1_TComp_Est7

Ejecutar_TComp_Est7:
                        tst TimerFinPant ;Es hora de apagar pantalla?
                        bne Fin_TComp_Est7
                                        
To_State1_TComp_Est7:
                        movw #TComp_Est1,Est_Pres_TComp ;pasa a estado 1
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
                        movb #tTimerBrillo,TimerBrillo ;inicia muestras cada
						       ;400mS
                        movw #TareaBrillo_Est2,Est_Pres_TBrillo

                        rts

;---------------------- TareaBrillo Est2 ------------------------------------

TareaBrillo_Est2:
                        tst TimerBrillo ;Termino el tiempo entre conversiones?
                        bne Fin_TareaBrillo_Est2

                        movb #$87,ATD0CTL5  ;Inicializa conversiones
                        movw #TareaBrillo_Est3,Est_Pres_TBrillo

Fin_TareaBrillo_Est2:
                        rts

;---------------------- TareaBrillo Est3 ------------------------------------

TareaBrillo_Est3:
                        brclr ATD0STAT0,MaskSCF,Fin_TareaBrillo_Est3 ;Terminaron
								     ;las 
								     ;conversiones?

                        ldd ADR00H   ;Primera Conversion ;Lee en acc D por si llega
                        addd ADR01H ;Segunda Conversion  ;a haber rebase en las

                        lsrd ;Division por 2, Promedio ;sumas de 8 bits

                        ldy #Max_Brillo                  ;Acomoda la escala del 
                        emul ;Max_Brillo x Potenciometro ;potenciometro a 100 tics
                        ldx #FS_Pot                      ;del brillo
                        ediv

                        tfr y,d
                        stab Brillo  ;Guarda valor de brillo

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
                tst Timer_LED_Testigo ;Ya paso un segundo?
                bne FinLedTest

                brset PTP,$20,Green ;Si Rojo, pase a verde
                brset PTP,$40,Blue  ;Si verde pase a azul, si ninguno, pasa rojo
Red:
                bclr PTP,$10 ;Borra Azul
                bset PTP,$20 ;Pone rojo
                bra Init_Timer_LED
Green:
                bclr PTP,$20 ;Borra rojo
                bset PTP,$40 ;Pone verde
                bra Init_Timer_LED
Blue:
                bclr PTP,$40 ;Borra verde
                bset PTP,$10 ;Pone Azul
                
Init_Timer_LED:
                Movb #tTimerLDTst,Timer_LED_Testigo

FinLedTest:      Rts

;******************************************************************************
;                               TAREA LEER PB1
;******************************************************************************

Tarea_Leer_PB1:
                        ldx Est_Pres_LeerPB1
                        jsr 0,x
                        rts
                        

; ---------------------------- Leer PB1 Estado 1 -----------------------------

LeerPB1_Est1:
                        brset PortPB,MaskPB1,PB1Est1_Retornar ;Se activo sensor1?

                        movb #tSupRebPB,Timer_RebPB1 ;Inicia sup rebotes
                        movb #tShortP,Timer_SHP1     ;Inicia tiempo shortp
                        movb #tLongP,Timer_LP1       ;Inicia tiempo longP
                        
                        movw #LeerPB1_Est2,Est_Pres_LeerPB1
                        

PB1Est1_Retornar:        rts

; ----------------------------- LeerPB1_Est2 ----------------------------------

LeerPB1_Est2:
                        tst Timer_RebPB1 ;Terminaron los rebotes?
                        bne PB1Est2_Retornar
                        
                        brset PortPB,MaskPB1,Label1_21 ;No fue presionado?
                        
                        movw #LeerPB1_Est3,Est_Pres_LeerPB1 ;Si si, pasa est3
                        bra PB1Est2_Retornar
                        
Label1_21:               movw #LeerPB1_Est1,Est_Pres_leerPB1 ;Si no, pasa est1

PB1Est2_Retornar:        rts

; ----------------------------- LeerPB1_Est3 ----------------------------------

LeerPB1_Est3:
                        tst Timer_SHP1       ;Fin tiempo de shortp?
                        bne PB1Est3_Retornar

                        brset PortPB,MaskPB1,Label1_31 ;Si sigue presionado?
                        
                        movw #LeerPB1_Est4,Est_Pres_LeerPB1 ;Si si, pasa est 4
                        bra PB1Est3_Retornar
                        
Label1_31:               bset Banderas_1,ShortP1       ;Si no, enciende bandera y
                        movw #LeerPB1_Est1,Est_Pres_LeerPB1 ;Regresa est1
                        
PB1Est3_Retornar:        rts

; ------------------------------ LeerPB1_Est4 ---------------------------------

LeerPB1_Est4:
                        tst Timer_LP1    ;Termino tiempo de LongP?
                        bne Label1_Short 
                        
                        brclr PortPB,MaskPB1,PB1Est4_Retornar ;Sigue presionado?
                        bset Banderas_1,LongP1
                        bra PB1Est4_State1
                        
Label1_Short:            brclr PortPB,MaskPB1,PB1Est4_Retornar ;Es ShortP?
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

                        movb #tSupRebPB,Timer_RebPB2 ;Inicia sup rebotes
                        movb #tShortP,Timer_SHP2     ;Inicia shortp
                        movb #tLongP,Timer_LP2       ;Inicia longP
                        
                        movw #LeerPB2_Est2,Est_Pres_LeerPB2
                        

PB2Est1_Retornar:        rts

; ----------------------------- LeerPB_Est2 ----------------------------------

LeerPB2_Est2:
                        tst Timer_RebPB2 ;Terminaron los rebotes?
                        bne PB2Est2_Retornar
                        
                        brset PortPB,MaskPB2,Label2_21 ;Sigue presionado?
                        
                        movw #LeerPB2_Est3,Est_Pres_LeerPB2
                        bra PB2Est2_Retornar
                        
Label2_21:               movw #LeerPB2_Est1,Est_Pres_leerPB2 ;Falsa alarma, Si rebotes

PB2Est2_Retornar:        rts

; ----------------------------- LeerPB_Est3 ----------------------------------

LeerPB2_Est3:
                        tst Timer_SHP2 ;Finalizo tiempo de shortp?
                        bne PB2Est3_Retornar

                        brset PortPB,MaskPB2,Label2_31 ;Sigue presionado?
                        
                        movw #LeerPB2_Est4,Est_Pres_LeerPB2
                        bra PB2Est3_Retornar
                        
Label2_31:               bset Banderas_1,ShortP2 ;Dejo de ser presionado, era shortp
                        movw #LeerPB2_Est1,Est_Pres_LeerPB2
                        
PB2Est3_Retornar:        rts

; ------------------------------ LeerPB_Est4 ---------------------------------

LeerPB2_Est4:
                        tst Timer_LP2 ;Termino tiempo de longP
                        bne Label2_Short 
                        
                        brclr PortPB,MaskPB2,PB2Est4_Retornar ;Dejo de ser presionado?
                        bset Banderas_1,LongP2 ;si, era un longP
                        bra PB2Est4_State1
                        
Label2_Short:            brclr PortPB,MaskPB2,PB2Est4_Retornar ;dejo de ser presionado?
                        bset Banderas_1,ShortP2 ;Si, era un shortp

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
                        tst TimerDigito                ;Finalizo tiempo de digito
                        bne Fin_PantallaMUX_Est1
                        
                        movb #tTimerDigito,TimerDigito ;Carga tiempo de prox digito
                        ldaa Cont_Dig                  ;Cual valor de digito se activa?
                        
                        cmpa #1
                        beq Display_1  ;7 segmentos MSB?

                        cmpa #2
                        beq Display_2  ;7 Segmentos 2nd MSB?

                        cmpa #3
                        beq Display_3 ;7 Segmentos 2nd LSB?

                        cmpa #4
                        beq Display_4 ;7 Segmentos LSB?
Display_LEDS:
                        bclr PTJ,$02      ;Habilita leds
                        movb LEDS,PORTB   ;Coloca patron de leds
                        movb #01,Cont_Dig ;Reinicia contador de digito
                        bra Cambio_Estado
                        
Display_1:
                        bclr PTP,$01     ;Habilita MSB 7 seg
                        movb Dsp1,PORTB  ;Coloca numero
                        inc Cont_Dig     ;pasa siguiente digito
                        bra Cambio_Estado
Display_2:
                        bclr PTP,$02     ;Habilita 2nd MSB 7 seg
                        movb Dsp2,PORTB  ;Coloca numero
                        inc Cont_Dig     ;Pasa siguiente digito
                        bra Cambio_Estado
Display_3:
                        bclr PTP,$04     ;Habilita 2nd LSB 7 seg
                        movb Dsp3,PORTB  ;Coloca numero
                        inc Cont_Dig     ;Pasa siguiente digito
                        bra Cambio_Estado
Display_4:
                        bclr PTP,$08     ;Habilita LSB 7 seg
                        movb Dsp4,PORTB  ;Coloca numero 
                        inc Cont_Dig     ;Pasa siguiente digito

Cambio_Estado:
                        movb #MaxCountTicks,Counter_Ticks ;Define cont para brillo
                        movw #PantallaMUX_Est2,Est_Pres_PantallaMUX

Fin_PantallaMUX_Est1:   rts


;------------------------------ PantallaMUX Est2 ---------------------------------

PantallaMUX_Est2:  
                        ldaa #MaxCountTicks ;Obtiene cantidad de ticks que
                        suba Counter_Ticks  ;se lleva a este momento
                        
                        cmpa Brillo         ;Si ticks < brillo apaga todo
                        blo Fin_PantallaMUX_Est2
                        
                        bset PTP,$0F  ;Apaga 7 segmentos
                        bset PTJ,$02  ;Apaga leds

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
                        bclr Banderas_2,FinSendLCD ;Borra Bandera de tareaSendLCD
                        bclr Banderas_2,RS         ;Define comandos 

                        brset Banderas_2,Second_Line,Load_Second_Line ;Es segunda linea?
Load_First_Line:
                        movb #ADD_L1,CharLCD   ;Carga la direccion de 1 linea
                        movw Msg_L1,Punt_LCD   ;Carga dir mensaje linea 1
                        bra Load_TLCD_Est2
Load_Second_LIne:
                        movb #ADD_L2,CharLCD   ;Carga la direccion de 2 linea
                        movw Msg_L2,Punt_LCD   ;Carga dir mensaje linea 2
Load_TLCD_Est2:
                        jsr Tarea_SendLCD      ;Llama tarea que envia los datos

                        movw #TareaLCD_Est2,EstPres_TareaLCD

                        rts

;---------------------- TareaLCD Est2 ----------------------------------------
TareaLCD_Est2:
                        brclr Banderas_2,FinSendLCD,Call_Send_LCD ;Ya termino de enviar?

                        bclr Banderas_2,FinSendLCD ;si si, borra bandera
                        bset Banderas_2,RS         ;y define datos

                        ldy Punt_LCD 
                        movb 1,y+,CharLCD ;Carga byte para enviar e
                        sty Punt_LCD      ;incrementa puntero

                        brset CharLCD,EOB,ToggleLine_EndMsg ;Final de mensaje?

Call_Send_LCD:
                        jsr Tarea_SendLCD     ;Si no, llama a tarea para seguir enviando
                        bra Fin_TareaLCD_Est2

ToggleLine_EndMsg:
                        brset Banderas_2,Second_Line,EndMsg ;Ya se envio segunda linea?
                        
                        bset Banderas_2,Second_Line ;Definir segunda linea
                        bra Load_TareaLCD_Est1
EndMsg:
                        bclr Banderas_2,Second_Line ;Ya se envio el mensaje completo
                        bset Banderas_2,LCD_OK      ;LCD queda libre
                        
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
                        ldaa #$F0     ;Aisla parte alta del byte
                        anda CharLCD  ;Y lo posiciona en el puerto K
                        lsra
                        lsra
                        staa PORTK

                        brclr Banderas_2,RS,ComandoLCD_Est1 ;Es comando?
                        bset PORTK,$01                      ;Avisar a LCD que es dato
                        bra No_ComandoLCD_Est1
ComandoLCD_Est1:
                        bclr PORTK,$01                     ;Avisar a LCD que es comando
No_ComandoLCD_Est1:
                        bset PORTK,$02                     ;Iniciar pulso estroboscopico
                        movb #tTimer260uS,Timer260uS       ;Iniciar ancho de pulso
                        movw #SendLCD_Est2,EstPres_SendLCD

Fin_SendLCD_Est1:       rts

;----------------------- SendLCD_Est2 ----------------------------------------

SendLCD_Est2:
                        tst Timer260uS       ;Ya termino el tiempo del pulso?
                        bne Fin_SendLCD_Est2

                        bclr PORTK,$02       ;Terminar el pulso

                        ldaa #$0F    ;Aisla parte baja del byte
                        anda CharLCD ;Y lo posiciona para enviar a LCD
                        lsla
                        lsla
                        staa PORTK

                        brclr Banderas_2,RS,ComandoLCD_Est2 ;Es comando?

                        bset PORTK,$01                      ;Avisar a LCD que es dato
                        bra No_ComandoLCD_Est2
ComandoLCD_Est2:
                        bclr PORTK,$01                      ;Avisar a LCD que es comando
No_ComandoLCD_Est2:
                        bset PORTK,$02 			    ;Inicia pulso estroboscopico
                        movb #tTimer260uS,Timer260uS        ;Inicia tiempo de pulso
                        movw #SendLCD_Est3,EstPres_SendLCD

Fin_SendLCD_Est2:
                        rts

;---------------------- SendLCD_Est3 -----------------------------------------

SendLCD_Est3:
                        tst Timer260uS       ;Termino el ancho del pulso?
                        bne Fin_SendLCD_Est3

                        bclr PORTK,$02              ;Terminar el pulso
                        movb #tTimer40uS,Timer40uS  ;Iniciar tiempo de procesamiento
                        movw #SendLCD_Est4,EstPres_SendLCD

Fin_SendLCD_Est3:       rts

;---------------------- SendLCD_Est4 -----------------------------------------

SendLCD_Est4:
                        tst Timer40uS               ;Termino tiempo de procesamiento?
                        bne Fin_SendLCD_Est4        
                        bset Banderas_2,FinSendLCD  ;Avisar que ya se envio el byte!
                        movw #SendLCD_Est1,EstPres_SendLCD
                        
Fin_SendLCD_Est4:       rts



;*****************************************************************************
;                  SUB RUTINA GENERAL BCD_BIN
;*****************************************************************************

BCD_BIN:
                	ldx #Num_Array
			ldaa 1,x+
			ldab #16         ;mueve numero a decada superior
			
			mul ;Resultado R1:R2 
			
			ldaa 0,x         ;Carga segunda decada

			aba
			staa BCD         ;Carga valor en BCD

                        ldx #BCD          ;Carga direccion dato origen
                        ldy #ValorVueltas ;Carga direccion dato resultado
                        
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
;                  SUB RUTINA GENERAL CALCULA
;*****************************************************************************

Calcula:
			ldab #tTimerVel        ;Carga valor maximo de timer
			subb TimerVel          ;Y resta para obtener magnitud de
			cmpb #CERO_8_BITS      ;tiempo transcurrido
			beq Velocidad_Infinita ;Si es cero, no se divide, se asigna
                                               ;Valor maximo
			stab DeltaT            ;Guarda valor de tiempo
			
			clra                   ;Limpia acumulador A
			tfr d,x                ;Prepara datos para realizar division
			ldy #CERO_16_BITS
			ldd #CONVERSOR_VELOC
			ediv
		
			tfr y,d                 ;Guarda valor de velocidad en la var
			stab Veloc              ;Correspondiente

			tfr d,x
			ldy #CERO_16_BITS       ;Toma valor de Velocidad y prepara datos
			ldd #CONVERSOR_PANT_ON  ;Para calcular tiempo de pantalla
			ediv

			tfr y,d                 ;Guarda valor de tiempo encendido en
			stab TimerPant          ;El timer correspondiente

			ldab Veloc              ;Carga valor de velocidad y prepara los 
			clra                    ;Datos para calcular tiempo de apagado
			tfr d,x                 ;de la pantalla
			ldy #CERO_16_BITS
			ldd #CONVERSOR_PANT_OFF
			ediv

			tfr y,d                 ;Guarda el valor de tiempo de apagado
			stab TimerFinPant       ;en el timer correspondiente
			
			bra Fin_Calcula
			
Velocidad_Infinita:
			movb #INF,Veloc	        ;Guarda valor max si es infinito
Fin_Calcula:
			rts

;*****************************************************************************
;                  SUB RUTINA GENERAL BIN BCD MUXP
;*****************************************************************************
BIN_BCD_MUXP:
                        bclr BCD,$FF        ;Limpia valor en BCD
                        movb #$05,Cont_BCD  ;carga cuentas para optimizacion
                        lsla                ;y rota dos veces sin probar
                        rol BCD
                        lsla
                        rol BCD

                        psha

bin_BCD_loop:
                        pula
                        lsla               ;Rotacion del XS3
                        rol BCD
                        psha

                        ldd #$F00F         ;Aisla las decadaas alta y baja
                        anda BCD
                        andb BCD

                        cmpa #$50         ;Compara mayor o igual a 5
                        blo no_add_30     ;para decada mas significativa
                        adda #$30         ;Si si, suma 3
no_add_30:
                        cmpb #$05         ;compara mayor o igual a 5
                        blo no_add_03     ;Para decada Menos Significativa
                        addb #$03         ;si si, suma 3
no_add_03:
                        aba
                        staa BCD          ;Guarda resultado evaluado

                        dec Cont_BCD
                        tst Cont_BCD     ;Ya se terminaron las rotaciones?
                        bne bin_BCD_loop

                        pula
                        lsla             ;Ultima rotacion, sin probar
                        rol BCD
Fin_BIN_BCD_MUXP:
                        rts

;*****************************************************************************
;                  SUB RUTINA GENERAL BCD - 7 SEG
;*****************************************************************************

BCD_7Seg:
                        
                        ldy #BCD2     ;Carga direccion de BCD2
                        ldx #SEGMENT  ;Carga direccion de tabla de segmentos
SegundoDisplay:
                        ldd #$F00F    ;Aisla decada alta de BCDn
                        anda 0,y
                        lsra          ;Acomoda decada alta rotando
                        lsra
                        lsra
                        lsra
                        andb 0,y      ;Aisla decada baja de BCDn

                        cpy #BCD1     ;Evalua si ya se asignaron ambos BCD1 y 2
                        beq Display34
Display12:
                        movb a,x,Dsp1 ;Usa BCD2 offset para guardar los valores
                        movb b,x,Dsp2 ;en sus DSP respectivos
                        ldy #BCD1     ;Carga la siguiente direccion de BCD
                        bra SegundoDisplay
Display34:                
                        movb a,x,Dsp3 ;Usa BCD1 offset para guardar los valores
                        movb b,x,Dsp4 ;en sus DSP respectivos
                
Fin_BCD_7Seg:                rts

;*****************************************************************************
;                TAREA BORRA TCL (anterior TAREA LED PB)
;*****************************************************************************

Borrar_NumArray:   
                        ldx #Num_Array      ;Carga direccion del array y en 
                        movb #$08,Cont_TCL  ;un ciclo, Guarda valores $FF en
forCLR:                 movb #$FF,1,x+      ;el mismo. Ademas tambien busca
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
