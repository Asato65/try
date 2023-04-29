PPUADDR				= $2006
PPUACCESS			= $2007

controller			= $80
prev_controller		= $81
is_end_nmi			= $82
computerChoice		= $83
frame_counter		= $84


.macro getPushedKey key
	lda prev_controller
	eor #$ff
	and controller

	.if (key = 'A')
		and #%10000000
	.elseif (key = 'B')
		and #%01000000
	.elseif (key = 'S')
		and #%00100000
	.elseif (key = 'T')
		and #%00010000
	.elseif (key = 'U')
		and #%00001000
	.elseif (key = 'D')
		and #%00000100
	.elseif (key = 'L')
		and #%00000010
	.elseif (key = 'R')
		and #%00000001
	.endif
.endmacro


.macro init
	sei									; IRQ禁止
	cld									; BCDオフ

	; PPU初期化
	lda #%00001000
	sta $2000
	lda #%00000000
	sta $2001

	ldx #$ff
	txs

	ldx #$00
	txa
INIT_ZEROPAGE:
	sta $00, x
	dex
	bne INIT_ZEROPAGE

INIT_STACK:
	sta $0100, x
	dex
	bne INIT_STACK

	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldx #$00
	ldy #$08
@INIT_VRAM_LOOP2:
@INIT_VRAM_LOOP1:
	sta PPUACCESS
	dex
	bne @INIT_VRAM_LOOP1
	dey
	bne @INIT_VRAM_LOOP2

	; パレットテーブルの転送
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	lda #$20
	sta PPUACCESS
	lda #$0f
	sta PPUACCESS
	lda #$36
	sta PPUACCESS

	lda #$00
	sta $2005
	sta $2005

	; スクリーンON
	lda #%10001000						; NMI-ON, SPR=$1000
	sta $2000
	lda #%00011110						; すべて表示
	sta $2001
.endmacro


.macro waitUpdatingDisp
	lda is_end_nmi
	beq MAINLOOP
.endmacro


.macro escapeRegister
	php
	pha
	txa
	pha
	tya
	pha
.endmacro


.macro restoreRegister
	pla
	tay
	pla
	tax
	pla
	plp
.endmacro


.macro drawImage
	getComputerChoice
	lda #$21
	sta PPUADDR
	lda #$ae
	sta PPUADDR
	ldy #$04
@DRAW_IMAGE_LINE1:
	stx PPUACCESS
	inx
	dey
	bne @DRAW_IMAGE_LINE1

	lda #$21
	sta PPUADDR
	lda #$ce
	sta PPUADDR
	ldy #$04
@DRAW_IMAGE_LINE2:
	stx PPUACCESS
	inx
	dey
	bne @DRAW_IMAGE_LINE2

	lda #$21
	sta PPUADDR
	lda #$ee
	sta PPUADDR
	ldy #$04
@DRAW_IMAGE_LINE3:
	stx PPUACCESS
	inx
	dey
	bne @DRAW_IMAGE_LINE3

	lda #$22
	sta PPUADDR
	lda #$0e
	sta PPUADDR
	ldy #$04
@DRAW_IMAGE_LINE4:
	stx PPUACCESS
	inx
	dey
	bne @DRAW_IMAGE_LINE4

	lda #$00
	sta $2005
	sta $2005
.endmacro


.macro getController
	lda controller
	sta prev_controller

	ldx #$01							; コントローラー初期化
	stx $4016
	dex
	stx $4016

	ldx #$08
@GET_CON1_LOOP:
	lda $4016
	and #%00000011
	cmp #$01							; A + 0xFF, Aレジスタが1のときキャリーが発生
	rol controller
	dex
	bne @GET_CON1_LOOP
.endmacro


.macro changeChoice
	ldx computerChoice
	inx
	cpx #$03
	bne @SKIP1
	ldx #$00
@SKIP1:
	stx computerChoice
.endmacro


.macro getComputerChoice
	ldx computerChoice
	beq @ROCK
	cpx #$01
	beq @SCISSORS
	bne @PAPER
@ROCK:
	ldx #$80
	bne @END
@SCISSORS:
	ldx #$90
	bne @END
@PAPER:
	ldx #$a0
@END:
.endmacro