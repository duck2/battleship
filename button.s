PORTF_DIR 		EQU		0X40025400
PORTF_DEN		EQU		0X4002551C		
PORTF_AFSEL		EQU		0X40025420
PORTF_LOCK		EQU		0X40025520
PORTF_CR		EQU		0X40025524
PORTF_PUR		EQU		0X40025510
PORTF_RIS 		EQU		0X40025414
PORTF_MIS 		EQU		0X40025418
PORTF_ICR		EQU		0X4002541C
PORTF_IS		EQU		0X40025404
PORTF_IBE		EQU		0X40025408
PORTF_IEV		EQU		0X4002540C
PORTF_IM		EQU		0X40025410

SYSCTL_RCGCGPIO	EQU		0X400FE608
NVIC_EN0		EQU		0xE000E100

	AREA |.ARM.__at_0x20001700|, READWRITE, DATA
	EXPORT battleship_btn_flag
	EXPORT civship_btn_flag
battleship_btn_flag DCD 0
civship_btn_flag DCD 0

	AREA |.text|, READONLY, CODE, ALIGN=2
	EXPORT init_buttons
	EXPORT GPIOPortF_Handler
	THUMB
		
GPIOPortF_Handler PROC
			LDR		R1,=PORTF_MIS
			LDR		R0,[R1]
			ANDS	R2,R0,#0X01
			BNE		battleship
			ANDS	R2,R0,#0X10
			BNE		civship
			B		ok
			
civship		LDR		R1,=civship_btn_flag
			MOV		R0, #0x1
			STR		R0,[R1]
			B		ok
			
battleship	LDR		R1,=battleship_btn_flag
			MOV		R0, #0x1
			STR		R0,[R1]
			
ok			LDR		R1,=PORTF_ICR
			LDR		R0,[R1]
			MOV		R0, #0x11
			STR		R0,[R1]

			BX 		LR
			ENDP

init_buttons
			LDR		R1,=SYSCTL_RCGCGPIO
			LDR		R0,[R1]
			ORR		R0,#0x20
			STR		R0,[R1]
			NOP
			NOP
			NOP
			
			LDR		R1,=PORTF_LOCK
			LDR		R0,=0X4C4F434B
			STR		R0,[R1]
			
			LDR		R1,=PORTF_CR
			LDR		R0,[R1]
			ORR		R0,#0XFF
			STR		R0,[R1]
			
			LDR		R1,=PORTF_DIR
			LDR		R0,[R1]
			BIC		R0,#0X11
			STR		R0,[R1]
			
			LDR		R1,=PORTF_AFSEL
			LDR		R0,[R1]
			BIC		R0,#0X11
			STR		R0,[R1]
			
			LDR		R1,=PORTF_PUR
			LDR		R0,[R1]
			ORR		R0,#0X11
			STR		R0,[R1]
			
			LDR		R1,=PORTF_DEN
			LDR		R0,[R1]
			ORR		R0,#0X11
			STR		R0,[R1]

			LDR		R1,=PORTF_IM
			LDR		R0,[R1]
			BIC		R0,#0X11
			STR		R0,[R1]
			
			LDR		R1,=PORTF_RIS
			MOV		R0,#0x0
			STR		R0,[R1]
			LDR		R1,=PORTF_IS
			LDR		R0,[R1]
			BIC		R0,#0x11
			STR		R0,[R1]
			LDR		R1,=PORTF_IBE
			MOV		R0,#0x0
			STR		R0,[R1]
			LDR		R1,=PORTF_IEV
			LDR		R0,[R1]
			BIC		R0,#0X11
			STR		R0,[R1]
			
			LDR		R1,=PORTF_IM
			LDR		R0,[R1]
			ORR		R0,#0X11
			STR		R0,[R1]
			
			LDR		R1,=NVIC_EN0		;NVIC 30
			MOV32	R0,#0X40000000
			STR		R0,[R1]
			
			BX LR
	
	ALIGN
	END