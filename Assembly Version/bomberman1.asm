/*
Whew ... this project was a doozy. I split the code into 2 files to manage 
the length.


 * This program is a modified version of the "bomberman" game. The user
 * enters their name and two integers (≥10) on the command line. These
 * integers are used as the dimensions for the board, which consists of 
 * 40% negative tiles, 40% positive tiles, and 20% special tiles, with one
 * exit tile. 
 * Before and after the game, the user is given the option to see the scoreboard.
 * If they choose to see it, they are prompted for how many top scores they
 * would like to see. The file containing the scores of previous games is
 * read, and the information is stored in an array which is then sorted and
 * the specified number of top scores is printed to the console. If the user
 * views the scoreboard at the end of the game, their game is included in the 
 * scoreboard.
 * Each game begins with 3 lives and a variable number of bombs. When the game 
 * starts, the user is prompted to continue playing or quit, then 
 * enter coordinates for the bomb if they continue. A bomb is then placed on
 * that tile, revealing all the tiles with a radius of one around the specified
 * tile. The scores of the non-special revealed tiles are added up, and if the sum
 * is negative, the player loses a life and the score is zeroed. Then the user is 
 * prompted to continue or quit again, and the game keeps going until the exit
 * tile is found, the user quits, or there are no more lives or bombs. Special
 * tiles are denoted by "$", and each special tile uncovered doubles the range of
 * the next bomb. If n $'s are uncovered, the next bomb's range will be 2^n.
 * The game is timed and the time is logged to the scoreboard file, along with
 * the player's name and score.
 * 
 * Note that the maximum dimensions that fit on my full sized screen is 55 rows x 115 columns
 * when covered, and 50 rows x 20 columns when uncovered.
 */


.data
continue:	.dword 0
bombR:		.word 0
bombC:		.word 0
seeSB:		.word 0
numScoresAns:	.word 0

.text														// Constant strings for scanning and printing
numArgsErrorMsg:        .string "Please enter your name and two integers through the command line.\n"      
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


define(argc_r, w19)			// Macros for the whole program
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

					// macros for bomb()
define(revealed, w19)
define(offset, w15)
define(counter, w14)

					// macros for displayTopScores()
define(scoreBoard_base, x22)
define(numPlayers, w24)
define(readFile, x25)
define(scoreBoard_offset, w26)
define(swap, w27)
define(sortCounter, w21)
define(this_score, d11)
define(next_score, d12)
define(name1, x19)
define(name2, x20)
define(duration1, w19)
define(duration2, w20)
define(numScores, w23)

					// macros for logScore()
define(logFile, x25)
define(playerName, x19)
define(duration, x20)
define(firstTimePlayed, w21)

					// Equates for memory allocation
mainAlloc = -(16+12) & -16
mainDealloc = -mainAlloc
gameInfoAlloc = -160
gameInfoDealloc = -gameInfoAlloc
initAlloc = -(16+8*10) & -16
initDealloc = -initAlloc
randIntAlloc = -(16+16) & -16
randIntDealloc = -randIntAlloc
randNumAlloc = -(16+8*3) & -16
randNumDealloc = -randNumAlloc
calcScoreAlloc = -(16+8*10) & -16
calcScoreDealloc = -calcScoreAlloc
exitGameAlloc = -(16+8*10) & -16
exitGameDealloc = -exitGameAlloc
logScoreAlloc = -(16+8*10) & -16
logScoreDealloc = -logScoreAlloc
viewSBAlloc = -(16 + 8*10 + 400) & -16
viewSBDealloc = -viewSBAlloc
AT_FDCWD = -100
                                                                                                                                           

.balign 4               // Ensures instructions are properly aligned
.global main            // Makes the label "main" visible to the linker


//---------------------------------------


/**
 * initializeGame
 * Populates the board for the game, which is a 2D float array with dimensions specified by
 * the user in the command line. 40% of the tiles are positive, 40% are negative, 1 is the exit tile,
 * and approximately 20% are double-range tiles.
 * Parameters:
 * 	table_base is the address of the initially empty 2D array, which is populated with tiles in this function
 */


