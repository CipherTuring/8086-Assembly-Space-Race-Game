STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	;window properties
	WINDOW_WIDTH DW 140h            					 			;THE WIDTH OF THE WINDOW (320 PIXELS)
	WINDOW_HEIGHT DW 0C8h           					 			;THE HEIGHT OF THE WINDOW (200 PIXELS)
	WINDOW_BOUND DW 3               					 			;VARIABLE USED TO CHECK COLLISIONS EARLY
	
	;text properties 
	TEXT_PLAYER_ONE_POINTS DB '0', '$'   				 			;text with the player one points
	TEXT_PLAYER_TWO_POINTS DB '0', '$'   				 			;text with the player two points
	TEXT_GAME_OVER_TITLE DB 'GAME OVER', '$'             			;text with the game over menu title 
	TEXT_GAME_OVER_WINNER DB 'Player 0 won', '$'         			; text with the winner
	TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to play again', '$' 		; text with the game over 'play again' message
	TEXT_MOTIVATIONAL_MESSAGE DB 'You can do it!!!', '$'
	TEXT_GAME_OVER_MAIN_MENU DB 'Press E to exit to main menu', '$' ; text with the game over 'main menu' message
	TEXT_MAIN_MENU_TITLE DB 'MAIN MENU', '$' 						;text with the main menu title
	TEXT_MAIN_MENU_SINGLEPLAYER DB 'SINGLEPLAYER - S KEY', '$'      ;text with the singleplayer message
	TEXT_MAIN_MENU_MULTIPLAYER DB 'MULTIPLAYER - M KEY', '$' 		;text with the multiplayer message
	TEXT_MAIN_MENU_EXIT DB 'EXIT GAME - E KEY', '$' 				;text with the exit game message 
	TEXT_DRAW_MESSAGE DB 'IT IS A DRAW!', '$'       				;message if the games ends with a draw (two ships reaches the same score)
	
	;game properties
	TIME_AUX DB 0                    					 ;VARIABLE USED WHEN CHECKING IF THE TIME HAS CHANGED
	GAME_ACTIVE DB 1                                     ;is the game active? (1 -> Yes, 0 -> No (game over))
	WINNER_INDEX DB 0                                    ;the index of the winner (1 -> player one, 2 -> player two)
	CURRENT_SCENE DB 0                                   ;the index of the current scene (0 -> main menu, 1 -> game)
	EXITING_GAME DB 0                                    ;the index used to exit the whole game 
	AI_MODE DB 0                                         ;the ai mode index (0 -> multiplayer (human vs human), 1 = Singleplayer (human vs cpu))
	CPU_TIMER DB 0                                       ;counter to regulate the cpu velocity
	
	;clock_variables
	GAME_TIMER_SEC DB 30                                 
	FRAMES_COUNTER DB 0                                  ;auxiliar counter to determine de seconds
	
	;meteor properties
	METEOR_X DW 0Ah, 60h, 0B0h, 40h, 90h, 0A0h,136h                ;X POSITION (COLUMN) OF THE METEOR
	METEOR_Y DW 07h, 40h, 65h, 90h, 09Bh, 0A5h, 0AAh               ;Y POSITION (LINE) OF THE METEOR
	
	METEOR_VELOCITY_X DW 03h, 05h, 02h, 04h, 06h, 06h ,06h         ;X (HORIZONTAL) VELOCITY OF THE METEOR
	
	METEOR_SIZE_X DW 03h            					 		   ;METEOR LENGTH SIZE
	METEOR_SIZE_Y DW 01h            					 		   ;METOR WIDTH SIZE
	
	NUM_METEORS DW 7                					 		   ;TOTAL NUMBER OF METEORS
	
	
	;ships properties
	;----------------
	;each byte represents a row
	;each bit represents a colored pixel. 1 = colored pixel, 0 = black pixel
	SHIP_SPRITE DB 18h              ; 00011000b
				DB 3Ch              ; 00111100b
	            DB 7Eh              ; 01111110b
				DB 7Eh              ; 01111110b
				DB 7Eh              ; 01111110b
				DB 0FFh             ; 11111111b
				DB 0A5h             ; 10100101b
				DB 00h              ; 00000000b
	
	SHIP1_X DW 64
	SHIP1_Y DW 180
	SHIP1_POINTS DB 0               ;represents the score of the ship1 (player 1)
	
	SHIP1_DEFAULT_X DW 64
	SHIP1_DEFAULT_Y DW 197
	
	SHIP2_X DW 218
	SHIP2_Y DW 180
	SHIP2_POINTS DB 0              ;represents the score of the ship2 (player 2)
	
	SHIP2_DEFAULT_X DW 218
	SHIP2_DEFAULT_Y DW 197
	
	SHIP_WIDTH DW 08h
	SHIP_HEIGHT DW 08h
	SHIP_VELOCITY DW 05h
	
	;sound properties
	SOUND_TIMER DB 0               ;this variable is used to synchronize the sound with the game time
								   ;0 = silent, >0 = sound
DATA ENDS

