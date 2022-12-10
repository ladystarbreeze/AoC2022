//
// Advent of Code 2022 - Day 10
// Michelle-Marie Schiller
//

.global _main
.align 4

// X19 - Pointer to input
// X20 - X register
// X21 - Sum of signal strengths
// X22 - Current cycle
// X23 - Remaining instruction cycles
// X24 - ADDX operand
_main:
    // Save registers
    STR LR, [SP, #-16]!
    STP X19, X20, [SP, #-16]!
    STP X21, X22, [SP, #-16]!
    STP X23, X24, [SP, #-16]!
    STR X25, [SP, #-16]!

    // Get pointer to input
    ADRP X19, TxtInput@PAGE
    ADD X19, X19, TxtInput@PAGEOFF

    // Initialize registers
    MOV X20, #1
    MOV X21, #0
    MOV X22, #1
    MOV X23, #0
    MOV X24, #0

    // Start processing the input
    LoopInput:

        // Get next instruction if current instruction has finished executing
        CBNZ X23, CheckSum

        // Get next character
        LDRB W8, [X19], #5

        // If character is '0', we're done
        CBZ W8, LoopEnd

        // If character is 'n', this is a No Operation
        CMP W8, #110
        B.EQ CheckSum

        // This is an ADDX instruction

        // Set instruction cycle count
        MOV X23, #2

        // Get ADDX operand
        MOV X0, X19
        BL _atoi
        SXTW X24, W0

        SkipToNextLine:
            LDRB W8, [X19], #1
            CMP W8, #10
            B.NE SkipToNextLine

        CheckSum:
            // If (X22 % 40) - 20 is 0, add (current cycle * X register) to sum
            MOV X0, #40
            UDIV X25, X22, X0
            MSUB X25, X25, X0, X22
            CMP X25, #20
            B.NE CheckHandleAddx

            MADD X21, X22, X20, X21

        CheckHandleAddx:
            // Increment current cycle, loop back if instruction cycle is 0 (not an ADDX)
            CBZ X23, DrawCrt

            // Decrement instruction cycle count, loop back if not 0
            SUBS X23, X23, #1
            B.NE DrawCrt

            // Add ADDX operand to X register
            ADD X20, X20, X24
        
        DrawCrt:
            ADD X22, X22, #1

            MOV X8, #46

            // Get pixel to draw
            SUB X0, X20, #1
            CMP X25, X20
            B.LO DrawChar

            ADD X0, X20, #1
            CMP X25, X0
            B.HI DrawChar

            MOV X8, #35

            DrawChar:

            ADRP X0, StrChar@PAGE
            ADD X0, X0, StrChar@PAGEOFF

            STR X8, [SP, #-16]!

            BL _printf

            ADD SP, SP, #16

            // Draw newline if (current cycle % 40) == 0
            CMP X25, #0
            B.NE LoopInput

            MOV X8, #10

            ADRP X0, StrChar@PAGE
            ADD X0, X0, StrChar@PAGEOFF

            STR X8, [SP, #-16]!

            BL _printf

            ADD SP, SP, #16
        
            B LoopInput

    LoopEnd:

    // Print out sum of signal strengths
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    STR X21, [SP, #-16]!

    BL _printf

    ADD SP, SP, #16

    // Restore registers, return
    LDR X25, [SP], #16
    LDP X23, X24, [SP], #16
    LDP X21, X22, [SP], #16
    LDP X19, X20, [SP], #16
    LDR LR, [SP], #16
    RET

StrFormat:
    .asciz "[Part 1] The sum of all signal strengths is %llu.\n"
    .align 4

StrChar:
    .asciz "%c"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
