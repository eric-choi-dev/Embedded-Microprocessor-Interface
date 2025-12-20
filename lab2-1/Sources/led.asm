; ***************************************************************
; Lab 2, Assignment 1-1: Read Switches and Display on LEDs
; ***************************************************************
            XDEF    Entry, _Startup
            ABSENTRY Entry
            INCLUDE 'derivative.inc'

            ORG     $4000
Entry:
_Startup:
            LDAA    #$FF         ; 16진수 FF (모두 1)를 ACCA에 로드
            STAA    DDRH         ; Port H를 출력으로 설정 (LED 제어용)
            STAA    PERT         ; Port T의 풀업 저항 활성화 (스위치 입력용)

Loop:
            LDAA    PTT          ; Port T(스위치)의 상태를 읽어옴
            STAA    PTH          ; 읽어온 값을 Port H(LED)로 바로 출력
            BRA     Loop         ; 계속 반복

            ORG     $FFFE
            FDB     Entry