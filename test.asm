#include "680xlogic.asm"

#include "decls.asm"

;#include "util.asm"

#include "game.asm"
	
.org $1800
main:	
setupPias:
	ldaA	00110001b	; irq state | n/u | CA2 output | ...mode | CA2 value 0 = blank displays | enable direction register | irq on | ...self test ->low
	staA	u10AControl
	ldaA	11111111b	; all outputs
	staA	u10A		
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u10AControl
	staA	u10AControl
	ldaA	11110000b	; blanking means any outputs here will affect displays
	staA	u10A		; 0-3 set all display latches low, 4-7 blank disp data
	
	ldaA	00111011b	; " | " | " | " | CB2 value 1 = ready for lamp strobe | " | irq when | ...zero crossing ->high
	staA	u10BControl
	ldaA	00000000b	; all inputs
	staA	u10B
	ldaA	00000100b	; toggle DDRA (3rd) bit to read from ports
	oraA	>u10BControl
	staA	u10BControl

	ldaA	00110001b	; " | " | " | " | CA2 value 0 = LED off | " | irq when | ...display irq -> low
	staA	u11AControl
	ldaA	11111111b	; all outputs
	staA	u11A
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u11AControl
	staA	u11AControl
	ldaA	00000000b	; 0 credit displya latch low, 1 n/u, 2-7 digit enables low
	staA	u11A

	ldaA	00110000b	; n/u | " | " | " | CB2 low = write to solenoids not sound | " | disable | ...CB1
	staA	u11BControl
	ldaA	11111111b
	staA	u11B
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u11BControl
	staA	u11BControl
	ldaA	10011111b
	staA	u11B
	clI
loop: ; setup done
						
	jmp	loop
	.dw 0
	.dw 0
	.dw 0
	.dw 0
	.dw 0
		
interrupt:	
	inc	RAM
	
	ldaA	10000000b ; IRQ status bit
	bitA	>u10AControl
	ifne	; self test switch
		nop
	endif
	
	ldaA	10000000b ; IRQ status bit
	bitA	>u10BControl
	ifne	; zero crossing
		nop
	endif
	
	ldaA	10000000b ; IRQ status bit
	bitA	>u11AControl
	ifne 	; display irq
		nop
		inc 	counter
		ifeq	; counter wrapped
			ldaA	00001000b	; led bit
			bitA	>u11AControl
			ifne	; led on?
				; turn led off
				ldaA	11110111b	
				andA	>u11AControl
				staA	u11AControl
			else
				; turn led on
				oraA	>u11AControl	
				staA	u11AControl
			endif
		endif
			
	endif
	rti
afterInterrupt:

pointers: 	.org $1FFF - 7 	
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end