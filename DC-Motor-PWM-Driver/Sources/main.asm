;***********************************************************************
; COE538 - Lab 3: Battery and Bumper Displays
; Description: This program reads the voltage from a potentiometer
;              on AN04, calculates the corresponding battery voltage,
;              and displays it on an LCD. It also reads the status
;              of two bumper switches on AN02 and AN03 and displays
;              their status.
; Microcontroller: HCS12 (mc9s12c32 on eebot)
;***********************************************************************

;***********************************************************************
; Equates and Definitions
;***********************************************************************
;-- I/O Port Equates
PORTB       EQU     $0001           ; Port B for LCD Data
DDRB        EQU     $0003           ; Port B Data Direction Register
PTJ         EQU     $0268           ; Port J for LCD Control
DDRJ        EQU     $026A           ; Port J Data Direction Register

;-- ATD (A/D Converter) Register Equates
ATDCTL2     EQU     $0082
ATDCTL3     EQU     $0083
ATDCTL4     EQU     $0084
ATDCTL5     EQU     $0085
ATDSTAT0    EQU     $0086
ATDDR4      EQU     $0098           ; Result register for AN04 (Potentiometer)
PORTAD0     EQU     $008F           ; Port AD for digital input of bumper switches
ATDDIEN     EQU     $008D           ; ATD Input Enable Register

;-- LCD Control Signal Definitions (Connected to Port J)
LCD_E       EQU     %10000000       ; PJ7 is LCD Enable
LCD_RS      EQU     %01000000       ; PJ6 is LCD Register Select

;-- Bumper Switch Definitions (Connected to Port AD)
BOW_SW      EQU     %00000100       ; AN02/PAD02 is Bow Bumper
STERN_SW    EQU     %00001000       ; AN03/PAD03 is Stern Bumper

;***********************************************************************
; Variable and Data Section
;***********************************************************************
            ORG     $3800
BCD_BUFFER  EQU     *
TEN_THOUS   RMB     1               ; 10,000s digit
THOUSANDS   RMB     1               ; 1,000s digit
HUNDREDS    RMB     1               ; 100s digit
TENS        RMB     1               ; 10s digit
UNITS       RMB     1               ; 1s digit
BCD_SPARE   RMB     2               ; Space for decimal point, terminator
NO_BLANK    RMB     1               ; Used by BCD2ASC for zero suppression

msg1        dc.b    "Battery volt ", 0
msg2        dc.b    "Sw status ", 0

;***********************************************************************
; Code Section
;***********************************************************************
            ORG     $4000
_Startup:
            LDS     #$4000          ; Initialize the stack pointer

            JSR     initLCD         ; Initialize the LCD controller
            JSR     initAD          ; Initialize the A/D converter

            ; Display static messages once at the start
            LDAA    #$80            ; Move cursor to line 1, position 0
            JSR     cmd2LCD
            LDX     #msg1
            JSR     putsLCD

            LDAA    #$C0            ; Move cursor to line 2, position 0
            JSR     cmd2LCD
            LDX     #msg2
            JSR     putsLCD

; Main loop: read sensors, calculate, and display
main_loop:
            ; 1. Start an A/D conversion sequence
            ; r.just, unsign, single conv, mult chan, ch0, start conv.
            MOVB    #$14, ATDCTL5   ; Multi-channel, start with AN4

            ; 2. Wait for the conversion sequence to complete
wait_conv:
            BRCLR   ATDSTAT0, #$80, wait_conv

            ; 3. Read potentiometer result and calculate voltage
            LDAA    ATDDR4          ; Load the channel 4 result into AccA
            LDAB    #39             ; AccB = 39
            MUL                     ; AccD = AccA * 39 (16-bit result)
            ADDD    #600            ; AccD = (result * 39) + 600

            ; 4. Convert 16-bit binary result to BCD, then to ASCII
            JSR     int2BCD
            JSR     BCD2ASC

            ; 5. Display the formatted voltage
            LDAA    #$8D            ; Position cursor at end of "Battery volt "
            JSR     cmd2LCD

            ; Display format: "TT.H" (e.g., "10.5", " 8.5", " 0.6")
            LDAA    TEN_THOUS       ; Display 10s digit (or space)
            JSR     putcLCD
            LDAA    THOUSANDS       ; Display 1s digit
            JSR     putcLCD
            LDAA    #'.'
            JSR     putcLCD
            LDAA    HUNDREDS        ; Display 0.1s digit
            JSR     putcLCD

            ; 6. Read and display bumper switch status
            LDAA    #$CD            ; Position cursor at end of "Sw status "
            JSR     cmd2LCD

            ; Check Bow Switch (AN02)
            LDAA    PORTAD0
            ANDA    #BOW_SW
            BNE     bow_off         ; Logic '1' (3.5V) means switch is open (off)
