#include "680xlogic.asm"

#include "decls.asm"

;#include "util.asm"

#include "game.asm"
;.org $4000	
;	nop
	
.org $1800	; start of 
main:	
setupPias:
	; setup U10A
	ldaA	00111001b	; irq state | n/u | CA2 output | ...mode | CA2 value 1 = don't blank displays | enable direction register | irq on | ...self test ->low
	staA	u10AControl
	ldaA	11111111b	; all outputs
	staA	u10A		
	ldaA	00000100b	; toggle DDRA (3rd) bit to write to ports
	oraA	>u10AControl
	staA	u10AControl
	ldaA	11110000b	; blanking means any outputs here won't affect displays
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
	
	ldX	cRAM
	ldaA	$0F
lClearCRam:
	staA	0,X
	inX
	cpX	cRAM+$ff
	bne	lClearCRam
	
initRam:
	clr 	counter
	clr 	5
	clr 	6
	ldaA	$FF
	;staA	lamp1+0
	;staA	lamp1+7
	staA	lamp16
	ldX	lamp1
	stX	7
	ldaA	10000b
	staA	9

	ldaA	$30
	ldX	disp1_100k
lTestDisp:
	staA	0,X
	addA	0,X
	inX
	cpX	disp2_1 + 1
	bne	lTestDisp
	
	ldX	disp1_100k
	stX	curDispDigitX
	
	ldaA	00000100b
	staA	curDispDigitBit
	;clra
	;staa	sound+1
	;ldaa	$92
	;staa	sound
	;inca
	;staa	sound+1
	;clr	sound
	;ldx	$8000
	;stx	sound+6
	;ldx	$0200
	;stx	sound+4
	;ldaa	$02
	;staa	sound
	
	;ldaa	$02
	;staa	$C0
	
	;ldaa	$01
	;clrb
	;stab	$A2
	;staa	$A3
	;stab	$A4
	;staa	$A5
	;stab	$A6
	;staa	$A7
	;staa	$C0
	;stab	$A1
	;stab	$A0
	;staa	$A1
	;staa	$A0
	;stab	$C0
	
	clI
loop: ; setup done
						
	jmp	loop
	.dw 0
	.dw 0
	.dw 0
	.dw 0
	.dw 0
		
interrupt:	
	ldaA	10000000b ; IRQ status bit
	bitA	>u10AControl
	ifne	; self test switch
		nop
	endif
	
	ldaA	10000000b ; IRQ status bit
	bitA	>u10BControl
	ifeq	; zero crossing
		jmp	afterZeroCrossing
	endif

StrobeLamps:

		;; reset latch 
		;ldaA	00001000b	
		;oraA	>u10BControl	
		;staA	u10BControl
		;
		;ldaA	$FF
		;staA	lampData
;
		ldaA	11110111b	
		andA	>u10BControl
		staA	u10BControl


		ldaB	33
lStrobeWait:	
		decB
		bne	lStrobeWait

		; note, counts from F -> 0 instead of 0 -> F since it gets inverted later
		ldaB	11111111b ; lower half is light addr (0-15), upper half will be ANDed with data
		ldX	lamp1
		
		; addr = low
		; data = high, inverted
		; loop b through 0-15 on lower nibble, anding in row  and sending each time
lStrobeLamps:

		; output address, turn off all outputs
		tBA
		comA
		oraA	$F0
		staA	lampData

		; latch addr into lamp board
		ldaA	00001000b	
		oraA	>u10BControl
		staA	u10BControl
		andA	~00001000b
		staA	u10BControl

		; turn on outputs
		ldaA	0, X		; combine data for this addr w/ addr
		comA
		staA	lampData	; send to lamp board
		
		
		; inc to next addr
		decB			
		inX

		; loop through all 16 addrs
		cpX	lamp16
		bne	lStrobeLamps
