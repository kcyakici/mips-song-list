##############################################################
#Dynamic array
##############################################################
#   4 Bytes - Capacity
#	4 Bytes - Size
#   4 Bytes - Address of the Elements
##############################################################

##############################################################
#Song
##############################################################
#   4 Bytes - Address of the Name (name itself is 64 bytes)
#   4 Bytes - Duration
##############################################################


.data
space: .asciiz " "
newLine: .asciiz "\n"
tab: .asciiz "\t"
menu: .asciiz "\n● To add a song to the list-> \t\t enter 1\n● To delete a song from the list-> \t enter 2\n● To list all the songs-> \t\t enter 3\n● To exit-> \t\t\t enter 4\n"
menuWarn: .asciiz "Please enter a valid input!\n"
name: .asciiz "Enter the name of the song: "
duration: .asciiz "Enter the duration: "
name2: .asciiz "Song name: "
duration2: .asciiz "Song duration: "
emptyList: .asciiz "List is empty!\n"
noSong: .asciiz "\nSong not found!\n"
songAdded: .asciiz "\nSong added.\n"
songDeleted: .asciiz "\nSong deleted.\n"

copmStr: .space 64

sReg: .word 3, 7, 1, 2, 9, 4, 6, 5
songListAddress: .word 0 #the address of the song list stored here!

.text 
main:

	jal initDynamicArray
	sw $v0, songListAddress
	
	la $t0, sReg
	lw $s0, 0($t0)
	lw $s1, 4($t0)
	lw $s2, 8($t0)
	lw $s3, 12($t0)
	lw $s4, 16($t0)
	lw $s5, 20($t0)
	lw $s6, 24($t0)
	lw $s7, 28($t0)

menuStart:
	la $a0, menu # print menu message
    li $v0, 4
    syscall

	li $v0,  5
    syscall
	li $t0, 1
	beq $v0, $t0, addSong # compare user input with menu options
	li $t0, 2
	beq $v0, $t0, deleteSong
	li $t0, 3
	beq $v0, $t0, listSongs
	li $t0, 4
	beq $v0, $t0, terminate
	
	la $a0, menuWarn # if invalid choice, print warning message, jump to the start of the menu
    li $v0, 4
    syscall
	b menuStart
	
addSong:
	jal createSong
	lw $a0, songListAddress
	move $a1, $v0
	jal putElement
	b menuStart
	
deleteSong:
	lw $a0, songListAddress
	jal findSong
	lw $a0, songListAddress
	move $a1, $v0
	jal removeElement
	b menuStart
	
listSongs:
	lw $a0, songListAddress
	jal listElements
	b menuStart
	
terminate:
	la $a0, newLine		
	li $v0, 4
	syscall
	syscall
	
	li $v0, 1
	move $a0, $s0
	syscall
	move $a0, $s1
	syscall
	move $a0, $s2
	syscall
	move $a0, $s3
	syscall
	move $a0, $s4
	syscall
	move $a0, $s5
	syscall
	move $a0, $s6
	syscall
	move $a0, $s7
	syscall
	
	li $v0, 10
	syscall


initDynamicArray: # probably done


	li $v0, 9
	li $a0, 12 
	syscall # create 12 bytes of dynamic memory for dynamic array

	move $t5, $v0 # move dynamic array address

	addi $sp, $sp, -4
	sw $v0, 0($sp) # save address of dynamic memory in stack pointer
	#! I didn't use the stack pointer in the code to access the dynamic array anywhere
	#! I didn't realize dynamic array had to be in heap at first so I used to save it here

	lw $t0, 0($sp) # t0 has address of dynamic array
	li $t1, 2 # capacity
	sw $t1, 0($t0) # capacity is saved first

	addi $t0, $t0, 4 # move 4 bytes forward
	li $t1, 0 # size
	sw $t1, 0($t0) # size is saved as second

	addi $t0, $t0, 4 # move 4 bytes forward
	li $v0, 9
	li $a0, 8 # need size of length of two addresses at the beginning to allocate
	syscall
	sw $v0, 0($t0) # third element holds an address now, which points to 8 bytes of memory

	move $v0, $t5 # move dynamic array address to v0 to return

	addi $sp, $sp, 4 # stack pointer is preserved
	
	jr $ra

