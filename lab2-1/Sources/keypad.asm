; ***************************************************************
; Lab 2, Assignment 1-2: Read Keypad and Control Color LED
; ***************************************************************
            XDEF    Entry, _Startup
            ABSENTRY Entry
            INCLUDE 'derivative.inc'

            ORG     $4000
Entry:
_Startup:
            BSET    DDRP, %11111111  ; Port P를 출력으로 설정 (컬러 LED 제어용)
            BSET    DDRE, %00010000  ; Port E의 4번 핀을 출력으로 설정 (키패드 활성화용)
            BCLR    PORTE, %00010000 ; 키패드 활성화 (OE 신호를 Low로 만듦)

Loop:
            LDAA    PTS          ; Port S에서 키패드 값을 읽어옴 (상위 4비트)
            LSRA                 ; 비트를 오른쪽으로 4번 밀어서
            LSRA                 ; 하위 4비트에 키패드 값을 맞춤
            LSRA
            LSRA
            STAA    PTP          ; 처리된 값을 Port P(컬러 LED)로 출력
            BRA     Loop         ; 계속 반복

            ORG     $FFFE
            FDB     Entry