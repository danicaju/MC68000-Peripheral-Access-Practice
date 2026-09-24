; ==============================================================================
; SUBROUTINES
; ==============================================================================
; Integrantes: Pau Salillas Justo y Daniel Casado Juan 
; ------------------------------------------------------------------------------
HWDINIT
; INITIALIZES HARDWARE DEVICES AS FOLLOWS:
; * DISABLES ALL MASKABLE INTERRUPTS
; * ENABLES EXCEPTION PROCESSING
; * SETS SCREEN RESOLUTION TO SCRWIDTH X SCRHEIGH (BOTH ARE GLOBAL CONSTANTS)
; * SETS WINDOWED MODE
; * ENABLES DOUBLE BUFFER
; * CLEARS THE HIDDEN BUFFER
; * SWITCH BUFFERS (REPAINT SCREEN TASK)
; * INSTALLS TRAPS AS FOLLOWS:
;   -> ROUTINE HWDDBUF GOES TO TRAP NUMBER TRNUPDBF
;   -> ROUTINE HWDPLOT GOES TO TRAP NUMBER TRNPLGFX
; * INSTALLS HWDRMOU FOR INTERRUPT NUMBER INTRDMOU
; * ENABLES MOUSE IRQ FOR MOUSE MOVE, BUTTON UP AND BUTTON DOWN
; * ENABLES INTERRUPTS FROM INTRDMOU TO 7
; * SWITCHES TO USER MODE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; ------------------------------------------------------------------------------

            MOVEM.L D0-D1,-(A7)
            
            ; Desactivamos todas las interrupciones enmascarables
            ; La clave para esto es poner a 1 los bits del 8 al 10 del SR
            OR.W    #$0700,SR

            ; Habilitamos el procesamiento de excepciones
            MOVEQ   #32, D0 ; Tarea 32: Enable exception processing
            MOVEQ   #5, D1
            TRAP    #15

            ; Ajustamos la resolucion a SCRWIDTH X SCRHEIGH
            MOVEQ   #33, D0 ; Tarea 33: Set Windowed Mode
            MOVE.L  #SCRWIDTH<<16|SCRHEIGH, D1
            TRAP    #15
            
            ; Activamos el modo ventana
            MOVEQ   #1,D1
            TRAP    #15

            ; Activamos el doble buffer
            MOVEQ   #92, D0 ; Tarea 92: Enable double buffering
            MOVEQ   #17, D1           
            TRAP    #15

            ; Limpiamos el buffer oculto 
            MOVEQ   #11, D0 ; Tarea 11: Clear screen
            MOVE.W  #$FF00,D1
            TRAP    #15
            
            ; Intercambiamos los buffers 
            MOVEQ   #94,D0 ; Tarea 94: Repaint screen 
            TRAP    #15    ; Copies off screen buffer to visible screen

            ; Instalamos los traps
            ; HWDDBUF -> Trap #TRNUPDBF
            MOVE.L  #HWDDBUF,($80+TRNUPDBF*4)
            ; HWDPLOT -> Trap #TRNPLGFX
            MOVE.L  #HWDPLOT,($80+TRNPLGFX*4)

            ; Instalamos HWDRMOU para el numero de interrupcion INTRDMOU
            MOVE.L #HWDRMOU, ($60+INTRDMOU*4)

            ; Habilitamos la interrupción de hardware del ratón
            ; D1.W se divide en:
            ; - Parte Alta (bits 8-15) = Vector del Ratón
            ; - Parte Baja (bits 0-7)  = Nivel 7 (NMI)
            MOVEQ   #60,D0  ; Tarea 60: Enable/Disable mouse IRQ
            MOVE.W  #(INTRDMOU<<8)|7, D1
            TRAP    #15

            ; Cambiamos a modo usuario
            MOVEM.L (A7)+,D0-D1
            
            ; Truco del RTE:
            ; Empujamos el SR actual a la pila
            ; La pila ahora tiene [SR][PC_retorno]
            MOVE.W SR, -(A7)
            
            ; Cambiamos a modo usuario (bit 13 = 0) y ajustamos nivel de interrupción
            ; desde  INTRDMOU-1, para sólo bloquear hasta el anterior a INTRDMOU
            ANDI.W  #$D0FF, (A7)
            ; Colocamos el nivel de interrupción
            ORI.W   #((INTRDMOU-1)<<8), (A7)
            
            ; Ejecutamos RTE. El procesador saca el SR y el PC.
            RTE