bow_on:
            LDAA    #'B'
            JSR     putcLCD
            BRA     check_stern
bow_off:
            LDAA    #'-'
            JSR     putcLCD

check_stern:
            ; Check Stern Switch (AN03)
            LDAA    PORTAD0
            ANDA    #STERN_SW
            BNE     stern_off       ; Logic '1' means switch is open (off)
stern_on:
            LDAA    #'S'
            JSR     putcLCD
            BRA     end_loop
stern_off:
            LDAA    #'-'
            JSR     putcLCD

end_loop:
            JMP     main_loop       ; Repeat forever

;***********************************************************************
; Subroutines
;***********************************************************************

;=======================================================================
; initAD: Initializes the A/D Converter
; Based on Lab Manual, page 17
;=======================================================================
initAD:
    MOVB    #%10000000, ATDCTL2 ; Power up AD, select fast flag clear
    JSR     delay_us_20     ; Wait for power up (min 20us)
    MOVB    #%00100000, ATDCTL3 ; 8 conversions in a sequence
    MOVB    #%10000101, ATDCTL4 ; res=8-bit, conv-clks=2, prescal=12 (1MHz bus -> 500kHz ATD clk)
    ; Configure AN02 and AN03 as digital inputs for bumpers
    BSET    ATDDIEN, #(BOW_SW|STERN_SW)
    RTS

;=======================================================================
; LCD Subroutines (4-bit interface)
; Assumes Port B (PB3-0) for data D7-D4, Port J for RS, E
; We send high nibble first, then low nibble.
;=======================================================================
initLCD:
    BSET    DDRB, #$FF      ; Port B as output
    BSET    DDRJ, #(LCD_E | LCD_RS) ; Port J control pins as output
    
    JSR     delay_ms_20     ; Wait for LCD power up

    ; Force 8-bit mode first
    LDAA    #$30
    JSR     lcd_write_nibble
    JSR     delay_ms_5
    JSR     lcd_write_nibble
    JSR     delay_ms_1
    JSR     lcd_write_nibble
    JSR     delay_ms_1

    ; Set to 4-bit mode
    LDAA    #$20
    JSR     lcd_write_nibble
    JSR     delay_ms_1

    ; Now in 4-bit mode, send full commands
    LDAA    #$28            ; Function Set: 4-bit, 2-line, 5x8 font
    JSR     cmd2LCD
    LDAA    #$0C            ; Display ON, Cursor OFF, Blink OFF
    JSR     cmd2LCD
    LDAA    #$01            ; Clear Display
    JSR     cmd2LCD
    JSR     delay_ms_5      ; Clear command takes longer
    LDAA    #$06            ; Entry Mode: Increment cursor, no shift
    JSR     cmd2LCD
    RTS

cmd2LCD:
    BCLR    PTJ, #LCD_RS    ; RS=0 for command
    JSR     lcd_write_byte
    RTS

putcLCD:
    BSET    PTJ, #LCD_RS    ; RS=1 for data
    JSR     lcd_write_byte
    RTS

putsLCD: ; Prints null-terminated string from address in X
puts_loop:
    LDAA    1,X+            ; Load character, post-increment pointer
    BEQ     puts_done
    JSR     putcLCD
    BRA     puts_loop
puts_done:
    RTS

lcd_write_byte: ; Write byte in AccA to LCD
    PSHA
    LSRA                ; high nibble -> low nibble
    LSRA
    LSRA
    LSRA
    JSR     lcd_write_nibble ; Send high nibble
    PULA
    JSR     lcd_write_nibble ; Send low nibble
    JSR     delay_us_50
    RTS
    
lcd_write_nibble: ; Write low nibble of AccA to Port B
    PSHA
    ANDA    #$0F
    STAA    PORTB
    BSET    PTJ, #LCD_E     ; Pulse E high
    NOP
    NOP
    BCLR    PTJ, #LCD_E     ; Pulse E low
    PULA
    RTS

;-- Delay Subroutines
delay_ms_20:
    LDY #4
delay_ms_loop_outer:
    JSR delay_ms_5
    DBNE Y, delay_ms_loop_outer
    RTS

delay_ms_5:
    LDY #5
delay_ms_loop:
    JSR delay_ms_1
    DBNE Y, delay_ms_loop
    RTS

delay_ms_1: ; Rough 1ms delay for 1MHz bus clock
    LDX #248
delay_1ms_inner:
    NOP
    NOP
    DBNE X, delay_1ms_inner
    RTS

delay_us_50:
    LDX #12
delay_50us_inner:
    NOP
    DBNE X, delay_50us_inner
    RTS

delay_us_20:
    LDX #4
