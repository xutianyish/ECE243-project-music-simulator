#r9 address of JTAG UART
.set nobreak

.section .data
test_start: 
.word 0 
# 0 indicates recording not started yet
# 1 indicates recording in process

test_replay: 
.word 0 
# 0 indicates replay not yet started
# 1 indicates replay started

counter_second:
.word 0

counter_minute:
.word 0

count_down_once:
.word 0
# 0 indicates has not exhausted left over periods
# 1 indicates left over periods already considered

counter_store:
.hword 0



.section .text

.equ PS2_KEYBOARD, 0xFF200100
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ volume, 0x60000000
.equ VGA_Front_Buffer, 0xFF203020
.equ TIMER, 0xFF202000
.equ TIMER2, 0xFF202020
.equ ADDR_7SEG,	0xFF200020
.equ SDRAM, 0x40000000

.global MODE2_MUSIC_RECORDER, PREP_RET_2, PS2_INT_2, TIMER_INT_2, TIMER2_INT

MODE2_MUSIC_RECORDER:
    addi sp, sp, -44
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp) 
    stw r19, 12(sp)
    stw r20, 16(sp)	
    stw r21, 20(sp)
    stw r22, 24(sp)
    stw r4, 28(sp)
    stw r2, 32(sp)
    stw ra, 36(sp)
    stw r23, 40(sp)

    movia r16, PS2_KEYBOARD
    movia r20, ADDR_AUDIODACFIFO 
    movia r17, TIMER
    movia r23, SDRAM
    
    # Initialize setting for timer [1 second]
	
    movhi r4, 0x5F5
  	ori r4, r4, 0xE100
  
   	stwio r4, 8(r17)                          # Set the period to be 262150 clock cycles 
   	srli r4, r4, 16
   	stwio r4, 12(r17)
    
    
    # Initialize 7 segments
    movia r17, ADDR_7SEG
    movia r4, 0x3f3f # 0 for hex 0 and 1
   	stwio r4, 0(r17) 
    
    # Tell the CPU to accept interrupt requests from IRQ7 and IRQ0 and IRQ2 when interrupts are enabled
    # set bit 7 and bit 0 and bit 2 of ctl3 to 1
    addi  r17, r0, 0x81
   	wrctl ctl3, r17
 
    # Tell the CPU to accept interrupts
    # set bit 0 of ctl0 to 1
    addi r17, r0, 0x1
    wrctl ctl0, r17
    
    # Enable interrupt of PS2
    addi r17, r0, 1
    stwio r17, 4(r16)
    
    PREP_2:	
    	movi r21, 0
    	movi r22, 0
        br WAIT_TO_WRITE
	
    PREP_RET_2:
    	mov r21, r19
        mov r22, r4
    
    WAIT_TO_WRITE:
        ldwio r17, 4(r20)
        # Test for right channel
        andhi r18, r17, 0xff00
        beq r18, r0, WAIT_TO_WRITE
        # Test for left channel
        andhi r18, r17, 0xff
        beq r18, r0, WAIT_TO_WRITE

     WRITE_TO_OUTPUT:
        stwio r22, 8(r20)
        stwio r22, 12(r20)
        subi r21, r21, 1
        bne r21, r0, WAIT_TO_WRITE

     INVERTING_WAVEFORM:
        mov r21, r19
        sub r22, r0, r22				# 32-bit signed samples: Negate.
        br WAIT_TO_WRITE

	EXIT_MODE_2:
       	# Tell the CPU to disable interrupt requests from IRQ7
    	# set bit 7 of ctl3 to 0
    	addi  r17, r0, 0
   		wrctl ctl3, r17
 
    	# Tell the CPU to stop accepting interrupts
    	# set bit 0 of ctl0 to 0
    	addi r17, r0, 0
    	wrctl ctl0, r17
    
    	# Disable interrupt of PS2
    	addi r17, r0, 0
    	stwio r17, 4(r16)
    
        # Turn off 7 segments
        movia r17, ADDR_7SEG
        stwio r0, 0(r17) 
        
	movia r17, counter_second
     	stw r0, 0(r17)
        
        movia r17, counter_minute
     	stw r0, 0(r17)

    	ldw r16, 0(sp)
    	ldw r17, 4(sp)
    	ldw r18, 8(sp) 
    	ldw r19, 12(sp)
   		ldw r20, 16(sp)	
    	ldw r21, 20(sp)
    	ldw r22, 24(sp)
    	ldw r4, 28(sp)
        ldw r2, 32(sp)
        ldw ra, 36(sp)
        ldw r23, 40(sp)

    	addi sp, sp, 44
    
    ret
    
