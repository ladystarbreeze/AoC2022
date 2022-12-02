//
// Advent of Code 2022 - Day 1
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

    // Reset calorie counters (temporary and final)
    MOV X7, #0
    MOV X8, #0
    MOV X9, #0
    MOV X10, #0 // 10

    // Start processing the input
    LoopInput:
        // Get new character
        LDRB W3, [X0], #1

        // Is this the end of our input?
        CBZ W3, LoopEnd

        // Do we go to the next Elf? (check for newline)
        CMP W3, #10
        B.NE GetNumber

        // Select new highest calorie counters

        // Is X7 the new highest calorie count?
        CMP X7, X8
        CSEL X10, X10, X9, LS
        CSEL X9, X9, X8, LS
        CSEL X8, X8, X7, LS

        B.HI ResetCounter // 20

        // Is X7 the new second highest calorie count?
        CMP X7, X9
        CSEL X10, X10, X9, LS
        CSEL X9, X9, X7, LS

        B.HI ResetCounter
        
        // Is X7 the new third highest calorie count?
        CMP X7, X10
        CSEL X10, X10, X7, LS
            
        ResetCounter:
            // Reset temporary calorie counter
            MOV X7, #0

        // Go to next Elf
        B LoopInput
    
    // Convert line to number
    GetNumber: // 30
        // Save pointer to start of line
        SUB X1, X0, #1

        // Find last digit (character before newline)
        LoopFindEOL:
            LDRB W3, [X0], #1
            CMP W3, #10
            B.NE LoopFindEOL

            SUB X2, X0, #1
        
        // Build a number from the digits (base 10)
        MOV X4, #0
        MOV X5, #1

        LoopBuildNumber:
            // Get least significant digit, subtract by value of character '0'
            LDRB W3, [X2, #-1]! // 40
            UXTB X3, W3
            SUB X3, X3, #48

            // Multiply by current position, add to result
            MADD X4, X3, X5, X4

            // Check if we are done
            CMP X1, X2
            B.EQ AddToCounter

            // Multiply current position by 10
            MOV X3, #10
            MUL X5, X5, X3
            B LoopBuildNumber
        
        AddToCounter:
            ADD X7, X7, X4 // 50
            B LoopInput
    
    LoopEnd:

    // Get format string
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    // Calculate sum of three highest numbers
    ADD X10, X10, X9
    ADD X10, X10, X8

    // Put calories on the stack
    SUB SP, SP, #32
    STR X10, [SP, #8]
    STR X8, [SP, #0]

    // Call printf
    BL _printf // 60

    // Restore stack
    ADD SP, SP, #32

    // Restore LR, return
    LDR LR, [SP], #16
    RET

.data

StrFormat:
    .asciz "The Elf is carrying %llu calories.\nThe top three Elves are carrying %llu calories.\n"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
