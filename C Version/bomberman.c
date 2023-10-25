/*
Disclaimer ... I made this game many years ago when I first started coding. I would change so 
many things about it now, but I have other things I'd rather do with my time. Please don't
judge my coding skills by this project. :)


 * This program is a modified version of the "bomberman" game. The user
 * enters their name and two integers (>10) on the command line. These
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
 * tile is found, the user quits, or there are no more lives or bombs. 
 * The game is timed and the time is logged to the scoreboard file, along with
 * the player's name and score.
 * The special tiles consist of:
 * 		- ($) double-range powerups, which double the range of the next bomb
 * 		- (!) Landmines, which cost the player 1 life
 * 		- (H) Hospitals, which give the player 1 life
 * 		- (&) Robbers, which remove 1 bomb from the player
 * 		- (#) Charities, which give the player 1 bomb
 * For the last 4 special packs, multiple occurrences of one special pack revealed
 * by a bomb has no more effect than only one revealed by a bomb.
 * 
 * Note that the maximum dimensions that fit on my full sized screen is 55 rows x 115 columns
 */

#include<stdio.h>
#include<unistd.h>
#include<stdlib.h>
#include<string.h>
#include<stdbool.h>
#include<ctype.h>
#include<time.h>

// Creates global variables of the number of rows and columns
int rows;
int cols;

/**
 * randomNum
 * Generates and returns a random float between two given integers
 * Parameters:
 * 	int m is the minimum (inclusive) value that can be returned by the random number generator
 *  int n is the maximum (inclusive) value that can be returned
 *  bool neg says whether or not to make the generated float negative
 */
float randomNum(int n, int m, bool neg) {

		int value = rand() & 0b10111011100;
		float num = (float)(((float)value)/100.0);

		while (num > m || num < n) {
			value = rand() & 0b10111011100;
			num = (float)(((float)value)/100.0);
		}
        if (neg) {
            num = (num-2*num);
        }
        return num;
}

/**
 * randomInt
 * Generates and returns a random integer between two given integers
 * Parameters:
 * 	int n is the minimum value that can be returned by the random number generator
 *  int m is the maximum value that can be returned
 */
int randomInt(int n, int m) {
        int num = rand()%(m+1);
        while (num < n) {
        	num = rand()%(m+1);
        }
        return num;
}

/**
 * readFile
 * Reads a file named "logFile.txt" and populates a 2D array, scoreBoard, based on the values
 * on each line, and populates a string array, nameArray, with the name on each line.
 * The first value on each line is the index corresponding to the name in nameArray, the second
 * is the name, the third is the player's score, and the fourth is the player's time.
 * The function also checks if the file previously exists, and if not, returns 1 without opening
 * the file.
 * Parameters:
 * 	float scoreBoard[][] is an unpopulated 2D array, which is populated in this function
 * 	char nameArray[][] is an unpopulated array of strings, which is populated in this function
 * Return:
 * 	int firstTimePlayed is 1 if the file does not exist, and 0 if the file exists
 */
int readFile(float scoreBoard[1000][3], char nameArray[1000][20]) {
	
	int firstTimePlayed;
	char fileName[] = "logFile.txt";
	// If the file doesn't already exist, sets firstTimePlayed to 1 (true)
	if(!( access( fileName, F_OK ) != -1 )) {		
		firstTimePlayed = 1;
		return firstTimePlayed;
	
	// Otherwise, reads the file and populate the arrays
	} else {
		
		firstTimePlayed = 0;
		int endLine;
		int playerNum;
		char playerName[20];
		float playerScore;
		float playerTime;
		
		FILE *readFile;
		readFile = fopen(fileName, "r");
		for (int p = 0; p<1000; p++) {
			scoreBoard[p][0] = -1.0;
			scoreBoard[p][1] = -1.0;
			scoreBoard[p][2] = -1.0;
		}
		
		// Reads through the file line by line, updating the arrays
		while (true) {	
			
				fscanf(readFile, "%d", &playerNum);
				fscanf(readFile, "%s", &playerName);
				fscanf(readFile, "%f", &playerScore);
				fscanf(readFile, "%f", &playerTime);
				
				strcpy(nameArray[playerNum-1], playerName);
				strcpy(playerName, "");				
								
				scoreBoard[playerNum-1][0] = (float)playerNum;
				scoreBoard[playerNum-1][1] = playerScore;
				scoreBoard[playerNum-1][2] = playerTime;
				
				playerNum++;
				
				if (feof(readFile)) {
					break;
				}
		}
		fclose(readFile);
		scoreBoard[playerNum-2][0] = -1;
		scoreBoard[playerNum-2][1] = -1;
		scoreBoard[playerNum-2][2] = -1;
		return firstTimePlayed;
	}
	
}

