; ==============================================================================
; TITLE       : PRAC2B
; DESCRIPTION : LAB ASSIGNMENT 2B (MAIN FILE)
; AUTHOR      : ANTONI BURGUERA
; HISTORY     : 13-OCTOBER-2025 - CREATION
; ==============================================================================

; ------------------------------------------------------------------------------
; CONSTANTS
; ------------------------------------------------------------------------------

; SCREEN
SCRWIDTH    EQU     640                     ; SCREEN WIDTH
SCRHEIGH    EQU     480                     ; SCREEN HEIGHT

; INTERRUPTS
INTRDMOU    EQU     7                       ; INTERRUPT NUMBER TO READ MOUSE

; TRAP
TRNUPDBF    EQU     1                       ; TRAP NUM. TO UPDATE DOUBLE BUFFER
TRNPLGFX    EQU     2                       ; TRAP NUM. TO PLOT GRAPHICS

; GRAPHICS
CLRGREEN    EQU     $0000FF00               ; GREEN BGR CODE
CLRRED      EQU     $000000FF               ; RED BGR CODE
RADCIRC     EQU     32                      ; CIRCLE RADIUS


            ORG     $1000

; ------------------------------------------------------------------------------
; CODE INCLUDES
; ------------------------------------------------------------------------------

            INCLUDE "SUBRTN.X68"

; ------------------------------------------------------------------------------
; MAIN PROGRAM
; ------------------------------------------------------------------------------

START       

            MOVE.L  #$D0D0D0D0,D0
            MOVE.L  #$D1D1D1D1,D1
            MOVE.L  #$D2D2D2D2,D2
            MOVE.L  #$D3D3D3D3,D3
            MOVE.L  #$D4D4D4D4,D4
            MOVE.L  #$D5D5D5D5,D5
            MOVE.L  #$D6D6D6D6,D6
            MOVE.L  #$D7D7D7D7,D7
            MOVE.L  #$A0A0A0A0,A0
            MOVE.L  #$A1A1A1A1,A1
            MOVE.L  #$A2A2A2A2,A2
            MOVE.L  #$A3A3A3A3,A3
            MOVE.L  #$A4A4A4A4,A4
            MOVE.L  #$A5A5A5A5,A5
            MOVE.L  #$A6A6A6A6,A6




            ; INIT HARDWARE DEVICES
            JSR     HWDINIT

.LOOP       ; GET MOUSE COORDINATES
            MOVE.L  (HWDMOUPY),D7

            ; GET MOUSE BUTTON STATE
            MOVE.B  (HWDMOUBT),D6

            ; PLOT
            TRAP    #TRNPLGFX

            ; UPDATE DOUBLE BUFFER
            TRAP    #TRNUPDBF
            BRA     .LOOP

            SIMHALT

; ------------------------------------------------------------------------------
; VARIABLES
; ------------------------------------------------------------------------------

HWDMOUPY    DS.W    1                       ; MOUSE Y COORDINATE
HWDMOUPX    DS.W    1                       ; MOUSE X COORDINATE
HWDMOUBT    DS.B    1                       ; MOUSE BUTTON STATUS
            DS.W    0

            END     START






*~Font name~Fixedsys~
*~Font size~18~
*~Tab type~0~
*~Tab size~4~
