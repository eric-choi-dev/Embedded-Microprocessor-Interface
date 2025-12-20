; ***************************************************************
; Lab 2, Assignment 1-3: Generate a Tone with Buzzer
; ***************************************************************
            XDEF    Entry, _Startup
            ABSENTRY Entry
            INCLUDE 'derivative.inc'

            ORG     $4000
Entry:
_Startup:
            BSET    DDRP, %11111111  ; Port P를 출력으로 설정 (부저 제어용)
            LDAA    #%10000000   ; PP7 핀을 High로 만들기 위한 값 준비

MainLoop:
            STAA    PTP          ; PP7 핀에 값을 출력
            LDX     #$1FFF       ; 딜레이를 위한 카운터 값 설정
Delay:
            DEX                  ; X 레지스터 1 감소
            BNE     Delay        ; X가 0이 아니면 Delay로 다시 점프
            EORA    #%10000000   ; PP7 비트만 반전 (High <-> Low)
            BRA     MainLoop     ; 다시 처음으로 돌아가 반복

            ORG     $FFFE
            FDB     Entry