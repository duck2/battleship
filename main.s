; for now, do nothing

	AREA main, READONLY, CODE, ALIGN=2			
	THUMB
	EXTERN init_screen
	EXPORT __main

__main
	BL init_screen
	WFI
	B __main
