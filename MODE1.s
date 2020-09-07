#r9 address of JTAG UART 

.text 
.equ PS2_KEYBOARD, 0xFF200100
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ volume, 0x6000000
.equ VGA_Front_Buffer, 0xFF203020
.equ ADDR_JP1, 0xFF200060   # address GPIO JP
.equ TIMER_MODE1, 0xFF202000

.global MODE1_MUSIC_SIMULATOR, PREP_RET, PS2_INT, LEGO_INT, TIMER_INT, PREP_RET_LEGO

MODE1_MUSIC_SIMULATOR:
	
    addi sp, sp, -36
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp) 
    stw r19, 12(sp)
    stw r20, 16(sp)	
    stw r21, 20(sp)
    stw r22, 24(sp)
    stw r4, 28(sp)
    stw r23, 32(sp)

    movia r16, PS2_KEYBOARD
    movia r20, ADDR_AUDIODACFIFO 
    movia r23, ADDR_JP1
    
    
    #Clear FIFO
    movui r18, 8
    stwio r18, 0(r20)

    #movui r18, 0
    #stwio r18, 0(r20) 
        
    # Initialize setting for Lego controller
    
    # set motor,threshold and sensors bits to output, set state and sensor valid bits to inputs 
  	movia  r17, 0x07f557ff       
   	stwio  r17, 4(r23)
    
    # Store threshold value (0xA) into each of the sensor
    
    # Sensor 0
    
    # Step 1: Load
   	movia  r17,  0xFCBFEFFF       # set motors off enable threshold load sensor 0
   	stwio  r17,  0(r23)            # store value into threshold register

    # Step 2: Disable
   	movia  r17,  0xFCFFFFFF       # set motors off disable threshold load sensor 0
   	stwio  r17,  0(r23)            # store value into threshold register

    # Sensor 1
    
    # Step 1: Load
   	movia  r17,  0xFCBFFBFF       # set motors off enable threshold load sensor 1
   	stwio  r17,  0(r23)            # store value into threshold register

    # Step 2: Disable
   	movia  r17,  0xFCFFFFFF       # set motors off disable threshold load sensor 1
   	stwio  r17,  0(r23)            # store value into threshold register
    
    # Sensor 2
    
    # Step 1: Load
   	movia  r17,  0xFCBFBFFF       # set motors off enable threshold load sensor 2
   	stwio  r17,  0(r23)            # store value into threshold register

    # Step 2: Disable
   	movia  r17,  0xFCFFFFFF      # set motors off disable threshold load sensor 2
   	stwio  r17,  0(r23)            # store value into threshold register

    # Sensor 3
    
    # Step 1: Load
   	movia  r17,  0xFCBEFFFF       # set motors off enable threshold load sensor 3
   	stwio  r17,  0(r23)            # store value into threshold register

    # Step 2: Disable
   	movia  r17,  0xFCFFFFFF       # set motors off disable threshold load sensor 3
   	stwio  r17,  0(r23)            # store value into threshold register
    
    # Sensor 4
    
    # Step 1: Load
   	movia  r17,  0xFCBBFFFF       # set motors off enable threshold load sensor 4
   	stwio  r17,  0(r23)            # store value into threshold register

    # Step 2: Disable
   	movia  r17,  0xFCFFFFFF      # set motors off disable threshold load sensor 4
   	stwio  r17,  0(r23)            # store value into threshold register
    
	# disable threshold register and enable state mode
  
   movia  r17,  0xFCDFFFFF      # keep threshold value same in case update occurs before state mode is enabled
   stwio  r17,  0(r23)
    
    # Initialize setting for timer [0.5 second]
	movia r17, TIMER_MODE1
    	movhi r4, 0x2FA
  	ori r4, r4, 0xF080
  
   	stwio r4, 8(r17)                          # Set the period to be 262150/2 clock cycles 
   	srli r4, r4, 16
   	stwio r4, 12(r17)
   
    # Tell the CPU to accept interrupt requests from IRQ7 and IRQ11 and IRQ0 when interrupts are enabled
    # set bit 7 and bit 11 and bit 0 of ctl3 to 1
    addi  r17, r0, 0x881
   	wrctl ctl3, r17
 
    # Tell the CPU to accept interrupts
    # set bit 0 of ctl0 to 1
    addi r17, r0, 0x1
    wrctl ctl0, r17
    
    # Enable interrupt of PS2
    addi r17, r0, 1
    stwio r17, 4(r16)
    
    # Enable interrupt of all five sensors
    movia  r17, 0xf8000000
    stwio  r17, 8(r23)
    
    PREP:	
    	movi r21, 0
    	movi r22, 0
        br WAIT_TO_WRITE

	
    PREP_RET:
    	mov r21, r19
        mov r22, r4
	movui r18, 0
    	stwio r18, 0(r20)   

    
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

