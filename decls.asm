u10A:			.equ $0088
u10AControl		.equ $0089
u10B:			.equ $008A
u10BControl:		.equ $008B
u11A:			.equ $0090
u11AControl		.equ $0091
u11B:			.equ $0092
u11BControl:		.equ $0093

sound:			.equ $00A0

switchRow:		.equ u10B
switchStrobe:		.equ u10A
lampAddress:		.equ u10A
lampData:		.equ u10A
scoreDispLatches:	.equ u10A
displayData:		.equ u10A
displayDigits:		.equ u11A

RAM:			.equ $0000
cRAM:			.equ $0200

counter:		.equ $0000
curDispDigitX:		.equ $0001 ; +  points to disp1_100k -> 1
curDispDigitBit:	.equ $0003 ; bit 2 thru 7, shifted left 
dU10ABackup:		.equ $0004 ; store bank in case display irq interrupts zero irq
lU10ABackup:		.equ $000A

lamp1:			.equ cRAM + $00 ; upper nibble is state of 4 lamps in this col
lamp16:			.equ lamp1 + 15
disp1_100k:		.equ cRAM + $10
disp1_1:		.equ disp1_100k + 5
disp2_100k:		.equ cRAM + $16
disp2_1:		.equ disp2_100k + 5
disp3_100k:		.equ cRAM + $1C
disp3_1:		.equ disp3_100k + 5
disp4_100k:		.equ cRAM + $22
disp4_1:		.equ disp4_100k + 5
disp5_100k:		.equ cRAM + $28
disp5_1:		.equ disp5_100k + 5

