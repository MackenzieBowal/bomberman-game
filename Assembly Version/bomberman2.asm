/* 
 * This file contains the functions displayGame and bomb. DisplayGame prints the table
 * and relevant information each turn, and bomb updates the arrays and structs each turn.
 */

.text				
numArgsErrorMsg:        .string "Please enter your name and two integers through the command line.\n"    		// Constant strings for scanning and printing  
invalidRangeMsg:	.string "The dimensions must be at least 10x10.\n"
printChar:		.string "%-9c "
printFP:		.string "%-9.2f "
newline:		.string "\n"
uncoveredTable:		.string "\nHere is the uncovered table: \n"
negRatio:		.string "Negative numbers %d/%d = %.2f\%\n"
posRatio:		.string "Positive numbers %d/%d = %.2f\%\n"
specialRatio:		.string "Special tiles %d/%d = %.2f\%\n"
contPrompt:		.string "Enter 1 to continue playing, or 2 to quit: "
bombPrompt:		.string "Enter bomb position (x y): "
invalidCoorMsg:		.string "Those were not valid coordinates. Enter bomb position: "
scanCoor:		.string "%d %d"
scanInt:		.string "%d"
scanStr:		.string "%s"
scanFloat:		.string "%lf"
doublesMsg:		.string "\nBang!! Your bomb range is doubled.\n"
uScoreMsg:		.string "\nYour bomb just scored %.2f points.\n"
printX:			.string "X "
asterisk:		.string "* "
dollarSign:		.string "$ "
minus:			.string "- "
plus:			.string "+ "
turnInfoMsg:		.string "Lives: %d\nScore: %.2f\nBombs: %d\n"
noLivesMsg:		.string "Oops! You ran out of lives.\n\n"
noBombsMsg:		.string "Oops! You ran out of bombs.\n\n"
endTileMsg:		.string "Congratulations! You found the exit tile.\n\n"
logFileName:		.string "logFile.txt"
appendMode:		.string "a"
logFileString:		.string "%s %f %d\n"
seeSBPrompt:		.string "Enter 1 to see the scoreboard, or 2 to quit: "
seeSBPromptFirst:	.string "Enter 1 to see the scoreboard, or 2 to start playing: "
readMode:		.string "r"
invalidNumScoresMsg:	.string "That is not a valid number of scores. Please try again: "
numScoresPrompt:	.string "How many scores would you like to view? "
tooManyScoresMsg:	.string "There aren't that many scores yet! Please try again: "
scoreBoardTitle:	.string "\n_______________Scoreboard_______________\n"
printScore:		.string "#%d: %s\n\tScore: %.2f\n\tDuration: %d seconds\n"
firstTimePlayedMsg:	.string "It looks like you are the first player!\n"
afterScoreBoard:	.string "________________________________________\n\n"


fp .req x29                     // Register equate for the frame pointer
lr .req x30                     // Register equate for the link register


define(argc_r, w19)		// Macros for the whole program
define(argv_r, x20)       
define(rows, w21)       
define(cols, w19)             
define(alloc_r, w27)
define(name_r, x24)
define(numElements, w22)
define(table_base, x23)
define(revealedTiles_base, x26)
define(element_offset, w25)
define(tableElement, d12)
define(gameInfo, x24)
define(cont, w25)
define(turnScore, d13)
define(bombRow, w22)
define(bombCol, w28)
define(score, d14)
define(bombs, w19)
define(hitEndTile, w19)
define(startTime, x9)
define(endTime, x10)
define(totalTime, x11)

// macros for initializeGame()
define(i_r, w22)
define(numTableElements, w20)
define(exitTile, d8)
define(specialTile, d9)
define(numNegAndPos, w24)
define(numSpecials, w27)
define(f_num, d10)
define(checkElement, d11)
define(emptySpot, d13)
define(elementRatio, d14)

// macros for randInt() & randomNum()
define(randNum, w19)
define(maxRange, w20)
define(minRange, w22)
define(neg, w21)
define(f_randNum, d17)

// macros for displayGame()
define(j_r, w27)

// macros for bomb()
define(tileCol, w20)
define(tileRow, w27)
define(revealed, w19)
define(offset, w15)
define(size, w25)
define(numD, w13)
define(counter, w14)
define(halfSize, w12)
define(lastCol, w10)
define(bottomRow, w11)

bombAlloc = -(16+8*10) & -16		// Equates for memory allocation
bombDealloc = -bombAlloc
dispAlloc = -(16+8*10) & -16
dispDealloc = -dispAlloc                                                                                                                   

.balign 4               	// Ensures instructions are properly aligned
.global displayGame             // Makes the functions "bomb" and "displayGame" visible to the linker
.global bomb




