//
// Advent of Code 2022 - Day 2
// Michelle-Marie Schiller
//

.global _main
.align 4

.equ SCORE_LOSS, 0
.equ SCORE_DRAW, 3
.equ SCORE_WIN , 6

.equ SCORE_ROCK    , 1
.equ SCORE_PAPER   , 2
.equ SCORE_SCISSORS, 3

_main:
    // Save link register
    STR LR, [SP, #-16]!

    // Get pointer to input
    ADRP X0, TxtInput@PAGE
    ADD X0, X0, TxtInput@PAGEOFF

    // Get pointer to score table
    ADRP X1, TableScore@PAGE
    ADD X1, X1, TableScore@PAGEOFF

    // Get pointer to move table
    ADRP X2, TableMove@PAGE
    ADD X2, X2, TableMove@PAGEOFF

    // Reset score counters (part 1 and 2)
    MOV W8, #0
    MOV W9, #0

    // Start processing the input
    LoopInput:
        // Get next character
        LDRB W3, [X0]

        // Is this the end of our input?
        CBZ W3, LoopEnd

        // Get opponent's move (skip whitespace), subtract by 'A'
        LDRB W3, [X0], #2
        SUB W4, W3, #65

        // [Part 1] Get our move (skip newline), subtract by 'X', multiply by 4
        LDRB W3, [X0], #2
        SUB W6, W3, #88   // Save this in W6 to calculate our score for Part 2
        LSL W3, W6, #2

        // [Part 2] Get move according to new strategy guide
        ADD W5, W3, W4, LSL #4
        LDR W5, [X2, W5, UXTW #0]

        // [Part 1] Get our score, add to score counter
        ADD W3, W3, W4, LSL #4
        LDR W3, [X1, W3, UXTW #0]
        ADD W8, W8, W3

        // [Part 2] Get our score, add to score counter
        // 3 * (Our character - 'X') + our move
        MOV W3, #3
        MADD W4, W6, W3, W5
        ADD W9, W9, W4

        B LoopInput
    
    LoopEnd:

    // Get format string
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    // Put scores on stack
    SUB SP, SP, #32
    STR W9, [SP, #8]
    STR W8, [SP, #0]

    BL _printf

    // Restore stack
    ADD SP, SP, #32

    // Restore link register, return
    LDR LR, [SP], #16
    RET

.data

TableScore:
    .word SCORE_DRAW + SCORE_ROCK     // A X
    .word SCORE_WIN  + SCORE_PAPER    // A Y
    .word SCORE_LOSS + SCORE_SCISSORS // A Z
    .word 0                           // For easier table access
    .word SCORE_LOSS + SCORE_ROCK     // B X
    .word SCORE_DRAW + SCORE_PAPER    // B Y
    .word SCORE_WIN  + SCORE_SCISSORS // B Z
    .word 0                           // For easier table access
    .word SCORE_WIN  + SCORE_ROCK     // C X
    .word SCORE_LOSS + SCORE_PAPER    // C Y
    .word SCORE_DRAW + SCORE_SCISSORS // C Z
    .align 4

TableMove:
    .word SCORE_SCISSORS // A X
    .word SCORE_ROCK     // A Y
    .word SCORE_PAPER    // A Z
    .word 0              // For easier table access
    .word SCORE_ROCK     // B X
    .word SCORE_PAPER    // B Y
    .word SCORE_SCISSORS // B Z
    .word 0              // For easier table access
    .word SCORE_PAPER    // C X
    .word SCORE_SCISSORS // C Y
    .word SCORE_ROCK     // C Z
    .align 4

StrFormat:
    .asciz "[Part 1] Our score is %u.\n[Part 2] Our score is %u.\n"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
