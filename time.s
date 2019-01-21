; TImer is configured to count a duration of 1 second, 
;and generate an interrupt
;
SYSCTL_RCGCTIMER	EQU		0X400FE65C
WTIMER0_CTL			EQU 	0x4003600C
WTIMER0_CFG			EQU		0x40036000
WTIMER0_TAMR		EQU		0x40036004
WTIMER0_ILR			EQU		0x40036028
WTIMER0_IMR			EQU		0x40036018
NVIC_EN2		EQU		0xE000E108

	AREA |.data|, READWRITE, DATA
	EXPORT countdown
countdown DCD 0

	AREA |.text|, READONLY, CODE, ALIGN=2
	EXTERN	__main
	EXPORT	WideTimer0A_Handler
	EXPORT init_timer
	THUMB
		
WideTimer0A_Handler	
			LDR 	R1,=countdown
			LDR		R0, [R1]
			SUBS	R0,#1
			STR		R0, [R1]
			
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
			
			LDR		R1,=WTIMER0_ILR
			LDR		R0,[R1]
			MOV32	R0,#0X00F42400
			STR		R0,[R1]
			
			LDR		R1,=WTIMER0_IMR
			LDR		R0,[R1]
			ORR		R0,#0X01
			STR		R0,[R1]
			
			LDR		R1,=NVIC_EN2		;NVIC 94
			MOV32	R0,#0x40000000
			STR		R0,[R1]
			BX LR
			ENDP
		ALIGN 
		END