; end strobe lamps

		; disable decoders
		ldaA	$FF
		staA	lampData

		; latch addr into lamp board
		ldaA	00001000b	
		oraA	>u10BControl
		staA	u10BControl
		andA	~00001000b
		staA	u10BControl

	
		nop
		ldX	>5
		inX
		; reset latch 
		ldaA	00001000b	
		oraA	>u10BControl	
		staA	u10BControl
		cpX	300
		ifeq	; counter wrapped
			ldX	0
			stX	5
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
				ldaA	01000000b
			endif

			ldX	cRAM
			ldaA	$0F
lClearLamp:
			staA	0,X
			inX
			cpX	lamp16
			bne	lClearLamp
			
			ldX	>7
			ldaA	>9
			oraA	$0F
			staA	0, X
			andA	$F0
			rolA
			ifcs
				ldaA	10000b
				inX
				cpX	lamp16
				ifeq
					ldX	lamp1
				endif
			endif
			staA	9
			stX	7

		else
			stX	5
		endif	
afterZeroCrossing:
	
	ldaA	10000000b ; IRQ status bit
	bitA	>u11AControl
 ;	ifne 	; display irq
 ;		; backup u10A bank
 ;		ldaA	>displayData
 ;		staA	dU10ABackup
 ;		
 ;		; make sure credit display isn't reading disp data
 ;		ldaA	1b ; 5th disp bit
 ;		oraA	>u11A
 ;		staA	u11A
 ;		
 ;		; blank displays
 ;		ldaB	~00001000b ; turn off CA2 bit
 ;		andB	>u10AControl
 ;		staB	u10AControl
 ;		
 ;		ldX	>curDispDigitX 	; get current disp digit addr
 ;		
 ;		
 ;		; select first display
 ;		ldaA	11111110b		
 ;		andA	0, X
 ;		staA	displayData	
 ;		nop
 ;		nop
 ;		oraA	00001111b	; disable first display
 ;		staA	displayData
 ;		
 ;		; select second
 ;		ldaA	11111101b
 ;		andA	6, X
 ;		staA	displayData	; disable second 
 ;		nop
 ;		nop
 ;		oraA	00001111b
 ;		staA	displayData
 ;		
 ;		; select third
 ;		ldaA	11111011b
 ;		andA	12, X
 ;		staA	displayData	; disable third 
 ;		nop
 ;		nop
 ;		oraA	00001111b
 ;		staA	displayData
 ;		
 ;		; select fourth
 ;		ldaA	11110111b
 ;		andA	18, X
 ;		staA	displayData
 ;		nop
 ;		nop
 ;		oraA	00001111b	; disable third 
 ;		staA	displayData
 ;		
 ;		; select fifth (credit)
 ;		ldaA	24, X		; get digit
 ;		staA	displayData	; send to display (not listening yet)
 ;		ldaA	11111110b ; ~5th disp bit
 ;		andA	>u11A
 ;		staA	u11A		; enable 5th disp
 ;		nop
 ;		nop
 ;		; stop 5th from reading
 ;		ldaA	1b ; 5th disp bit
 ;		oraA	>u11A
 ;		staA	u11A	
 ;		
 ;		
 ;		; enable proper digit
 ;		ldaB	>curDispDigitBit
 ;		staB	displayDigits
 ;		
 ;		; stop blanking displays (digit now displayed)
 ;		ldaA	00001000b ; turn on CA2 bit
 ;		oraA	>u10AControl
 ;		staA	u10AControl
 ;		
 ;		
 ;		; advance to next digit for next irq
 ;		clC	; want to shift 1s into curDispDigitBit since it's inverted
 ;		rol	curDispDigitBit
 ;		ifeq	; reset if reached last digit
 ;			ldaA	00000100b
 ;			staA	curDispDigitBit
 ;			ldX	disp1_100k
 ;		else
 ;			inX
 ;		endif
 ;		stX	curDispDigitX
 ;		
 ;		
 ;		; restore u10A bank
 ;		ldaA	>dU10ABackup
 ;		staA	displayData
 ;	endif
	rti
afterInterrupt:

pointers: 	.org $1FFF - 7 	
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end