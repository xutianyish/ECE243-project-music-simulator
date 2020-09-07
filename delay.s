/*****
*delay by 1/48000 secs
*****/


# r16 Timer pointer
# r17 temporary register

.section .text
.equ TIMER, 0XFF202000
.equ time, 2083

.global DELAY

DELAY:

# store registers used to the stack
addi sp, sp, -8
stw r16, 0(sp)
stw r17, 4(sp)

#initialize TIMER pointer
movia r16, TIMER

movui r17, %lo(time)
stwio r17, 8(r16) #init counter start value (low)
movui r17, %hi(time)
stwio r17, 12(r16) #init counter start value (high)

stwio r0, 0(r16) #reset TIMER
movui r17, 0b100 #enable start; disable CONT
stwio r17, 4(r16) # start TIMER

#check if time out
poll:
ldwio r17, (r16) #read first reg in TIMER
andi r17, r17, 0b1 #check if TO is 1
beq r17, r0, poll

#restore registers
ldw r16, 0(sp)
ldw r17, 4(sp)
addi sp, sp, 8

ret