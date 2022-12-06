//
// Advent of Code 2022 - Day 6
// Michelle-Marie Schiller
//

.global _main
.align 4

_main:
    // Save link register
    STR LR, [SP, #-16]!

    // Get pointer to input
    ADRP X15, TxtInput@PAGE
    ADD X15, X15, TxtInput@PAGEOFF

    // [Part 1] Find SOP marker of size 4
    MOV X0, X15
    MOV X1, #4
    BL FindMarker
    MOV X8, X1

    // [Part 2] Find SOP marker of size 14
    MOV X0, X15
    MOV X1, #14
    BL FindMarker
    MOV X9, X1

    // Get format string
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    // Put positions on stack
    SUB SP, SP, #32
    STR X9, [SP, #8]
    STR X8, [SP, #0]

    BL _printf

    // Restore stack
    ADD SP, SP, #32

    // Restore link register, return
    LDR LR, [SP], #16
    RET

// Returns position after start-of-packet marker of size n
// X0 - Pointer to input
// X1 - Marker size
// Returns:
// X1 - Position of end of SOP marker
// Destroys:
// X2, X3, X4, X5, X6
FindMarker:
    MOV X2, X0
    MOV X3, X1
    MOV X4, #0

    LoopFind:
        // Decrement length counter
        SUB X3, X3, #1

        // Load string byte
        LDRB W5, [X0], #1
        UXTB X5, W5

        // Subtract with 'a' to get bit index
        SUB X5, X5, #97

        // OR X4 with (1 << X5)
        MOV X6, #1
        LSL X6, X6, X5
        ORR X4, X4, X6

        // Loop back if we're not done yet
        CBNZ X3, LoopFind

        // Calculate population count
        FMOV D0, X4
        CNT V0.8B, V0.8B
        ADDV B0, V0.8B
        FMOV X4, D0

        // If population count == marker size, we're done
        CMP X4, X1
        B.EQ LoopFindEnd

        // Reset length counter, clear X4, subtract (X1 - 1) from input pointer
        MOV X3, X1
        MOV X4, #0
        SUB X0, X0, X1
        ADD X0, X0, #1

        B LoopFind

    LoopFindEnd:

    // Get result
    SUB X1, X0, X2
    RET

StrFormat:
    .asciz "[Part 1] The marker has been detected after %llu characters.\n[Part 2] The marker has been detected after %llu characters.\n"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