//---------------------------------------

/**
 * bomb
 * Executes the action of "placing a bomb" on the board. The range is determined by the number of double-range tiles
 * that were revealed in the previous turn. The revealed tiles are updated, and if double-range tiles were revealed, they
 * are counted for the next bomb.
 * Parameters:
 * 	table_base is the base address of the table array, populated with floats
 * 	revealedTiles_base is the base address of the revealedTiles array, which contains 1 (revealed) or 0 (not revealed)
 *		corresponding to each entry of the table
 *	gameInfo is the base address of the game information struct
 * 	bombRow is the row specified by the user to bomb
 * 	bombCol is the columns specified by the user to bomb
 *
 * Returns:
 * 	The current turn's score, which is only calculated from tiles that have not previously been revealed.
 */

bomb:
	stp fp, lr, [sp, bombAlloc]!
	mov fp, sp
						// Stores registers
	stp x19, x20, [fp, 16]
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

	mov table_base, x0			// Gets parameters
	mov revealedTiles_base, x1
	mov gameInfo, x2
	mov bombRow, w3
	mov bombCol, w4

	mov size, 3				// Finds the side length of the square to be bombed
	mov counter, 0				// depending on the number of double-range tiles
	ldr numD, [gameInfo, 36]		// uncovered in the previous bomb
	mov w9, 2
	mov w10, -1
	b sizeLoopTest

sizeLoop:					// Increases the size of the square by 2n - 1, where
	madd size, w9, size, w10		// n is the previous size of the square
	
sizeLoopTest:					// Increases the square size according to the number
	add counter, counter, 1			// of double-range bombs uncovered last
	cmp counter, numD
	b.le sizeLoop

bombing:				
	str wzr, [gameInfo, 36]			// Updates the number of doubles section to 0
	mov w19, 0
	scvtf turnScore, w19
	lsr halfSize, size, 1			// Calculates the radius of the bomb range
	sub tileRow, bombRow, halfSize
	cmp tileRow, 0
	b.lt updateTileRow			// Checks if the topmost row to bomb is less than zero
	b afterTileRow

updateTileRow:					// If it is less than zero, changes it to zero
	mov tileRow, 0

afterTileRow:					// Calculates the bottommost row in the range and checks
	add bottomRow, bombRow, halfSize	// if it is greater than the number of rows
	cmp bottomRow, rows
	b.ge updateBottomRow
	b columns

updateBottomRow:				// If it is greater than the number of rows, changes it to
	sub bottomRow, rows, 1			// the last row

columns:
	add lastCol, bombCol, halfSize		// Checks if the rightmost column in the bomb range is greater
	ldr cols, [gameInfo, 32]		// than the number of columns
	cmp lastCol, cols
	b.ge updateLastCol
	b rowLoop

updateLastCol:					// If it is greater than the number of columns, changes it to
	sub lastCol, cols, 1			// the last column

rowLoop:
	ldr rows, [gameInfo, 28]		// If the row we are on is greater than the number of rows,
	cmp tileRow, rows			// breaks the loop
	b.ge afterBomb
	cmp tileRow, 0				// If the row we are on is less than zero, moves on to the next row
	b.lt rowLoopTest

	sub tileCol, bombCol, halfSize
	cmp tileCol, 0				// Checks if the current column is less than zero
	b.lt updateTileCol
	b colLoop
updateTileCol:
	mov tileCol, 0				// Changes the column to zero if it is less than zero

colLoop:					
	ldr cols, [gameInfo, 32]		// Checks if the current column is greater than the number of columns
	cmp tileCol, cols
	b.ge rowLoopTest
	cmp tileCol, 0				// Checks if the current column is less than zero
	b.lt colLoopTest

	madd offset, tileRow, cols, tileCol			// Checks if the current tile has already been uncovered
	ldrb revealed, [revealedTiles_base, offset, SXTW]
	cmp revealed, 0
	b.eq bombTile
	b colLoopTest

bombTile:							// If it hasn't yet been uncovered, uncovers the tile and 
	mov revealed, 1						// updates the corresponding revealedTiles entry
	strb revealed, [revealedTiles_base, offset, SXTW]
	lsl offset, offset, 3
	ldr tableElement, [table_base, offset, SXTW]
	fmov d15, 15.5
	fcmp tableElement, d15
	b.eq foundExitTile
	fmov d15, 16.0
	fcmp tableElement, d15
	b.eq foundDoubleTile
	b foundNormalTile

foundExitTile:						// Changes the "hitEndTile" boolean to true
	mov w19, 1
	str w19, [gameInfo, 40]
	b colLoopTest

