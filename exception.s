.text
.equ TIMER, 0xFF202000
.equ time, 41667
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ PS2_KEYBOARD, 0xFF200100

.global ISR_EXIT_MODE_1, ISR_EXIT_MODE_2, ISR_EXIT_MODE2, ISR_EXIT_MODE2_TIMER

.section  .exceptions, "ax"

    #push r16,r17,r18 to stack
    addi sp, sp, -12
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)   
    
    #check the current mode
    movia et, current_mode
    ldb et, 0(et)
	movi r16, 1
    beq et, r16, MODE1_ISR
    movi r16, 2
    beq et, r16, MODE2_ISR
    movi r16, 3
    beq et, r16, MODE3_ISR
    br ISR_EXIT
    
 MODE1_ISR:
    
    # Restore r16,r17,r18, because different route for return in this mode
    # Not going to br ISR_EXIT
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    addi sp, sp, 12
    
    # push registers to stack
    addi sp, sp, -20
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw r21, 12(sp)
    stw r22, 16(sp)	  
 	
    # Test which device caused interrupt
    rdctl r16, ctl4
    
    andi r17, r16, 0x80 # PS2 
    addi r18, r0, 0x80
    beq r18, r17, PS2_INT
    
    andi r17, r16, 0x800 # LEGO
    addi r18, r0, 0x800
    beq r17, r18, LEGO_INT
    
    andi r17, r16, 0x1# TIMER
    addi r18, r0, 0x1
    beq r17, r18, TIMER_INT
    
    ISR_EXIT_MODE_1:    
    # restore registers
    ldw r21, 12(sp)
    ldw r22, 16(sp)
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    addi sp, sp, 20
    
    movia ea, PREP_RET
    eret
    
    ISR_EXIT_MODE_2:    
    # restore registers
    ldw r21, 12(sp)
    ldw r22, 16(sp)
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    addi sp, sp, 20
    
    movia ea, PREP_RET_LEGO
    eret
    
    MODE2_ISR:
    
    # Restore r16,r17,r18, because different route for return in this mode
    # Not going to br ISR_EXIT
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    addi sp, sp, 12
    
    # push registers to stack
    addi sp, sp, -28
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw r21, 12(sp)
    stw r22, 16(sp)	  
 	stw r2, 20(sp)
    stw r5, 24(sp)
    
    # Test which device caused interrupt
    rdctl r16, ctl4
    
    andi r17, r16, 0x80 # PS2 
    addi r18, r0, 0x80
    beq r18, r17, PS2_INT_2
    
    andi r17, r16, 0x1# TIMER1
    addi r18, r0, 0x1
    beq r17, r18, TIMER_INT_2
    
    ISR_EXIT_MODE2:    
    # restore registers
    ldw r21, 12(sp)
    ldw r22, 16(sp)
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    ldw r2, 20(sp)
    ldw r5, 24(sp)
    addi sp, sp, 28
    
    movia ea, PREP_RET_2
    eret

    ISR_EXIT_MODE2_TIMER:    
    # restore registers
    ldw r21, 12(sp)
    ldw r22, 16(sp)
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    ldw r2, 20(sp)
    ldw r5, 24(sp)
    addi sp, sp, 28
    
    subi ea, ea, 4
    eret
    
    MODE3_ISR:
   	#check which device causes interrupt
    rdctl et, ipending
    andi et, et, 1
    beq et, r0, ISR_EXIT

    MODE3_TIMER:
    #Acknowledge interrupt
    movia et, TIMER
    stwio r0, 0(et)
    
    #check which music is playing
    movia et, current_music
    ldb et, 0(et)
    movi r16, 1
    beq r16, et, PLAY_MUSIC1
    
    PLAY_MUSIC2:
    #Time out read from current sample
    movia r16, music2_current_sample
    ldw r17, 0(r16) #load from current sample number
    movia r18, MODE3_MUSIC2_LENGTH
    ldw et, 0(r18) #load from MUSIC LENGTH
    
    blt r17, et, MUSIC2_WRITE_TO_AUDIO_OUT #if current sample exceed music length
    #set current sample to 0
    stw r0, 0(r16)
    
    MUSIC2_WRITE_TO_AUDIO_OUT:
    movia r16, MODE3_MUSIC2
    muli r17, r17, 4
    add r17, r16, r17 #r17 stores the address of current sample
    ldw r17, 0(r17) #load current sample from current address
    movia et, audio_out
    stw r17, 0(et) #write to audio out
    
    #increment current sample by 1
    movia r16, music2_current_sample
	ldw r17, 0(r16)
    addi r17, r17, 1
    stw r17, 0(r16)
    
    br ISR_EXIT
    
    
    PLAY_MUSIC1:
    #Time out read from current sample
    movia r16, music1_current_sample
    ldw r17, 0(r16) #load from current sample number
    movia r18, MODE3_MUSIC1_LENGTH
    ldw et, 0(r18) #load from MUSIC LENGTH
    
    blt r17, et, MUSIC1_WRITE_TO_AUDIO_OUT #if current sample exceed music length
    #set current sample to 0
    stw r0, 0(r16)
    
    
    MUSIC1_WRITE_TO_AUDIO_OUT:
    movia r16, MODE3_MUSIC1
    muli r17, r17, 4
    add r17, r16, r17 #r17 stores the address of current sample
    ldw r17, 0(r17) #load current sample from current address
    movia et, audio_out
    stw r17, 0(et) #write to audio out
    
    #increment current sample by 1
    movia r16, music1_current_sample
	ldw r17, 0(r16)
    addi r17, r17, 1
    stw r17, 0(r16)
    
    
    
    ISR_EXIT:
    #restore r16,r17,r18
    ldw r18, 8(sp) 
    ldw r17, 4(sp)
    ldw r16, 0(sp)
    addi sp, sp, 12
    
    subi ea, ea, 4
    eret