/**
 * sortTopScores
 * Uses a bubble sort algorithm to arrange the given scoreBoard array by each player's score.
 * Parameters:
 * 	float scoreBoard[][] is a 2D array, which is sorted in terms of descending scores in this function
 * Returns:
 * 	int numberOfPlayers is the number of games that have been entered in the scoreBoard array
 */
int sortTopScores(float scoreBoard[1000][3]) {
	
	
	int numberOfPlayers;
	
	// Calculates numberOfPlayers based on how many entries in scoreBoard are not -1
	int i;
	for (i=0; i<1000; i++) {
		if (scoreBoard[i][0] == -1) {
			numberOfPlayers = i;
			break;
		}
	}
	
	//Uses bubble sort to arrange scoreBoard in order of top scores
	int swap;
	int p;
	
	do {
		swap = 0;
		for (int p=0; p < numberOfPlayers-1; p++) {
			
			//Swaps the current and next entries if they are out of order
			if (scoreBoard[p][1] < scoreBoard[p+1][1]) {
				swap += 1;
				float temp[3];
				temp[0] = scoreBoard[p][0];
				temp[1] = scoreBoard[p][1];
				temp[2] = scoreBoard[p][2];
				
				scoreBoard[p][0] = scoreBoard[p+1][0];
				scoreBoard[p][1] = scoreBoard[p+1][1];
				scoreBoard[p][2] = scoreBoard[p+1][2];
				
				scoreBoard[p+1][0] = temp[0];
				scoreBoard[p+1][1] = temp[1];
				scoreBoard[p+1][2] = temp[2];
				
			}
		
		}
		p = 0;
	} while (swap != 0);
	
	return numberOfPlayers;
}

/**
 * logScore
 * Appends the input/output information from the latest search to a file named "assign1.log". 
 * Prints the number of the search, the word index, number of documents, and resulting top 
 * documents of the search. If this is the first time the user has searched since starting
 * the program, the rows, columns, and document table are printed at the beginning.
 * Parameters:
 * 	int numPlayer is the number of players on the scoreboard before this game plus one
 * 	char name[] is the name the user gave via command line arguments
 * 	float score is the score the player had at the end of their game
 * 	float time is the length of time the player spent on their game
 */
void logScore(int numPlayer, char name[20], float score, float time) {
	
	//Opens file in append mode
	FILE *logFile;
	logFile = fopen("logFile.txt", "a");
	// Prints one line of information to the end of the file
	fprintf(logFile, "%d %s %.2f %d\n", numPlayer, name, score, (int)time);
	fclose(logFile);

}

/**
 * displayTopScores
 * Prints the top specified number of items in the scoreBoard to the console. 
 * Parameters:
 * 	int n is the number of scores to display, specified by the user
 * 	float scoreBoard[][] is the sorted array of scores and player other information
 * 	char nameArray[][] is an array of strings containing each player's name
 */
void displayTopScores(int n, float scoreBoard[1000][3], char nameArray[1000][20]) {
	printf("__________________Scoreboard__________________\n");
	int i;
	for (i=0; i<n; i++) {
		int nameIndex = (int)scoreBoard[i][0]-1;
		printf("%d.  %s\n\tScore: %.2f\n\tTime: %d seconds\n", i+1, nameArray[nameIndex], scoreBoard[i][1], (int)scoreBoard[i][2]);
	}
	printf("\n");
}

/**
 * initializeGame
 * Populates the board for the game, which is a 2D float array with dimensions specified by
 * the user in the command line. 40% of the tiles are positive, 40% are negative,
 * 4 are each of landmines, hospitals, robbers, and charities, 1 is the exit tile,
 * and the rest are double-range tiles.
 * Parameters:
 * 	float board[][] is an initially empty 2D array, which is populated with tiles in this function
 */