initializeGame:
	stp fp, lr, [sp, initAlloc]!
	mov fp, sp

						// Stores registers
	stp x19, x20, [fp, 16]
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

	mov table_base, x0			// Gets parameters
	mov rows, w1
	mov cols, w2
	mov revealedTiles_base, x3


	mov i_r, 0				// Prepares registers for future use in loops
	mul numTableElements, rows, cols

	
	mov x0, 0				// Seeds the rand function
	bl time
	bl srand
	
	b fillBlankLoopTest

						// Fills each entry of the table with 17.0, and puts 0's in
						// the corresponding revealedTiles array
fillBlankLoop:
	fmov emptySpot, 17.0
	mov element_offset, i_r
	strb wzr, [revealedTiles_base, element_offset, SXTW]
	lsl element_offset, i_r, 3
	str emptySpot, [table_base, element_offset, SXTW]
	add i_r, i_r, 1

fillBlankLoopTest:				// Stops filling the arrays once they are complete 
	cmp i_r, numTableElements
	b.lt fillBlankLoop
	b makeExitTile


makeExitTile:					// Generates a random integer as an index for the exit tile
	mov w0, numTableElements
	bl randInt
	mov element_offset, w0

	lsl element_offset, element_offset, 3	// Puts the exit tile in the randomly generated index
	fmov exitTile, 15.5
	str exitTile, [table_base, element_offset, SXTW]

calculateProportions:				// Calculates how many positive, negative, and special tiles there will be
	mul numNegAndPos, rows, cols
	lsl numNegAndPos, numNegAndPos, 2
	mov i_r, 10
	sdiv numNegAndPos, numNegAndPos, i_r
	lsr numSpecials, numNegAndPos, 1
	sub numSpecials, numSpecials, 1

	mov i_r, 0

negatives:					// Randomly populates the board with 40% negative tiles
	mov x0, 15
	mov w1, 0
	mov w2, 1
	bl randomNum				// Generates a negative float to put in the table
	fmov f_num, d0

negLoop:					// Loops generating random indices until there is an open space
	mov w0, numTableElements
	bl randInt
	mov element_offset, w0
	lsl element_offset, element_offset, 3
	ldr checkElement, [table_base, element_offset, SXTW]
	fcmp checkElement, emptySpot
	b.ne negLoop

	str f_num, [table_base, element_offset, SXTW]	// Stores the float to the open space
	
	add i_r, i_r, 1
	cmp i_r, numNegAndPos
	b.lt negatives
	mov i_r, 0

positives:					// Randomly populates the board with 40% positive tiles
	mov x0, 15
	mov w1, 0
	mov w2, 0
	bl randomNum				// Generates a positive float to put in the table
	fmov f_num, d0

posLoop:					// Loops generating random indices until there is an open space
	mov w0, numTableElements
	bl randInt
	mov element_offset, w0
	lsl element_offset, element_offset, 3
	ldr checkElement, [table_base, element_offset, SXTW]
	fcmp checkElement, emptySpot
	b.ne posLoop

	str f_num, [table_base, element_offset, SXTW]	// Stores the float to the open space

	add i_r, i_r, 1
	cmp i_r, numNegAndPos
	b.lt positives
	mov i_r, 0

specials:					// Populates the rest of the board with special tiles (20% left)
	mov w0, numTableElements
	bl randInt
	mov element_offset, w0
	lsl element_offset, element_offset, 3
	ldr checkElement, [table_base, element_offset, SXTW]
	fcmp checkElement, emptySpot
	b.ne specials

	fmov f_num, 16.0
	str f_num, [table_base, element_offset, SXTW]	// Stores the "special character" (16.0) in the open space

	add i_r, i_r, 1
	cmp i_r, numSpecials
	b.lt specials

	mov i_r, 0					// Prepares registers for the printing loop
	mov element_offset, 0
	fmov exitTile, 15.5
	fmov specialTile, 16.0
	mov i_r, 0
	
	ldr x0, =uncoveredTable
	bl printf
							// Prints the uncovered table
printUOuterLoop:

	ldr x0, =newline				// Prints a new line for each row, checks that the index is in range
	bl printf
	mov i_r, 0
	lsl w28, numTableElements, 3
	sub w28, w28, 1
	cmp element_offset, w28
	b.lt printUncovered
	b printRatios

