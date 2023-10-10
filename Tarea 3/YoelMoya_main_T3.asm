;----------------- ENCABEZADO ----------------------------;
; Estudiante: Yoel Moya Carmona
; Carne: B75262
;
;----------------- DESCRIBCION GENERAL -------------------;
; Se implementaron cuatro sub rutinas, las cuales se dan a la tarea
; de procesar datos recibidos por IoT, los cuales se encuentran en
; una tabla inicializada en el programa.
; La cantidad de datos a procesar de la tabla, se recibe con las
; sub rutinas Putchar y Getchar del debug12, asi como la utilizacion
; de Printf, la cual es utilizada para brindar informacion al usuario
;
; De las creadas, se tiene GET_CANT, la cual recibe la cantidad de datos
; a ser procesados.
; ASCII_BIN, la cual traduce la tabla de datos obtenida a numeros binarios
; MOVER, la cual separa en tres nibbles los numeros binarios anteriormente
; obtenidos
; E IMPRIMIR, la cual devuelve al usuario una lista de cada uno de estos
; nibbles anteriormente separados.
;----------------- ESTRUCTURAS DE DATOS ------------------;
CR:             EQU $0D
LF:             EQU $0A
PrintF:         EQU $EE88
GetChar:        EQU $EE84
PutChar:        EQU $EE86
FINMSG:         EQU $0

                org $1000
CANT:           ds 1
CONT:           ds 1
Offset:         ds 1
ACC:            ds 2

                org $1010
Nibble_UP:      ds 2
Nibble_MED:     ds 2
Nibble_LOW:     ds 2

                org $1030
MSG_INICIAL:    FCC "INGRESE EL VALOR DE CANT (ENTRE 1 Y 25): "
                dB FINMSG
                
MSG_ENTER:      FCC " "
                db CR,CR,LF
                db FINMSG

MSG_CONT:       FCC "CANTIDAD DE VALORES PROCESADOS: %d"
                db CR,CR,LF
                db FINMSG

MSG_UP:         FCC "Nibble_UP: "
                db FINMSG

MSG_MED:        FCC "Nibble_MED: "
                db FINMSG

MSG_LOW:        FCC "Nibble_LOW: "
                db FINMSG

MSG_NIBBLE:     FCC "%X, "
                db FINMSG

MSG_NIBEND:     FCC "%X"
                db CR,CR,LF
                db FINMSG

                org $1500
Datos_IoT:      fcc "0129"
                fcc "0749"
                fcc "3854"
                fcc "1975"
                fcc "0077"
                
                fcc "1346"
                fcc "5343"
                fcc "2575"
                fcc "2023"
                fcc "0398"

                fcc "0000"
                fcc "1239"
                fcc "1873"
                fcc "0005"
                fcc "2084"

                fcc "0064"
                fcc "0128"
                fcc "0256"
                fcc "0512"
                fcc "4095"


                org $1600
Datos_BIN:      ds 25

;----------------- PROGRAMA PRINCIPAL --------------------;

                org $2000
                lds #$3BFF
                ldd #$1630
                std Nibble_UP
                ldd #$1660
                std Nibble_MED
                ldd #$1690
                std Nibble_LOW


                jsr GET_CANT

                leas -2,sp

                ldab #$00
                pshb

                ldd #Datos_BIN
                pshd

                ldd #Datos_IoT
                pshd

                leas 7,sp
                jsr ASCII_BIN                

                ldx #Datos_BIN
                jsr MOVER

                jsr IMPRIMIR

                bra *



;---------------------------------------------------------;
;----------------- SUBRUTINA IMPRIMIR --------------------;
;---------------------------------------------------------;
; Se separa en tres secciones, donde se imprime cada uno de los
; arreglos que contienen los nibbles, iniciando en print_UP, que
; imprime el arreglo de Nibble_UP, print_MED, que imprime el arreglo
; de Nibble_MED, y print_LOW, que imprime el arreglo de Nibble_LOW.
; Se utilizo la variable CONT para mantener un offset con el cual se
; barren los arrays, esto luego de haber sido utilizada en la impresion
; en pantalla.

IMPRIMIR:
		ldab CONT
                sex b,d
                pshd
                ldd #MSG_CONT

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp

print_UP:
                ldx #$0000
                ldd #MSG_UP
                jsr [PrintF,x]

                ldy Nibble_UP
                ldaa #$00
                staa CANT
                dec CONT
                

print_loop:     ldaa CANT
		ldab a,y
                sex b,d
                pshd
                ldd #MSG_NIBBLE

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp
                ldy Nibble_UP

                inc CANT
                ldaa CANT

                cmpa CONT
                blt print_loop
                cmpa #$01
                beq print_MED

                ldaa CANT
                ldab a,y
                sex b,d
                pshd
                ldd #MSG_NIBEND

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp
                
                
print_MED:
                ldx #$0000
                ldd #MSG_MED
                jsr [PrintF,x]

                ldy Nibble_MED
                ldaa #$00
                staa CANT


