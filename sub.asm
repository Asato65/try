controller = $00
prev_controller = $01
is_end_nmi = $02
counter = $03
speed = $04
state = $05
computerChoice = $06
playerChoice = $07
result = $08
frame_counter = $ff


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
	sta $2006
	lda #$00
	sta $2006
	ldx #$00
	ldy #$08
@INIT_VRAM_LOOP2:
@INIT_VRAM_LOOP1:
	sta $2007
	dex
	bne @INIT_VRAM_LOOP1
	dey
	bne @INIT_VRAM_LOOP2

	; パレットテーブルの転送
	lda #$3f
	sta $2006
	lda #$00
	sta $2006
	lda #$20
	sta $2007
	lda #$0f
	sta $2007
	lda #$36
	sta $2007

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


drawImage:
	jsr getComputerChoice
	lda #$21
	sta $2006
	lda #$ae
	sta $2006
	ldy #$04
@DRAW_IMAGE_LINE1:
	stx $2007
	inx
	dey
	bne @DRAW_IMAGE_LINE1

	lda #$21
	sta $2006
	lda #$ce
	sta $2006
	ldy #$04
@DRAW_IMAGE_LINE2:
	stx $2007
	inx
	dey
	bne @DRAW_IMAGE_LINE2

	lda #$21
	sta $2006
	lda #$ee
	sta $2006
	ldy #$04
@DRAW_IMAGE_LINE3:
	stx $2007
	inx
	dey
	bne @DRAW_IMAGE_LINE3

	lda #$22
	sta $2006
	lda #$0e
	sta $2006
	ldy #$04
@DRAW_IMAGE_LINE4:
	stx $2007
	inx
	dey
	bne @DRAW_IMAGE_LINE4

	lda #$00
	sta $2005
	sta $2005

	rts  ; -----------------------------


getController:
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

	rts  ; -----------------------------


changeChoice:
	ldx computerChoice
	inx
	cpx #$03
	bne @SKIP1
	ldx #$00
@SKIP1:
	stx computerChoice
	rts  ; -----------------------------


getComputerChoice:
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
	rts  ; -----------------------------