.section .text 
 PS2_INT_2:
    movia r16, PS2_KEYBOARD
    ldwio r18, 0(r16)
	andi r18, r18, 0x000000ff
    
    TEST_BREAK_CODE:
    movui r17, 0xf0
    beq r18, r17, STOP_AUDIO
    
    TEST_SECOND:
    movui r17, 0xf0
    beq gp, r17, ISR_EXIT_IGNORE    
    
    CONVERSION:
    # In order to get 50% duty cycle, cycles will be divided by 2
    # So that the output is positive 50% of the time and negative 50% of the time
    D:
    # Note Do, Frequency: 261.62Hz, 84 samples for half period
      movui r19, 0x23
      bne r19, r18, F

      movia r17, VGA_Front_Buffer
      movia r19, DO
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 84
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER

      br ISR_EXIT_MODE2
      
    F:
    # Note Re, Frequency: 293.66Hz, 75 samples for half period
      movui r19, 0x2B
      bne r19, r18, G

      movia r17, VGA_Front_Buffer
      movia r19, RE
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 75
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER
      
      br ISR_EXIT_MODE2
      
    G:
    # Note Mi, Frequency: 329.63Hz, 66 samples for half period
      movui r19, 0x34
      bne r19, r18, H

      movia r17, VGA_Front_Buffer
      movia r19, MI
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 66
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER
      
      br ISR_EXIT_MODE2
      
    H:
    # Note Fa, Frequency: 349.23Hz, 63 samples for half period
      movui r19, 0x33
      bne r19, r18, J

      movia r17, VGA_Front_Buffer
      movia r19, FA
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 63
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER
      
      br ISR_EXIT_MODE2  
      
    J:
    # Note So, Frequency: 392.00Hz, 56 samples for half period
      movui r19, 0x3B
      bne r19, r18, K

      movia r17, VGA_Front_Buffer
      movia r19, SO
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 56
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER
      
      br ISR_EXIT_MODE2
      
    K:
    # Note La, Frequency: 440.00Hz, 50 samples for half period
      movui r19, 0x42
      bne r19, r18, L

      movia r17, VGA_Front_Buffer
      movia r19,LA
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 50
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER
      
      br ISR_EXIT_MODE2
 
    L:
    # Note Si, Frequency: 493.88Hz, 45 samples for half period
      movui r19, 0x4B
      bne r19, r18, S

      movia r17, VGA_Front_Buffer
      movia r19, SI
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 45
      movia r4, volume
      
      # Test if recording
      movia r17, test_start
      ldw r17, 0(r17)
      bne r17, r0, SET_TIMER
      
      br ISR_EXIT_MODE2

	S:
      # To start recording
      movui r19, 0x1B # s
      bne r19, r18, Q
      
		#update test_start byte to 1
     	movia r17, test_start 
     	movui r19, 1
     	stw r19, 0(r17)
        
        movia r17, counter_second
     	stw r0, 0(r17)
        
        movia r17, counter_minute
     	stw r0, 0(r17)
      
      movia r17, TIMER
      movui r19, 7
      stwio r19, 4(r17)                          # Start the timer1 with continuing and enable interrupt    
      
      movia r23, SDRAM
      
      br ISR_EXIT_IGNORE
    
    Q:
      # To stop recording
      movui r19, 0x15 # Q
      bne r19, r18, P
      
	#update test_start byte to 0
     	movia r17, test_start 
     	movui r19, 0
     	stw r19, 0(r17)
      
      
      # STORING DATA
      	movia r17, TIMER
        
      # Step 1: Store the last data
        # Stop the timer, read the current period left
        # Store counter, note and period info onto stack
        # Reset counter_store
		
        # Read current period left 
        stwio r0,16(r17)              	# Take a snapshot of the timer 
        ldwio r18,16(r17)             	# Read snapshot bits 0..15 
        ldwio r19,20(r17)              	# Read snapshot bits 16...31 
        slli  r19,r19,16				# Shift left by 16 bits
        or    r19,r19,r18               # Combine bits 0..15 and 16...31 and store in r19
        
        # Stop the timer and disable interrupt
    	movui r18, 8
    	stwio r18, 4(r17)              # Stop the timer and disable interrupt
		stwio r0, 0(r17) 				# Clear flag
        
        # Store counter, note and period left onto SDRAM
        sth r0, 0(r23)
        
    	movia r18, counter_store
    	ldh r17, 0(r18)
        sth r17, 2(r23)
        
        movhi r18, 0x5F5
  		ori r18, r18, 0xE100
        
        sub r18, r18, r19
        add r18, r18, r12
        
        # reset r12 to 0
        mov r12, r0 
        
        stw r18, 4(r23)
        
        addi r23, r23, 8 # two half word plus a word 
        
        # Reset counter_store
        movia r18, counter_store
    	sth r0, 0(r18)
        
      # Step 2: Store additional hword [-1] to indicate stop
      	addi r19, r0, -1
      	sth r19, 0(r23)
		addi r23, r23, 2
        
      br ISR_EXIT_IGNORE
      
      
   	P:
      # To start playing record
      movui r19, 0x4D # p
      bne r19, r18, E
      
     #update test_replay byte to 1
     movia r17, test_replay
     movui r19, 1
     stw r19, 0(r17)
        
      movia r17, TIMER
      movui r19, 7
      stwio r19, 4(r17)             # Start the timer1 with continuing and enable interrupt   
      movia r23, SDRAM
      
      br ISR_EXIT_REPLAY
      
    E: 
    # To quit current mode
      movui r19, 0x24 # e
      bne r19, r18, ISR_EXIT_IGNORE

      movia r17, VGA_Front_Buffer
      movia r19, START_DISPLAY
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      br ISR_EXIT_RETURN

    # Ignore the next data read from PS2 and stop outputting to audio
    STOP_AUDIO:
    	# Clear output FIFO
		addi gp, gp, 0xf0
    	movui r18, 8
    	stwio r18, 0(r20)

    	movui r18, 0
    	stwio r18, 0(r20)   

		movia r17, VGA_Front_Buffer
        movia r19, MUSIC_SIMULATOR
        stwio r19, 4(r17)
        movia r19, 1
        stwio r19, 0(r17)
        
        TIMER_TO_STORE:
       	movia r18, test_start
      	ldw r18, 0(r18)
        beq r18, r0, TO_RETURN
        
        # Read the current period left
        # Store counter, note and period info onto stack
        # Reset counter_store
       
        movia r17, TIMER
		
        # Read current period left 
        stwio r0,16(r17)              	# Take a snapshot of the timer 
        ldwio r18,16(r17)             	# Read snapshot bits 0..15 
        ldwio r19,20(r17)              	# Read snapshot bits 16...31 
        slli  r19,r19,16				# Shift left by 16 bits
        or    r19,r19,r18               # Combine bits 0..15 and 16...31 and store in r19
        
        # Store counter, note and period left onto SDRAM
        sth bt, 0(r23)
        
    	movia r18, counter_store
    	ldh r17, 0(r18)
        sth r17, 2(r23)
        
        movhi r18, 0x5F5
  		ori r18, r18, 0xE100
        
        sub r18, r18, r19
        add r18, r18, r12
        
        # r12 stores the number of period for next action
        mov r12, r19   
        
        stw r18, 4(r23)
        
        addi r23, r23, 8 # two half word plus a word 
        
        # Restart Timer & reset counter_store
        movia r18, counter_store
    	sth r0, 0(r18)
        
        TO_RETURN:
        # restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
        ldw r2, 20(sp)
        ldw r5, 24(sp)
    	addi sp, sp, 28
    
    	movia ea, PREP_2
    	eret    
        
    SET_TIMER:
    	# Update last pressed note by its cycle and store in bt
        mov bt, r19
        
        # Stop the timer, read the current period left
        # Store counter, note and period info onto stack
        # Restart the timer & Reset counter_store
       
        movia r17, TIMER
		
        addi sp, sp, -4
        stw r19, 0(sp)
        
        # Read current period left 
        stwio r0,16(r17)              	# Take a snapshot of the timer 
        ldwio r18,16(r17)             	# Read snapshot bits 0..15 
        ldwio r19,20(r17)              	# Read snapshot bits 16...31 
        slli  r19,r19,16				# Shift left by 16 bits
        or    r19,r19,r18               # Combine bits 0..15 and 16...31 and store in r19
        
        # Store counter, note and period left onto SDRAM
        sth r0, 0(r23)
        
    	movia r18, counter_store
    	ldh r17, 0(r18)
        sth r17, 2(r23)
        
        movhi r18, 0x5F5
  		ori r18, r18, 0xE100
        
        sub r18, r18, r19
        add r18, r18, r12
        
        # r12 stores the number of period for next action
        mov r12, r19   
        
        stw r18, 4(r23)
        
        addi r23, r23, 8 # two half word plus a word 
        
        # Reset counter_store
        movia r18, counter_store
    	sth r0, 0(r18)  
        
        ldw r19, 0(sp)
        addi sp, sp, 4
        
    br ISR_EXIT_MODE2

    ISR_EXIT_IGNORE:
    	# restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
        ldw r2, 20(sp)
        ldw r5, 24(sp)
    	addi sp, sp, 28
    	
        movi gp, 0
    	subi ea, ea, 4
    	eret
        
     ISR_EXIT_REPLAY:
    	# restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
        ldw r2, 20(sp)
        ldw r5, 24(sp)
    	addi sp, sp, 28
    	
        movi gp, 0
    	movia ea, START_REPLAY
    	eret

   ISR_EXIT_RETURN:
     	# restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
        ldw r2, 20(sp)
        ldw r5, 24(sp)
    	addi sp, sp, 28
        
        movi gp, 0
        movia ea, EXIT_MODE_2
        eret
 
