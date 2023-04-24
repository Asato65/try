counter = $00
controller = $01
is_end_nmi = $02
countdown = $03
frame_counter = $ff


.macro isPushedKey key
	lda controller
	.if (key = 'A')
		and #%10000000
	.elseif (key = 'B')
		and #%01000000
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


drawImage:
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


incCounter:
	ldx counter
	inx
	cpx #$03
	bne @SKIP1
	ldx #$00
@SKIP1:
	stx counter
	rts  ; -----------------------------


getRockPaperScissors:
	ldx counter
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