printUncovered:							// Prints each element according to its category
	ldr tableElement, [table_base, element_offset, SXTW]
	fcmp tableElement, exitTile
	b.eq printStar
	fcmp tableElement, specialTile
	b.eq printDollarSign
	b printFloat

printStar:						// Prints the exit tile
	ldr x0, =printChar
	mov x1, 42
	bl printf
	b printULoopTest

printDollarSign:					// Prints the double range tiles
	ldr x0, =printChar
	mov x1, 36
	bl printf
	b printULoopTest

printFloat:						// Prints the normal tiles
	ldr x0, =printFP
	fmov d0, tableElement
	bl printf

printULoopTest:						// Loops back to print another element or start a new row
	add element_offset, element_offset, 8
	add i_r, i_r, 1
	cmp i_r, cols
	b.eq printUOuterLoop
	lsl w28, numTableElements, 3
	sub w28, w28, 1
	cmp element_offset, w28
	b.lt printUncovered
	

							// Prints the % negative, positive, and special tiles
printRatios:

	scvtf d8, numNegAndPos				// Calculates the percentage of negative and positive tiles
	scvtf d9, numTableElements
	fdiv elementRatio, d8, d9
	mov w28, 100
	scvtf d8, w28
	fmul elementRatio, elementRatio, d8

	ldr x0, =negRatio				// Prints the negative ratio
	mov w1, numNegAndPos
	mov w2, numTableElements
	fmov d0, elementRatio
	bl printf

	ldr x0, =posRatio				// Prints the positive ratio
	mov w1, numNegAndPos
	mov w2, numTableElements
	fmov d0, elementRatio
	bl printf

	add numSpecials, numSpecials, 1			// Calculates the percentage of special tiles
	scvtf d8, numSpecials
	scvtf d9, numTableElements
	fdiv elementRatio, d8, d9
	mov w28, 100
	scvtf d8, w28
	fmul elementRatio, elementRatio, d8

	ldr x0, =specialRatio				// Prints the special tile ratio
	mov w1, numSpecials
	mov w2, numTableElements
	fmov d0, elementRatio
	bl printf

	ldr x0, =newline
	bl printf
	ldr x0, =newline
	bl printf
	
							// Restores registers
	ldp x19, x20, [fp, 16]
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], initDealloc
	ret

//---------------------------------------

/**
 * randomNum
 * Generates and returns a random float between two given integers
 * Parameters:
 * 	maxRange is the maximum value that can be returned by the random number generator
 *  	minRange is the minimum value that can be returned
 *  	neg says whether or not to make the generated float negative (1 = negative, 0 = not negative)
 */

randomNum:
	stp fp, lr, [sp, randNumAlloc]!
	mov fp, sp

	stp x19, x20, [fp, 16]			// Stores callee-saved registers used in this function
	stp x21, x22, [fp, 32]

	mov maxRange, w0			// Gets parameters
	mov minRange, w1
	mov neg, w2

randLoop:					// Loops through generating random floats until one is within the right range
	bl rand
	mov randNum, w0
	mov w9, 100
	mul maxRange, maxRange, w9
	and randNum, randNum, maxRange		// Uses binary arithmetic to restrict the float's range
	scvtf d16, x9
	scvtf f_randNum, randNum
	fdiv f_randNum, f_randNum, d16
	fcmp f_randNum, 0.0
	b.le randLoop
	scvtf d18, maxRange
	fcmp f_randNum, d18
	b.gt randLoop

	fmov d10, 15.0
	fcmp f_randNum, d10
	b.gt changeNum
	b checkNegate

changeNum:					// Ensures the generated float is not above the max
	mov x9, 3
	scvtf f_randNum, x9

checkNegate:					// checks if neg = 1
	cmp neg, 1
	b.eq negate
	b exitRandomNum

negate:						// Negates the float if neg=1
	fneg f_randNum, f_randNum


exitRandomNum:
	fmov d0, f_randNum
	ldp x21, x22, [fp, 32]			// Restores registers and returns random float
	ldp x19, x20, [fp, 16]
	ldp fp, lr, [sp], randNumDealloc
	ret

//---------------------------------------

