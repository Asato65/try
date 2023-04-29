; win = 1, lose = 2, draw = 3
; cp = x, player = y
; table[3 * playerChoice + computerChoice]

table:
	.byte 3, 1, 2
	.byte 2, 3, 1
	.byte 1, 2, 3


text:
	.byte $20, $23, 25
	.byte "<:ROCK >:PAPER ^:SCISSORS"