print_loop2:    ldaa CANT
		ldab a,y
                sex b,d
                pshd
                ldd #MSG_NIBBLE

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp
                ldy Nibble_MED

                inc CANT
                ldaa CANT

                cmpa CONT
                blt print_loop2
                cmpa #$01
                beq print_LOW

                ldaa CANT
                ldab a,y
                sex b,d
                pshd
                ldd #MSG_NIBEND

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp
                
                
print_LOW:
                ldx #$0000
                ldd #MSG_LOW
                jsr [PrintF,x]

                ldy Nibble_LOW
                ldaa #$00
                staa CANT
                

print_loop3:    ldaa CANT
		ldab a,y
                sex b,d
                pshd
                ldd #MSG_NIBBLE

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp
                ldy Nibble_LOW

                inc CANT
                ldaa CANT

                cmpa CONT
                blt print_loop3
                cmpa #$01
                beq END_PRINT

                ldaa CANT
                ldab a,y
                sex b,d
                pshd
                ldd #MSG_NIBEND

                ldx #$0000
                jsr [PrintF,x]
                leas 2,sp

END_PRINT:      rts

;---------------------------------------------------------;
;----------------- SUBRUTINA MOVER -----------------------;
;---------------------------------------------------------;
; Se utilizaron dos mascaras para aislar Nibble_UP y Nibble
; LOW. De ultimo se utilizaron 4 rotaciones hacia la derecha
; Para aislar Nibble_MED.
MOVER:
                pshx
                ldab #$00
                pshb

mover_loop:     leas 1,sp
                pulx

                ldd 2,x+
                pshx

                leas -1,sp
                tfr d,y

                anda #$0F
                pulb
                ldx Nibble_UP
                staa b,x

                pshb
                tfr y,d
                
                andb #$0F
                pula
                ldx Nibble_LOW
                stab a,x

                psha
                tfr y,d

                lsrb
                lsrb
                lsrb
                lsrb

                pula
                ldx Nibble_MED
                stb a,x

                adda #$01
                psha

                cmpa CANT
                bne mover_loop

                leas 3,sp

                rts


;---------------------------------------------------------;
;----------------- SUBRUTINA ASCII BIN -------------------;
;---------------------------------------------------------;
; Se implemento el algoritmo de multiplicacion de decadas y
; suma, adaptado a cada una de las decadas. Se utilizo el
; Manejo de pila para poder mantener un offset para el arreglo
; de numeros binarios.

ASCII_BIN:
                leas -5,sp

                bclr CONT,$FF
                bclr Offset,$FF

ascii_loop:     pulx

Decada_4:       ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00
                ldy #1000
                emul

                std ACC

Decada_3:       ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00
                ldy #100
                emul

                addd ACC
                std ACC
        
Decada_2:       ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00
                ldy #10
                emul

                addd ACC
                std ACC

Decada_1:       ldaa Offset
                ldab a,x
                adda #1
                staa Offset

                subb #$30
                ldaa #$00

                addd ACC
                std ACC

guarda_val:     pshx
                leas 2,sp

                puly
                pulb

                ldx ACC
                stx b,y

                addb #$02
                pshb
                pshy

                leas -2,sp
                inc CONT
                ldaa CONT

                cmpa CANT
                bne ascii_loop

                leas 5,sp
                rts

;---------------------------------------------------------;
;----------------- SUBRUTINA GET CANT --------------------;
;---------------------------------------------------------;
; Se utilizan todas las subtutinas del debugger, asi como una
; implementacion pequenna de el algoritmo de multiplicacion de
; decadas y suma para poder expresar el numero ingresado en
; binario y mantenerlo manejable.


GET_CANT:
                bclr CANT,$FF

                ldd #MSG_INICIAL
                ldx #$0000

                jsr [PrintF,x]

Char_decenas:   ldx #$0000
                jsr [GetChar,x]

                cmpb #$30
                beq valid_decenas
                cmpb #$31
                beq valid_decenas
                cmpb #$32
                bne Char_decenas

valid_decenas:  ldaa #$00
                ldx #$0000
                
                jsr [PutChar,x]

                ldaa #$0A
                subb #$30
                mul
                stab CANT

Char_unidades:  ldx #$0000
                jsr [GetChar,x]

                tba
                subb #$30
                addb CANT
                
                cmpb #1
                blo Char_unidades
                cmpb #25
                bhi Char_unidades

                stab CANT

                tab
                ldaa #$00
                ldx #$0000
                jsr [PutChar,x]

                ldd #MSG_ENTER
                ldx #$0000
                jsr [PrintF,x]

                rts

                