foundDoubleTile:
	ldr w19, [gameInfo, 36]				// Increments the number of doubles in gameInfo for this turn
	add w19, w19, 1
	str w19, [gameInfo, 36]
	b colLoopTest

foundNormalTile:					// Updates the turn score if the tile is a normal tile
	fadd turnScore, turnScore, tableElement
	b colLoopTest

colLoopTest:						// Iterates through columns until the bomb range limit is reached
	cmp tileCol, lastCol				// for that row
	add tileCol, tileCol, 1
	b.ge rowLoopTest
	b colLoop

rowLoopTest:						// Iterates through rows until the bomb range limit is reached
	add tileRow, tileRow, 1
	cmp tileRow, bottomRow
	b.le rowLoop

afterBomb:
	fmov d0, turnScore				// Returns the score uncovered by the current bomb

							// Restores registers
	ldp x19, x20, [fp, 16]
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], bombDealloc
	ret


//---------------------------------------


/**
 * displayGame
 * Prints the board to the console. All non-revealed tiles are displayed as 'X's, while revealed
 * negative tiles are '-', revealed positives are '+', and the revealed special tiles are either '$' or '*'.
 * Information about current lives, score, and bombs is also printed.
 * Parameters:
 * 	table_base is the base address of the game board
 * 	revealedTiles_base is the base address of the revealed tiles array, corresponding to entries in the table
 * 	gameInfo is a base address of the struct containing relevant game information
 * 	turnScore is the score revealed by the current bomb
 */

displayGame:

	stp fp, lr, [sp, dispAlloc]!
	mov fp, sp
						// Stores registers
	stp x19, x20, [fp, 16]
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

	mov table_base, x0			// Gets parameters
	mov revealedTiles_base, x1
	mov gameInfo, x2
	fmov turnScore, d0

	mov w20, w3
	mov i_r, 0				// Prepares registers for printing loops
	mov j_r, 0

	ldr w19, [gameInfo, 40]			// Checks if this bomb hit any double-range tiles
	cmp w19, 0
	b.gt printDoubles
	b printBoard

	ldr cols, [gameInfo, 32]

printDoubles:					// If the bomb hit double-range tiles, prints the appropriate message
	ldr x0, =doublesMsg
	bl printf

printBoard:					// Prints the initial display messages
	cmp w20, 10
	b.eq printRow

	ldr x0, =uScoreMsg
	fmov d0, turnScore
	bl printf

printRow:					// Iterates through each row, printing the table elements
	mov j_r, 0
	
printCol:					// Iterates through each column, printing each element
	madd element_offset, i_r, cols, j_r
	ldrb revealed, [revealedTiles_base, element_offset, SXTW]
	cmp revealed, 0							// Checks if the tile is revealed or not
	b.eq printUnrevealed
	b.ne printRevealed

printUnrevealed:				// Prints an 'X' for a covered tile
	ldr x0, =printX
	bl printf
	b printColTest

printRevealed:							// Prints the character corresponding to the tile
	lsl element_offset, element_offset, 3
	ldr tableElement, [table_base, element_offset, SXTW]
	fmov d13, 15.5
	fcmp tableElement, d13
	b.eq printExitTile
	fmov d13, 16.0
	fcmp tableElement, d13
	b.eq printDoubleTile
	b printNormalTile

printExitTile:					// Prints the exit tile character: '*'
	ldr x0, =asterisk
	bl printf
	b printColTest
	
printDoubleTile:				// Prints the double tile character: '$'
	ldr x0, =dollarSign
	bl printf
	b printColTest

printNormalTile:				// Checks if the float is positive or negative
	fcmp tableElement, 0.00
	b.gt printPlus
	b.lt printMinus

printPlus:					// Prints a '+' for a positive float
	ldr x0, =plus
	bl printf
	b printColTest
printMinus:					// Prints a '-' for a negative float
	ldr x0, =minus
	bl printf
	b printColTest

printColTest:					// Prints each element in the row until the row is done
	add j_r, j_r, 1
	ldr cols, [gameInfo, 32]
	cmp j_r, cols
	b.lt printCol
	
	add i_r, i_r, 1

printRowTest:					// Prints a new line after each row and continues until 
	ldr x0, =newline			// the table is printed
	bl printf
	cmp i_r, rows
	b.lt printRow


	ldr x0, =turnInfoMsg			// Prints the lives, score, and bomb information
	ldr w1, [gameInfo]
	ldr d0, [gameInfo, 8]
	ldr w2, [gameInfo, 4]
	bl printf

						// Restores registers
	ldp x19, x20, [fp, 16]
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], dispDealloc
	ret


//---------------------------------------

