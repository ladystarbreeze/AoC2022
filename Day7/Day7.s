//
// Advent of Code 2022 - Day 7
// Michelle-Marie Schiller
//

.global _main
.align 4

// Tree node structure:
//       Node name -  24 bytes
//       File size -   8 bytes
// Child node list - 128 bytes

.equ CHILD_NODES, 16

// Offsets to tree node members
.equ NODEOFF_NAME, 0
.equ NODEOFF_FILESIZE, 24
.equ NODEOFF_LIST, 32

// Sizes of tree node members
.equ NODE_NAME, 24
.equ NODE_FILESIZE, 8
.equ NODE_LIST, CHILD_NODES * 8

// Node size
.equ NODE_SIZE, NODE_NAME + NODE_FILESIZE + NODE_LIST

.equ TOTAL_DISK_SPACE, 70000000
.equ REQUIRED_UNUSED_SPACE, 30000000

// X19 - Pointer to input
// X20 - Root node
// X21 - Current node
// X22 - Scratch register/Part one answer
// X23 - Scratch register
_main:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STP X20, X21, [SP, #-16]!
    STP X22, X23, [SP, #-16]!
    STR X24, [SP, #-16]!

    // Get pointer to input
    ADRP X19, TxtInput@PAGE
    ADD X19, X19, TxtInput@PAGEOFF

    // Create root node
    ADRP X0, StrRoot@PAGE
    ADD X0, X0, StrRoot@PAGEOFF
    MOV X1, #0
    BL CreateNode

    // Save pointer to root node
    MOV X20, X0
    MOV X21, X0

    // Skip first cd command
    ADD X19, X19, #7

    // Start processing the input
    LoopInput:
        // Get next character
        LDRB W8, [X19, #2]

        // If character is '0', we're done
        CBZ W8, LoopEnd

        // Skip command string
        ADD X19, X19, #5

        // If character is 'l', this is an ls command
        CMP W8, #108
        B.NE SkipLs

        LoopHandleLs:
            // Get next character
            LDRB W8, [X19]

            // If character is '0', we're done
            CBZ W8, LoopEnd

            // If character is '$', get next command
            CMP W8, #36
            B.EQ LoopInput

            // If character is not 'd', this is a file
            CMP W8, #100
            B.NE SkipDir

            // This is a directory

            // Skip "dir ", save pointer to start of directory name
            ADD X19, X19, #4
            MOV X23, X19

            // Replace newline character with '\0'
            MOV X0, X19
            BL StrReplaceNewline
            MOV X19, X0

            // Find directory
            MOV X0, X21
            MOV X1, X23
            BL FindNode

            // Create directory if directory doesn't exist, else skip
            CBNZ X0, LoopHandleLs
            MOV X0, X21
            MOV X1, X23
            MOV X2, #0
            BL AddNode

            B LoopHandleLs

            SkipDir:

            // This is a file
            
            // Get file size
            MOV X0, X19
            BL _atoi
            MOV X23, X0

            MOV X0, X19
            BL StrSkipWhitespace
            MOV X19, X0
            MOV X22, X0

            // Replace newline character with '\0'
            MOV X0, X19
            BL StrReplaceNewline
            MOV X19, X0

            // Add file
            MOV X0, X21
            MOV X1, X22
            MOV X2, X23
            BL AddNode

            B LoopHandleLs

        SkipLs:

        // This is a cd command
        
        // Get next character
        LDRB W8, [X19]

        // If character is '.', return to previous node
        CMP W8, #46
        B.NE SkipReturnPrevious

        // Skip argument string, get previous node from stack
        ADD X19, X19, #3
        LDR X22, [SP], #16
        MOV X21, X22

        B LoopInput

        SkipReturnPrevious:

        // Push current node on stack
        STR X21, [SP, #-16]!

        // Save pointer to start of directory name
        MOV X23, X19

        // Replace newline character with '\0'
        MOV X0, X19
        BL StrReplaceNewline
        MOV X19, X0

        // Find child node, set new current node
        MOV X0, X21
        MOV X1, X23
        BL FindNode
        MOV X21, X0

        B LoopInput
    
    LoopEnd:

    // Restore stack pointer
    ADD SP, SP, #16

    MOV X22, #0

    // [Part 1] Find sum of directory sizes lower than or equal 100000
    MOV X0, X20
    BL FindDirSum
    MOV X24, X0

    // Get required disk space
    ADRP X0, DiskSpace@PAGE
    ADD X0, X0, DiskSpace@PAGEOFF
    LDR X23, [X0]

    // 70000000 - used space
    SUB X23, X23, X24

    // 30000000 - free space
    LDR X24, [X0, #8]
    SUB X23, X24, X23

    MOVN X24, #0

    // [Part 2] Find smallest sum that exceeds 30000000
    MOV X0, X20
    BL FindSmallestDirSum

    // Destroy all nodes
    MOV X0, X20
    BL DeleteTree

    // Print result
    ADRP X0, StrFormat@PAGE
    ADD X0, X0, StrFormat@PAGEOFF
    
    SUB SP, SP, #32
    STR X24, [SP, #8]
    STR X22, [SP, #0]

    BL _printf

    ADD SP, SP, #32

    // Restore registers, return
    LDR X24, [SP], #16
    LDP X22, X23, [SP], #16
    LDP X20, X21, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Traverses all child nodes, returns size of parent node
// X0 - Pointer to parent node
// Returns:
// X0 - Size of parent node
FindDirSum:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STP X20, X21, [SP, #-16]!

    ADD X19, X0, #NODEOFF_LIST
    LDR X20, [X0, #NODEOFF_FILESIZE]
    MOV X21, #0

    LoopFindDirSum:
        // Get next node
        LDR X0, [X19], #8
        CBZ X0, LoopFindDirSumEnd
        ADD X21, X21, #1

        // Get size of child node, add to result
        BL FindDirSum
        ADD X20, X20, X0

        B LoopFindDirSum
    
    LoopFindDirSumEnd:
    
    MOV X0, X20

    // This is a file!! Don't add value to directory sum
    CBZ X21, SkipAddSum

    // If sum is lower than or equal 100000, add sum to result
    MOV X21, #0x186
    LSL X21, X21, #8
    ADD X21, X21, #0xA0
    CMP X20, X21
    B.HI SkipAddSum

    ADD X22, X22, X20

    SkipAddSum:

    // Restore registers, return
    LDP X20, X21, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Too lazy for a description. Solves part two.
// X0 - Pointer to parent node
// Returns:
// X0 - Size of parent node
FindSmallestDirSum:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STP X20, X21, [SP, #-16]!

    ADD X19, X0, #NODEOFF_LIST
    LDR X20, [X0, #NODEOFF_FILESIZE]
    MOV X21, #0

    LoopFindSmallestDirSum:
        // Get next node
        LDR X0, [X19], #8
        CBZ X0, LoopFindSmallestDirSumEnd
        ADD X21, X21, #1

        // Get size of child node, add to result
        BL FindSmallestDirSum
        ADD X20, X20, X0

        B LoopFindSmallestDirSum
    
    LoopFindSmallestDirSumEnd:
    
    MOV X0, X20

    // This is a file!! Don't compare sum
    CBZ X21, SkipCompareSetSum

    // If sum is higher than or equal required disk space, compare sum with current smallest sum
    CMP X20, X23
    B.LO SkipCompareSetSum

    CMP X20, X24
    CSEL X24, X24, X20, HI

    SkipCompareSetSum:

    // Restore registers, return
    LDP X20, X21, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Creates a tree node
// X0 - Pointer to node name
// X1 - Node size
// Returns:
// X0 - Pointer to new node
CreateNode:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STR X20, [SP, #-16]!

    MOV X19, X0
    MOV X20, X1

    // Print text
    ADRP X0, StrFormatCreateNode@PAGE
    ADD X0, X0, StrFormatCreateNode@PAGEOFF

    SUB SP, SP, #32
    STR X20, [SP, #8]
    STR X19, [SP, #0]

    BL _printf

    ADD SP, SP, #32

    // Allocate tree node
    MOV X0, #NODE_SIZE
    BL _malloc

    // Initialize tree node

    // Clear node memory
    MOV X1, #NODE_SIZE

    LoopClearNode:
        SUB X1, X1, #8
        STR XZR, [X0, X1]
        CBNZ X1, LoopClearNode
    
    // Set node name
    LoopSetName:
        LDRB W2, [X19, X1]
        STRB W2, [X0, X1]
        CBZ W2, LoopSetNameEnd

        ADD X1, X1, #1
        B LoopSetName
    
    LoopSetNameEnd:

    // Set node size
    STR X20, [X0, #NODEOFF_FILESIZE]

    // Restore registers, return
    LDR X20, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Adds a tree node to an existing node
// X0 - Current parent node
// X1 - Pointer to child node name
// X2 - Child node size
// Returns:
// X0 - Pointer to new child node
AddNode:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STP X20, X21, [SP, #-16]!
    STR X22, [SP, #-16]!

    MOV X19, X0
    MOV X20, X1
    MOV X21, X2

    // Print text
    ADRP X0, StrFormatAddNode@PAGE
    ADD X0, X0, StrFormatAddNode@PAGEOFF

    SUB SP, SP, #32
    STR X19, [SP, #8]
    STR X20, [SP, #0]

    BL _printf

    ADD SP, SP, #32

    // Find next free node
    ADD X0, X19, #NODEOFF_LIST

    LoopFindFreeNode:
        LDR X1, [X0]
        CBZ X1, LoopFindFreeNodeEnd

        ADD X0, X0, #8
        B LoopFindFreeNode
    
    LoopFindFreeNodeEnd:
    
    MOV X22, X0

    // Create new child node
    MOV X0, X20
    MOV X1, X21
    BL CreateNode

    // Save pointer to child node
    STR X0, [X22]

    // Restore registers, return
    LDR X22, [SP], #16
    LDP X20, X21, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Finds child node by name
// X0 - Pointer to node
// X1 - Pointer to child node name
// Returns:
// X0 - Pointer to child node
FindNode:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STP X20, X21, [SP, #-16]!

    MOV X19, X0
    MOV X20, X1

    // Print text
    ADRP X0, StrFormatFindNode@PAGE
    ADD X0, X0, StrFormatFindNode@PAGEOFF

    STR X1, [SP, #-16]!

    BL _printf

    ADD SP, SP, #16

    // Find node
    ADD X19, X19, #NODEOFF_LIST

    LoopFindNode:
        LDR X0, [X19], #8
        CBZ X0, LoopFindNodeEnd

        // Save pointer to child node
        MOV X21, X0

        // Compare child node names
        MOV X1, X20
        BL _strcmp

        // If result is not 0, we're not done
        CBNZ X0, LoopFindNode

    MOV X0, X21

    LoopFindNodeEnd:

    // Restore registers, return
    LDP X20, X21, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Recursively deletes tree
// X0 - Pointer to root node
DeleteTree:
    // Save registers
    STP X19, LR, [SP, #-16]!
    STP X20, X21, [SP, #-16]!

    MOV X19, X0
    ADD X20, X0, #NODEOFF_LIST

    // Find and delete child nodes
    LoopFindAndDeleteChildNodes:
        LDR X21, [X20], #8
        CBZ X21, LoopFindAndDeleteChildNodesEnd

        // Delete child node
        MOV X0, X21
        BL DeleteTree

        B LoopFindAndDeleteChildNodes
    
    LoopFindAndDeleteChildNodesEnd:

    // Print text
    ADRP X0, StrFormatDeleteTree@PAGE
    ADD X0, X0, StrFormatDeleteTree@PAGEOFF

    STR X19, [SP, #-16]!

    BL _printf

    ADD SP, SP, #16

    // Delete node
    MOV X0, X19
    BL _free

    // Restore registers, return
    LDP X20, X21, [SP], #16
    LDP X19, LR, [SP], #16
    RET

// Advances string to the next line
// X0 - Pointer to string
StrSkipLine:
    LDRB W1, [X0], #1
    CMP W1, #10
    B.NE StrSkipLine

    RET

// Advances string to after the next whitespace character
// X0 - Pointer to string
StrSkipWhitespace:
    LDRB W1, [X0], #1
    CMP W1, #32
    B.NE StrSkipWhitespace

    RET

// Replaces newline character with null byte, advances string to the next line
// X0 - Pointer to string
StrReplaceNewline:
    LDRB W1, [X0], #1
    CMP W1, #10
    B.NE StrReplaceNewline

    MOV W1, #0
    STRB W1, [X0, #-1]

    RET

.data

DiskSpace:
    .dword TOTAL_DISK_SPACE
    .dword REQUIRED_UNUSED_SPACE

StrFormat:
    .asciz "[Part 1] The sum of total sizes of the directories is %llu.\n[Part 2] The smallest directory that frees up enough space is %llu bytes.\n"
    .align 4

StrFormatCreateNode:
    .asciz "Creating node %s, size %u.\n"
    .align 4

StrFormatAddNode:
    .asciz "Adding node %s to node %s.\n"
    .align 4

StrFormatFindNode:
    .asciz "Finding node %s.\n"
    .align 4

StrFormatDeleteTree:
    .asciz "Removing node %s.\n"
    .align 4

StrRoot:
    .asciz "/"
    .align 4

TxtInput:
    .include "input.txt"
    .align 4