void initializeGame(float board[rows][cols]) {

		// Fills the board with 'X's first for later comparison
        int i;
        int j;
        for (i = 0; i<rows; i++) {
                for (j = 0; j<cols; j++) {
                        board[i][j] = (float)('X');
                }
        }


        // Sets the exit tile randomly
        int exitTileRow = randomInt(0, rows-1);
        int exitTileCol = randomInt(0, cols-1);
        board[exitTileRow][exitTileCol] = (float)('*');

        // Calculates the number of positive and negative tiles
        int boardSize = (rows*cols);

        int numOfNegatives = (0.4*boardSize);
        int numOfPositives = (0.4*boardSize);

        // Calculates the number of special tiles 
        int numOfSpecials = (0.2*boardSize)-1;
        int numOfLandmines = 4;
        int numOfHospitals = 4;
        int numOfRobbers = 4;
        int numOfCharities = 4;
        int numOfDoubles = numOfSpecials-16;

        int n=0;
        int p=0;
        int d=0;
        int l=0;
        int h=0;
        int r=0;
        int c=0;

        // Generates and populates the negative entries
        while (n<numOfNegatives) {

                // Generates the score number
                float num = randomNum(1,15, true);

                while (num == 0.0) {
                        num = randomNum(1,15, true);
                }

                bool openSpot = false;
                while (openSpot == false) {
                        // Randomizes where it goes in the board
                        int rowNum = randomInt(0, rows);
                        int colNum = randomInt(0, cols);
                        
                        if (board[rowNum][colNum] == (float)('X')) {
                        	
                        	board[rowNum][colNum] = num;
                            openSpot = true;
                        }
                }
                n++;
        }
        // Generates and populates the positive entries
        while (p<numOfPositives) {

                // Generates the score number
                float num = randomNum(1,15, false);

                while (num == 0.0) {
                        num = randomNum(1,15, false);
                }

                bool openSpot = false;
                while (openSpot == false) {
                        // Randomizes where it goes in the board
                        int rowNum = randomInt(0, rows);
                        int colNum = randomInt(0, cols);
                        
                        // If that spot is not already filled in, then fills it in
                        if (board[rowNum][colNum] == (float)('X')) {
                                board[rowNum][colNum] = num;
                                openSpot = true;
                        }
                }
                p++;
        }
        // Populates the double-range tiles
        while (d<numOfDoubles) {

                bool openSpot = false;
                while (openSpot == false) {
                        // Randomizes where it goes in the board
                        int rowNum = randomInt(0, rows);
                        int colNum = randomInt(0, cols);
                        
                        if (board[rowNum][colNum] == (float)('X')) {
                            board[rowNum][colNum] = (float)('$');
                            openSpot = true;
                        }
                }
                d++;
        }
        // Populates the landmine tiles
        while (l<numOfLandmines) {

            bool openSpot = false;
            while (openSpot == false) {
                    // Randomizes where it goes in the board
                    int rowNum = randomInt(0, rows);
                    int colNum = randomInt(0, cols);
                    
                    if (board[rowNum][colNum] == (float)('X')) {
                        board[rowNum][colNum] = (float)('!');
                        openSpot = true;
                    }
            }
            l++;
        }
        // Populates the hospital tiles
        while (h<numOfHospitals) {

            bool openSpot = false;
            while (openSpot == false) {
                    // Randomizes where it goes in the board
                    int rowNum = randomInt(0, rows);
                    int colNum = randomInt(0, cols);
                    
                    if (board[rowNum][colNum] == (float)('X')) {
                        board[rowNum][colNum] = (float)('%');
                        openSpot = true;
                    }
            }
            h++;
        }
        // Populates the robber tiles
        while (r<numOfRobbers) {

            bool openSpot = false;
            while (openSpot == false) {
                    // Randomizes where it goes in the board
                    int rowNum = randomInt(0, rows);
                    int colNum = randomInt(0, cols);
                    
                    if (board[rowNum][colNum] == (float)('X')) {
                        board[rowNum][colNum] = (float)('&');
                        openSpot = true;
                    }
            }
            r++;
        }
        // Populates the charity tiles
        while (c<numOfCharities) {

            bool openSpot = false;
            while (openSpot == false) {
                    // Randomizes where it goes in the board
                    int rowNum = randomInt(0, rows);
                    int colNum = randomInt(0, cols);
                    
                    if (board[rowNum][colNum] == (float)('X')) {
                        board[rowNum][colNum] = (float)('#');
                        openSpot = true;
                    }
            }
            c++;
        }
        
        
}

