.setcpu "6502"
.autoimport on

.include "data.asm"
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
	init

	; 初期値をセット
	lda #%00000111
	sta speed
	lda #$00
	sta state							; 0: 停止中，1: ルーレット中，2: ルーレットゆっくり

MAINLOOP:
	waitUpdatingDisp					; 画面が更新されるまで待機

	lda #$00
	sta is_end_nmi						; 画面が更新されたフラグをOFFにする
	getController					; コントローラーの情報を取得

	; ----- メインプログラムここから -----

	inc frame_counter					; フレームカウンター（プログラム内で使う時間）を進める
	lda frame_counter
	and speed
	bne SKIP_INC_COUNTER
	lda state
	beq SKIP_INC_COUNTER				; ルーレット停止中はCPの手を変更しない
	changeChoice					; 次の手に変更する
SKIP_INC_COUNTER:

	; 状態によって場合分け
	lda state
	beq CHECK_ISSTART
	cmp #$01
	beq CHECK_IS_CHOICE
	cmp #$02
	beq DEC_COUNTDOWN

; state=0(停止中)のとき
CHECK_ISSTART:
	getPushedKey 'T'
	beq END
	; ストップ中でSTARTボタン(T)が押されていたらルーレット開始
	lda #$01
	sta state
	lda #$00
	sta computerChoice
	sta result
	lda #%00000111
	sta speed
	jmp END

; state=1(ルーレット中)のとき
CHECK_IS_CHOICE:
	getPushedKey 'L'
	beq CHECK_U
	lda #$00
	sta playerChoice
	jmp SLOWDOWN_ROULETTE
CHECK_U:
	getPushedKey 'U'
	beq CHECK_R
	lda #$01
	sta playerChoice
	jmp SLOWDOWN_ROULETTE
CHECK_R:
	getPushedKey 'R'
	beq END
	lda #$02
	sta playerChoice
SLOWDOWN_ROULETTE:
	; ルーレット中にAボタンが押されたら
	lda #120							; Aボタンが押されていたらカウントダウンをセット
	sta counter
	lda #%00001111						; 速度遅くする
	sta speed
	lda #$02
	sta state
	jmp END

; state=2(ルーレットゆっくり)のとき
DEC_COUNTDOWN:
	; ルーレットがゆっくりになっている時実行
	dec counter
	bne END								; カウントダウンして値が0でなければ終了
	; カウントダウンして値が0になったら
	lda #$00
	sta state							; ルーレット停止
	lda playerChoice
	asl
	clc
	adc playerChoice					; playerChoiceを3倍する
	clc
	adc computerChoice
	tax
	lda table, x
	sta result

END:
	; ----- メインプログラムここまで -----

	jmp MAINLOOP
.endproc


.proc NMI
	; ---- 画面描画プログラムここから ----

	; ルーレット中の文字表示
	lda #$20
	sta $2006
	lda #$20
	sta $2006
	lda #$00
	ldx #$20
INIT_TEXT:
	sta $2007
	dex
	bne INIT_TEXT

	lda state
	beq STOP_DISP
	cmp #$01
	beq ROULETTE_DISP
	bne DRAW_IMAGE
STOP_DISP:
	; 停止中の文字表示
	lda #$20
	sta $2006
	lda #$3b
	sta $2006
	lda #'S'
	sta $2007
	lda #'T'
	sta $2007
	lda #'O'
	sta $2007
	lda #'P'
	sta $2007
	jmp DRAW_IMAGE
ROULETTE_DISP:
	ldx #$00
	lda roulette_text, x
	sta $2006
	inx
	lda roulette_text, x
	sta $2006
	inx
	lda roulette_text, x
	tay
LOOP1:
	inx
	lda roulette_text, x
	sta $2007
	dey
	bne LOOP1

	; ---- 画面描画プログラムここまで ----

DRAW_IMAGE:
	drawImage						; Xレジスタを引数に持つ

	; 画面を更新したフラグをONにする
	lda #$01
	sta is_end_nmi

	rti									; 終了
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
