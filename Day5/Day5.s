//
// Advent of Code 2022 - Day 5
// Michelle-Marie Schiller
//

.global _main
.align 4

.equ STACK_ITEMS, 48
.equ STACK_ADDR_AREA, 9 * 8
.equ STACK_DATA_AREA, STACK_ITEMS * 9 * 8
.equ STACK_SIZE, STACK_ADDR_AREA + STACK_DATA_AREA

_main:
    // Save registers
    STP X21, LR, [SP, #-16]!
    STP X19, X20, [SP, #-16]!

    // Allocate memory to hold emulated stack pointers and stack data (X15 = pointer to memory)
    MOV X0, #STACK_SIZE * 2
    BL _malloc
    MOV X15, X0
    ADD X21, X0, #STACK_SIZE

    // Zero out all memory
    MOV X0, #STACK_SIZE * 2

    LoopClearMemory:
        SUBS X0, X0, #8
        STR XZR, [X15, X0]
        B.NE LoopClearMemory
    
    // Set "stack" pointers
    MOV X13, X15
    MOV X19, X21
    ADD X14, X15, #STACK_ADDR_AREA
    ADD X20, X21, #STACK_ADDR_AREA

    // Get pointer to input
    ADRP X0, TxtInput@PAGE
    ADD X0, X0, TxtInput@PAGEOFF

    // Set up registers for preprocessing
    MOV X1, #0     // Start with first stack
    MOV X2, #7     // Start from top of stack
    ADD X0, X0, #1 // Skip first open bracket

    // Preprocess the input (get initial stack state)
    LoopPreprocess:
        // Get next crate
        LDRB W3, [X0], #4

        // Check if crate is non-existent (whitespace character)
        CMP W3, #32
        B.EQ SkipWhitespace

        // Set stack entry
        UXTB X3, W3
        BL SetStack

        SkipWhitespace:

        // Increment X1 if lower than 8, else reset to 0
        CMP X1, #8
        CSINC X1, XZR, X1, HS

        // If X1 was lower than 8, we haven't finished processing the current line
        B.LO LoopPreprocess

        // If X2 is 0, we're done
        CBZ X2, LoopPreprocessEnd

        // Decrement X2, jump back to top
        SUB X2, X2, #1
        B LoopPreprocess
    
    LoopPreprocessEnd:

    // Copy first stack to second stack
    MOV X1, #STACK_SIZE

    LoopMemcpy:
        SUB X1, X1, #8
        LDR X2, [X15, X1]
        STR X2, [X21, X1]
        CBNZ X1, LoopMemcpy

    // Skip to first "move"
    ADD X0, X0, #36

    // Start processing the input
    LoopInput:
        // Get next character
        LDRB W3, [X0]

        // Is this the end of our input?
        CBZ W3, LoopEnd

        // Skip "move", get first number
        ADD X0, X0, #5
        BL StrToInt
        MOV X8, X3

        // Skip "from", get second number
        ADD X0, X0, #5
        BL StrToInt
        SUB X9, X3, #1

        // Skip "to", get third number
        ADD X0, X0, #3
        BL StrToInt
        SUB X10, X3, #1

        // [Part 2] Move stack data with CrateMover 9001
        MOV X1, X8
        MOV X2, X9
        MOV X3, X10
        BL MoveStack9001

        // [Part 1] Move stack data
        MOV X1, X8
        MOV X2, X9
        MOV X3, X10
        BL MoveStack

        B LoopInput

    LoopEnd:

    // Get format string
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF

    // Put crates on stack
    SUB SP, SP, #80
    MOV X1, #9
    MOV X13, X19
    MOV X14, X20

    LoopWriteMsg1:
        MOV X4, X1
        SUB X1, X1, #1
        BL GetStack
        STR X3, [SP, X4, LSL #3]
        CBNZ X1, LoopWriteMsg1
    
    MOV X1, #9
    SUB X13, X13, #STACK_SIZE
    SUB X14, X14, #STACK_SIZE
    SUB SP, SP, #64

    LoopWriteMsg2:
        SUB X1, X1, #1
        BL GetStack
        STR X3, [SP, X1, LSL #3]
        CBNZ X1, LoopWriteMsg2

    BL _printf

    // Restore stack
    ADD SP, SP, #144

    // Free allocated memory
    MOV X0, X15
    BL _free

    // Restore registers, return
    LDP X19, X20, [SP], #16
    LDP X21, LR, [SP], #16
    RET

// Returns the topmost stack entry
// X1 - Stack selector - 1
// Returns:
// X3 - Stack data
// Destroys:
// X2, X12
GetStack:
    // Get stack offset
    LDR X2, [X13, X1, LSL #3]
    SUB X2, X2, #1

    // Get stack address (STACK_ITEMS * 8 * X1 + 8 * X2), put stack data in X3
    MOV X12, #STACK_ITEMS * 8
    MADD X12, X12, X1, X14
    LDR X3, [X12, X2, LSL #3]

    RET

// Sets a stack entry, initializes stack offset
// X1 - Stack selector - 1
// X2 - Stack offset
// X3 - Data to push
// Destroys:
// X12
SetStack:
    // Set stack offset if old stack offset is 0
    LDR X12, [X13, X1, LSL #3]
    CMP X12, #0
    B.NE SkipOffset

    ADD X12, X2, #1
    STR X12, [X13, X1, LSL #3]

    SkipOffset:

    // Get stack address (STACK_ITEMS * 8 * X1 + 8 * X2), set stack data
    MOV X12, #STACK_ITEMS * 8
    MADD X12, X12, X1, X14
    STR X3, [X12, X2, LSL #3]

    RET

// Moves data from one stack to the other
// X1 - Number of moves
// X2 - First stack selector - 1
// X3 - Second stack selector - 2
// Destroys:
// X8, X9, X10, X11, X12
MoveStack:
    // Get stack offsets
    LDR X11, [X13, X2, LSL #3]
    LDR X12, [X13, X3, LSL #3]
        
    MOV X9, #STACK_ITEMS * 8

    LoopMove:
        SUB X1, X1, #1

        // Get data from first stack
        SUB X11, X11, #1
        MADD X10, X9, X2, X14
        LDR X8, [X10, X11, LSL #3]

        // Move data to second stack
        MADD X10, X9, X3, X14
        STR X8, [X10, X12, LSL #3]
        ADD X12, X12, #1

        CBNZ X1, LoopMove

    // Save new stack offsets
    STR X11, [X13, X2, LSL #3]
    STR X12, [X13, X3, LSL #3]

    RET

// Moves data from stack to the other while preserving order
// X1 - Number of moves
// X2 - First stack selector - 1
// X3 - Second stack selector - 1
MoveStack9001:
    // Get stack offsets
    LDR X11, [X19, X2, LSL #3]
    LDR X12, [X19, X3, LSL #3]

    // Get stack addresses
    SUB X6, X11, X1
    MOV X11, X6
    MOV X5, #STACK_ITEMS * 8
    MADD X4, X5, X2, X20
    MADD X5, X5, X3, X20

    LoopMove9001:
        SUB X1, X1, #1

        LDR X7, [X4, X11, LSL #3]
        ADD X11, X11, #1

        STR X7, [X5, X12, LSL #3]
        ADD X12, X12, #1

        CBNZ X1, LoopMove9001

    // Save new stack offsets
    STR X6, [X19, X2, LSL #3]
    STR X12, [X19, X3, LSL #3]

    RET


// Converts a text string (terminated by '-', ',' or '\n') to an integer
// X0 - Pointer to string
// Returns:
// X3 - Integer
// Destroys:
// X1, X2
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
    .asciz "[Part 1] The resulting message is %c%c%c%c%c%c%c%c%c.\n[Part 2] The resulting message is %c%c%c%c%c%c%c%c%c.\n"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
