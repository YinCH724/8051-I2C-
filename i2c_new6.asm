$NOMOD51
$INCLUDE (REG_MPC82G516.INC)	
	ORG 00H
	JMP INIT
	ORG 0BH
	JMP TIMER0_INT
;	ORG 23H
;	JMP UART_INT
	
	ORG 50H

	SDA EQU P0.0
	SCL EQU P0.1

	S_FLAG EQU 20H.1

	SAMP_20Hz_H EQU 60
	SAMP_20Hz_L EQU 176
	
   	SAMP_50Hz_H EQU 177
	SAMP_50Hz_L EQU 224

	SAMP_100Hz_H EQU 216
	SAMP_100Hz_L EQU 240

	SAMP_200Hz_H EQU 236
	SAMP_200Hz_L EQU 120

	SAMP_500Hz_H EQU 248
	SAMP_500Hz_L EQU 48

	SAMP_1000Hz_H EQU 252
	SAMP_1000Hz_L EQU 24

	/*
	ACC EQU 08H
	MAG EQU 0EH
	GYR EQU 14H
	EUL EQU 1AH
	QUA EQU 20H
	*/

;SAMPLING RATE SET
;*********************************
 	SAMPLING_H EQU SAMP_1000Hz_H
	SAMPLING_L EQU SAMP_1000Hz_L
;*********************************


;8051 SET
;*********************************	
INIT:
	MOV P0M0,#0FFH
	MOV P0M1,#0FFH
	SETB SDA
    SETB SCL
	
	MOV IE,#10000010B
	MOV SCON,#01010000B
	MOV TMOD,#21H
	MOV TH1,#243
	SETB TR1

	MOV R4,#0
	MOV R6,#100
	
	MOV R7,#0FFH
	DJNZ R7,$
	MOV R7,#0FFH
	DJNZ R7,$
	MOV R7,#0FFH
	DJNZ R7,$
	MOV R1,#50H
	MOV R2,#07H
	MOV R3,#00H	
	CALL WR_DATA
;*********************************


;BNO055 SET
;*********************************
MAIN:
 	MOV R1,#50H
	MOV R2,#07H
	MOV R3,#00H	
	CALL WR_DATA

	MOV R1,#50H
	MOV R2,#3DH
	MOV R3,#08H	
	CALL WR_DATA

	CALL WAIT_7ms

	MOV TH0,#SAMPLING_H
	MOV TL0,#SAMPLING_L

	SETB TR0

	MOV R7,#255
	DJNZ R7,$
	
;*********************************


;DATA READ
;***********************************

READ_DATA: 
 	JNB S_FLAG,$   
	MOV R1,#50H
	MOV R2,#1AH
	MOV R3,#06H
	CALL RD_DATA
	CLR S_FLAG
	

	SJMP READ_DATA


;***********************************


;I2C FUNCTION
;***********************************

WR_DATA:
	CALL START
	MOV A,R1
	CALL SEND
	MOV A,R2
	CALL SEND
	MOV A,R3
	CALL SEND
	CALL STOP
 	RET
RD_DATA:
 	CALL START

	MOV A,R1
	CALL SEND
	
	MOV A,R2
	CALL SEND
	
	CALL RSTART

	MOV A,R1
	ORL A,#01H
	CALL SEND

 
	SJMP REC_STEP
CON_REC:
	CALL ACK
REC_STEP:
	CALL RECIEVE
	/*
	MOV SBUF,A
	JNB TI,$
	CLR TI
	*/	
	DJNZ R3,CON_REC
 	CALL NACK
	CALL STOP
	RET	
	
START:
	MOV R7,#3
	DJNZ R7,$
	CLR SDA	
	MOV R7,#3
	DJNZ R7,$
	CLR SCL
	RET

RSTART:
    CLR SCL
	SETB SDA 
	SETB SCL
	MOV R7,#3
	DJNZ R7,$
	CLR SDA
	MOV R7,#3
	DJNZ R7,$
	CLR SCL
	SETB SDA
	MOV R7,#3
	DJNZ R7,$
	RET
	
SEND:
    MOV R0,#8
SEND_NEXT:
	RLC A
	CLR SCL
	MOV SDA,C
	SETB SCL
	MOV R7,#3
	DJNZ R7,$
	DJNZ R0,SEND_NEXT
	CLR SCL 
	SETB SDA
	JB SDA,$
    CALL CHECK_RELEASE
	RET
		
RECIEVE:
 	CLR C
	CLR A
	MOV R0,#8
REC_NEXT:
	CLR SCL
    CALL CHECK_RELEASE
	MOV C,SDA
	RLC A
	MOV R7,#3
	DJNZ R7,$
	DJNZ R0,REC_NEXT
	CLR SCL      ;LX
	RET
	
ACK:
	CLR SDA
	CALL CHECK_RELEASE
	MOV R7,#3
 	DJNZ R7,$
	CLR SCL 
	SETB SDA
	RET           ;HL
	
	
NACK:
	SETB SDA
	SETB SCL     ;HH
	RET
		
STOP:
    CLR SCL
	CLR SDA
	SETB SCL
	MOV R7,#3
	DJNZ R7,$
	SETB SDA     ;H H
	RET
			
	
CHECK_RELEASE:
	SETB SCL
	JNB SCL,CHECK_RELEASE
	RET
;***********************************

;WAIT FOR OPR_MODE CONFIG
;***********************************
WAIT_7ms:
 	MOV A,IE
	ANL A,#7FH
	MOV IE,A
 	MOV TH0,#228
	MOV TL0,#168
	SETB TR0
	JNB TF0,$
 	CLR TF0
	CLR TR0
	MOV A,IE
	ORL A,#80H
	MOV IE,A
    RET
;**********************************

;SAMPLING TIME
;***********************************

TIMER0_INT:
    /*
	DJNZ R6,GO_S
	
	MOV SBUF,R4
	JNB TI,$
	CLR TI
	CLR TR0
	*/
 	
	JNB S_FLAG,GO_S
 	MOV SBUF,#11H
	JNB TI,$
	CLR TI
	MOV SBUF,#22H
	JNB TI,$
	CLR TI
	MOV SBUF,#33H
	JNB TI,$
	CLR TI
	MOV SBUF,#44H
	JNB TI,$
	CLR TI
	MOV SBUF,#55H
	JNB TI,$
	CLR TI
	MOV SBUF,#66H
	JNB TI,$
	CLR TI
 	CLR TR0
	SJMP END_TM0
	
GO_S:
 	SETB S_FLAG
	MOV TH0,#SAMPLING_H ;60
	MOV TL0,#SAMPLING_L;176

END_TM0:
 	RETI

;******************************
 	
END	
	
	