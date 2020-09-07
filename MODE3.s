# r9 address of PS2 keyboard
# r16 address of TIMER / address of ADDR_AUDIODACFIFO
# r17 temp register
# r18 audio out
# r19 address of PS2_keyboard

.section .data
audio_out:
.word 0
music1_current_sample:
.word 0
music2_current_sample:
.word 0
current_music:
.byte 1

.section .text
.equ TIMER, 0xFF202000
.equ time, 41667
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ PS2_KEYBOARD, 0xFF200100


.global MODE3_MUSIC_PLAYER, current_music, music2_current_sample, music1_current_sample, audio_out


MODE3_MUSIC_PLAYER:
	#push callee saved registers onto stack
    addi sp, sp, -16
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp) 
    stw r19, 12(sp)
    
    #initialize counter value
    movia r16, TIMER
    movui r17, %lo(time)
    stwio r17, 8(r16)
    movui r17, %hi(time)
    stwio r17, 12(r16)
    
   	stwio r0, 0(r16) #reset timer
    movui r17, 0b111 #enable start, CONT, interrupt
    stwio r17, 4(r16)
    
    #setup PS2_keyboard
    movia r19, PS2_KEYBOARD
    movi r17, 1
    stwio r17, 4(r19) # enable interrupt
    
    
    #Enable external interrupts and disable global interupt
    movui r17, 1
    wrctl status, r17
    wrctl ienable, r0
    
    
    
    #stop the music check for inputs
    STOP:
    # PS2_READ_POLL
    ldwio r17, 0(r19)
    andi r18, r17, 0x8000
    beq r18, r0, STOP
    andi r17, r17, 0x00FF

    movi r18, 0x1b # s
    beq r17, r18, STOP
    movi r18, 0x21 # c
    beq r17, r18, CONTINUE
    movi r18, 0x24 # e
    beq r17, r18, EXIT
    movi r18, 0x16 # '1'
    beq r17, r18, STOP_SWITCH_TO_MUSIC1
    movi r18, 0x1e # '2'
    beq r17, r18, STOP_SWITCH_TO_MUSIC2
	br STOP

	STOP_SWITCH_TO_MUSIC1:
    movia r17, current_music
    movi r18, 1
    stb r18, 0(r17)
    br STOP
    
	STOP_SWITCH_TO_MUSIC2:
	movia r17, current_music
    movi r18, 2
    stb r18, 0(r17)
	br STOP

    CONTINUE:
    movia r16, ADDR_AUDIODACFIFO
    
    #enable global interupt
    movi r17, 1
    wrctl ienable, r17
    
    play:
    #write to FIFO
    ldwio r17,4(r16)      # Read fifospace register 
    srli r17, r17, 16
    andi r17, r17, 0xFF
    beq r17, r0, CONTINUE
    movia r18, audio_out
    ldw r18, 0(r18)
    stwio r18,8(r16)      # Echo to left channel 
    stwio r18,12(r16)     # Echo to right channel
    
    
    
    #check the current mode
    ldwio r17, 0(r19)
    andi r18, r17, 0x8000
    beq r18, r0, play
    andi r17, r17, 0x00FF

    movi r18, 0x1b # s
    beq r17, r18, STOP
    movi r18, 0x21 # c
    beq r17, r18, play
    movi r18, 0x24 # e
    beq r17, r18, EXIT
    movi r18, 0x16 # '1'
    beq r17, r18, CONTINUE_SWITCH_TO_MUSIC1
    movi r18, 0x1e # '2'
    beq r17, r18, CONTINUE_SWITCH_TO_MUSIC2
    br play
    
    CONTINUE_SWITCH_TO_MUSIC1:
    movia r17, current_music
    movi r18, 1
    stb r18, 0(r17)
    br play
    
    CONTINUE_SWITCH_TO_MUSIC2:
    movia r17, current_music
    movi r18, 2
    stb r18, 0(r17)
    br  play
    
    
    
    
    #restore callee saved registers onto stack
    EXIT:
    wrctl ienable, r0
    
	# Tell the CPU to disable interrupt requests from all devices
    	# set bits of ctl3 to 0
    	addi  r17, r0, 0
   	wrctl ctl3, r17

    # Disable interrupt of timer1
     movia r17, TIMER
     stwio r0, 0(r17) # Clear flag
     movui r19, 8
     stwio r19, 4(r17)              # Stop timer1 and disable interrupt  

    ldw r16, 0(sp)
    ldw r17, 4(sp)
    ldw r18, 8(sp)
    ldw r19, 12(sp)
    addi sp, sp, 16
   
    ret
    








	