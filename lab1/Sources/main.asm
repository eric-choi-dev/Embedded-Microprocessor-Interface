;********************************************************
;LAB 1 Assignment: 8-bit multiplication
;writer: Keunhyeok Choi
;********************************************************

;export symbols
  XDEF Entry, _Startup
  ABSENTRY Entry

;include derivative-specific definitions
  INCLUDE 'derivative.inc'
   
;********************************************************  
; variable and data section
;********************************************************
  ORG $3000 
MULTIPLICAND FCB $05 
MULTIPLIER FCB $0A
PRODUCT RMB 2
  
;********************************************************
;program code section  
;********************************************************
  ORG $4000
Entry:
_Startup:
            LDAA MULTIPLICAND
            LDAB MULTIPLIER
            MUL
            STD PRODUCT
            SWI
;********************************************************

;********************************************************
  ORG $FFFE
  FDB Entry
  
  