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
	init

	; 初期値をセット
	lda #%00000111
	sta speed
	lda #$00
	sta state							; 0: 停止中，1: ルーレット中，2: ルーレットゆっくり

MAINLOOP:
	waitUpdatingDisp					; 画面が更新されるまで待機

	; メインプログラム
	lda #$00
	sta is_end_nmi						; 画面が更新されたフラグをOFFにする
	jsr getController					; コントローラーの情報を取得

	inc frame_counter					; フレームカウンター（プログラム内で使う時間）を進める
	lda frame_counter
	and speed
	bne SKIP_INC_COUNTER
	lda state
	beq SKIP_INC_COUNTER				; ルーレット停止中はCPの手を変更しない
	jsr changeChoice					; 次の手に変更する
SKIP_INC_COUNTER:

	lda state
	cmp #$02
	bne SKIP_DEC_COUNTDOWN
	; ルーレットがゆっくりになっている時実行
	dec counter
	bne END							; カウントダウンして値が0でなければ終了
	; カウントダウンして値が0になったら
	lda #$00
	sta state							; ルーレット停止
	jmp END
SKIP_DEC_COUNTDOWN:
	lda state
	bne CHECK_ISSTART
	getPushedKey 'A'
	beq CHECK_ISSTART
	lda #$01							; ストップ中でAボタンが押されていたらルーレット開始
	sta state
	lda #$00
	sta choice
	lda #%00000111
	sta speed
	jmp END
CHECK_ISSTART:
	getPushedKey 'A'
	beq END
	lda #120							; Aボタンが押されていたらカウントダウンをセット
	sta counter
	lda #%00001111						; 速度遅くする
	sta speed
	lda #$02
	sta state
END:

	; メインプログラム終了

	jmp MAINLOOP

.endproc


.proc NMI
	; ------------ 画面描画 -------------
	jsr drawImage						; Xレジスタを引数に持つ

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
