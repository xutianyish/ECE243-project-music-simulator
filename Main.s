
#NOTE: globally declared label: START_DISPLAY, MUSIC_PLAYER, 
# MUSIC_SIMULATOR, DO, RE, MI, FA, SO, LA, SI
.section .data
current_mode: 
.byte 0


.section .text
.global _start, current_mode
_start:

.equ VGA_Front_Buffer, 0xFF203020
.equ PS2_KEYBOARD, 0xFF200100
   
    #initialization
    movia sp, 0x04000000 
    movia r8, VGA_Front_Buffer
    movia r9, PS2_KEYBOARD
    
    #start_display
    movia r10, START_DISPLAY
    stwio r10, 4(r8)
    movi r10, 1
    stwio r10, 0(r8)

LOOP:
    #read from user input
	READ_POLL_1:
    ldwio r10, 0(r9)
    andi r11, r10, 0x8000
    beq r11, r0, READ_POLL_1
    andi r10, r10, 0x00FF
    movui r11, 0xf0
    bne r10, r11, BRANCHING
    
    #break char has been sent read again
    READ_POLL_2:
    ldwio r10, 0(r9)
    andi r11, r10, 0x8000
    beq r11, r0, READ_POLL_2
    andi r10, r10, 0x00FF    
    
    BRANCHING:
	#branch depending on user inputs
    movi r11, 0x16 # 1
    beq r11, r10, MODE1
    movi r11, 0x1E # 2
    beq r11, r10, MODE2
    movi r11, 0x26 # 3
    beq r11, r10, MODE3
    movi r11, 0x25 # 4
    beq r11, r10, MODE4
    br LOOP

    
    
    MODE1:
        movia r10, MUSIC_SIMULATOR
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)

		#update current_mode bit to 1
        movia r11, current_mode 
        movi r10, 1
        stb r10, 0(r11)
        
        call MODE1_MUSIC_SIMULATOR
		#update current_mode bit to 0
        movia r11, current_mode 
        movi r10, 0
        stb r10, 0(r11)
        

        #display start screen
        movia r10, START_DISPLAY
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)

    br LOOP
    
    
    
    MODE2:
        movia r10, MUSIC_SIMULATOR
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)


		#update current_mode byte to 2
        movia r11, current_mode 
        movi r10, 2
        stb r10, 0(r11)
        
        call MODE2_MUSIC_RECORDER
        
        #update current_mode byte to 0
        movia r11, current_mode 
        movi r10, 0
        stb r10, 0(r11)

        #display start screen
        movia r10, START_DISPLAY
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)

    br LOOP
    
    MODE3:
        movia r10, MUSIC_PLAYER
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)

        #update current_mode byte to 3
        movia r11, current_mode 
        movi r10, 3
        stb r10, 0(r11)
        
       	call MODE3_MUSIC_PLAYER

        #update current_mode byte to 0
        movia r11, current_mode 
        movi r10, 0
        stb r10, 0(r11)

        #display start screen
        movia r10, START_DISPLAY
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)
        
    br LOOP
        
    MODE4:
    	movia r10, MUSIC_MIXER
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)

        #update current_mode byte to 4
        movia r11, current_mode 
        movi r10, 4
        stb r10, 0(r11)
        
       	call MODE4_MUSIC_MIXER

        #update current_mode byte to 0
        movia r11, current_mode 
        movi r10, 0
        stb r10, 0(r11)

        #display start screen
        movia r10, START_DISPLAY
        stwio r10, 4(r8)
        movi r10, 1
        stwio r10, 0(r8)
        
        
    br LOOP
    
    
    










	