/**
 * calculateScore
 * Calculates the player's overall current score. 
 * Parameters:
 * 	float score is the total score the player had before this turn
 * 	float turnScore is the score (positive or negative) of the revealed tiles during the current turn
 * Returns:
 * 	A float of the total current score, including previous turns and the current turn (either
 * 	positive or negative)
 */
float calculateScore(float score, float turnScore) {
	return (score + turnScore);
}

/**
 * displayGame
 * Prints the board to the console. All non-revealed tiles are displayed as 'X's, while revealed
 * negative tiles are '-', revealed positives are '+', and the revealed special tiles are their respective character.
 * Information about current lives, score, and bombs is also printed.
 * Parameters:
 * 	float board[][] contains the values for each tile on the board. Its contents are printed in this function
 * 	int lives is the current number of lives the player has, after accounting for the current turn
 * 	float score is the player's total score during the game so far 
 * 	int bombs is the number of bombs the player has left in this game
 * 	int revealedTiles[][] contains coordinates for which tiles in the board have been revealed
 * 	int numRevealedTiles is the number of tiles on the board that have been revealed at this point in the game
 */
void displayGame(float board[rows][cols], int lives, float score, int bombs, int revealedTiles[rows*cols][2], int numRevealedTiles, bool firstDisplay) {
		bool doubleSign;
		bool endTile;
		bool normalTile;
		bool landmine;
		bool hospital;
		bool robber;
		bool charity;
		
		// Iterates through each tile of the board and, if it is revealed, prints its respective
		// symbol, and if it is not revealed, prints an 'X' in its place
        int i;
        int j;
        int p;
        for (i = 0; i<rows; i++) {
                for (j = 0; j<cols; j++) {
                	if (firstDisplay) {
                		if (board[i][j] > -15 && board[i][j] < 15) {
                			printf("%-9.2f ", board[i][j]);
                		} else {
                			if (board[i][j] == '%') {
                				printf("%-9c ", 'H');
                			} else {
                    		printf("%-9c ", (int)board[i][j]);
                			}
                		}
                		continue;
                	}
                	
                	// For each tile, searches through all the currently revealed tiles and sets 
                	// an appropriate boolean if it is a revealed tile
                	for (p=0; p<=numRevealedTiles; p++) { 
                		doubleSign = false;
                		endTile = false;
                		normalTile = false;
                		landmine = false;
                		hospital = false;
                		robber = false;
                		charity = false;
                		if (revealedTiles[p][0] == i && revealedTiles[p][1] == j) {
	                        if (board[i][j] == (float)('*')) {
	                        	endTile = true;
	                        	break;
	                        } else if (board[i][j] == (float)('$')) {
	                        	doubleSign = true;
	                        	break;
	                        } else if (board[i][j] == (float)('!')) {
	                        	landmine = true;
	                        	break;
	                        } else if (board[i][j] == (float)('%')) {
	                        	hospital = true;
	                        	break;
	                        } else if (board[i][j] == (float)('&')) {
	                        	robber = true;
	                        	break;
	                        } else if (board[i][j] == (float)('#')) {
	                        	charity = true;
	                        	break;
	                        } else {
	                        	normalTile = true;
	                        	break;
	                        }
                		}
                	}
                	
                	// Prints the appropriate symbol for the tile
                	if (endTile) {
                		printf("* ");
                	} else if (doubleSign) {
                		printf("$ ");
                	} else if (landmine) {
                		printf("! ");
                	} else if (hospital) {
                		printf("H ");
                	} else if (robber) {
                		printf("& ");
                	} else if (charity) {
                		printf("# ");
                	} else if (normalTile){
                		if (board[i][j] > 0) {
                    		printf("+ ");
                    	} else if (board[i][j] < 0) {
                    		printf("- ");
                    	}
                	} else {
                		printf("X ");
                		}

                }
                
                printf("\n");
        }
        
        // Prints other information about lives, score, and bombs
        if (score < 0.0) {
			lives-=1;
			printf("\nOops! You lost a life.\n");
			score = 0.0;
		}
        printf("Lives: %d\n", lives);
        printf("Score: %.2f\n", score);
        printf("Bombs: %d\n", bombs);

}