TIMER_INT_2:
	  movia r17, TIMER
      stwio r0, 0(r17) # Clear flag
      
      movia r17, test_replay
      ldw r18, 0(r17)
      bne r0, r18, COUNT_DOWN
     
      movia r18, counter_store
	  ldh r17, 0(r18)	
      addi r17, r17, 1
      sth r17, 0(r18)
      
	  movia r18, counter_second
      ldw r18, 0(r18)
      movui r17, 9
      beq r17, r18, INCREMENT_MIN
      
      addi r18, r18, 1
      movia r17, counter_second
      stw r18, 0(r17)
      
      br DISPLAY_SEG
      
INCREMENT_MIN:
	movia r18, counter_second
	stw r0, 0(r18)
    
    movia r18, counter_minute
    ldw r17, 0(r18)
    addi r17, r17, 1
    stw r17, 0(r18)

DISPLAY_SEG:
    movia r18, counter_minute
    ldw r5, 0(r18)
    
    call CONVERSION_SEG

    slli r17, r2, 8			# Go to second

    movia r18, counter_second
    ldw r5, 0(r18)
    
    call CONVERSION_SEG

    or r17, r17, r2
    
    movia r18, ADDR_7SEG
   	stwio r17, 0(r18) 
    
    movia r17, test_replay
    ldw r18, 0(r17)
    beq r0, r18, ISR_EXIT_MODE2_TIMER
    
    beq bt, r0, ISR_EXIT_REPLAY
    
    subi bt, bt, 1
    
    br ISR_EXIT_MODE2_TIMER
    
