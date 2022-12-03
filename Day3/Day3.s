//
// Advent of Code 2022 - Day 3
// Michelle-Marie Schiller
//

.global _main
.align 4

_main:
    // Save registers
    STP X21, LR, [SP, #-16]!
    STP X19, X20, [SP, #-16]!

    // Get pointer to input
    ADRP X0, TxtInput@PAGE
    ADD X0, X0, TxtInput@PAGEOFF

    // Reset compartment and sum registers
    MOV X6, #0
    MOV X7, #0
    MOV X8, #0
    MOV X9, #0

    // Offsets to convert ASCII values to priorities
    MOV X10, #96
    MOV X11, #38

    // Group counter
    MOV X15, #3

    // Start processing the input
    LoopInput:
        // Get next character
        LDRB W3, [X0]

        // Is this the end of our input?
        CBZ W3, LoopEnd

        // Save pointer to the first compartment
        MOV X1, X0

        // Find end of line (newline character) to get the size of the rucksack
        LoopFindEOL:
            LDRB W3, [X0], #1
            CMP W3, #10
            B.NE LoopFindEOL
        
        // Get compartment size ((X0 - X1 - 1) / 2)
        SUB X4, X0, X1
        SUB X4, X4, #1
        LSR X4, X4, #1

        // Get pointer to the second compartment
        ADD X2, X1, X4

        // Start scanning the compartments for items
        LoopFindItems:
            // Decrement compartment counter
            SUB X4, X4, #1

            // Get item from each compartment
            LDRB W3, [X1, X4]
            UXTB X3, W3

            LDRB W5, [X2, X4]
            UXTB X5, W5

            // Convert item to priority
            // priority = if (char >= 'a') char - 96 else char - 38
            CMP X3, #97
            CSEL X12, X10, X11, HS
            SUB X3, X3, X12

            CMP X5, #97
            CSEL X13, X10, X11, HS
            SUB X5, X5, X13

            // Mark items as present
            MOV X14, #1
            LSL X14, X14, X3
            ORR X6, X6, X14

            MOV X14, #1
            LSL X14, X14, X5
            ORR X7, X7, X14

            // Check for end of rucksack
            CBNZ X4, LoopFindItems
        
        // [Part 2] OR X6 and X7, decrement group counter, write group registers
        ORR X3, X6, X7
        SUB X15, X15, #1

        CMP X15, #2
        CSEL X19, X3, X19, EQ

        CMP X15, #1
        CSEL X20, X3, X20, EQ

        CMP X15, #0
        CSEL X21, X3, X21, EQ

        // If group counter is 0, find item that appears in all three rucksacks
        B.NE SkipPart2

        // Reset group counter
        MOV X15, #3

        // AND X19, X20 and X21 to get the item that appears in all three rucksacks
        AND X19, X19, X20
        AND X19, X19, X21
        
        // Get item priority, add to sum
        RBIT X19, X19
        CLZ X19, X19
        ADD X9, X9, X19

        SkipPart2:

        // [Part 1] AND X6 and X7 to get the item that appears in both compartments
        AND X6, X6, X7

        // Get item priority, add to sum
        RBIT X6, X6
        CLZ X6, X6
        ADD X8, X8, X6

        // Reset compartment registers
        MOV X6, #0
        MOV X7, #0

        B LoopInput

    LoopEnd:

    // Get format string
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    // Put sums on stack
    SUB SP, SP, #32
    STR X9, [SP, #8]
    STR X8, [SP, #0]

    BL _printf

    // Restore stack
    ADD SP, SP, #32

    // Restore registers, return
    LDP X19, X20, [SP], #16
    LDP X21, LR, [SP], #16
    RET

.data

StrFormat:
    .asciz "[Part 1] The sum of priorities is %llu.\n[Part 2] The sum of priorities is %llu.\n"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
