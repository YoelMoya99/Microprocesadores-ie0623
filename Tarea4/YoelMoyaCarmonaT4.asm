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
                                Org $3E70 ;RTI para maquina de tiempos
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers de la aplicacion ----

tSupRebPB:        EQU 10
tSupRebTCL:       EQU 10    ;Timer de sup rebotes para TCL, 10ms
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
MAX_TCL:          dB $06       ;Valor maximo del arreglo (1-6)
Tecla:            ds 1         ;Variable retorno de sr Leer Teclado
Tecla_IN:         ds 1         ;Variable temp para validez de tecla pulsada
Cont_TCL:         ds 1         ;Offset del arreglo resultado
Patron:           ds 1         ;Patron de lectura/escritura del puerto A
Est_Pres_TCL:     ds 2         ;Variable de estado para teclado
Est_Pres_LeerPB:  ds 2         ;Variable de estado para Leer PB

Banderas:         ds 1
ShortP:           EQU $01      ;Bandera para short press
LongP:            EQU $02      ;Bandera para long press
ARRAY_OK:         EQU $04      ;Bandera para arreglo listo

                  org $1010
Num_Array:        ds 10        ;Arreglo de resultados

                  org $1020
Teclas:           dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$00,$0E,$0B ;Tabla TCL

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1030
Tabla_Timers_BaseT:

Timer1mS        ds 1    ;Timer 1 ms con base a tiempo de interrupcion

Fin_BaseT       db $FF

Tabla_Timers_Base1mS

Timer10mS:      ds 1    ;Timer para generar la base de tiempo 10 mS
Timer_RebPB:    ds 1    ;Timer supresion rebotes Leer PB
Timer_RebTCL:   ds 1    ;Timer de supresion de rebotes teclado

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer100mS:     ds 1    ;Timer para generar la base de tiempo de 100 mS
Timer_SHP:      ds 1    ;Timer para short press

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1S:        ds 1    ;Timer para generar la base de tiempo de 1 Seg.

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LED_Testigo ds 1  ;Timer para parpadeo de led testigo
Timer_LP:         ds 1  ;Timer para long press

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

        ldx #Num_Array     ;Inicializa el array con FF para los primeros
        movb #$09,Cont_TCL ;9 valores.
for:    movb #$FF,1,x+
        dec Cont_TCL
        bne for
        movb #$00,Cont_TCL ;Fin de inicializacion de array

        Lds #$3BFF                          ;Define puntero de pila
        Cli                                 ;Habilita interrupciones
        Clr Banderas                        ;Limpia las banderas
        Movw #LeerPB_Est1,Est_Pres_LeerPB   ;Inicializa estado1 LeerPB
        Movw #Teclado_Est1,Est_Pres_TCL     ;Inicializa estado3 Teclado

Despachador_Tareas

        Jsr Tarea_Led_Testigo
        Jsr Tarea_Teclado
        Jsr Tarea_Leer_PB
        Jsr Tarea_Borra_TCL
        
        Bra Despachador_Tareas
       

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
                        bset Banderas,ARRAY_OK ;anta bandera y borra offset

Reestablecer:           movw #Teclado_Est1,Est_Pres_TCL ;siempre se regresa al
                        bset Tecla,#$FF                 ;1st estado y se borran
                        bset Tecla_IN,#$FF              ;las variables de tecla

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
                        
Label_31:               bset Banderas,ShortP
                        movw #LeerPB_Est1,Est_Pres_LeerPB
                        
PBEst3_Retornar:        rts

; ------------------------------ LeerPB_Est4 ---------------------------------

LeerPB_Est4:
                        tst Timer_LP
                        bne Label_Short
                        
                        brclr PortPB,MaskPb,PBEst4_Retornar
                        bset Banderas,LongP
                        bra PBEst4_State1
                        
Label_Short:            brclr PortPB,MaskPB,PBEst4_Retornar
                        bset Banderas,ShortP

PBest4_State1:          movw #LeerPB_Est1,Est_Pres_LeerPB

PBEst4_Retornar:        rts

;*****************************************************************************
;                TAREA BORRA TCL (anterior TAREA LED PB)
;*****************************************************************************

Tarea_Borra_TCL:
                        BrSet Banderas,ShortP,ON
                        BrSet Banderas,LongP,OFF
                        Bra FIN_Led
ON:                     BClr Banderas,ShortP
                        Bset PORTB,$01
                        Bra FIN_Led
OFF:                    BClr Banderas,LongP
                        BClr PORTB,$01
                        
                        ldx #Num_Array      ;se utiliza el mismo ciclo
                        movb #$09,Cont_TCL  ;implementado en el main, para
forCLR:                 movb #$FF,1,x+      ;limpiar el arreglo. Y se agrega
                        dec Cont_TCL        ;poner la bandera array en cero.
                        bne forCLR
                        movb #$00,Cont_TCL
                        bclr Banderas,ARRAY_OK

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
;                        TAREA LED TESTIGO
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
               ;MAQUINA DE TIEMPOS
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