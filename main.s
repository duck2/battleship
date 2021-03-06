; for now, do nothing
ADC0_SSFIFO1 EQU 0x40038068
ADC1_SSFIFO2 EQU 0x40039088
ADC0_PSSI EQU 0x40038028
ADC1_PSSI EQU 0x40039028
ADC0_ISC EQU 0x4003800C
ADC1_ISC EQU 0x4003900C

STCTRL EQU 0xE000E010
STRELOAD EQU 0xE000E014
STCURRENT EQU 0xE000E018

WTIMER0_CTL	EQU 0x4003600C

deploy_ships EQU 0
deploy_ships_end EQU 1
p2_wait EQU 2
p2_peek EQU 3
deploy_mines EQU 4
check_winner EQU 5
p1_wins EQU 6
p2_wins EQU 7

	; also R11 holds game state
	AREA |.ARM.__at_0x20001500|, READWRITE, DATA
cursor_y DCD 0
cursor_x DCD 0
battleship_count DCD 0
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
mine1_x DCD 0
mine1_y DCD 0
mine2_x DCD 0
mine2_y DCD 0
mine3_x DCD 0
mine3_y DCD 0
mine4_x DCD 0
mine4_y DCD 0

	AREA |.text|, READONLY, CODE, ALIGN=2			
	THUMB
	EXTERN civship_btn_flag
	EXTERN battleship_btn_flag
	EXTERN countdown
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

poll_adc PROC
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
	ENDP

enable_adc PROC
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
	ENDP

; input -> update -> draw -> post-input...
__main
	BL init_screen
	BL init_pots
	BL init_buttons
	BL init_timer
	MOV R12, #deploy_ships
	MOV R11, #0

	LDR R1, =battleship_count		; reset count
	MOV R0, #0
	STR R0, [R1]
	LDR R1, =battleship_btn_flag	; buttons tend to think they are pressed
	MOV R0, #0						; after first configuration
	STR R0, [R1]
	LDR R1, =civship_btn_flag
	MOV R0, #0
	STR R0, [R1]

_input
	BL poll_adc

_update
	CMP R12, #deploy_ships
	BEQ _deploy_ships
	CMP R12, #deploy_ships_end
	BEQ _deploy_ships_end
	CMP R12, #p2_wait
	BEQ _p2_wait
	CMP R12, #p2_peek
	BEQ _p2_peek
	CMP R12, #deploy_mines
	BEQ.W _deploy_mines
	CMP R12, #check_winner
	BEQ.W _check_winner
	CMP R12, #p1_wins
	BEQ.W _p1_wins
	CMP R12, #p2_wins
	BEQ.W _p2_wins

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
	CMP R10, #0	
	BNE __real_put_ship			; if not battleship, go on placing
	LDR R1, =battleship_count	; if battleship, increment battleship count
	LDR R0, [R1]
	ADD R0, R0, #1
	STR R0, [R1]
__real_put_ship
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
	CMP R11, #4			; if ship_count == 4, game_state <- deploy_ships_end
	BNE.W _draw
	MOV R12, #deploy_ships_end
	B _post_input

_deploy_ships_end
	LDR R1, =battleship_btn_flag
	LDR R0, [R1]
	CMP R0, #0
	BEQ.W _draw
	MOV R0, #0
	STR R0, [R1]		; clear button flag
	MOV R12, #p2_wait
	B _post_input

_p2_wait
	LDR R1, =battleship_btn_flag
	LDR R0, [R1]
	CMP R0, #0
	BEQ.W _draw
	MOV R0, #0
	STR R0, [R1]		; clear button flag
	MOV R12, #p2_peek

_p2_peek				; a small draw-wait so we don't pollute draw
	BL clear_frame		; with a systick wait
	BL draw_arena
	BL draw_ships
	BL send_frame
	LDR R1, =STCTRL
	MOV R0, #0
	STR R0, [R1]

	LDR R1, =STRELOAD
	LDR R0, =0x001E8480
	STR R0, [R1]

	LDR R1, =STCURRENT
	STR R0, [R1]

	LDR R1, =STCTRL
	LDR R0, [R1]
	ORR R0, #0x1
	STR R0, [R1]

	LDR R1, =STCTRL
L3  LDR R0, [R1]
	ANDS R0, #0x10000
	BEQ L3
							; when 0.5s is over, set countdown to 20, enable timer, deploy mines
	LDR	R1,=countdown
	MOV	R0,#20
	STR	R0,[R1]
	LDR	R1,=WTIMER0_CTL  ;BURASI MAIN I�INDE STLENECEK
	LDR	R0,[R1]
	ORR	R0,#0x01
	STR	R0,[R1]

	MOV R9, #0	; we don't know what will happen to R9...
	MOV R12, #deploy_mines
	B _post_input

; Deploy mines. R9 is mine count.
_deploy_mines
	LDR R1, =battleship_btn_flag
	LDR R0, [R1]
	CMP R0, #0
	BNE __put_mine
	B _draw