/**
 * randInt
 * Generates and returns a random integer between 0 and a given integer
 * Parameters:
 * 	maxRange is the maximum value that can be returned by the random number generator
 */

randInt:
	stp fp, lr, [sp, randIntAlloc]!
	mov fp, sp

	stp x19, x20, [fp, 16]			// Stores callee-saved registers used
	str x21, [fp, 32]

	mov maxRange, w0
	bl rand					// Generates a random number and calculates the remainder
        mov randNum, w0
        mov w10, maxRange
        sdiv w11, w0, w10
        mul randNum, w11, w10
        sub randNum, w0, randNum

	mov w0, randNum
	ldr x21, [fp, 32]			// Restores registers and returns a random integer
	ldp x19, x20, [fp, 16]

	ldp fp, lr, [sp], randIntDealloc
	ret

//---------------------------------------

/**
 * calculateScore
 * Calculates the player's overall current score. 
 * Parameters:
 * 	gameInfo is the base address of a struct containing information about the current game, including the overall score
 * 	turnScore is the score (positive or negative) of the revealed tiles during the current turn
 * Returns:
 * 	A float of the total current score, including previous turns and the current turn (either
 * 	positive or negative)
 */

calculateScore:
	stp fp, lr, [sp, calcScoreAlloc]!
	mov fp, sp

	stp x19, x20, [fp, 16]			// Stores registers
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

	mov gameInfo, x0			// Sums the turn's score and the overall score
	fmov turnScore, d0
	ldr score, [gameInfo, 8]
	fadd score, score, turnScore

	fmov d0, score
					
	ldp x19, x20, [fp, 16]			// Restores registers and returns the total score
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], calcScoreDealloc
	ret

//---------------------------------------

/**
 * logScore
 * Appends the game information (player name, score, and duration) to a log file. 
 * Parameter:
 * 	gameInfo is the base address of the struct containing relevant information
 */

logScore:
	stp fp, lr, [sp, logScoreAlloc]!
	mov fp, sp

						// Stores registers
	stp x19, x20, [fp, 16]
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

						// Gets parameter
	mov gameInfo, x0

	
	ldr playerName, [gameInfo, 16]		// Gets the info to log from the struct
	ldr score, [gameInfo, 8]
	ldr duration, [gameInfo, 60]
	
	ldr x0, =logFileName			// Opens the file in append mode
	ldr x1, =appendMode
	bl fopen
	mov logFile, x0

	mov x0, logFile				// Writes the info to the file
	ldr x1, =logFileString
	mov x2, playerName
	fmov d0, score
	mov x3, duration
	bl fprintf
	
	mov x0, logFile				// Closes the file
	bl fclose


exitLS:
						// Restores registers
	ldp x19, x20, [fp, 16]
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], logScoreDealloc
	ret

//---------------------------------------

/**
 * exitGame
 * Finishes up the game by prompting the user to see the top entries on the scoreboard 
 * if they wish, and logs their game information to the file regardless of whether or 
 * not they chose to view the scoreboard.
 * Parameters:
 * 	gameInfo is the base address of the struct array that contains relevant game information
 */

exitGame:
	stp fp, lr, [sp, exitGameAlloc]!
	mov fp, sp

						// Stores registers
	stp x19, x20, [fp, 16]
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

						// Gets parameters
	mov gameInfo, x0

	mov x0, gameInfo			// Logs the game info to the file
	bl logScore
	

endScoreBoardOption:				// Prompts the user to view the scoreboard	
	ldr x0, =seeSBPrompt
	bl printf
	ldr x0, =scanInt
	ldr w1, =seeSB
	bl scanf
	ldr w9, seeSB
	cmp w9, 2
	b.eq exitExitGame
	cmp w9, 1
	b.eq viewSB2
	b endScoreBoardOption
	
viewSB2:					// Views the scoreboard if the user wants to
	bl displayTopScores

exitExitGame:
						// Restores registers
	ldp x19, x20, [fp, 16]
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], exitGameDealloc
	ret

//---------------------------------------

/**
 * displayTopScores
 * Performs all the functionality of viewing the scoreboard. First reads the file and copies the 
 * scoreboard entries into a struct array, and then uses bubble sort to arrange them in order of 
 * decreasing score. Then prompts the user to enter the number of scores to display, and prints 
 * that number of top scores to the console.
 */