EXIT_MODE_1:
    # Tell the CPU to disable interrupt requests from IRQ7 and IRQ11 and IRQ0
    # set bit 7 and bit 11 and bit 0 of ctl3 to 0
    addi  r17, r0, 0
    wrctl ctl3, r17
 
    # Tell the CPU to stop accepting interrupts
    # set bit 0 of ctl0 to 0
    addi r17, r0, 0
    wrctl ctl0, r17
    
    # Disable interrupt of PS2
    addi r17, r0, 0
    stwio r17, 4(r16)
	
    # Disable interrupt of LEGO
    movia  r17, 0
    stwio  r17, 8(r23)    

    ldw r16, 0(sp)
    ldw r17, 4(sp)
    ldw r18, 8(sp) 
    ldw r19, 12(sp)
    ldw r20, 16(sp)	
    ldw r21, 20(sp)
    ldw r22, 24(sp)
    ldw r4, 28(sp)
    ldw r23, 32(sp)

    addi sp, sp, 36

    ret
    
    
.section .text 
 PS2_INT:
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

      br ISR_EXIT_MODE_1
      
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
      br ISR_EXIT_MODE_1
      
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
      br ISR_EXIT_MODE_1
      
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
      br ISR_EXIT_MODE_1   
      
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
      br ISR_EXIT_MODE_1
      
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
      br ISR_EXIT_MODE_1
 
    L:
    # Note Si, Frequency: 493.88Hz, 45 samples for half period
      movui r19, 0x4B
      bne r19, r18, E

      movia r17, VGA_Front_Buffer
      movia r19, SI
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 45
      movia r4, volume
      br ISR_EXIT_MODE_1

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

	movia r17, VGA_Front_Buffer
        movia r19, MUSIC_SIMULATOR
        stwio r19, 4(r17)
        movia r19, 1
        stwio r19, 0(r17)

        # restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
		ldw r23, 20(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
    	addi sp, sp, 24
    
    	movia ea, PREP
    	eret    

    ISR_EXIT_IGNORE:
   		movia r20, ADDR_AUDIODACFIFO
        movui r18, 8
    	stwio r18, 0(r20)

    	movui r18, 0
    	stwio r18, 0(r20) 
        
    	# restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
		ldw r23, 20(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
    	addi sp, sp, 24
    	
        movi gp, 0
    	movia ea, PREP
    	eret

   	ISR_EXIT_RETURN:
     	# restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
    	addi sp, sp, 20
        
        movi gp, 0
        movia ea, EXIT_MODE_1
        eret

   LEGO_INT:
	movia r23, ADDR_JP1
    # Enable interrupt of timer
    movia r17, TIMER_MODE1
    movui r4, 5
    stwio r4, 4(r17)                          # Start the timer without continuing and enable interrupt    
    
    ldwio r17, 12(r23)
    srli  r17, r17, 27          # shift to the right by 27 bits to get 5-bit sensor value 
    andi  r17, r17, 0x1f
    
    addi r18, r0, 0xffffffff
    stwio r18, 12(r23)
    

    
    andi r18, r17, 0x1
    addi r19, r0, 0x1
    beq r19, r18, SENSOR0

    andi r18, r17, 0x2
    addi r19, r0, 0x2
    beq r19, r18, SENSOR1

    andi r18, r17, 0x4
    addi r19, r0, 0x4
    beq r19, r18, SENSOR2
  
    andi r18, r17, 0x8
    addi r19, r0, 0x8
    beq r19, r18, SENSOR3
  
    andi r18, r17, 0x10
    addi r19, r0, 0x10
    beq r19, r18, SENSOR4
    
    SENSOR0: #DO
      # Note Do, Frequency: 261.62Hz, 84 samples for half period
      movia r17, VGA_Front_Buffer
      movia r19, DO
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 84
      movia r4, volume

      br ISR_EXIT_MODE_2
    
     SENSOR1: #RE
    # Note Re, Frequency: 293.66Hz, 75 samples for half period
      movia r17, VGA_Front_Buffer
      movia r19, RE
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 75
      movia r4, volume
      br ISR_EXIT_MODE_2
      
    SENSOR2: #MI
    # Note Mi, Frequency: 329.63Hz, 66 samples for half period
      movia r17, VGA_Front_Buffer
      movia r19, MI
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 66
      movia r4, volume
      br ISR_EXIT_MODE_2
      
    SENSOR3: # FA
    # Note Fa, Frequency: 349.23Hz, 63 samples for half period
      movia r17, VGA_Front_Buffer
      movia r19, FA
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 63
      movia r4, volume
      br ISR_EXIT_MODE_2 
      
    SENSOR4: #SO
    # Note So, Frequency: 392.00Hz, 56 samples for half period
      movia r17, VGA_Front_Buffer
      movia r19, SO
      stwio r19, 4(r17)
      movi r19, 1
      stwio r19, 0(r17)

      movui r19, 56
      movia r4, volume
      br ISR_EXIT_MODE_2

TIMER_INT:
	  movia r17, TIMER_MODE1
      stwio r0, 0(r17) # Clear flag
      
      # Disable interrupt of timer
    	movui r18, 8
    	stwio r18, 4(r17)              # Stop the timer and disable interrupt
      
      br STOP_AUDIO_LEGO
    	
    PREP_LEGO:	
    	movi r21, 0
    	movi r22, 0
        br WAIT_TO_WRITE_LEGO
	
    PREP_RET_LEGO:
    	mov r21, r19
        mov r22, r4
	movui r18, 0
    	stwio r18, 0(r20)   
    
    WAIT_TO_WRITE_LEGO:
        ldwio r17, 4(r20)
        # Test for right channel
        andhi r18, r17, 0xff00
        beq r18, r0, WAIT_TO_WRITE_LEGO
        # Test for left channel
        andhi r18, r17, 0xff
        beq r18, r0, WAIT_TO_WRITE_LEGO

     WRITE_TO_OUTPUT_LEGO:
        stwio r22, 8(r20)
        stwio r22, 12(r20)
        subi r21, r21, 1
        bne r21, r0, WAIT_TO_WRITE_LEGO

     INVERTING_WAVEFORM_LEGO:
        mov r21, r19
        sub r22, r0, r22				# 32-bit signed samples: Negate.
        br WAIT_TO_WRITE_LEGO

        # Stop outputting to audio
    STOP_AUDIO_LEGO:
    	# Clear output FIFO
        movia r20, ADDR_AUDIODACFIFO 
    	movui r18, 8
    	stwio r18, 0(r20)

    	movui r18, 0
    	stwio r18, 0(r20)   

		movia r17, VGA_Front_Buffer
        movia r19, MUSIC_SIMULATOR
        stwio r19, 4(r17)
        movia r19, 1
        stwio r19, 0(r17)

        # restore registers
    	ldw r21, 12(sp)
    	ldw r22, 16(sp)
		ldw r23, 20(sp)
    	ldw r18, 8(sp) 
    	ldw r17, 4(sp)
    	ldw r16, 0(sp)
    	addi sp, sp, 24
    
    	movia ea, PREP_LEGO
    	eret 
	