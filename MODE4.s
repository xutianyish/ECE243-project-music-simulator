  
# r16 address ADDR_AUDIODACFIFO
# r17 temp register
# r18 audio out
# r19 address of PS2_keyboard

.section .data
audio_out:
.word 0
recorded_start:
.skip 192000
recoreded_end:
.word 0

.section .text
.equ ADDR_AUDIODACFIFO, 0xFF203040
.equ PS2_KEYBOARD, 0xFF200100


.global MODE4_MUSIC_MIXER

MODE4_MUSIC_MIXER:  
    #store the registers onto stack
    addi sp, sp, -24
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw r19, 12(sp)
    stw r20, 16(sp)
    stw ra, 20(sp)
    
    
    #setup PS2_keyboard
    movia r19, PS2_KEYBOARD
    
    
    STOP:
    movia r19, PS2_KEYBOARD
    # PS2_READ_POLL
    ldwio r17, 0(r19)
    andi r18, r17, 0x8000
    beq r18, r0, STOP
    andi r17, r17, 0x00FF


    movi r18, 0x1a # z
    beq r17, r18, Z
    movi r18, 0x22 # x
    beq r17, r18, X
    movi r18, 0x21 # c
    beq r17, r18, C
    movi r18, 0x2a # v
    beq r17, r18, V
    movi r18, 0x32 # b
    beq r17, r18, B
    movi r18, 0x31 # n
    beq r17, r18, N    
    movi r18, 0x3a # m
    beq r17, r18, M
    movi r18, 0x24 # e
    beq r17, r18, EXIT
    movi r18, 0x2d # r
    beq r17, r18, RECORD
	br STOP
	
    
    RECORD:
    call CLEAR_PS2_FIFO
  	movia r16, ADDR_AUDIODACFIFO
  	movia r18, recorded_start
	
    STORE_SAMPLES:
    ldwio r17,4(r16)      # Read fifospace register 
    andi  r17,r17,0xff    # Extract # of samples in Input Right Channel FIFO 
    beq   r17,r0,STORE_SAMPLES    # If no samples in FIFO, go back to start
    call DELAY          #delay by 1/48000 sec
    ldwio r17,8(r16)
    movia r20, recoreded_end 
    beq r18, r20, STOP
    stw r17, 0(r18)
    stwio r17,8(r16)      # Echo to left channel 
    stwio r17,12(r16)     # Echo to right channel 
    addi r18, r18, 4
    br STORE_SAMPLES 

    

    V:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    V_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 4
    br V_play
    
    

    
    
    C:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    C_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    #write again
    call check_read_FIFO
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 4
    br C_play
 
 
    X:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    X_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    #write again
    call check_read_FIFO
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    #write again
    call check_read_FIFO
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 4
    br X_play    
  
  
  
    B:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    B_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 8
    br B_play
    
    
    N:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    N_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 12
    br N_play
    
       
    M:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    M_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 16
    br M_play
    
    
  
    Z:
    call CLEAR_PS2_FIFO
    movia r16, ADDR_AUDIODACFIFO
    movia r18, recorded_start
    
    Z_play:
    #make sure FIFO has write space available
    call check_read_FIFO
    #write to FIFO
    movia r17, recoreded_end
    beq r17, r18, STOP
    ldw r20, 0(r18)
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    #write again
    call check_read_FIFO
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel    
    #write again
    call check_read_FIFO
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    #write again
    call check_read_FIFO
    stwio r20,8(r16)      # Echo to left channel 
    stwio r20,12(r16)     # Echo to right channel
    addi r18, r18, 4
    br Z_play      
    
    
    

    
    
    check_read_FIFO:
    addi sp, sp, -8
    stw r16, 0(sp)
    stw r17, 4(sp)
    movia r16, ADDR_AUDIODACFIFO
    
    POLL:
    ldwio r17,4(r16)      # Read fifospace register 
    srli r17, r17, 16
    andi r17, r17, 0xFF   #check left channel only
    beq r17, r0, POLL
    
    ldw r16, 0(sp)
    ldw r17, 4(sp)
    addi sp, sp, 8
    ret
    
    
    CLEAR_PS2_FIFO:
    addi sp, sp, -8
    stw r16, 0(sp)
    stw r17, 4(sp)    
    
    PS2_POLL:
    ldwio r17, 0(r19)
    andi r16, r17, 0x8000
    bne r16, r0, PS2_POLL
    
    ldw r16, 0(sp)
    ldw r17, 4(sp)
    addi sp, sp, 8    
    ret


	#restore callee saved registers onto stack
    EXIT:
    ldw r16, 0(sp)
    ldw r17, 4(sp)
    ldw r18, 8(sp)
    ldw r19, 12(sp)
    ldw r20, 16(sp)
    ldw ra, 20(sp)
    addi sp, sp, 24
   
    ret
	