; for now, do nothing

	AREA |.text|, READONLY, CODE, ALIGN=2			
	THUMB
	EXTERN potx_value
	EXTERN poty_value
	EXTERN init_screen
	EXTERN init_pots
	EXTERN clear_frame
	EXTERN draw_arena
	EXTERN draw_cursor
	EXTERN draw_digit
	EXTERN send_frame
	EXPORT __main

__main
	BL init_screen
	BL init_pots
	BL clear_frame
	BL draw_arena
	LDR R2, =potx_value
	LDR R0, [R2]
	LDR R2, =poty_value
	LDR R1, [R2]
	BL draw_cursor
	BL send_frame
	WFI
done
	B done
	END