; ------------------------------------------------------------------------------
HWDPLOT
; TRAP SERVICE ROUTINE TO PLOT THE FOLLOWING. X, Y AND F ARE DEFINED IN "INPUT".
; * TWO GREEN LINES, ONE HORIZONTAL AND ONE VERTICAL CROSSING AT (X,Y) POINT.
;   THE HORIZONTAL LINE OCCUPIES ALL THE SCREEN HORIZONTALLY AND THE VERTICAL
;   LINE OCCUPIES ALL THE SCREEN VERTICALLY.
; * A CIRCLE CENTERED AT (X,Y). CIRCLE CONTOUR IS GREEN. CIRCLE FILL IS
;   GREEN IF F==0 OR RED IF F==1.
; THE FOLLOWING CONSTANTS (ALREADY DEFINED) HAVE TO BE USED:
; * CLRGREEN : COLOR CODE (BGR FORMAT) FOR GREEN
; * CLRRED   : COLOR CODE (BGR FORMAT) FOR RED
; * RADCIRC  : RADIUS OF THE CIRCLE CENTERED AT (X,Y)
; * SCRWIDTH : SCREEN WIDTH
; * SCRHEIGH : SCREEN HEIGHT
; INPUT    : D7.L - Y (16 MOST SIGNIFICANT BITS), X (16 LEAST SIGNIFICANT BITS)
;            D6 BIT 0 - F
; OUTPUT   : NONE
; MODIFIES : NONE
; ------------------------------------------------------------------------------

            MOVEM.L D0-D4,-(A7)

            ; ------------------------------------------
            ; DIBUJAR LÍNEAS (VERDES)
            ; ------------------------------------------
            
            ; Configurar color LÍNEA (verde)
            MOVE.L  #CLRGREEN,D1
            MOVEQ   #80,D0              ; Tarea 80: Set Pen Color
            TRAP    #15

            ; --- LÍNEA HORIZONTAL ---
            ; Coordenadas: (0, Y) a (SCRWIDTH, Y)
            ; Y está en la parte ALTA de D7.
            MOVE.L  D7,D2              ; Copiamos D7 (Todo el registro para asegurar)
            SWAP    D2                 ; Bajamos la Y a la parte baja (D2.W = Y)
                                       ; Ahora en D2 tenemos Y1 = D2.W
            
            MOVEQ   #0,D1              ; X1 = D1.W = 0 (Linea horizontal)
            MOVE.W  #SCRWIDTH,D3       ; X2 = D3.W (Ancho de la pantalla)
            MOVE.W  D2,D4              ; Y2 = Y1 = D4.W, 
                                       ; (Misma altura inicial y final)
            
            MOVEQ   #84,D0             ; Tarea 84: Draw Line (X1,Y1)-(X2,Y2)
            TRAP    #15                ; where X1 = D1.W, Y1 = D2.W, 
                                       ; X2 = D3.W, Y2 = D4.W
            
            ; --- LÍNEA VERTICAL ---
            ; Coordenadas: (X, 0) a (X, SCRHEIGH)
            ; X está en la parte BAJA de D7.
            MOVE.W  D7,D1              ; X1 = D1.W
            MOVEQ   #0,D2              ; Y1 = D2.W = 0
            MOVE.W  D1,D3              ; X2 = X1 = D3.W,
                                       ; (Mismo eje X inicial y final)
                                       
            MOVE.W  #SCRHEIGH,D4       ; Y2 = D4.W (Alto de la pantalla)
            
            MOVEQ   #84,D0             ; Tarea 84: Draw Line (X1,Y1)-(X2,Y2)
            TRAP    #15                ; where X1 = D1.W, Y1 = D2.W, 
                                       ; X2 = D3.W, Y2 = D4.W

            ; CONFIGURAR RELLENO (VERDE O ROJO)
            ; Segun bit 0 de D6 
            
            MOVE.L  #CLRGREEN,D1       ; Asumimos Verde
            BTST    #0,D6               
            BEQ     .APPLY_FILL        ; Si es 0 -> Verde (Saltamos)
                                       
                                       ; Si no salta, es 1 -> Rojo
            MOVE.L  #CLRRED,D1