CODE SEGMENT PARA 'CODE'
	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK ; ASSUME AS CODE, DATA AND STACK SEGMENTS THE RESPECTIVE REGISTERS
	PUSH DS                         ; PUSH TO THE STACK THE DS SEGMENT
	SUB AX, AX                      ; CLEAN THE AX REGISTERS
	PUSH AX
	MOV AX, DATA                    ; SAVE ON THE AX REGISTER THE CONTENTS OF THE DATA SEGMENT
	MOV DS, AX                      ; SAVE ON THE DS SEGMENT THE CONTENTS OF AX
	POP AX                          ; RELEASE THE TOP ITEM FROM THE STACK TO THE AX REGISTER
	POP AX                          ; RELEASE THE TOP ITEM FROM THE STACK TO THE AX REGISTER
	
	
	
		CALL CLEAR_SCREEN           ; SET ALL THE VIDEO CONFIGURATIONS
		
		CHECK_TIME:
			
			CMP EXITING_GAME, 01h
			JE START_EXIT_PROCESS
			
			CMP CURRENT_SCENE, 00h
			JE SHOW_MAIN_MENU
			
			CMP GAME_ACTIVE, 00h
			JE SHOW_GAME_OVER
			
			MOV AH, 2Ch             ; GET THE SYSTEM TIME
			INT 21h                 ; CH = HOUR, CL = MINUTE, DH = SECOND, DL = 1/100 SECONDS
  
			CMP DL, TIME_AUX        ; IS THE CURRENT TIME EQUAL TO THE PREVIOUS ONE (TIME_AUX)?
			JE CHECK_TIME           ; IF IT IS THE SAME, CHECK AGAIN
			                        ; IF IT'S DIFFERENT, THEN DRAW, MOVE, ETC.
			
			MOV TIME_AUX, DL        ; UPDATE TIME
			
			CALL CLEAR_SCREEN
			
			CALL UPDATE_GAME_TIMER  ;update the game clock and check if the game needs to end
			CALL DRAW_TIMER_BAR     ;draw the timer bar
			
	;  	    --- LOOP OF METEORS ---
			MOV SI, 0				;we start at 0 index (first meteor)
			MOV CX, NUM_METEORS     ;number of loops = number of meteors
			
			METEORS_LOOP:
				PUSH CX				;save the initial value of the counter (num of meteors) in the stack
				
				CALL MOVE_METEOR      ;move the current meteor [SI]
				CALL DRAW_METEOR      ;draw the current meteor [SI]
				CALL CHECK_COLLISIONS ;check if the ship has a collition with the current meteor [SI]
				
				ADD SI, 2           ;we go to the next meteor (we add 2 because the data type is DW)
				POP CX              ;we recover the value of the counter
				LOOP METEORS_LOOP   ;repeat until CX becomes 0
	;       ------------------------
	
			CALL MOVE_SHIPS
			CALL DRAW_SHIPS
			
			CALL UPDATE_SOUND
			
			CALL DRAW_UI
			
			JMP CHECK_TIME          ; AFTER EVERYTHING CHECKS TIME AGAIN
			
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU
				JMP CHECK_TIME
			
			SHOW_MAIN_MENU:
				CALL DRAW_MAIN_MENU
				JMP CHECK_TIME
			
			START_EXIT_PROCESS:
				CALL CONCLUDE_EXIT_GAME
		RET
	MAIN ENDP
	
	MOVE_METEOR PROC NEAR
		MOV AX, METEOR_VELOCITY_X[SI] 	        ;use the velocity of the current meteor     
		ADD METEOR_X[SI], AX                    ;move horizontally the current meteor
		
		MOV AX, WINDOW_BOUND
		CMP METEOR_X[SI], AX
		JL NEG_VELOCITY_X             		    ;METEOR_X[SI] < 0 + WINDOW_BOUND (Y -> COLLIDED)
		
		MOV AX, WINDOW_WIDTH
		SUB AX, METEOR_SIZE_X
		SUB AX, WINDOW_BOUND
		CMP METEOR_X[SI], AX          			;METEOR_X[SI] > WINDOW_WIDTH - METEOR_SIZE_X - WINDOW_BOUND (Y -> COLLIDED) 
		JG NEG_VELOCITY_X
		
		RET
		
		NEG_VELOCITY_X:
			NEG METEOR_VELOCITY_X[SI]           ;negate the velocity of the current meteor 
			                                    ;(METEOR_VELOCITY_X[SI] = - METEOR_VELOCITY_X)
			RET
			
	MOVE_METEOR ENDP
	