delay_20us_inner:
    NOP
    DBNE X, delay_20us_inner
    RTS


;***********************************************************************
; Binary 16 to BCD Conversion Routine
; From Lab 3 Manual, Section 8, by Peter Hiscocks
; Converts a 16-bit binary number in D into BCD digits in BCD_BUFFER.
;***********************************************************************
int2BCD:
    XGDX                    ; Save the binary number into X
    LDAA #0                 ; Clear the BCD_BUFFER
    STAA TEN_THOUS
    STAA THOUSANDS
    STAA HUNDREDS
    STAA TENS
    STAA UNITS

    CPX #0                  ; Check for a zero input
    BEQ CON_EXIT            ; and if so, exit

    ; Get UNITS digit
    XGDX                    ; Get the binary number back to D as dividend
    LDX #10                 ; Setup 10 as the divisor
    IDIV                    ; Quotient is now in X, remainder in D
    STAB UNITS              ; Store remainder (B is low byte of D)
    CPX #0                  ; If quotient is zero,
    BEQ CON_EXIT            ; then exit

    ; Get TENS digit
    XGDX                    ; Swap first quotient back into D
    LDX #10                 ; and setup for another divide by 10
    IDIV
    STAB TENS
    CPX #0
    BEQ CON_EXIT

    ; Get HUNDREDS digit
    XGDX                    ; Swap quotient back into D
    LDX #10
    IDIV
    STAB HUNDREDS
    CPX #0
    BEQ CON_EXIT

    ; Get THOUSANDS digit
    XGDX
    LDX #10
    IDIV
    STAB THOUSANDS
    CPX #0
    BEQ CON_EXIT

    ; Get TEN_THOUSANDS digit
    XGDX
    LDX #10
    IDIV
    STAB TEN_THOUS
    ; No need to check quotient, it must be zero

CON_EXIT:
    RTS                     ; We're done the conversion


;***********************************************************************
; BCD to ASCII Conversion Routine: Version 2
; From Lab 3 Manual, Section 10, by Peter Hiscocks
; Converts BCD number in BCD_BUFFER into ascii format with
; leading zero suppression.
;***********************************************************************
BCD2ASC:
    LDAA    #0              ; Initialize the blanking flag
    STAA    NO_BLANK

;-- Check 'ten_thousands' digit
C_TTHOU:
    LDAA    TEN_THOUS
    ORAA    NO_BLANK
    BNE     NOT_BLANK1
ISBLANK1:
    LDAA    #' '            ; It's blank, so store a space
    STAA    TEN_THOUS
    BRA     C_THOU
NOT_BLANK1:
    LDAA    TEN_THOUS
    ORAA    #$30            ; Convert to ascii
    STAA    TEN_THOUS
    LDAA    #$1             ; Signal that we have seen a 'non-blank' digit
    STAA    NO_BLANK

;-- Check 'thousands' digit for blankness
C_THOU:
    LDAA    THOUSANDS
    ORAA    NO_BLANK        ; If it's blank and 'no-blank' is still zero
    BNE     NOT_BLANK2
ISBLANK2:
    LDAA    #' '            ; Thousands digit is blank, so store a space
    STAA    THOUSANDS
    BRA     C_HUNS
NOT_BLANK2:
    LDAA    THOUSANDS       ; (similar to 'ten_thousands' case)
    ORAA    #$30
    STAA    THOUSANDS
    LDAA    #$1
    STAA    NO_BLANK

;-- Check 'hundreds' digit for blankness
C_HUNS:
    LDAA    HUNDREDS
    ORAA    NO_BLANK        ; If it's blank and 'no-blank' is still zero
    BNE     NOT_BLANK3
ISBLANK3:
    LDAA    #' '            ; Hundreds digit is blank, so store a space
    STAA    HUNDREDS
    BRA     C_TENS
NOT_BLANK3:
    LDAA    HUNDREDS        ; (similar to 'ten_thousands' case)
    ORAA    #$30
    STAA    HUNDREDS
    LDAA    #$1
    STAA    NO_BLANK

;-- Check 'tens' digit for blankness
C_TENS:
    LDAA    TENS
    ORAA    NO_BLANK        ; If it's blank and 'no-blank' is still zero
    BNE     NOT_BLANK4
ISBLANK4:
    LDAA    #' '            ; Tens digit is blank, so store a space
    STAA    TENS
    BRA     C_UNITS
NOT_BLANK4:
    LDAA    TENS            ; (similar to 'ten_thousands' case)
    ORAA    #$30
    STAA    TENS
    ; No need to set NO_BLANK again

;-- Convert 'units' digit
C_UNITS:
    LDAA    UNITS           ; No blank check necessary, convert to ascii.
    ORAA    #$30
    STAA    UNITS

    RTS                     ; We're done