displayTopScores:
	stp fp, lr, [sp, viewSBAlloc]!
	mov fp, sp

						//Store registers
	stp x19, x20, [fp, 16]
	stp x21, x22, [fp, 32]
	stp x23, x24, [fp, 48]
	stp x25, x26, [fp, 64]
	stp x27, x28, [fp, 80]

	add scoreBoard_base, fp, 90		// Creates the struct array for keeping all the game information

	mov numPlayers, 0
	

						// Reads the file and populates the scoreBoard struct array
	ldr x0, =logFileName
	ldr x1, =readMode
	bl fopen
	mov readFile, x0

enterScore:							// Reads each entry of the file
	mov w10, 20
	mul scoreBoard_offset, numPlayers, w10
	mov x0, readFile
	ldr x1, =scanStr
	mov x2, scoreBoard_base
	add x2, x2, scoreBoard_offset, SXTW
	bl fscanf						// Scans for the player name
	mov x0, readFile
	ldr x1, =scanFloat
	add scoreBoard_offset, scoreBoard_offset, 8
	mov x2, scoreBoard_base
	add x2, x2, scoreBoard_offset, SXTW
	bl fscanf						// Scans for the player's score
	mov x0, readFile
	ldr x1, =scanInt
	add scoreBoard_offset, scoreBoard_offset, 8
	mov x2, scoreBoard_base
	add x2, x2, scoreBoard_offset, SXTW
	bl fscanf						// Scans for the player's duration

enterScoreTest:
	add numPlayers, numPlayers, 1				// Stops looping when the end of the file has been reached
	mov x0, readFile
	bl feof
	cmp x0, 0
	b.eq enterScore

	mov x0, readFile					// Closes the file
	bl fclose

	sub numPlayers, numPlayers, 1				// Doesn't sort if there is only one score
	cmp numPlayers, 1
	b.eq numScoresOption

	sub numPlayers, numPlayers, 1

sortLoop:							// Sorts the scores in descending order, using
        mov swap, 0						// bubble sort
        mov sortCounter, 0

swapLoop:							// Compares "this" score with the next score
	mov w9, 20
        mul scoreBoard_offset, sortCounter, w9
	add scoreBoard_offset, scoreBoard_offset, 8
        ldr this_score, [scoreBoard_base, scoreBoard_offset, SXTW]

        add scoreBoard_offset, scoreBoard_offset, 20
        ldr next_score, [scoreBoard_base, scoreBoard_offset, SXTW]

        add sortCounter, sortCounter, 1

        fcmp this_score, next_score
        b.lt swapElements

        b swapLoopTest

swapElements:							// Performs a swap if they are out of order
        add swap, swap, 1

	sub scoreBoard_offset, scoreBoard_offset, 8			// Swaps the names
	ldr name2, [scoreBoard_base, scoreBoard_offset, SXTW]
	sub scoreBoard_offset, scoreBoard_offset, 20
	ldr name1, [scoreBoard_base, scoreBoard_offset, SXTW]
	str name2, [scoreBoard_base, scoreBoard_offset, SXTW]
	add scoreBoard_offset, scoreBoard_offset, 20
	str name1, [scoreBoard_base, scoreBoard_offset, SXTW]

	add scoreBoard_offset, scoreBoard_offset, 8			// Swaps the scores
	str this_score, [scoreBoard_base, scoreBoard_offset, SXTW]
	sub scoreBoard_offset, scoreBoard_offset, 20
	str next_score, [scoreBoard_base, scoreBoard_offset, SXTW]

	add scoreBoard_offset, scoreBoard_offset, 8			// Swaps the durations
	ldr duration1, [scoreBoard_base, scoreBoard_offset, SXTW]
	add scoreBoard_offset, scoreBoard_offset, 20
	ldr duration2, [scoreBoard_base, scoreBoard_offset, SXTW]
	str duration1, [scoreBoard_base, scoreBoard_offset, SXTW]
	sub scoreBoard_offset, scoreBoard_offset, 20
	str duration2, [scoreBoard_base, scoreBoard_offset, SXTW]

	
