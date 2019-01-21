; for now, do nothing
ADC0_SSFIFO1 EQU 0x40038068
ADC1_SSFIFO2 EQU 0x40039088
ADC0_PSSI EQU 0x40038028
ADC1_PSSI EQU 0x40039028
ADC0_ISC EQU 0x4003800C
ADC1_ISC EQU 0x4003900C

deploy_ships EQU 0
blank_screen EQU 1
peek_screen EQU 2
deploy_mines EQU 3
end_screen EQU 4

	; also R11 holds game state
	AREA |.data|, READWRITE, DATA
cursor_y DCD 0
cursor_x DCD 0
ship1_x DCD 0
ship1_y DCD 0
ship1_type DCD 0
ship2_x DCD 0
ship2_y DCD 0
ship2_type DCD 0
ship3_x DCD 0
ship3_y DCD 0
ship3_type DCD 0
ship4_x DCD 0
ship4_y DCD 0
ship4_type DCD 0

	AREA |.text|, READONLY, CODE, ALIGN=2			
	THUMB
	EXTERN civship_btn_flag
	EXTERN battleship_btn_flag
	EXTERN init_screen
	EXTERN init_pots
	EXTERN init_buttons
	EXTERN clear_frame
	EXTERN draw_arena
	EXTERN draw_cursor
	EXTERN draw_battleship
	EXTERN draw_digit
	EXTERN send_frame
	EXPORT __main
	ENTRY

; input -> update -> draw -> post-input...
__main
	BL init_screen
	BL init_pots
	BL init_buttons
	MOV R12, #deploy_ships

_input
	BL poll_adc

_update
	CMP R12, #deploy_ships
	BEQ _deploy_ships
_deploy_ships

_draw
	BL clear_frame
	BL draw_arena
_draw_cursor
	LDR R2, =cursor_x
	LDR R0, [R2]
	LDR R2, =cursor_y
	LDR R1, [R2]
	BL draw_cursor
	
	BL send_frame

_post_input
	BL enable_adc
	LDR R0, =50000
L	SUBS R0, R0, #1
	BNE L
	B _input
	

	WFI

poll_adc
	PUSH {LR}
	LDR R1, =ADC0_SSFIFO1
	LDR R0, [R1]
	LDR R2, =cursor_y
	MOV R3, #29
	MUL R0, R0, R3
	MOV R3, #0xFFF
	UDIV R0, R0, R3
	ADD R0, R0, #9
	STR R0, [R2]

	LDR R1, =ADC1_SSFIFO2
	LDR R0, [R1]
	LDR R2, =cursor_x
	MOV R3, #62
	MUL R0, R0, R3
	MOV R3, #0xFFF
	UDIV R0, R0, R3
	ADD R0, R0, #7
	STR R0, [R2]
	POP {LR}
	BX LR

enable_adc
	PUSH {LR}
	LDR R1, =ADC1_PSSI
	LDR R0, [R1]
	LDR R2, =0x88000004
	ORR R0, R0, R2
	STR R0, [R1]
	LDR R1, =ADC1_ISC
	MOV R0, #0x04
	STR R0, [R1]

	LDR R1, =ADC0_PSSI
	LDR R0, [R1]
	LDR R2, =0x88000002
	ORR R0, R0, R2
	STR R0, [R1]
	LDR R1, =ADC0_ISC
	MOV R0, #0x02
	STR R0, [R1]
	POP {LR}
	BX LR

done
	B done
	ALIGN
	END

