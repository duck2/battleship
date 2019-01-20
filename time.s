; TImer is configured to count a duration of 1 second, 
;and generate an interrupt
;
SYSCTL_RCGCTIMER	EQU		0X400FE65C
WTIMER0_CTL			EQU 	0x4003600C
WTIMER0_CFG			EQU		0x40036000
WTIMER0_TAMR		EQU		0x40036004
WTIMERO_ILR			EQU		0x40036028
WTIMER0_IMR			EQU		0x40036018


	AREA |.text|, READONLY, CODE, ALIGN=2
	EXTERN	__main
	EXPORT	WideTimer0A_Handler
	EXPORT init_timer
	THUMB
		
WideTimer0A_Handler	
			LDR 	R1,=COUNT_ADR
			LDR		R0,[R1]
			SUBS	R0,#1
			BEQ		time_over
			STR		R0,[R1]
			MOV		R1,#10						; sayilari nasil yazdiriyosun ekrana
			UDIV	R2,R0,R1					;sag üst koseye yani
			LDR		R1,=numbers
			MOV		R3,#4
			MUL		R0,R2,R3
			ADD		R2,R1,R0
			
			BX 		LR
; TImer is configured to count a duration of 1 second, 
;and generate an interrupt
;
init_timer	PROC
			LDR		R1,=SYSCTL_RCGCTIMER
			LDR		R0,[R1]
			ORR		R0,#0X01
			STR		R0,[R1]
			NOP
			NOP
			NOP
			
			LDR		R1,=WTIMER0_CTL
			LDR		R0,[R1]
			BIC		R0,#0X01
			STR		R0,[R1]
			
			LDR		R1,=WTIMER0_CFG
			LDR		R0,[R1]
			BIC		R0,#0XF
			ORR		R0,#0X4
			STR		R0,[R1]
			
			LDR		R1,=WTIMER0_TAMR
			LDR		R0,[R1]
			ORR		R0,#0X002
			STR		R0,[R1]
			
			LDR		R1,=WTIMERO_ILR
			LDR		R0,[R1]
			MOV32	R0,#0X00F42400
			STR		R0,[R1]
			
			LDR		R1,=WTIMER0_IMR
			LDR		R0,[R1]
			ORR		R0,#0X01
			STR		R0,[R1]
			ENDP
		ALIGN 
		END