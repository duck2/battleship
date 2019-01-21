; provide graphics functions

FB_ADDR EQU 0x20000500
; linker fails to get framebuffer address reliably
; see http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0474h/CHDBBAEE.html
	AREA |.ARM.__at_0x20001000|, READWRITE, DATA
framebuffer
	SPACE 504

	AREA |.data|, READONLY, DATA
; templates
battleship
	DCD 0xFFFFFFFF
	DCD 0xFFFFFFFF
civship
	DCB 0xFF, 0xE7, 0xE7, 0x81
	DCB 0x81, 0xE7, 0xE7, 0xFF
cursor
	DCB 0xE0, 0xC0, 0xA0, 0x10
numbers
	DCB 0x7E, 0x89, 0x91, 0xA1, 0x7E
	DCB 0x00, 0x41, 0xFF, 0x01, 0x00
	DCB 0x61, 0x83, 0x85, 0x89, 0x71
	DCB 0x42, 0x81, 0x91, 0x91, 0x6E
	DCB 0x0C, 0x14, 0x24, 0x44, 0xFF
	DCB 0xF2, 0x91, 0x91, 0x91, 0x8E
	DCB 0x7E, 0x91, 0x91, 0x91, 0x0E
	DCB 0x80, 0x80, 0x87, 0x98, 0xE0
	DCB 0x6E, 0x91, 0x91, 0x91, 0x6E
	DCB 0x70, 0x89, 0x89, 0x89, 0x7E

	AREA |.text|, READONLY, CODE, ALIGN=2
	EXTERN send_spi_byte
	EXTERN reset_screen_addr
	EXPORT clear_frame
	EXPORT draw_cursor
	EXPORT draw_arena
	EXPORT draw_digit
	EXPORT draw_civship
	EXPORT draw_battleship
	EXPORT send_frame
	THUMB

; draw the battle arena: a big rectangle
draw_arena
	PUSH {LR}
	LDR R2, =FB_ADDR+84+6
	MOV R3, #64
L2	LDRB R0, [R2]
	ORR R0, R0, #0x01
	STRB R0, [R2]
	ADD R2, R2, #1
	SUBS R3, R3, #1
	BNE L2
	LDR R2, =FB_ADDR+84+6
	MOV R0, #0xFF
	STRB R0, [R2], #84
	STRB R0, [R2], #84
	STRB R0, [R2], #84
	STRB R0, [R2], #84
	LDR R2, =FB_ADDR+(4*84)+6
	MOV R3, #64
L4	LDRB R0, [R2]
	ORR R0, R0, #0x80
	STRB R0, [R2]
	ADD R2, R2, #1
	SUBS R3, R3, #1
	BNE L4
	LDR R2, =FB_ADDR+84+70
	MOV R0, #0xFF
	STRB R0, [R2], #84
	STRB R0, [R2], #84
	STRB R0, [R2], #84
	STRB R0, [R2], #84
	POP {LR}
	BX LR

; blit single byte to framebuffer. R0=X, R1=Y, R2=byte.
; it is particularly hard because FB is bit-based.
blit_byte
	PUSH {R0-R5, LR}
	LDR R3, =FB_ADDR
	LSR R4, R1, #3 ; Y position in the buffer corresponds to Y/8 -> R4
	MOV R5, #84
	MUL R4, R4, R5 ; R4 <- Y/8*84
	ADD R0, R0, R4 ; the first position to write is X+(Y/8)*84
	ADD R3, R0, R3 ; R3 <- FB_ADDR + X+(Y/8)*84
	AND R1, R1, #0x7 ; to get the first half, shift left by Y%8 -> R1
	LSL R5, R2, R1 ; and get the last 8 bits
	AND R5, R5, #0xFF
	LDRB R0, [R3]
	ORR R0, R0, R5
	STRB R0, [R3] ; blit the first half of the byte
	MOV R6, #0x8
	SUB R1, R6, R1 ; R1 <- 8-R1
	LSR R5, R2, R1 ; to get the second half, shift right by 8-Y%8
	ADD R3, R3, #84
	LDRB R0, [R3]
	ORR R0, R0, R5
	STRB R0, [R3] ; and blit the second half
	POP {R0-R5, LR}
	BX LR

; blit a sprite on the screen. R0=X, R1=Y, R2=sprite addr, R3=sprite size
draw_sprite
	PUSH {LR}
L5	LDRB R4, [R2], #1
	PUSH {R0-R3}
	MOV R2, R4
	RBIT R2, R2
	LSR R2, R2, #24
	BL blit_byte
	POP {R0-R3}
	ADD R0, R0, #1
	SUBS R3, R3, #1
	BNE L5
	POP {LR}
	BX LR

; R0=X, R1=Y
draw_battleship
	PUSH {R0-R5, LR}
	LDR R2, =battleship
	MOV R3, #0x8
	BL draw_sprite
	POP {R0-R5, LR}
	BX LR

draw_civship
	PUSH {R0-R5, LR}
	LDR R2, =civship
	MOV R3, #0x8
	BL draw_sprite
	POP {R0-R5, LR}
	BX LR

draw_cursor
	PUSH {R0-R5, LR}
	LDR R2, =cursor
	MOV R3, #0x4
	BL draw_sprite
	POP {R0-R5, LR}
	BX LR

; R0: X, R1: Y, R2: digit
draw_digit
	PUSH {LR}
	LDR R4, =numbers
	MOV R5, #0x5
	MUL R2, R2, R5 ; R2 <- &numbers + R2*5
	ADD R4, R4, R2
	MOV R2, R4
	MOV R3, #0x5
	BL draw_sprite
	POP {LR}
	BX LR

clear_frame
	PUSH {LR}
	LDR R2, =FB_ADDR
	MOV R3, #504
	MOV R0, #0x00
L3	STRB R0, [R2], #1
	SUBS R3, R3, #1
	BNE L3
	POP {LR}
	BX LR

send_frame
	PUSH {LR}
	BL reset_screen_addr
	LDR R2, =FB_ADDR
	MOV R3, #504
L	LDRB R0, [R2], #1
	BL send_spi_byte
	SUBS R3, R3, #1
	BNE L
	POP {LR}
	BX LR
	END