putElement:

	move $t0, $a0 # $a0 holds the address of the dynamic array
	move $t1, $a1 # address of the song

	addi $t0, $t0, 8 # moved to the address of element part of the dynamic array
	lw $t3, 0($t0) # keep starting address of elements part in $t3
	
	addi $t0, $t0, -4
	lw $t8, 0($t0) # keep size in $t8

	addi $t0, $t0, -4
	lw $t7, 0($t0) # keep capacity in $t7

	sll $t2, $t8, 2 # multiply size by four
	add $t3, $t3, $t2 # address of first empty byte in the song array ($t3 starting address of elements, $t2 size * 4)

	sw $t1, 0($t3) # write song address to element address list

	li $v0, 4
	la $a0, songAdded
	syscall

	addi $t8, $t8, 1 # increase size by one
	addi $t0, $t0, 4 # move to size
	sw $t8, 0($t0) # write the new size

	slt $t5, $t8, $t7 # if size is not less than capacity ($t7 = capacity, $t8 = size)
	beq $t5, $zero, moveToNewPlace # expand
	j exitPutElement

	moveToNewPlace:

		sll $t7, $t7, 1 # multiply capacity by two
		addi $t0, $t0, -4 # move to capacity
		sw $t7, 0($t0) # write new capacity

		sll $t7, $t7, 2 # multiply capacity by four again (multiplied by 4 in the end, to find new bytes to be allocated)

		li $v0, 9
		move $a0, $t7
		syscall # create capacity * 4 bytes of memory space
		
		sub $t3, $t3, $t2 # return to the address of the first song

		addi $t0, $t0, 8 # address of the elements in $t0 (last 4 bytes of dynamic array)
		sw $v0, 0($t0)

		copySongsOneByOne:
			lw $t5, 0($t3)
			sw $t5, 0($v0) # write the song to the new address

			addi $v0, $v0, 4 # place where the address of the next song will be written if there is any left
			addi $t3, $t3, 4 # address of the next song in line to be copied to the new place

			addi $t8, $t8, -1 # reducing size until it reaches 0
			bne $t8, $zero, copySongsOneByOne

	#Write your instructions here!
	exitPutElement:
		jr $ra

removeElement:

	li $t0, -1
	beq $t0, $a1, noSuchSong # jump to print that there is no song with that name

	move $t0, $a1 # $t0 has index of the song now
	move $t1, $a0 # t1 -> address of the dynamic array

	lw $t2, 0($t1) # t2 has capacity

	addi $t1, $t1, 4
	lw $t3, 0($t1) # t3 has size
	beq $t3, $zero, removeElementExit # exit if size is 0, no elements to remove

	addi $t6, $t3, -1
	sub $t6, $t6, $t0 # t6 = size - (index + 1) -> this is the number of songs that must be moved backwards

	addi $t3, $t3, -1 # new size after removal
	sw $t3, 0($t1)

	addi $t1, $t1, 4
	lw $t4, 0($t1) # t4 has starting address of the songs

	sll $t5, $t0, 2 # multiply index by four to find how much we must move until the song to be deleted
	add $t4, $t4, $t5 # address of the song to be removed

	shiftIndex:

		addi $t7, $t4, 4 # second pointer, one cell in front of the previous pointer
		lw $t8, 0($t7)
		sw $t8, 0($t4) # write the content of the address to the address which precedes
		addi $t4, $t4, 4

		beq $t6, $zero, shrink
		addi $t6, $t6, -1
		j shiftIndex 

	
	shrink:

		li $t0, 2
		beq $t2, $t0, removeElementExit # jump to exit if capacity is 2

		addi $t3, $t3, 1 # (size + 1) * 2 must be equal to capacity if the array needs shrinking
		sll $t3, $t3, 1
		bne $t3, $t2, removeElementExit # t2 -> capacity

		srl $t2, $t2, 1 # new capacity must be old capacity / 2
		addi $t1, $t1, -8 # move to capacity
		sw $t2, 0($t1) # save new capacity

		sll $t2, $t2, 2 # multiply capacity by four to find new bytes to be allocated

		li $v0, 9
		move $a0, $t2
		syscall # create capacity * 4 bytes of memory space

		addi $t1, $t1, 8 # move to address of elements part of dynamic array
		lw $t0, 0($t1) # starting address of the songs

		sw $v0, 0($t1) # put new element address to dynamic array

		addi $t1, $t1, -4 # move to size
		lw $t3 0($t1) # t3 now holds size

		copySongs:

			lw $t4, 0($t0) # get address from the old place
			sw $t4, 0($v0) # save it in the new place

			addi $v0, $v0, 4
			addi $t0, $t0, 4
			addi $t3, $t3, -1
			
			beq $t3, $zero, removeElementExit
			j copySongs

	noSuchSong:

		li $v0, 4
		la $a0, noSong
		syscall # print no song
	

	removeElementExit:
	
		jr $ra

listElements:

	addi $sp, $sp, -4
	sw $ra 0($sp)

	move $t0, $a0 # move dynamic array address to t0
	addi $t0, $t0, 4 # move to size
	lw $t1, 0($t0) # size value in $t1 now
	beq $t1, $zero, printEmptyList # print empty list if size is zero
	addi $t0, $t0, 4 # move to address of elements

	lw $t2, 0($t0) # t2 = address of the first song
	
	printElementFunctionCallingLoop:

		move $a0, $t2
		jal printElement

		addi $t1, $t1, -1
		beq $t1, $zero, exitListElements
		addi $t2, $t2, 4 # move to next song
		j printElementFunctionCallingLoop

	printEmptyList:

		li $v0, 4
		la $a0, emptyList
		syscall

	#Write your instructions here!
	
	exitListElements:

		lw $ra 0($sp)
		addi $sp, $sp, 4
		jr $ra

