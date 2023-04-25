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

	initRam

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

	lda #%00000111
	sta inc_speed

MAINLOOP:
	lda is_end_nmi
	beq MAINLOOP

	; メインプログラム
	lda #$00
	sta is_end_nmi
	jsr getController					; コントローラーの情報を取得

	ldx frame_counter
	inx
	stx frame_counter
	txa
	and inc_speed
	bne @SKIP_INC_COUNTER
	lda stopflag
	bne @SKIP_INC_COUNTER
	jsr incCounter
@SKIP_INC_COUNTER:

	ldx countdown
	beq @SKIP_DEC_COUNTDOWN
	dex
	stx countdown
	bne @END							; カウントを-1したら終了
	lda #$01							; カウントダウンして値が0になったらフラグを立てる
	sta stopflag
	jmp @END
@SKIP_DEC_COUNTDOWN:
	lda stopflag
	beq @CHECK_ISSTART
	getPushedKey 'A'
	beq @CHECK_ISSTART
	lda #$00							; ストップ中でAボタンが押されていたらルーレット開始
	sta stopflag
	sta counter
	lda #%00000111
	sta inc_speed
	jmp @END
@CHECK_ISSTART:
	getPushedKey 'A'
	beq @END
	lda #120							; Aボタンが押されていたらカウントダウンをセット
	sta countdown
	lda #%00001111						; 速度遅くする
	sta inc_speed
@END:

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