MOVE_SHIPS PROC NEAR
    ;check if a key is being pressed
    MOV AH, 01h
    INT 16h
    
    JNZ READ_KEY            ;if a key has been pressed, read it again
    JMP CHECK_AI_LOGIC      ;if not, check the AI
    
    READ_KEY:
        MOV AH, 00h
        INT 16h
    
    ;ship 1 (human player)
    CMP AL, 'w'
    JE JMP_LEFT_UP     
    CMP AL, 'W'
    JE JMP_LEFT_UP
    CMP AL, 's'
    JE JMP_LEFT_DOWN
    CMP AL, 'S'
    JE JMP_LEFT_DOWN
    
    ;ship 2 (human player)
    ;first, we check if AI mode is active
    CMP AI_MODE, 1
    JE JMP_TO_AI_LOGIC  ;if AI mode (singleplayer mode) is active, then ignore the keys that moves ship2 
    
    CMP AL, 'o'
    JE JMP_RIGHT_UP
    CMP AL, 'O'
    JE JMP_RIGHT_UP
    CMP AL, 'l'
    JE JMP_RIGHT_DOWN
    CMP AL, 'L'
    JE JMP_RIGHT_DOWN
    
    ;if does not detects the keys of ship2, check if the AI ship needs to move
    JMP CHECK_AI_LOGIC

	;jump to the ship movements
    JMP_LEFT_UP:    JMP MOVE_LEFT_SHIP_UP
    JMP_LEFT_DOWN:  JMP MOVE_LEFT_SHIP_DOWN
    JMP_RIGHT_UP:   JMP MOVE_RIGHT_SHIP_UP
    JMP_RIGHT_DOWN: JMP MOVE_RIGHT_SHIP_DOWN
    
	;checks the AI logic
	JMP_TO_AI_LOGIC: JMP CHECK_AI_LOGIC
    
	;implements the AI logic
    CHECK_AI_LOGIC:
        CMP AI_MODE, 1
        JNE JMP_EXIT_SHIP   ;if AI mode is not active, just exit the procedure
        
        INC CPU_TIMER
        CMP CPU_TIMER, 3
        
        ;check the cpu timer
        JGE AI_MOVE_NOW        ;if timer >= 3, move
        JMP EXIT_SHIP_MOVEMENT ;if not, exit procedure
        
        AI_MOVE_NOW:
            MOV CPU_TIMER, 0
            JMP MOVE_RIGHT_SHIP_UP ;when the AI moves, it moves the right ship (just up)

    JMP_EXIT_SHIP: JMP EXIT_SHIP_MOVEMENT

    ;ship movements
	
	;left ship
    MOVE_LEFT_SHIP_UP:
        MOV AX, SHIP_VELOCITY
        SUB SHIP1_Y, AX
        MOV AX, 00h
        CMP SHIP1_Y, AX
        JL RESET_SHIP_LEFT_TOP
        JMP EXIT_SHIP_MOVEMENT
            
        RESET_SHIP_LEFT_TOP:
            INC SHIP1_POINTS
            CALL RESET_LEFT_SHIP_POSITION
            CALL UPDATE_TEXT_PLAYER_ONE_POINTS
            CMP SHIP1_POINTS, 05h
            JGE GAME_OVER_CALLER
            JMP EXIT_SHIP_MOVEMENT
            
    MOVE_LEFT_SHIP_DOWN:
        MOV AX, SHIP_VELOCITY
        ADD SHIP1_Y, AX
        MOV AX, WINDOW_HEIGHT
        SUB AX, WINDOW_BOUND
        SUB AX, SHIP_HEIGHT
        CMP SHIP1_Y, AX
        JG FIX_LEFT_BOTTOM
        JMP EXIT_SHIP_MOVEMENT
        FIX_LEFT_BOTTOM:
            MOV SHIP1_Y, AX
            JMP EXIT_SHIP_MOVEMENT

	;right ship
    MOVE_RIGHT_SHIP_UP:
        MOV AX, SHIP_VELOCITY
        SUB SHIP2_Y, AX
        MOV AX, 00h
        CMP SHIP2_Y, AX
        JL RESET_SHIP_RIGHT_TOP
        JMP EXIT_SHIP_MOVEMENT
            
        RESET_SHIP_RIGHT_TOP:
            INC SHIP2_POINTS
            CALL RESET_RIGHT_SHIP_POSITION
            CALL UPDATE_TEXT_PLAYER_TWO_POINTS
            CMP SHIP2_POINTS, 05h
            JGE GAME_OVER_CALLER
            JMP EXIT_SHIP_MOVEMENT

    MOVE_RIGHT_SHIP_DOWN:
        MOV AX, SHIP_VELOCITY
        ADD SHIP2_Y, AX
        MOV AX, WINDOW_HEIGHT
        SUB AX, WINDOW_BOUND
        SUB AX, SHIP_HEIGHT
        CMP SHIP2_Y, AX
        JG FIX_RIGHT_BOTTOM
        JMP EXIT_SHIP_MOVEMENT
        FIX_RIGHT_BOTTOM:
            MOV SHIP2_Y, AX
            JMP EXIT_SHIP_MOVEMENT
	
	;if a ship reaches the necessary points, the game ends
    GAME_OVER_CALLER:
        CALL GAME_OVER
        RET

    EXIT_SHIP_MOVEMENT: 
        RET