.APPLY_FILL:
            MOVEQ   #81,D0             ; Tarea 81: Set Fill Color
            TRAP    #15

            ; Configurar Centro (X,Y)
            MOVE.W  D7,D1              ; LX = D1.W (parte baja de D7)
            
            MOVE.L  D7,D2              ; Copiamos D7 (Todo el registro)
            SWAP    D2                 ; UY = D2.W (parte baja tras swap)
            
            MOVE.W  D1,D3              ; D3 sera X2 (base X)
            MOVE.W  D2,D4              ; D4 sera Y2 (base Y)
            
            SUB.W   #RADCIRC,D1        ; LX (X izquierda) = X - Radio
            SUB.W   #RADCIRC,D2        ; UY (Y izquierda) = Y - Radio
            ADD.W   #RADCIRC,D3        ; RX (X derecha) = X + Radio
            ADD.W   #RADCIRC,D4        ; LY (Y derecha) = Y + Radio
            
            MOVEQ   #88,D0             ; Tarea 88: Draw Ellipse (LX,UY)-(RX,LY)
            TRAP    #15                ; where LX = D1.W, UY = D2.W, 
                                       ; RX = D3.W, LY = D4.W

            MOVEM.L (A7)+,D0-D4

            RTE
            
; ------------------------------------------------------------------------------
HWDDBUF
; TRAP SERVICE ROUTINE TO UPDATE DOUBLE BUFFER AS FOLLOWS:
; * SWITCH BUFFERS (REPAINT SCREEN IN THE MANUAL)
; * CLEARS HIDDEN BUFFER.
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; ------------------------------------------------------------------------------
            
            MOVEM.L D0-D1, -(A7)
            
            ; Intercambiamos los buffers
            MOVEQ   #94,D0 ; Tarea 94: Repaint screen 
            TRAP    #15
            
            ; Limpiamos el buffer oculto para que este
            ; limpio para el siguiente frame
            MOVEQ   #11, D0 ; Tarea 11: Clear screen
            MOVE.W  #$FF00,D1
            TRAP    #15
            
            MOVEM.L (A7)+,D0-D1

            RTE


; ------------------------------------------------------------------------------
HWDRMOU
; ISR TO READ THE MOUSE
; INPUT    : NONE
; OUTPUT   : VARIABLE HWDMOUPX (WORD) - MOUSE X COORDINATE
;            VARIABLE HWDMOUPY (WORD) - MOUSE Y COORDINATE
;            VARIABLE HWDMOUBT (BYTE) - BIT0=LEFT MOUSE BUTTON PRESSED.
;                                    BIT1..7=UNDEFINED.
; MODIFIES : NONE
; ------------------------------------------------------------------------------

            MOVEM.L D0-D1,-(A7)
            
            ; Necesitamos D1 a 0 para la tarea 61
            MOVEQ   #0, D1  

            ; Tarea 61: Read Mouse
            ; Con esta tarea se nos guarda en D1 las coordenadas
            ; del raton, Y en la parte alta y X en la parte baja
            MOVEQ   #61,D0
            TRAP    #15
            
            ; Guardamos coordenada X (parte baja de D1)
            ; (HWDMOUPX) es una direccion de memoria
            MOVE.W  D1,(HWDMOUPX)   ; Guardar X (Word bajo de D1)
            
            ; Guardamos coordenada Y (parte alta de D1)
            SWAP    D1              ; Hacemos SWAP
            MOVE.W  D1,(HWDMOUPY)   ; Guardar Y (Word alto de D1)
            
            ; Guardamos el estado de botones
            ; La tarea 61 devuelve los botones en D0
            MOVE.B  D0, (HWDMOUBT)    
       
            MOVEM.L (A7)+,D0-D1
            RTE




*~Font name~Fixedsys~
*~Font size~18~
*~Tab type~0~
*~Tab size~4~