/**
 * updateRevealedTiles
 * Updates the variables that contain information about which tiles have been revealed, by one tile's coordinates.
 * Parameters:
 * 	int r is the row coordinate of the newly revealed tile
 * 	int c is the column coordinate of the newly revealed tile
 * 	int revealedTiles[][] is the array containing the coordinates of the board tiles that have been revealed
 * 	int *numRevealedTiles is a pointer to the number of revealed tiles on the board, which is incremented by one in this function
 */
void updateRevealedTiles(int r, int c, int revealedTiles[rows*cols][2], int *numRevealedTiles) {
	
	revealedTiles[*numRevealedTiles][0] = r;
	revealedTiles[*numRevealedTiles][1] = c;
	*numRevealedTiles = *numRevealedTiles + 1;
}

/**
 * bomb
 * Executes the action of "placing a bomb" on the board. The range is determined by the number of double-range tiles
 * that were revealed in the previous turn. The revealed tiles are updated, and if special tiles were revealed, they 
 * are updated as well.
 * Parameters:
 * 	float board[][] is the game board, containing the value of each tile
 * 	int bombRow is the row coordinate specified by the user this turn
 * 	int bombCol is the column coordinate specified by the user this turn
 * 	int *numDoubles is a pointer to the number of doubles that were revealed by the previous bomb. It is updated
 * 	with the number of double-range tiles that are revealed by the current bomb
 * 	int revealedTiles[][] is used to update which tiles are revealed
 * 	int *numRevealedTiles is used to update the number of total revealed board tiles
 * 	int *hitEndTile is used to set the value of hitEndTile to 1 if the exit tile was revealed in this turn
 * 	int *landmine is used to set the value of landmine to 1 if any landmine tiles were revealed in this turn
 *  int *hospital is used to set the value of hospital to 1 if any hospital tiles were revealed in this turn
 * 	int *robber is used to set the value of robber to 1 if any robber tiles were revealed in this turn
 * 	int *charity is used to set the value of charity to 1 if any charity tiles were revealed in this turn
 * Returns:
 * 	The current turn's score, which is only calculated from tiles that have not previously been revealed.
 */
float bomb(float board[rows][cols], int bombRow, int bombCol, int *numDoubles, int revealedTiles[rows*cols][2], int *numRevealedTiles, int *hitEndTile, int *landmine, int *hospital, int *robber, int *charity) {
	bool revealed = false;
	
	// Uses numDoubles of previous turn to determine range of the current bomb
	int size = 3;
	int z;
	for (z=0; z<*numDoubles; z++) {
		size = 2*size - 1;
	}
	
	// Sets the value of numDoubles to 0 so it can be updated during this bomb
	*numDoubles = 0;
	
	float turnScore = 0.0;

	// If the range of the bomb is bigger than the board itself, reveals the entire board
	int a;
	int b;
	int c;
	if (size > rows && size > cols) {
		for (a=0; a<rows; a++) {
			for (b=0; b<cols; b++) {
				
				// If the tile has been previously revealed, moves on to the next tile
				for (c=0; c<=*numRevealedTiles; c++) { 
					if (revealedTiles[c][0] == a && revealedTiles[c][1] == b) {
            			revealed = true;
                        continue;
                    }
            	}
				if (revealed) {
					revealed = false;
					continue;
				}
				
				// If the tile has not been previously revealed, updates the revealed tiles and special tile information
				if (board[a][b] == (float)('$')) {
					*numDoubles = *numDoubles + 1;
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				} else if (board[a][b] == (float)('*')) {
					*hitEndTile = 1;
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				} else if (board[a][b] == (float)('!')) {
					*landmine = 1;
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				} else if (board[a][b] == (float)('%')) {
					*hospital = 1;
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				} else if (board[a][b] == (float)('&')) {
					*robber = 1;
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				} else if (board[a][b] == (float)('#')) {
					*charity = 1;
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				} else {
					turnScore += board[a][b];
					updateRevealedTiles(a, b, revealedTiles, numRevealedTiles);
				}
			}
			b = 0;
		}
	
	// If the range of the bomb is not larger than the board, reveals only the tiles within the bomb range
	} else {
		revealed = false;
		int j;
		int k;
		int p;
		for (j=-(size/2); j<=(size/2); j++) {
			for (k=-(size/2); k<=(size/2); k++) {
				
				// If the coordinates are outside of the board, moves on to the next row or tile
				if (bombRow+j < 0 || bombRow+j > rows-1) {
					break;
				} else if (bombCol+k < 0 || bombCol+k > cols-1) {
					continue;
				}
				
				// If the tile has already been revealed, moves on to the next tile
				for (p=0; p<=*numRevealedTiles; p++) { 
            		if (revealedTiles[p][0] == bombRow+j && revealedTiles[p][1] == bombCol+k) {
            			revealed = true;
                        continue;
                    }
            	}
				if (revealed) {
					revealed = false;
					continue;
				}
				
				// If the tile has not been previously revealed, updates the revealed tiles and special tile information
				if (board[bombRow+j][bombCol+k] == (float)('$')) {
					*numDoubles = *numDoubles + 1;
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				} else if (board[bombRow+j][bombCol+k] == (float)('!')) {
					*landmine = 1;
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				} else if (board[bombRow+j][bombCol+k] == (float)('%')) {
					*hospital = 1;
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				} else if (board[bombRow+j][bombCol+k] == (float)('&')) {
					*robber = 1;
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				} else if (board[bombRow+j][bombCol+k] == (float)('#')) {
					*charity = 1;
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				} else if (board[bombRow+j][bombCol+k] == (float)('*')) {
					*hitEndTile = 1;
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				} else {
					turnScore += board[bombRow+j][bombCol+k];
					updateRevealedTiles(bombRow+j, bombCol+k, revealedTiles, numRevealedTiles);
				}
			}
			k = -(size/2);
		}
	}
	
	return turnScore;
	
}

