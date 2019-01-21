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
	AREA |.ARM.__at_0x20001500|, READWRITE, DATA
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
	EXTERN init_timer
	EXTERN clear_frame
	EXTERN draw_arena
	EXTERN draw_cursor
	EXTERN draw_battleship
	EXTERN draw_digit
	EXTERN draw_civship
	EXTERN send_frame
	EXPORT __main
	ENTRY

; input -> update -> draw -> post-input...
__main
	BL init_screen
	BL init_pots
	BL init_buttons
;	BL init_timer
	MOV R12, #deploy_ships
	MOV R11, #0

_input
	BL poll_adc

_update
	CMP R12, #deploy_ships
	BEQ _deploy_ships

; Deployment stage. R11 is ship count. R10 is ship type(0=battle, 1=civ)
_deploy_ships
	LDR R1, =battleship_btn_flag
	MOV R10, #0
	LDR R0, [R1]
	CMP R0, #0
	BNE __put_ship
	LDR R1, =civship_btn_flag
	MOV R10, #1
	LDR R0, [R1]
	CMP R0, #0
	BNE __put_ship
	B _draw
__put_ship				; XXX: add bounds check
	LDR R1, =battleship_btn_flag
	MOV R0, #0
	STR R0, [R1]
	LDR R1, =civship_btn_flag
	MOV R0, #0
	STR R0, [R1]
	LDR R1, =cursor_x
	LDR R0, [R1]
	LDR R1, =cursor_y
	LDR R2, [R1]		; R0 <- cursor_x, R2 <- cursor_y
	LDR R4, =ship1_x
	MOV R3, #12
	MUL R3, R3, R11
	ADD R3, R3, R4		; R3 <- &ship1_x + ship_count*3*4
	STR R0, [R3]		; [R3] <- cursor_x
	ADD R3, R3, #4		; R3 <- R3+4 (brings to &shipN_y!)
	STR R2, [R3]		; [R3] <- cursor_y
	ADD R3, R3, #4		; R3 <- R3+4 (brings to &shipN_type!)
	STR R10, [R3]		; [R3] <- ship_type
	ADD R11, R11, #1	; ship_count++
	CMP R11, #4			; if ship_count == 4, game_state <- blank_screen and skip draw
	BNE _draw
	MOV R12, #blank_screen
	B _post_input

_draw
	BL clear_frame
	BL draw_arena
_draw_ships
	MOV R5, R11			; R5(i) <- ship_count
	LDR R4, =ship1_x	; R4 <- &ship1_x
L2	CMP R5, #0
	BEQ _draw_cursor	; stop if i == 0
	SUB R5, R5, #1		; i--
	MOV R3, #12	
	MUL R3, R3, R5
	ADD R3, R3, R4		; R3 <- &ship1_x + 12*i
	LDR R0, [R3]		; R0 <- [R3] (shipN_x)
	ADD R3, R3, #4		; R3 <- R3+4
	LDR R1, [R3]		; R1 <- [R3] (shipN_y)
	ADD R3, R3, #4		; R3 <- R3+4
	LDR R2, [R3]		; R2 <- [R3] (shipN_type)
	CMP R2, #0			; if shipN_type == 0, draw battleship
	BEQ __draw_b
	B __draw_c			; else, draw civilian ship
__draw_b
	BL draw_battleship
	NOP
	B L2
__draw_c
	BL draw_civship
	NOP
	B L2				; in any case, go back to loop check
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