swapLoopTest:							// Iterates through the whole scoreboard struct array
        cmp sortCounter, numPlayers
        b.lt swapLoop

sortLoopTest:							// Stops the algorithm once none of the
        cmp swap, 0						// scores have to be swapped, i.e. they
        b.gt sortLoop						// are all sorted


	add numPlayers, numPlayers, 1

numScoresOption:						// Asks the user how many scores to display
	ldr x0, =numScoresPrompt
	bl printf
	ldr x0, =scanInt
	ldr w1, =numScoresAns
	bl scanf
	ldr numScores, numScoresAns
	cmp numScores, 0
	b.lt invalidNumScores
	cmp numScores, numPlayers
	b.gt tooManyScores
	b printTopScores

invalidNumScores:						// Loops for valid input if the user entered a negative number
	ldr x0, =invalidNumScoresMsg
	bl printf
	ldr x0, =scanInt
	ldr w1, =numScoresAns
	bl scanf
	ldr numScores, numScoresAns
	cmp numScores, 0
	b.lt invalidNumScores
	cmp numScores, numPlayers
	b.gt tooManyScores
	b printTopScores
	
tooManyScores:							// Loops for valid input if the user entered a number that was too high
	ldr x0, =tooManyScoresMsg
	bl printf
	ldr x0, =scanInt
	ldr w1, =numScoresAns
	bl scanf
	ldr numScores, numScoresAns
	cmp numScores, 0
	b.lt invalidNumScores
	cmp numScores, numPlayers
	b.gt tooManyScores
	b printTopScores


printTopScores:							// Prints out the top of the scoreboard
	ldr x0, =scoreBoardTitle
	bl printf

	mov w19, 0

printScoresLoop:						// Prints out each entry of the scoreboard
	mov w10, 20
	mul scoreBoard_offset, w19, w10
	ldr x0, =printScore
	add w1, w19, 1
	add x2, scoreBoard_base, scoreBoard_offset, SXTW
	add scoreBoard_offset, scoreBoard_offset, 8
	ldr d0, [scoreBoard_base, scoreBoard_offset, SXTW]
	add scoreBoard_offset, scoreBoard_offset, 8
	ldr w3, [scoreBoard_base, scoreBoard_offset, SXTW]
	bl printf

printScoresLoopTest:						// Loops until the specified number of scores has been displayed
	add w19, w19, 1
	cmp w19, numScores
	b.lt printScoresLoop

	ldr x0, =afterScoreBoard				// Prints the bottom of the scoreboard
	bl printf

exitVSB:
								// Restores registers
	ldp x19, x20, [fp, 16]
	ldp x21, x22, [fp, 32]
	ldp x23, x24, [fp, 48]
	ldp x25, x26, [fp, 64]
	ldp x27, x28, [fp, 80]

	ldp fp, lr, [sp], viewSBDealloc
	ret
	

//---------------------------------------

/**
 * main
 * Executes the program by calling other functions. First, checks and handles the command line arguments, then gives the
 * user the option to view the scoreboard before the game begins. Afterward, the game board is created and filled,
 * and the user takes turns bombing the board until the game ends or they choose to quit. Then, the player has the option
 * to view the scoreboard again, and their game information is logged to a file.
 * Parameters:
 * 	argc_r is a count of the command line arguments entered by the user. It is expected to be 4.
 *  	argv_r contains the command line arguments. The first element is expected to be the name
 *  		of the program, the second is the player's name, and the third and fourth are expected to be
 *  		integers corresponding to rows and columns for the board's dimensions.
 */

main:
	stp fp, lr, [sp, mainAlloc]!
	mov fp, sp

	mov argc_r, w0				// Gets command line arguments
	mov argv_r, x1

	cmp argc_r, 4				// Checks if there is a valid number of arguments
	b.ne invalidNumArgs
	b validNumArgs

invalidNumArgs:					// If there were not 4 arguments, prints an error message and quits
	ldr x0, =numArgsErrorMsg
	bl printf
	b exit

validNumArgs:					// If there were 4 arguments, moves the dimensions into registers
	ldr x0, [argv_r, 16]			// and checks that they are within range (≥ 10)
	bl atoi
	mov rows, w0
	ldr x0, [argv_r, 24]
	bl atoi
	mov cols, w0
	cmp rows, 10
	b.lt invalidRangeArgs
	cmp cols, 10
	b.lt invalidRangeArgs
	b getName