/**
 * exitGame
 * Finishes up the game by allowing the user to see the top entries on the scoreboard 
 * if they wish, and logs their game information to the file regardless of whether or 
 * not they chose to view the scoreboard.
 * Parameters:
 * 	float turnTime is the time taken for the current game
 * 	float turnScore is the final score of the current game
 * 	int numPlayers is the total number of players that have played
 * 	char name[] is the current player's name
 * 	float scoreBoard[][] is an array with information about each game played
 * 	char nameArray[][] is an array of each player's name
 */
void exitGame(float turnTime, float turnScore, int numPlayers, char name[20], float scoreBoard[1000][3], char nameArray[1000][20]) {
	if (turnScore < 0) {
		turnScore = 0.0;
	}
	int numTopScores;
    char seeScores[20];	
    int firstGamePlayed = readFile(scoreBoard, nameArray);
    
    // Prompts the user to view the scoreboard or not
	printf("Thank you for playing! Would you like to see the scoreboard? (y/n) ");
	scanf(" %s", &seeScores);
	printf("\n");
	while (seeScores[0] != 'n' && seeScores[0] != 'y') {
		strcpy(seeScores, "");
		printf("Enter \"y\" to see the scoreboard or \"n\" to quit the program: ");
		scanf(" %s", &seeScores);
		printf("\n");
	}
	
	// If the user chooses to view the scoreboard, prints the top entries and logs their info to the file
	if (seeScores[0] == 'y') {
		
		// If this is the first game played, simply prints their information
		if (firstGamePlayed == 1) {
				printf("\nIt looks like you're the first one on the scoreboard!\n\n");
				printf("__________________Scoreboard__________________\n");
				printf("1.  %s\n\tScore: %.2f\n\tTime: %d seconds\n\n", name, turnScore, (int)turnTime);
				logScore(1, name, turnScore, turnTime);
				
		// If it is not the first game, prompts for further input
		} else {
			printf("How many top scores would you like to view? ");
			scanf(" %d", &numTopScores);
			printf("\n");
			while (numTopScores <= 0 || numTopScores > 1000) {
				// Clears the buffer
			    while ((getchar()) != '\n'); 
			    
				printf("That is not a valid number. Please enter the number of top scores you would like to see: ");
				scanf(" %d", &numTopScores);
				printf("\n");
			}
			
			numPlayers = sortTopScores(scoreBoard);
			numPlayers++;
			while (numTopScores > numPlayers) {
			    while ((getchar()) != '\n'); 
				printf("There aren't that many scores yet! Please try again: ");
			    scanf(" %d", &numTopScores);
			}
	
			// Updates the scoreBoard with the current user's information
			int i;
			for (i=0; i<numPlayers+1; i++) {
	
				if (scoreBoard[i][0] == -1.0) {
					scoreBoard[i][0] = (float)numPlayers;
					scoreBoard[i][1] = turnScore;
					scoreBoard[i][2] = turnTime;
					strcpy(nameArray[numPlayers-1], name);
					break;
				}
			}
			
			sortTopScores(scoreBoard);
			displayTopScores(numTopScores, scoreBoard, nameArray);
			logScore(numPlayers, name, turnScore, turnTime);
		}
	
	// If the user chooses not to view the scoreboard, just logs their info to the file
	} else {
		numPlayers = sortTopScores(scoreBoard);
		
		// Updates the scoreBoard with the current user's information
		int i;
		for (i=0; i<numPlayers+1; i++) {

			if (scoreBoard[i][0] == -1.0) {
				scoreBoard[i][0] = (float)numPlayers;
				scoreBoard[i][1] = turnScore;
				scoreBoard[i][2] = turnTime;
				strcpy(nameArray[numPlayers-1], name);
				break;
			}
		}
		numPlayers = sortTopScores(scoreBoard);

		if (firstGamePlayed == 1) {
			numPlayers = 1;
		}
		logScore(numPlayers, name, turnScore, turnTime);
	}
}

