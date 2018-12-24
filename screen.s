; drive the screen
; assumes SSI0 at port A.
; screen pins:
; RST->PA7
; CE ->PA3
; DC ->PA6
; DIN->PA5
; CLK->PA2

RCGCSSI EQU 0x400FE61C
PRSSI EQU 0x400FEA1C
RCGCGPIO EQU 0x400FE608

GPIOA_AFSEL EQU 0x40004420
GPIOA_PCTL EQU 0x4000452C
GPIOA_DEN EQU 0x4000451C
GPIOA_DIR EQU 0x40004400
GPIOA_DATA EQU 0x400043FC

SSI0_CR0 EQU 0x40008000
SSI0_CR1 EQU 0x40008004
SSI0_CPSR EQU 0x40008010
SSI0_DR EQU 0x40008008
SSI0_SR EQU 0x4000800C

	AREA |.text|, READONLY, CODE, ALIGN=2
	EXPORT init_screen
	THUMB

; 1. initialize SSI module
; 2. pull down RST for some cycles, pull up
; 3. set H=1,V=0: send 0b00100001, DC=0
; 4. set Vop=5V: send 0b11000000
; 5. set TempC=3: send 0b00000111
; 6. set 0x13 for Vbias for some reason.
; 7. set H=0,V=0: send 0b00100000
; 8. set D=0,E=1(normal display): send 0b00001100
; 9. set DC to 1 after now
; 10. send some dummy data to demonstrate
init_screen
	PUSH {LR}
	BL init_ssi_gpio

	LDR R1, =GPIOA_DATA
	LDR R0, [R1]
	BIC R0, #0x80
	STR R0, [R1]

	LDR R5, =100000
L	SUBS R5, R5, #1
	BNE L

	ORR R0, #0x80
	STR R0, [R1]

	BIC R0, #0x40
	STR R0, [R1]

	MOV R0, #0x21
	BL send_spi_byte
	MOV R0, #0xC0
	BL send_spi_byte
	MOV R0, #0x07
	BL send_spi_byte
	MOV R0, #0x13
	BL send_spi_byte

	MOV R0, #0x20
	BL send_spi_byte
	MOV R0, #0x0C
	BL send_spi_byte
	MOV R0, #0x40
	BL send_spi_byte

	LDR R1, =GPIOA_DATA
	LDR R0, [R1]
	ORR R0, #0x40
	STR R0, [R1]

	MOV R0, #0x1F
	BL send_spi_byte
	MOV R0, #0x05
	BL send_spi_byte
	MOV R0, #0x07
	BL send_spi_byte
	MOV R0, #0x00
	BL send_spi_byte
	MOV R0, #0x1D
	BL send_spi_byte
	MOV R0, #0x00
	BL send_spi_byte
	MOV R0, #0x1F
	BL send_spi_byte
	MOV R0, #0x05
	BL send_spi_byte
	MOV R0, #0x07
	BL send_spi_byte
	MOV R0, #0x00
	BL send_spi_byte
	MOV R0, #0x1D
	BL send_spi_byte

	POP {LR}
	BX LR

; put byte in FIFO, wait until SSI is idle
; takes byte in R0
send_spi_byte
	LDR R1, =SSI0_DR
	STR R0, [R1]
	LDR R1, =SSI0_SR
L2	LDR R0, [R1]
	ANDS R0, R0, #0x10
	BNE L2
	BX LR

; 1. initialize SSI clock
; 2. initialize GPIO clock
; 3. AFSEL for PA[5:2]: 0b00111100
; 4. fn 2(SSI) for PA[5:2]: 0x00222200
; X. maybe add pull-up resistors?
; 5. DEN for PA[7:2]. we use PA7 for RST, PA6 for DC.
; 6. DIR for PA[7:2]: 0b11101100, bit 4 is RX.
; 7. disable SSI0: clear SSE bit of CR1
; 8. put SSI0 into master mode: clear MS bit of CR1
; 9. we want to set SCLK to 4MHz. divisor in CPSR is 4.
; 10. configure CR0 with Freescale and 8-bit data 
; 11. enable SSI0: set SSE bit of CR1
init_ssi_gpio
	LDR R1, =RCGCSSI
	LDR R0, [R1]
	ORR R0, #0x01
	STR R0, [R1]
	NOP
	NOP
	NOP

	LDR R1, =RCGCGPIO
	LDR R0, [R1]
	ORR R0, #0x01
	STR R0, [R1]
	NOP
	NOP
	NOP

	LDR R1, =GPIOA_AFSEL
	MOV R0, #0x3C
	STR R0, [R1]
	LDR R1, =GPIOA_PCTL
	LDR R0, =0x00222200
	STR R0, [R1]
	LDR R1, =GPIOA_DEN
	MOV R0, #0xFC
	STR R0, [R1]
	LDR R1, =GPIOA_DIR
	MOV R0, #0xEC
	STR R0, [R1]

	LDR R1, =SSI0_CR1
	LDR R0, [R1]
	BIC R0, #0x06
	STR R0, [R1]
	LDR R1, =SSI0_CPSR
	MOV R0, #0x04
	STR R0, [R1]
	LDR R1, =SSI0_CR0
	MOV R0, #0x07
	STR R0, [R1]
	LDR R1, =SSI0_CR1
	LDR R0, [R1]
	ORR R0, #0x02
	STR R0, [R1]

	BX LR

	END