CONVERSION_SEG:
	zero:
    movui r2, 0
    bne r2, r5, one
    
    movui r2, 0x3f
    ret

	one:
    movui r2, 1
    bne r2, r5, two
    
    movui r2, 0x06
    ret
    
    two:
    movui r2, 2
    bne r2, r5, three
    
    movui r2, 0x5b
    ret
    
    three:
    movui r2, 3
    bne r2, r5, four
    
    movui r2, 0x4f
    ret
    
    four:
    movui r2, 4
    bne r2, r5, five
    
    movui r2, 0x66
    ret
    
    five:
    movui r2, 5
    bne r2, r5, six
    
    movui r2, 0x6d
    ret
    
    six:
    movui r2, 6
    bne r2, r5, seven
    
    movui r2, 0x7d
    ret
    
    seven:
    movui r2, 7
    bne r2, r5, eight
    
    movui r2, 0x07
    ret
    
    eight:
    movui r2, 8
    bne r2, r5, nine
    
    movui r2, 0xff
    ret
    
    nine:
    movui r2, 0x6f
    ret    

COUNT_DOWN:

	movia r18, counter_second
    ldw r18, 0(r18)
    beq r0, r18, DECREASE_MIN
      
    subi r18, r18, 1
    movia r17, counter_second
    stw r18, 0(r17)
      
    br DISPLAY_SEG
      
DECREASE_MIN:
    movia r18, counter_minute
    ldw r17, 0(r18)
    beq r0, r17, STOP_TIMER
    
	movia r18, counter_second
    movui r17, 9
	stw r17, 0(r18)
    
    movia r18, counter_minute
    ldw r17, 0(r18)
    subi r17, r17, 1
    stw r17, 0(r18)
    
    br DISPLAY_SEG

STOP_TIMER:
	movia r18, counter_second
	stw r0, 0(r18)
	movia r18, counter_minute
	stw r0, 0(r18)    
    
    br DISPLAY_SEG
	
START_REPLAY:
    ldh r19, 0(r23) # Number of cycles 
    addi r17, r0, -1
    beq r17, r19, END_REPLAY
    
    ldh bt, 2(r23) # Number of 1 seconds 
    ldw r17, 4(r23) # Left over periods
    
    addi r23, r23, 8
    
    movia r4, volume 
    br PREP_RET_2

END_REPLAY:
	# Reset 7 segments
    movia r17, ADDR_7SEG
    movia r18, 0x3f3f # 0 for hex 0 and 1
   	stwio r18, 0(r17) 

    # Disable interrupt of timer1
     movia r17, TIMER
     stwio r0, 0(r17) # Clear flag
     movui r19, 8
     stwio r19, 4(r17)              # Stop timer1 and disable interrupt  
     
     movia r17, count_down_once
     stw r0, 0(r17)

     movia r17, test_replay
     stw r0, 0(r17)
     
     movia r23, SDRAM
     
     br PREP_2