invalidRangeArgs:				// If the dimensions were not in range, prints an error message and quits
	ldr x0, =invalidRangeMsg
	bl printf
	b exit

getName:					// If the dimensions were in range, moves the address of the name to a register
	ldr x0, [argv_r, 8]
	mov name_r, x0

						// Calculates RAM space required for table and revealedTiles array, given 
	mul numElements, rows, cols		// the board dimensions
	mov alloc_r, numElements
	lsl alloc_r, alloc_r, 3
	add alloc_r, alloc_r, numElements
	and alloc_r, alloc_r, -16
	add alloc_r, alloc_r, 16
	sub sp, sp, alloc_r, SXTW		// Allocates space on the stack for the table and revealedTiles array
	
	mov revealedTiles_base, sp		// Sets the base addresses for the table and revealedTiles array
	add table_base, sp, numElements

	mov x0, table_base
	mov w1, rows
	mov w2, cols
	mov x3, revealedTiles_base
	bl initializeGame			// Creates the game board

						// Adds space on the stack for the game information struct
	add sp, sp, gameInfoAlloc
	str name_r, [sp, 16]			// Stores the name address in the game info struct
	mov gameInfo, sp			// Sets "gameInfo" as the base address for the struct
	mov w22, 3
	str w22, [gameInfo]			// Sets the player's initial life count to 3
	cmp rows, cols
	b.gt numBombs1
	b numBombs2

numBombs1:					// Calculates the number of initial bombs, depending on 
	mov w22, 3				// the board size (1/3 of the higher of rows and columns)
	sdiv w22, rows, w22
	b storeBombs
numBombs2:
	mov w22, 3
	sdiv w22, cols, w22

storeBombs:					// Stores the initial number of bombs
	str w22, [gameInfo, 4]
	mov w22, 0
	scvtf score, w22
	str score, [gameInfo, 8]		// Sets the user's initial score to 0.00
	str rows, [gameInfo, 28]		// Stores the rows to the game info struct
	str cols, [gameInfo, 32]		// Stores the cols to the game info struct
	mov w22, 0
	str w22, [gameInfo, 36]			// Sets the number of double tiles hit to 0 initially
	str w22, [gameInfo, 40]			// Sets the "hit end tile" boolean to 0 (false) initially

startScoreBoardOption:				// Before-game prompt to see the scoreboard
	ldr x0, =seeSBPromptFirst
	bl printf
	ldr x0, =scanInt
	ldr w1, =seeSB
	bl scanf
	ldr w9, seeSB
	cmp w9, 2
	b.eq afterFirstScoreBoard
	cmp w9, 1
	b.eq viewSB1
	b startScoreBoardOption

viewSB1:
	mov w0, AT_FDCWD			// Tries to open the file - if it cannot be opened, it means it
        ldr x1, =logFileName			// is the first time the game is played
        mov w2, 0
        mov w3, 0
        mov x8, 56
        svc 0
        mov x28, x0
        cmp x28, 0
        b.lt fileNonexistent
	b fileExists

fileNonexistent:				// Tells the user that it is the first game played and continue
	ldr x0, =firstTimePlayedMsg		// with the game
	bl printf
	b afterFirstScoreBoard

fileExists:					// If the file exists, closes it and passes to the "displayTopScores" function
	mov x0, x28		
        mov x8, 57
        svc 0
	bl displayTopScores

afterFirstScoreBoard:

	mov x0, table_base			// Displays the covered board initially
	mov x1, revealedTiles_base
	mov x2, gameInfo
	fmov d0, turnScore
	mov w3, 10
	bl displayGame

	mov x0, 0				// Starts timing the game
	bl time
	mov startTime, x0
	str startTime, [gameInfo, 44]

						// Start the player's turns