MOVE_SHIPS ENDP
	
	DRAW_METEOR PROC NEAR
		MOV CX, METEOR_X[SI]                    ;set the initial column (X) of the current meteor
		MOV DX, METEOR_Y[SI]                    ;set the initial line (Y) of the current meteor
		
		DRAW_METEOR_HORIZONTAL:
			MOV AH, 0Ch                         ;set the configuration to write a pixel
			MOV AL, 0Fh                         ;choose white as the color of the pixel
			MOV BH, 00h                         ;set the page number
			INT 10h                 			;execute the configuration
			
			INC CX                  			;CX = CX + 1
			MOV AX, CX              			;CX - METEOR_X  > METEOR_SIZE_X (Y -> WE GO TO THE NEXT LINE, N -> WE GO TO THE NEXT COLUMN)
			SUB AX, METEOR_X[SI]
			CMP AX, METEOR_SIZE_X
			JNG DRAW_METEOR_HORIZONTAL
			
			MOV CX, METEOR_X[SI]        		;the CX register goes back to the initial column of the current meteor
			INC DX                  			;advance to the next line 
			
		    MOV AX, DX              			;DX - METEOR_Y > METEOR_SIZE_Y (Y -> WE EXIT THE PROCEDURE, N -> WE CONTINUE TO THE NEXT LINE
		    SUB AX, METEOR_Y[SI]
			CMP AX, METEOR_SIZE_Y
			JNG DRAW_METEOR_HORIZONTAL
			
		RET
	DRAW_METEOR ENDP
	
	DRAW_SHIPS PROC NEAR
		; DRAW LEFT SHIP
		MOV CX, SHIP1_X
		MOV DX, SHIP1_Y
		MOV BL, 0Fh
		LEA SI, SHIP_SPRITE
		CALL DRAW_SPRITE
		
		; DRAW RIGHT SHIP
		MOV CX, SHIP2_X
		MOV DX, SHIP2_Y
		MOV BL, 0Fh
		LEA SI, SHIP_SPRITE
		CALL DRAW_SPRITE
	    
		RET
	DRAW_SHIPS ENDP
	
	DRAW_SPRITE PROC NEAR
		PUSH CX                     ;stores the original x position of the ship 
		PUSH DX                     ;stores the original y position of the ship
		PUSH SI                     ;store the sprite pointer
		
		MOV DI, 0                   ; row counter (0 to 7)
		
		ROW_LOOP:
			MOV AL, [SI]            ;store the byte from the design of the actual row
			PUSH CX                 ;store x to the top of the stack 
			
			MOV AH, 8               ;bit counter (8 pixels per row)
			
			PIXEL_LOOP:
				SHL AL, 1           ;shift 1 bit to the left towards the Carry Flag (CF)
				JNC SKIP_PIXEL      ; IF THE MSB IS 0 (NO CARRY), JUMP (DO NOT DRAW the pixel)
									; if the MSB is 1, draw the pixel
				
				PUSH AX             ;to avoid conflicts with INT 10h (because AL is supposed to store the pixel color)
				MOV AH, 0Ch         ;sub-function to draw a pixel
				MOV AL, BL          ;set the pixel color (previously stored in BL)
				MOV BH, 00h         ;set the page number
				INT 10h
				POP AX              ;restore AX (restore previous values stored in both AH and AL)
				
			SKIP_PIXEL:
				INC CX              ;move to the next pixel (on the right side)
				DEC AH              ;substract one to the bit counter
				JNZ PIXEL_LOOP
			
			POP CX                  ;restore the x position to draw the next row
			INC DX                  ;go to the next row (y position increments in one)
			INC SI                  ;move to the next byte direction of SHIP_SPRITE 
			INC DI                  ;increment the row counter
			CMP DI, 8               ;have been done 8 rows?
			JNE ROW_LOOP
		
		POP SI
		POP DX
		POP CX			
		RET                         
	DRAW_SPRITE ENDP
	
	DRAW_UI PROC NEAR	
;		draw the points of the left player (player one)
		
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 04h						  ;set row
		MOV DL, 06h   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_PLAYER_ONE_POINTS    ;give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h                           ;print the string
		
;   	draw the points of the right player (player two)

		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 04h						  ;set row
		MOV DL, 1Fh   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_PLAYER_TWO_POINTS    ;give DX a pointer to the string TEXT_PLAYER_TWO_POINTS
		INT 21h                           ;print the string
		
		RET
	DRAW_UI ENDP
	
	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
		XOR AX, AX
		MOV AL, SHIP1_POINTS         ;given for example that P1 -> 2 points => AL, 2 
		
		;before printing to the screen, we need to convert the decimal value to teh ascii code character
		;we can do this by adding 30H (number to ASCII)
		;and by substracting 30h (ASCII to number)
		
		ADD AL, 30h
		MOV [TEXT_PLAYER_ONE_POINTS], AL
		
		RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
	
	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
		XOR AX, AX
		MOV AL, SHIP2_POINTS         ;given for example that P1 -> 2 points => AL, 2 
		
		;before printing to the screen, we need to convert the decimal value to the ascii code character
		;we can do this by adding 30H (number to ASCII)
		;and by substracting 30h (ASCII to number)
		
		ADD AL, 30h
		MOV [TEXT_PLAYER_TWO_POINTS], AL
	
		RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
	
	RESET_LEFT_SHIP_POSITION PROC NEAR
		MOV AX, SHIP1_DEFAULT_X
		MOV SHIP1_X, AX
		
		MOV AX, SHIP1_DEFAULT_Y
		MOV SHIP1_Y, AX
		
		RET
	RESET_LEFT_SHIP_POSITION ENDP
	
	RESET_LEFT_SHIP_POSITION_AFTER_COLLIDE PROC NEAR
		CALL PLAY_CRASH_SOUND
		
		MOV AX, 64
		MOV SHIP1_X, AX
		
		MOV AX, 180
		MOV SHIP1_Y, AX
		
		RET
	RESET_LEFT_SHIP_POSITION_AFTER_COLLIDE ENDP
	
	RESET_RIGHT_SHIP_POSITION PROC NEAR
		MOV AX, SHIP2_DEFAULT_X
		MOV SHIP2_X, AX
		
		MOV AX, SHIP2_DEFAULT_Y
		MOV SHIP2_Y, AX
		
		RET
	RESET_RIGHT_SHIP_POSITION ENDP
	
	RESET_RIGHT_SHIP_POSITION_AFTER_COLLIDE PROC NEAR
		CALL PLAY_CRASH_SOUND
		
		MOV AX, 218
		MOV SHIP2_X, AX
		
		MOV AX, 180
		MOV SHIP2_Y, AX
		
		RET
	RESET_RIGHT_SHIP_POSITION_AFTER_COLLIDE ENDP
	
	CHECK_COLLISIONS PROC NEAR
	
		;check if the left ship collides with a meteor
		;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		;METEOR_X + METEOR_SIZE_X > SHIP1_X && METEOR_X < SHIP1_X + SHIP_WIDTH 
		;&& METEOR_Y + METEOR_SIZE_Y > SHIP1_Y && METEOR_Y < SHIP1_Y + SHIP_HEIGHT
			
		;METEOR_X + METEOR_SIZE_X > SHIP1_X
		MOV AX, METEOR_X[SI]
		ADD AX, METEOR_SIZE_X
		CMP AX, SHIP1_X
		JNG CHECK_RIGHT_SHIP_COLLISION
			
		;METEOR_X < SHIP1_X + SHIP_WIDTH
		MOV AX, SHIP1_X
		ADD AX, SHIP_WIDTH
		CMP AX, METEOR_X[SI]
		JNG CHECK_RIGHT_SHIP_COLLISION
			
		;METEOR_Y + METEOR_SIZE_Y > SHIP1_Y
		MOV AX, METEOR_Y[SI]
		ADD AX, METEOR_SIZE_Y
		CMP AX, SHIP1_Y
		JNG CHECK_RIGHT_SHIP_COLLISION
			
		;METEOR_Y < SHIP1_Y + SHIP_HEIGHT
		MOV AX, SHIP1_Y
		ADD AX, SHIP_HEIGHT
		CMP AX, METEOR_Y[SI]
		JNG CHECK_RIGHT_SHIP_COLLISION
			
		;if it reaches this point, the left ship is colliding with a meteor
		CALL RESET_LEFT_SHIP_POSITION_AFTER_COLLIDE
		RET
		
		CHECK_RIGHT_SHIP_COLLISION:
			;check if the right side ship collides with a meteor
			;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
			;METEOR_X + METEOR_SIZE_X > SHIP2_X && METEOR_X < SHIP2_X + SHIP_WIDTH 
			;&& METEOR_Y + METEOR_SIZE_Y > SHIP2_Y && METEOR_Y < SHIP2_Y + SHIP_HEIGHT
				
			;METEOR_X + METEOR_SIZE_X > SHIP2_X
			MOV AX, METEOR_X[SI]
			ADD AX, METEOR_SIZE_X
			CMP AX, SHIP2_X
			JNG EXIT_CHECK_COLLISIONS_PROCEDURE
				
			;METEOR_X < SHIP2_X + SHIP_WIDTH
			MOV AX, SHIP2_X
			ADD AX, SHIP_WIDTH
			CMP AX, METEOR_X[SI]
			JNG EXIT_CHECK_COLLISIONS_PROCEDURE
				
			;METEOR_Y + METEOR_SIZE_Y > SHIP2_Y
			MOV AX, METEOR_Y[SI]
			ADD AX, METEOR_SIZE_Y
			CMP AX, SHIP2_Y
			JNG EXIT_CHECK_COLLISIONS_PROCEDURE
				
			;METEOR_Y < SHIP2_Y + SHIP_HEIGHT
			MOV AX, SHIP2_Y
			ADD AX, SHIP_HEIGHT
			CMP AX, METEOR_Y[SI]
			JNG EXIT_CHECK_COLLISIONS_PROCEDURE
			
			;if it reaches this point, the right ship is colliding with a meteor
			CALL RESET_RIGHT_SHIP_POSITION_AFTER_COLLIDE
			RET
			
			EXIT_CHECK_COLLISIONS_PROCEDURE:
				RET
	CHECK_COLLISIONS ENDP
	
	PLAY_CRASH_SOUND PROC NEAR
		PUSH AX
		
		;set the frequency
		MOV AL, 182
		OUT 43h, AL
		MOV AX, 4000h        ;about 72HZ (low-pitched sound)
		OUT 42h, AL
		MOV AL, AH
		OUT 42h, AL
		
		;turn on the speaker
		IN AL, 61h
		OR AL, 03h
		OUT 61h, AL
		
		;set the duration of the sound
		MOV SOUND_TIMER, 5  
		
		POP AX
		RET
	PLAY_CRASH_SOUND ENDP
	
	UPDATE_SOUND PROC NEAR
		;check if the sound is being played 
		CMP SOUND_TIMER, 0
		JE EXIT_UPDATE_SOUND    ;if it is 0, it means that there is no sound being played
		                        ;exit from the procedure 
		
		;if the value is greater than 0, we start decreasing the value by one
		DEC SOUND_TIMER
		
		;we check again the value, it is 0?
		;yes -> turn off the speaker
		;no  -> exit from the procedure
		CMP SOUND_TIMER, 0
		JNE EXIT_UPDATE_SOUND
		
		;turn off the speaker
		IN AL, 61h
		AND AL, 0FCh             ;turns in 0 the bits "0" and "1"
		OUT 61h, AL
		
		EXIT_UPDATE_SOUND:
			RET
	UPDATE_SOUND ENDP
	
	GAME_OVER PROC NEAR
		CMP  SHIP1_POINTS, 05h        ;check wich player has 5 or more points
		JNL  WINNER_IS_PLAYER_ONE     ;if the player one has not less than 5 points, is the winner
		JMP WINNER_IS_PLAYER_TWO      ;if not, the player two is the winner
		
		WINNER_IS_PLAYER_ONE:
			MOV WINNER_INDEX, 01h     ;update the winner index with the player one index
			JMP CONTINUE_GAME_OVER
		WINNER_IS_PLAYER_TWO:
			MOV WINNER_INDEX, 02h         ;update the winner index with the player two index
			JMP CONTINUE_GAME_OVER
		
		CONTINUE_GAME_OVER:
			CALL GAME_OVER_ROUTINE
			RET
	GAME_OVER ENDP
	
	
	DRAW_GAME_OVER_MENU PROC NEAR
		
		CALL CLEAR_SCREEN                 ;clear the screen before displaying the menu
	
; 		shows the menu title	
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 04h						  ;set row
		MOV DL, 04h   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_GAME_OVER_TITLE      ;give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h                           ;print the string

;		check if draw (index 3 = draw)
		CMP WINNER_INDEX, 03h
		JE PRINT_DRAW_MSG
		
;	   shows the winner
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 06h						  ;set row
		MOV DL, 04h   					  ;set column
		INT 10h							  ;execute the configuration
		
		CALL UPDATE_WINNER_TEXT
		
		MOV AH, 09h                        ;write string to standard output
		LEA DX, TEXT_GAME_OVER_WINNER     ;give DX a pointer to the string TEXT_GAME_OVER_WINNER
		INT 21h                           ;print the string
		
		JMP PRINT_OPTIONS
		
		PRINT_DRAW_MSG:
			MOV AH, 02h                     
            MOV BH, 00h                     
            MOV DH, 06h                     
            MOV DL, 04h                     
            INT 10h 
            MOV AH, 09h
            LEA DX, TEXT_DRAW_MESSAGE
            INT 21h
		
		PRINT_OPTIONS:
	;	   shows the play again message
			MOV AH, 02h						  ;set cursor position
			MOV BH, 00h						  ;set page number
			MOV DH, 08h						  ;set row
			MOV DL, 04h   					  ;set column
			INT 10h							  ;execute the configuration
			
			MOV AH, 09h                       ;write string to standard output
			LEA DX, TEXT_GAME_OVER_PLAY_AGAIN  ;give DX a pointer to the string TEXT_GAME_OVER_PLAY_AGAIN
			INT 21h                           ;print the string

	;	   shows the main menu message
			MOV AH, 02h						  ;set cursor position
			MOV BH, 00h						  ;set page number
			MOV DH, 0Ah						  ;set row
			MOV DL, 04h   					  ;set column
			INT 10h							  ;execute the configuration
			
			MOV AH, 09h                       ;write string to standard output
			LEA DX, TEXT_GAME_OVER_MAIN_MENU  ;give DX a pointer to the string TEXT_GAME_OVER_MAIN_MENU
			INT 21h                           ;print the string

	;	   displays a motivational message to the player
			MOV AH, 02h						  ;set cursor position
			MOV BH, 00h						  ;set page number
			MOV DH, 0Fh						  ;set row
			MOV DL, 04h   					  ;set column
			INT 10h							  ;execute the configuration
			
			MOV AH, 09h                       ;write string to standard output
			LEA DX, TEXT_MOTIVATIONAL_MESSAGE     ;give DX a pointer to the string TEXT_MOTIVATIONAL_MESSAGE
			INT 21h                           ;print the string

		WAIT_GO_KEY:
	;	    waits for a key press
			MOV AH, 00h
			INT 16h

	;	   if the key is either 'R' or 'r', restart the game
		   CMP AL, 'R'
		   JE RESTART_GAME
		   CMP AL, 'r'
		   JE RESTART_GAME

	;	   if the key is either 'E' or 'e', exit to main menu
		   CMP AL, 'E'
		   JE EXIT_TO_MAIN_MENU
		   CMP AL, 'e'
		   JE EXIT_TO_MAIN_MENU
		   JMP WAIT_GO_KEY
	   
	   RESTART_GAME:
			XOR AX, AX
			
			MOV AX, 64
			MOV SHIP1_X, AX
			
			MOV AX, 180
			MOV SHIP1_Y, AX
			
			MOV AX, 218
			MOV SHIP2_X, AX
			
			MOV AX, 180
			MOV SHIP2_Y, AX
			
			;reset points
			MOV SHIP1_POINTS, 0
			MOV SHIP2_POINTS, 0
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS
			
			;reset time
			MOV GAME_TIMER_SEC, 30
			MOV FRAMES_COUNTER, 0
			
			;activate game
			MOV GAME_ACTIVE, 01h
			RET
		
		EXIT_TO_MAIN_MENU:
			MOV GAME_ACTIVE, 00h
			MOV CURRENT_SCENE, 00h  
			RET
	DRAW_GAME_OVER_MENU ENDP	
	
	DRAW_MAIN_MENU PROC NEAR
		CALL CLEAR_SCREEN
;	   shows the menu title
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 04h						  ;set row
		MOV DL, 04h   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_MAIN_MENU_TITLE      ;give DX a pointer 
		INT 21h                           ;print the string

;	   shows the singleplayer menu
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 06h						  ;set row
		MOV DL, 04h   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_MAIN_MENU_SINGLEPLAYER     ;give DX a pointer 
		INT 21h 

;	   shows the multiplayer option
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 08h						  ;set row
		MOV DL, 04h   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_MAIN_MENU_MULTIPLAYER     ;give DX a pointer 
		INT 21h 		

;	   shows the exit message
		MOV AH, 02h						  ;set cursor position
		MOV BH, 00h						  ;set page number
		MOV DH, 0Ah						  ;set row
		MOV DL, 04h   					  ;set column
		INT 10h							  ;execute the configuration
		
		MOV AH, 09h                       ;write string to standard output
		LEA DX, TEXT_MAIN_MENU_EXIT     ;give DX a pointer 
		INT 21h 

		MAIN_MENU_WAIT_FOR_KEY:
	;	    waits for a key press
			MOV AH, 00h
			INT 16h

	;	   if the key is either 'E' or 'e', start singleplayer mode
		   CMP AL, 'S'
		   JE START_SINGLEPLAYER
		   CMP AL, 's'
		   JE START_SINGLEPLAYER
		   

	;	   if the key is either 'M' or 'm', start multiplayer mode
		   CMP AL, 'M'
		   JE START_MULTIPLAYER
		   CMP AL, 'm'
		   JE START_MULTIPLAYER
		   

	;	   if the key is either 'E' or 'e', exit game
		   CMP AL, 'E'
		   JE JMP_EXIT_GAME
		   CMP AL, 'e'
		   JE JMP_EXIT_GAME
		   
		   JMP MAIN_MENU_WAIT_FOR_KEY
		
		JMP_EXIT_GAME:
			JMP EXIT_GAME
		
		START_SINGLEPLAYER:
			
			;restart the ships positions
			XOR AX, AX
		
			MOV AX, 64
			MOV SHIP1_X, AX
			
			MOV AX, 180
			MOV SHIP1_Y, AX
			
			MOV AX, 218
			MOV SHIP2_X, AX
			
			MOV AX, 180
			MOV SHIP2_Y, AX
				
			MOV AI_MODE, 01h                       ;activates the AI mode         
			MOV CURRENT_SCENE, 01h
			MOV GAME_ACTIVE, 01h
			
			;restart the player scores
			MOV SHIP1_POINTS, 0
			MOV SHIP2_POINTS, 0
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS
			
			;reset time
			MOV GAME_TIMER_SEC, 30
			MOV FRAMES_COUNTER, 0
			
			RET
		
		START_MULTIPLAYER:
			
			;restart the ships positions
			XOR AX, AX
		
			MOV AX, 64
			MOV SHIP1_X, AX
			
			MOV AX, 180
			MOV SHIP1_Y, AX
			
			MOV AX, 218
			MOV SHIP2_X, AX
			
			MOV AX, 180
			MOV SHIP2_Y, AX
			
			MOV AI_MODE, 00h              ;deactivate the AI mode
			MOV CURRENT_SCENE, 01h
			MOV GAME_ACTIVE, 01h
			
			;restart players score
			MOV SHIP1_POINTS, 0
			MOV SHIP2_POINTS, 0
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS
			
			;reset time
			MOV GAME_TIMER_SEC, 30
			MOV FRAMES_COUNTER, 0
			RET
		EXIT_GAME:
			MOV EXITING_GAME, 01h
			RET
	DRAW_MAIN_MENU ENDP
		
	UPDATE_WINNER_TEXT PROC NEAR
		
		MOV AL, WINNER_INDEX			 	          ;if winner index is 1 => AL, 1
		ADD AL, 30h                      			  ;AL, 32H => AL, '1'
		MOV [TEXT_GAME_OVER_WINNER + 7], AL ;uptade the index in the text with the character
		
		RET
	UPDATE_WINNER_TEXT ENDP
		
	CLEAR_SCREEN PROC NEAR
		MOV AH, 00H             		; SET THE CONFIGURATION TO VIDEO MODE
		MOV AL, 04h             		; CHOOSE THE VIDEO MODE
		INT 10h                 		; EXECUTE THE CONFIGURATION
				
		MOV AH, 0Bh             		; SET THE CONFIGURATION
		MOV BH, 00h             		; TO THE BACKGROUND COLOR
		MOV BL, 00h             		; CHOOSE BLACK AS BACKGROUND COLOR
		INT 10h                 		; EXECUTE THE CONFIGURATION
				
				RET	
	CLEAR_SCREEN ENDP
	
	CONCLUDE_EXIT_GAME PROC NEAR        ;goes back to the text mode 
		MOV AH, 00H             		; SET THE CONFIGURATION TO VIDEO MODE
		MOV AL, 02h             		; CHOOSE THE VIDEO MODE
		INT 10h                 		; EXECUTE THE CONFIGURATION
		
		MOV AH, 4Ch                     ;terminate program
		INT 21h
		
		RET
	CONCLUDE_EXIT_GAME ENDP
	
	DRAW_TIMER_BAR PROC NEAR
        ;the timer bar would be in the center (X = 160)
        ;the high of the bar depends on GAME_TIMER_SEC
        
        CMP GAME_TIMER_SEC, 0
        JE RET_DRAW_BAR         		;if it is 0, stop drawing
        
        ;calculate height
        MOV AL, GAME_TIMER_SEC
        MOV BL, 6
        MUL BL                  		; AX = AL * 6
        
        ;the bar is draw from top to bottom
        ;start_y = 200 - height
        ;end_y = 200
        
        MOV DX, 200             
        SUB DX, AX              ;starts at y = 20
                                ; DX now have the y from top of the bar
        
        MOV CX, 0A0h            ; X = 160 (center)
        
        DRAW_BAR_PIXEL:
            MOV AH, 0Ch
            MOV AL, 0Fh         ;white color
            MOV BH, 00h
            INT 10h
            
            INC DX              ;decrement a pixel (go down)
            CMP DX, 200         ;is in the bottom?
            JNE DRAW_BAR_PIXEL  ;if not, continue drawing
            
        RET_DRAW_BAR:
        RET
    DRAW_TIMER_BAR ENDP
	
	UPDATE_GAME_TIMER PROC NEAR
        INC FRAMES_COUNTER
        CMP FRAMES_COUNTER, 100 ; have passed 100 frames?
        JL EXIT_TIMER_UPDATE    ; if not, exit
        
        ;have passed 100 frames
        MOV FRAMES_COUNTER, 0   ;reset frames counter
        DEC GAME_TIMER_SEC      ;decrease in one the GAME_TIMER_SEC
        
        ;check if time is over
        CMP GAME_TIMER_SEC, 0
        JE TIME_IS_UP
        
        RET
        
        TIME_IS_UP:
            ;if time is over, check the winner
            MOV AL, SHIP1_POINTS
            MOV BL, SHIP2_POINTS
            
            CMP AL, BL
            JG P1_WINS_BY_TIME      ; P1 > P2
            JL P2_WINS_BY_TIME      ; P2 > P1
            
            ; EMPATE (Draw)
            MOV WINNER_INDEX, 03h   ;we are going to use 3 to indicate if it is a draw (both have the same score)
            JMP END_GAME_BY_TIME
            
            P1_WINS_BY_TIME:
                MOV WINNER_INDEX, 01h
                JMP END_GAME_BY_TIME
                
            P2_WINS_BY_TIME:
                MOV WINNER_INDEX, 02h
                
            END_GAME_BY_TIME:
                CALL GAME_OVER_ROUTINE
                
        EXIT_TIMER_UPDATE:
            RET
    UPDATE_GAME_TIMER ENDP
	
	GAME_OVER_ROUTINE PROC NEAR
        MOV SHIP1_POINTS, 00h
        MOV SHIP2_POINTS, 00h
        CALL UPDATE_TEXT_PLAYER_ONE_POINTS
        CALL UPDATE_TEXT_PLAYER_TWO_POINTS
        MOV GAME_ACTIVE, 00h
        RET
    GAME_OVER_ROUTINE ENDP
	
	
	
	
CODE ENDS
END