compareString:

	lb $t9, 0($a0) # load the character
	lb $t8, 0($a1) # load the character
	# addi $a2, $a2, -1
	#! We discussed that I can compare strings without using string size so
	#! I removed the loop in which I use the string size to iterate 64 times, which I have done earlier.

	bne $t9, $t8, stringsNotEqual # if not equal, jump
	beq $t9, $zero, stringsEqual # if no jump occurs above and no more character to compare, strings are equal

	addi $a0, $a0, 1 # move to next character
	addi $a1, $a1, 1 # move to next character

	j compareString

	stringsEqual:

		li $v0, 4
		la $a0, songDeleted
		syscall

		li $v0, 1
		j exitCompareString
	
	stringsNotEqual:

		li $v0, 0
		j exitCompareString

	#Write your instructions here!
	
	exitCompareString:
	
		jr $ra
	
printElement:

	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# move $v0, $a0
	#! I commented it out since apparently we don't use v0 in the calling function (listElements)

	jal printSong

	lw $ra 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

createSong:

	li $v0, 9
	li $a0, 8 # allocate 8 bytes for name address and duration
	syscall

	move $t0, $v0 # move song address to $t0

	la $a0, name
	li $v0, 4
	syscall

	li $v0, 9
	li $a0, 64 # allocate 64 bytes for name
	syscall

	move $t1, $v0 # t1 now holds a memory address which leads to 64 bytes of memory

	sw $t1, 0($t0) # first 4 bytes of song now holds the address for the name

	move $a0, $t1 # move name address to $a0 for fgets argument?
	li $a1, 64 # name is 64 bytes
	li $v0, 8 # fgets
	syscall # string is saved

	la $a0, duration
	li $v0, 4
	syscall

	li $v0, 5
	syscall # ask for duration int

	addi $t0, $t0, 4
	sw $v0, 0($t0) # next four bytes of the where the song address leads now holds the duration (duration was written in $v0 above)

	addi $t0, $t0, -4 # return to the start of the allocated memory (song address)
	move $v0, $t0 # move the song address to $v0 before function returns
	jr $ra

findSong:

	addi $sp, $sp, -4
	sw $ra, 0($sp) # keep return address

	addi $a0, $a0, 4
	lw $t1, 0($a0) # size in $t1
	beq $t1, $zero, printEmptyListForDelete

	addi $a0, $a0, 4
	lw $t2, 0($a0) # address of elements in $t2
	
	lw $t3, 0($t2) # address of first song in $t3
	lw $t4, 0($t3) # address of the name of the song

	la $a0, name2
	li $v0, 4
	syscall

	la $a0, copmStr # move name address to $a0 for fgets argument?
	li $a1, 64 # name is 64 bytes
	li $v0, 8 # fgets
	syscall # string is saved

	move $a1, $t4 # plug song name as argument
	li $a2, 64 # plug comparison size as argument
	addi $t1, $t1, -1 # use array size for loop count
	li $t7, 0 # $t7 to keep index for the song lists

	jal compareString
	li $t0, 1
	beq $v0, $t0, songFound # if 1 returns from above jal compareString, go to songFound

	compareStringLoop:

		beq $t1, $zero songNotFound # branch out if array has no more elements to compare
		addi $t2, $t2, 4 # move to new song address
		lw $t3, 0($t2) # t3 now holds the address of the song
		lw $t4, 0($t3) # t4 now holds the address of the name of the song

		la $a0, copmStr # set arguments
		move $a1, $t4
		li $a2, 64

		jal compareString
		addi $t1, $t1, -1 # use array size for loop count
		addi $t7, $t7, 1 # increase index by one
		beq $v0, $t0, songFound # if v0 == 1 song is found
		j compareStringLoop # return to loop
	
	#Write your instructions here!

	songFound:

		move $v0, $t7 # return index of the song
		j findSongExit
	
	songNotFound:
	
		li $v0, -1 # return -1 if not found
		j findSongExit
	
	printEmptyListForDelete:

		li $v0, 4
		la $a0, emptyList
		syscall

	findSongExit:

		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		jr $ra

printSong:

	lw $t3, 0($a0) # t2 = address of name of the song

	addi $t4, $t3, 4 # address of duration of song

	li $v0, 4
	la $a0, newLine
	syscall

	li $v0, 4
	la $a0, name2
	syscall

	li $v0, 4
	lw $a0, 0($t3)
	syscall

	li $v0, 4
	la $a0, duration2
	syscall

	li $v0, 1
	lw $a0, 0($t4)
	syscall

	li $v0, 4
	la $a0, newLine
	syscall # printed new line twice at the start and end to group the song and durations together
	#Write your instructions here!
	
	jr $ra

additionalSubroutines:



