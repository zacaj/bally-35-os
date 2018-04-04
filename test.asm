#include "680xlogic.asm"

#include "decls.asm"

;#include "util.asm"

#include "game.asm"
	
.org $1800	; start of 
main:	
setupPias:
	; setup U10A
	ldaA	00110001b	; irq state | n/u | CA2 output | ...mode | CA2 value 0 = blank displays | enable direction register | irq on | ...self test ->low
	staA	u10AControl
	ldaA	11111111b	; all outputs
	staA	u10A		
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u10AControl
	staA	u10AControl
	ldaA	11110000b	; blanking means any outputs here will affect displays
	staA	u10A		; 0-3 set all display latches low, 4-7 blank disp data
	
	; setup U10B
	ldaA	00111011b	; " | " | " | " | CB2 value 1 = ready for lamp strobe | " | irq when | ...zero crossing ->high
	staA	u10BControl
	ldaA	00000000b	; all inputs
	staA	u10B
	ldaA	00000100b	; toggle DDRA (3rd) bit to read from ports
	oraA	>u10BControl
	staA	u10BControl

	; setup U11A
	ldaA	00110001b	; " | " | " | " | CA2 value 0 = LED off | " | irq when | ...display irq -> low
	staA	u11AControl
	ldaA	11111111b	; all outputs
	staA	u11A
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u11AControl
	staA	u11AControl
	ldaA	00000000b	; 0 credit display latch low, 1 n/u, 2-7 digit enables low
	staA	u11A

	; setup U11B
	ldaA	00110000b	; n/u | " | " | " | CB2 low = write to solenoids not sound | " | disable | ...CB1
	staA	u11BControl
	ldaA	11111111b
	staA	u11B
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u11BControl
	staA	u11BControl
	ldaA	10011111b	; 0-3 = solenoid number to fire, 1111 = 15 = none
	staA	u11B		; 4-7 = continuous solenoids
	
initRam:
	clr 	counter
	
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

StrobeLamps:
		ldaB	11110000b ; lower half is light addr (0-15), upper half will be ANDed with data
		ldX	lamp1
lStrobeLamps:
		tBA
		andA	0, X		; combine data for this addr w/ addr
		staA	lampData	; send to lamp board
		
		; latch data into lamp board
		ldaA	11110111b	
		andA	>u10BControl
		staA	u10BControl
		
		; inc to next addr
		incB			
		inX
		
		; reset latch 
		ldaA	00001000b	
		oraA	>u10BControl	
		staA	u10BControl
		
		; loop through all 16 addrs
		cpX	lamp16+1
		bne	lStrobeLamps
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
				ldaA	10100000b
			else
				; turn led on
				oraA	>u11AControl	
				staA	u11AControl
				ldaA	01010000b
			endif
			
			ldX	lamp1
lCopyLamp:
			staA	0, X
			inX
			cpX	lamp16+1
			bne	lCopyLamp
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