/**
 * main
 * Executes the program by calling other functions. First, checks and handles the command line arguments, then gives the
 * user the option to view the scoreboard before the game begins. Afterward, the game board is created and filled,
 * and the user takes turns bombing the board until the game ends or they choose to quit. Then, the player has the option
 * to view the scoreboard again, and their game information is logged to a file.
 * Parameters:
 * 	int argc is a count of the command line arguments entered by the user. It is expected to be 4.
 *  char* argv[] contains the command line arguments. The first element is expected to be the name
 *  of the program, the second is the player's name, and the third and fourth are expected to be
 *  integers corresponding to rows and columns for the board's dimensions.
 */
void main(int argc, char* argv[]) {

        // Provides an error message and exits if there aren't the right number of command line arguments 
        if (argc != 4) {
                printf("Please provide a name and two dimensions.\n");
                exit(0);
        }

        // Provides an error message if the dimensions given are less than 10 (or not integers)
        rows = atoi(argv[2]);
        cols = atoi(argv[3]);
        if (rows < 10 || cols < 10) {
                printf("The dimensions must be at least 10x10.\n");
                exit(0);
        }

        char* name = argv[1];

        srand(time(0));
        
        
        // Prints the top n scores if the user wants to
        int numTopScores = 0;
        char seeScores[20];
        float scoreBoard[1000][3];
        char nameArray[1000][20];
        int firstGamePlayed;
        int numPlayers = 0;
        
        
        // Asks the user if they would like to view the scoreboard
        printf("\n\nWelcome to bomberman! Would you like to see the scoreboard? (y/n) ");
		scanf(" %s", &seeScores);
		printf("\n");
		while (seeScores[0] != 'n' && seeScores[0] != 'y') {
			strcpy(seeScores, "");
			printf("Enter \"y\" to see the scoreboard or \"n\" to start playing right away: ");
			scanf(" %s", &seeScores);
			printf("\n");
		}
		// If the user chooses to view the scoreboard, reads it from the file and prints the top specified 
		// scores to the console
		if (seeScores[0] == 'y') {
			int firstGamePlayed = readFile(scoreBoard, nameArray);
			if (firstGamePlayed == 1) {
				printf("You're the first to play the game, so there is no one else on the leaderboard.\n\n");
			} else {
				printf("How many top scores would you like to view? ");
				scanf(" %d", &numTopScores);
				printf("\n");
				while (numTopScores < 0 || numTopScores > 1000) {
	    			// Clears the buffer
	    		    while ((getchar()) != '\n'); 
	    		    
	    			printf("That is not a valid number. Please enter the number of top scores you would like to see: ");
	    			scanf(" %d", &numTopScores);
	    			printf("\n");
	    		}
				int numPlayers = sortTopScores(scoreBoard);
				while (numTopScores > numPlayers) {
	    		    while ((getchar()) != '\n'); 
					printf("There aren't that many scores yet! Please try again: ");
	    		    scanf(" %d", &numTopScores);
				}
				displayTopScores(numTopScores, scoreBoard, nameArray);
			}
		}
		
		strcpy(seeScores, "");
        numTopScores = 0;
        numPlayers++;
        
        // Starts the timer
        time_t start = time(0);

        // Sets up the game to begin
        float board[rows][cols];
        int lives = 3;
        float score = 0.0;
        float turnScore = 0.0;
        int bombs;
        
        if (rows >= cols) {
        	bombs = rows/3;
        } else {
        	bombs = cols/3;
        }
        
        initializeGame(board);
       
        int bombRow;
        int bombCol;
        int numDoubles = 0;
        int numRevealedTiles=0;
        int hitEndTile = 0;
        int revealedTiles[rows*cols][2];
        char contInput[20];
        
        
        int i;
        for (i=0; i<=rows*cols-1; i++) {
        	revealedTiles[i][0] = -1;
        	revealedTiles[i][1] = -1;
        }
        
        displayGame(board, lives, score, bombs, revealedTiles, numRevealedTiles, true);
        
        displayGame(board, lives, score, bombs, revealedTiles, numRevealedTiles, false);


        // Allows the user to take turns bombing the board
        bool quit = false;
        while (quit == false) {
        	
        	bombRow = -1;
        	bombCol = -1;
        	
        	// Allows the user to quit if they want to
        	printf("Would you like to continue playing? (y/n) ");
    		scanf(" %s", &contInput);
    		printf("\n");
    		while (contInput[0] != 'n' && contInput[0] != 'y') {
    			strcpy(contInput, "");
    			printf("Please enter \"y\" to continue playing or \"n\" to quit the game: ");
    			scanf(" %s", &contInput);
    			printf("\n");
    		}
    		if (contInput[0] == 'n') {
    			quit = true;
    			continue;
    		}
			strcpy(contInput, "");
    		
			// Continues the turn if the user does not want to quit
    		printf("Enter bomb position: ");
    		scanf("%d %d", &bombRow, &bombCol);
    		
    		while (bombRow < 0 || bombRow > rows-1 || bombCol < 0 || bombCol > cols-1) {
    			// Clears the buffer
    		    while ((getchar()) != '\n'); 
    		    
    			printf("Those were not valid coordinates. Please enter bomb position: ");
    			scanf("%d %d", &bombRow, &bombCol);
    			printf("\n");
    		}
    		
    		printf("\n\n");
    		int landmine;
    		int hospital;
    		int robber;
    		int charity;
    		
    		// Bombs the board and calculates the total score
    		turnScore = bomb(board, bombRow, bombCol, &numDoubles, revealedTiles, &numRevealedTiles, &hitEndTile, &landmine, &hospital, &robber, &charity);
    		
    		score = calculateScore(score, turnScore);
    		    		
    		bombs-=1;
    		
    		
    		// Special tile feature implementation
    		if (landmine == 1) {
    			printf("Ouch! You hit a landmine. -1 life\n");
    			lives-=1;
    		}
    		if (hospital == 1) {
    			printf("You found a hospital! +1 life\n");
    			lives+=1;

    		}
    		if (robber == 1) {
    			printf("Robbers got you! -1 bomb\n");
    			bombs-=1;

    		}
    		if (charity == 1) {
    			printf("A charity was feeling generous today. +1 bomb\n");
    			bombs+=1;

    		}
    		
    		if (numDoubles>0) {
    			printf("Bang!! Your bomb range is doubled\n");
    		}
    		
    		
         	displayGame(board, lives, score, bombs, revealedTiles, numRevealedTiles, false);
    		
         	landmine = 0;
         	hospital = 0;
         	robber = 0;
         	charity = 0;
         	
         	
         	// Ends the game if one of the following three things happen
    		if (hitEndTile == 1) {
    			printf("Congratulations! You found the exit!\n\n");
    			quit = true;
    		}
    		if (lives <= 0) {
    			printf("Uh oh, you ran out of lives!\n\n");
    			quit = true;
    		}
    		
    		if (bombs == 0) {
    			printf("Uh oh, you ran out of bombs!\n\n");
    			quit = true;
    		} 

        }
        
        // Ends the timer and calculates the time taken
        time_t end = time(0);
		int timeTaken = difftime(end, start);
		
		// Finishes the game
		printf("\n");
		exitGame((float)timeTaken, score, numPlayers, name, scoreBoard, nameArray); 	
}
