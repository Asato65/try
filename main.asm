.setcpu "6502"
.autoimport on

.include "sub.asm"

.segment "HEADER"
	.byte $4e, $45, $53, $1a
	.byte $02	; プログラムバンク
	.byte $01	; キャラクターバンク
	.byte $01	; 垂直ミラー
	.byte $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00

.segment "STARTUP"
.proc RESET
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
INIT_VRAM_LOOP2:
INIT_VRAM_LOOP1:
	sta $2007
	dex
	bne INIT_VRAM_LOOP1
	dey
	bne INIT_VRAM_LOOP2

	; パレットテーブルの転送
	lda #$3f
	sta $2006
	lda #$00
	sta $2006
	lda #$0f
	sta $2007

	lda #$00
	sta $2005
	sta $2005

	; スクリーンON
	lda #%10001000						; NMI-ON, SPR=$1000
	sta $2000
	lda #%00011110						; すべて表示
	sta $2001

MAINLOOP:
	lda is_end_nmi
	beq MAINLOOP

	; メインプログラム
	lda #$00
	sta is_end_nmi
	sta controller
	sta $f0
	sta $f1

	ldx frame_counter
	inx
	stx frame_counter
	txa
	and #%00000111
	bne @SKIP_INC_COUNTER
	jsr incCounter
@SKIP_INC_COUNTER:

	jsr getController					; コントローラーの情報を取得
	isPushedKey 'A'
	bne @NOT_PUSH_A
	lda #120
	sta countdown
@NOT_PUSH_A:

	; メインプログラム終了

	jmp MAINLOOP

.endproc

.proc NMI
	php
	pha
	txa
	pha
	tya
	pha

	; 画面描画

	jsr getRockPaperScissors
	jsr drawImage						; Xレジスタを引数に持つ
	lda #$01
	sta is_end_nmi

	pla
	tay
	pla
	tax
	pla
	plp
	rti
.endproc


.proc IRQ
	rti
.endproc


.segment "CHARS"
	.incbin "character.chr"

.segment "VECTORS"
	.word NMI
	.word RESET
	.word IRQ