turnLoop:
	ldr x0, =bombPrompt			// Prompts for bomb coordinates
	bl printf
	ldr x0, =scanCoor
	ldr w1, =bombR
	ldr w2, =bombC
	bl scanf
	ldr bombRow, bombR
	ldr bombCol, bombC

	ldr rows, [gameInfo, 28]
	ldr cols, [gameInfo, 32]
	
	cmp bombRow, 0				// Checks if the coordinates were invalid
	b.lt invalidCoor
	cmp bombRow, rows
	b.ge invalidCoor
	cmp bombCol, 0
	b.lt invalidCoor
	cmp bombCol, cols
	b.ge invalidCoor
	b doAction

invalidCoor:					// If the coordinates were invalid, loops for valid input
	ldr x0, =invalidCoorMsg
	bl printf
	ldr x0, =scanCoor
	ldr w1, =bombR
	ldr w2, =bombC
	bl scanf
	ldr bombRow, bombR
	ldr bombCol, bombC
	
	cmp bombRow, 0
	b.lt invalidCoor
	cmp bombRow, rows
	b.ge invalidCoor
	cmp bombCol, 0
	b.lt invalidCoor
	cmp bombCol, cols
	b.ge invalidCoor

doAction:					// Continues after the user enters valid input
	mov x0, table_base
	mov x1, revealedTiles_base
	mov x2, gameInfo
	mov w3, bombRow
	mov w4, bombCol
	bl bomb					// Bombs the tile specified by the user
	fmov turnScore, d0

	ldr bombs, [gameInfo, 4]		// Decrements the number of bombs
	sub bombs, bombs, 1
	str bombs, [gameInfo, 4]

	mov x0, gameInfo			// Calculates the updated score from this bomb
	fmov d0, turnScore
	bl calculateScore
	fcmp d0, 0.0
	b.lt loseLife				// Decrements the player's lives if the score becomes negative
	str d0, [gameInfo, 8]			// Updates score otherwise
	b disp

loseLife:
	mov w19, 0				// Zeroes total score
	scvtf score, w19
	str score, [gameInfo, 8]
	ldr w20, [gameInfo]			// Player loses a life
	sub w20, w20, 1
	str w20, [gameInfo]
	cmp w20, 0	
	b.lt noLives				// Checks if the player has run out of lives
	
disp:
	mov x0, table_base			// Displays the post-bomb board
	mov x1, revealedTiles_base
	mov x2, gameInfo
	fmov d0, turnScore
	mov w3, 0
	bl displayGame

checkBombsLivesEndTile:				// Checks the bombs, lives, and end tile to see if
	ldr hitEndTile, [gameInfo, 40]		// the game is over
	cmp hitEndTile, 1
	b.eq endTileFound

	ldr bombs, [gameInfo, 4]
	cmp bombs, 0
	b.le noBombs

	ldr w20, [gameInfo]
	cmp w20, 0
	b.le noLives


	mov w19, 0				// Resets the turn score to 0.00 for the next turn
	scvtf turnScore, w19

quitOption:					// Asks the user to continue or quit, and loops for valid input	
	ldr x0, =contPrompt
	bl printf
	ldr x0, =scanInt
	ldr w1, =continue
	bl scanf
	ldr cont, continue
	cmp cont, 2
	b.eq quitGame
	cmp cont, 1
	b.eq turnLoop
	b quitOption

noLives:					// Prints a message and quits if the player ran out of lives
	ldr x0, =noLivesMsg
	bl printf
	b quitGame

noBombs:					// Prints a message and quits if the player ran out of bombs
	ldr x0, =noBombsMsg
	bl printf
	b quitGame

endTileFound:					// Prints a message and quits if the player found the exit tile
	ldr x0, =endTileMsg
	bl printf
	b quitGame

quitGame:					
	mov x0, 0	
	bl time					// Finds the end time of the game
	mov endTime, x0
	str endTime, [gameInfo, 52]

	ldr startTime, [gameInfo, 44]
	ldr endTime, [gameInfo, 52]
	sub totalTime, endTime, startTime	// Calculates the total time played this game

	str totalTime, [gameInfo, 60]
	
	mov x0, gameInfo	
	bl exitGame				// Performs exit game functionality - logging the score and viewing the scoreboard

	add sp, sp, gameInfoDealloc
	add sp, sp, alloc_r, SXTW


exit:						// Exits the program and returns control to the calling code
	ldp fp, lr, [sp], mainDealloc
	ret


