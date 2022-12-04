//
// Advent of Code 2022 - Day 4
// Michelle-Marie Schiller
//

.global _main
.align 4

_main:
    // Save link register
    STR LR, [SP, #-16]!

    // Get pointer to input
    ADRP X0, TxtInput@PAGE
    ADD X0, X0, TxtInput@PAGEOFF

    // Reset pair counters
    MOV X8, #0
    MOV X9, #0

    // Start processing the input
    LoopInput:
        // Get next character
        LDRB W3, [X0]

        // Is this the end of our input?
        CBZ W3, LoopEnd

        // Convert the next two ranges into numbers
        // First range
        BL StrToInt
        MOV X4, X3
        BL StrToInt
        MOV X5, X3

        // Second range
        BL StrToInt
        MOV X6, X3
        BL StrToInt
        MOV X7, X3

        MOV X10, X6
        MOV X11, X7

        // Find bigger range, sort ranges
        SUB X2, X7, X6
        SUB X3, X5, X4
        CMP X2, X3
        CSEL X7, X5, X7, LO
        CSEL X6, X4, X6, LO
        CSEL X5, X11, X5, LO
        CSEL X4, X10, X4, LO

        // [Part 1] Check if bigger range fully includes smaller range
        // Go to part 2 if start of smaller range is lower than end of bigger range 
        CMP X4, X6
        B.LO SkipPart1

        // Increment pair counter if end of smaller range is lower than or same as end of bigger range
        CMP X5, X7
        CINC X8, X8, LS

        SkipPart1:
        
        // [Part 2] Check if ranges overlap
        // Get new ranges if end of smaller range is lower than start of bigger range
        CMP X5, X6
        B.LO LoopInput

        // Increment pair counter if start of smaller range is lower than or same as end of bigger range
        CMP X4, X7
        CINC X9, X9, LS

        B LoopInput

    LoopEnd:

    // Get format string
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    // Put printf arguments on stack
    SUB SP, SP, #32
    STR X9, [SP, #8]
    STR X8, [SP, #0]

    BL _printf

    // Restore stack
    ADD SP, SP, #32

    // Restore link register, return
    LDR LR, [SP], #16
    RET

// Converts a text string (terminated by '-', ',' or '\n') to an integer
// X0 - Pointer to string
// Returns:
// X3 - Integer
// NOTE: We can be extra lazy because the input is either 1- or 2-character strings
StrToInt:
    // Save pointer to beginning of string, increment string pointer
    MOV X1, X0
    ADD X0, X0, #1

    // Find length of string (as offset to the last character)
    // If the second character is another number, set offset to 1, increment string pointer
    LDRB W3, [X0], #1
    CMP W3, #48       // Lazy, but this works for our input
    CINC X2, XZR, HS
    CINC X0, X0, HS

    // Build number (char - '0')
    LDRB W3, [X1, X2]
    SUB W3, W3, #48

    // If the string has a length of 1, we're done
    CBZ X2, ReturnStrToInt

    // Get last (= first in string) digit, multiply by 10, add to previous digit
    LDRB W2, [X1]
    MOV W1, #10
    SUB W2, W2, #48
    MADD W3, W1, W2, W3

    ReturnStrToInt:

    UXTB X3, W3
    RET

.data

StrFormat:
    .asciz "[Part 1] %llu pairs fully overlap.\n%llu pairs partially overlap.\n"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