__put_mine
	LDR R1, =battleship_btn_flag
	MOV R0, #0
	STR R0, [R1]
	LDR R1, =cursor_x
	LDR R0, [R1]
	LDR R1, =cursor_y
	LDR R2, [R1]		; R0 <- cursor_x, R2 <- cursor_y
	LDR R4, =mine1_x
	MOV R3, #8
	MUL R3, R3, R9
	ADD R3, R3, R4		; R3 <- &mine1_x + mine_count*2*4
	STR R0, [R3]		; [R3] <- cursor_x
	ADD R3, R3, #4		; R3 <- R3+4 (brings to &mineN_y!)
	STR R2, [R3]		; [R3] <- cursor_y
	ADD R9, R9, #1		; mine_count++
	CMP R9, #4			; if mine_count == 4, game_state <- check_winner
	BNE _draw
	MOV R12, #check_winner
	B _post_input

_check_winner
	LDR R1, =battleship_count
	LDR R9, [R1]		; R9 is remaining battleships
	MOV R6, #4			; R6 is mineN, R7 is shipN
Lmine
	CMP R6, #0
	BEQ check_results
	SUB R6, R6, #1
	MOV R7, #4
Lship
	CMP R7, #0
	BEQ Lmine
	SUB R7, R7, #1
load_data
	LDR R1, =mine1_x	; R2 = &mineN_x = &mine1_x + 8*mineN
	MOV R0, #8
	MUL R0, R0, R6
	ADD R1, R1, R0
	LDR R2, [R1]
	LDR R1, =ship1_x	; R3 = &shipN_x = &ship1_x + 12*shipN
	MOV R0, #12
	MUL R0, R0, R7
	ADD R1, R1, R0
	LDR R3, [R1]
	LDR R1, =mine1_y	; R4 = &mineN_y = &mine1_x + 8*mineN
	MOV R0, #8
	MUL R0, R0, R6
	ADD R1, R1, R0
	LDR R4, [R1]
	LDR R1, =ship1_y	; R5 = &shipN_y = &ship1_y + 12*shipN
	MOV R0, #12
	MUL R0, R0, R7
	ADD R1, R1, R0
	LDR R5, [R1]
	LDR R1, =ship1_type	; R8 = &shipN_type = &ship1_type + 12*shipN
	MOV R0, #12
	MUL R0, R0, R7
	ADD R1, R1, R0
	LDR R8, [R1]
check_mine_ship			; R5=shipN_y, R4=mineN_y, R3=shipN_x, R2=mineN_x, R8=shipN_type
	SUBS R5, R4, R5		; if mineN_y - shipN_y >= 8, no collision
	CMP R5, #8
	BGT Lship
	SUBS R3, R2, R3		; if mineN_x - shipN_x >= 8, no collision
	CMP R3, #8
	BGT Lship
	LDR R1, =ship1_type ; if collision, check type of ship
	LDR R0, [R1]
	CMP R0, #0
	BNE goto_p1_wins	; if not battleship, p1 wins.
	SUB R9, R9, #1		; else, reduce battleship count
	B Lship
check_results
	CMP R9, #0
	BLE goto_p2_wins
	B goto_p1_wins

goto_p1_wins
	MOV R12, #p1_wins
	B _post_input
goto_p2_wins
	MOV R12, #p2_wins
	B _post_input

_p2_wins
	BL clear_frame
	MOV R0, #30
	MOV R1, #20
	MOV R2, #2
	BL draw_digit
	MOV R0, #40
	BL draw_digit
	BL send_frame
	LDR R1, =battleship_btn_flag
L4	LDR R0, [R1]
	CMP R0, #0
	BEQ L4
	B __main

_p1_wins
	BL clear_frame
	MOV R0, #30
	MOV R1, #20
	MOV R2, #1
	BL draw_digit
	MOV R0, #40
	MOV R2, #1
	BL draw_digit
	BL send_frame
	LDR R1, =battleship_btn_flag
L5	LDR R0, [R1]
	CMP R0, #0
	BEQ L5
	B __main

_draw
	BL clear_frame
	CMP R12, #p2_wait
	BEQ _draw_p2_and_exit
	CMP R12, #deploy_mines
	BEQ _draw_deploy_mines
	B _draw_game

_draw_p2_and_exit
	MOV R0, #30
	MOV R1, #20
	MOV R2, #2
	BL draw_digit
	BL send_frame
	B _post_input

_draw_deploy_mines
	BL draw_arena
	BL draw_timer
	B _draw_cursor

_draw_game
	BL draw_arena
	BL draw_ships
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

; moved out for neatness
draw_ships PROC
	PUSH {LR}
	MOV R5, R11			; R5(i) <- ship_count
	LDR R4, =ship1_x	; R4 <- &ship1_x
L2	CMP R5, #0
	BEQ exit			; stop if i == 0
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
exit
	POP {LR}
	BX LR
	ENDP

draw_timer PROC
	PUSH {R0-R6, LR}
	LDR R3, =countdown
	LDR R4, [R3]
	MOV R0, #10
	UDIV R5, R4, R0
	MUL R6, R5, R0
	SUB R4, R4, R6
	MOV R0, #70
	MOV R1, #0
	MOV R2, R5
	BL draw_digit
	MOV R0, #76
	MOV R1, #0
	MOV R2, R4
	BL draw_digit
	POP {R0-R6, LR}
	BX LR
	ENDP

done
	B done
	ALIGN
	END

