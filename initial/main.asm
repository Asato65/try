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

MAINLOOP:
	waitUpdatingDisp					; 画面が更新されるまで待機

	lda #$00
	sta is_end_nmi						; 画面が更新されたフラグをOFFにする
	getController						; コントローラーの情報を取得
	inc frame_counter					; フレームカウンター（プログラム内で使う時間）を進める

	; ----- メインプログラムここから -----

	; ----- メインプログラムここまで -----

	jmp MAINLOOP
.endproc


.proc NMI
	; ---- 画面描画プログラムここから ----

	; ---- 画面描画プログラムここまで ----

DRAW_IMAGE:
	drawImage							; Xレジスタを引数に持つ

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
