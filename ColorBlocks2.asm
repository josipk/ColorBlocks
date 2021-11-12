/**********************************************
		Simple script demo
************************************************/
#import "Libs/MyStdLibs.lib"

BasicUpstart2(mainProg)


.function screenToD018(addr) {										// <- This is how we define a function
	.return ((addr&$3fff)/$400)<<4
}
.function charsetToD018(addr) {
	.return ((addr&$3fff)/$800)<<1
}
.function toD018(screen, charset) {
	.return screenToD018(screen) | charsetToD018(charset)			//<- This is how we call functions
}
//----------------------------------------------------
// 			Main Program
//----------------------------------------------------
*=$1000 "Main Program"

//.var char_color = $10

.var init_color = 0
.var x0 = 0
.var y0 = 0
.var position = $20
.var old_position = $22
.var color_position = $28
.var temp_position = $26
.var temp_position2 = $24
.var temp_position3 = $30
.var temp_position4 = $40
.var temp_position5 = $42
.var temp_color_position_1 = $46
.var temp_color_position_2 = $32
.var temp_color_position_3 = $34
.var temp_color_position_4 = $36
.var temp_color_position_5 = $44
.var chk_position = $50
.var chk_position_temp = $54
.var chk_color_position = $58

.label SCNKEY     = $ff9f   // scan keyboard - kernal routine
.label GETIN      = $ffe4   // read keyboard buffer - kernal routine
//sta $d800,x
//0400 + d4000 = color memory locations

mainProg: {		// <- Here we define a scope

		
		sei
		//ClearScreen($3c00, $20)
		ClearScreen($0400, $20)
		ClearScreen($d800, $ff)
		jsr setSIDGenerator
		//Set 1st color	
		//lda #init_color
		//sta char_color
		// set to 25 line text mode and turn on the screen
		lda #$1B
		sta $d011

		lda #13
		sta 2040

		// set background color
		//lda #$6
		//sta $d021		

		// set background color
		lda #0
		sta $d021		

		// set text color
		lda #$02
		sta $0286

		//activate 3c000 screen
		//lda #$F5 //5- uppercase chars
		lda #$F6   //6- lowercase chars
		sta $d018

        lda #1
        sta $0289  //  disable keyboard buffer
        lda #127
        sta $028a  // disable key repeat

check_keypress:
        jsr SCNKEY
        jsr GETIN

spacebar_check:
        cmp #$20
        bne check_keypress

        //back to 0400 screen
		//lda #$15
		//sta $d018			

        //back to 0400 screen, custom char ($2800)
		lda #$1A
		sta $d018			


//------------------------------------------

		jsr GenerateColorsHorizontal


//------------------------------------------
		/*Create top bar*/
		ldx #0
drawnextbar:
		lda top_bar,x
		sta $0400,x
		lda #7
		sta $d800,x
		inx
		cpx #40
		bcc drawnextbar
//------------------------------------------


//------------------------------------------
		ldx #0
		stx y_pos
		stx y2_pos
		stx x_pos
		stx x2_pos
		stx color_index
		
		stx score
		stx score+1

		lda #$24
		sta y_pos_min	

//generate start column
rnd1:   jsr generateRnd		
		ldx seed
		cpx #40
		bcs rnd1
/*
rnd1:   jsr setSIDGenerator
		ldx $D41B	
		cpx #40
		bcs rnd1
*/

		//set y_pos at zero!
		ldx #1
		stx y_pos

		ldx #10
		stx main_deley_speed

		//set x_pos at seed value!
		lda seed
		sta x_pos

		adc #40
		sta position
		lda #$04
		sta position+1

		//Set old position same as current position	
		lda position
        sta old_position 
		lda position+1
        sta old_position+1 

		lda #228  //char that we want to print
        ldy #x0 //offset
        sta (position), y 

//---------------------------------------set position color--------------------
		jsr setPositionAndColorIndex	
//---------------------------------------set position color--------------------

        jsr setDelay1


 // Add 41 to the low byte
loop1:	  
		jsr checkIfPositionsAreEmpty
		// positions_taken = #% 0 0 0 0           0            0      0       0
		//                            [down left] [down right] [down] [right] [left] 

		ldx #0
		stx x_offset

left:   lda $DC00 //56320	
		and #4
		bne right
		
		lda positions_taken
		and #%00000010
		cmp #2
		beq right	

		lda positions_taken
		and #%00010000
		cmp #16
		beq right

		lda x_pos
		cmp #0
		beq right			

		//inc main_deley_speed
		sec
		dec x_pos
		inc y_pos

		clc
		lda position
		adc #39       //add 39 colums
		sta position
		// If carry is set, increment the high byte
		bcc skipleft4
		inc position+1
skipleft4:	clc	    

		jsr AnimateLeftMove

		lda position
        sta old_position 
		lda position+1
        sta old_position+1 

right:	lda $DC00 //56320	
		and #8
		bne button

		lda positions_taken
		and #%00000001
		cmp #1
		beq button	

		lda positions_taken
		and #%00001000
		cmp #8
		beq button	

		lda x_pos
		cmp #39
		bcs button			

		//clc
		//inc main_deley_speed
		clc
		inc x_pos
		inc y_pos

		clc
		lda position
		adc #41       //add 40 colums
		sta position
		// If carry is set, increment the high byte
		bcc skipright34
		inc position+1
skipright34:	clc	 


		jsr AnimateRightMove

		lda position
        sta old_position 
		lda position+1
        sta old_position+1 


button:	lda $DC00 //56320	
		and #16
		bne continuedropping

		//ldx #1
		//stx main_deley_speed
		jsr setPositionAndColorIndex


continuedropping:
		clc
		lda position
		adc #40       //add 40 colums
		sta position
		// If carry is set, increment the high byte
		bcc skip
		inc position+1
skip:	clc

		//Check if position is taken!!!!
		ldx #0
        lda (position,x) 
        cmp #32
        bne addrHasChar

        //Update y_pos
		//incroment y_pos 
		clc
		inc y_pos



//------------------------------------------------
//Clear old position
frame1: 
		lda $d012		// Wait for frame
		cmp #$ff
		bne frame1

		lda #121  //char that we want to print
        ldy #x0 //offset
        sta (old_position), y

		lda #120  //char that we want to print
        ldy #x0 //offset
        sta (position), y 

		jsr setPositionColor1

		jsr setDelay2
		//--------------------------------------------------------------------------------HERE WE DEFINE SPEED!!!!

frame2: lda $d012		// Wait for frame
		cmp #$ff
		bne frame2

		lda #$20  //char that we want to print
        ldy #x0 //offset
        sta (old_position), y

        jsr clearOldPositionColor1	

		lda #228  //char that we want to print
        ldy #x0 //offset
        sta (position), y 

		//jsr setPositionColor1

		jsr setDelay2

		//--------------------------------------------------------------------------------HERE WE DEFINE SPEED!!!!


//Check did we get to the end of screen!
     	lda position
        cmp #$C0
        lda position+1
        sbc #$07
        bcc addr1IsBigger
        bne weHitBottomScreen
        //else equal...


//we hit bottom of page
//or we hit another char
weHitBottomScreen:

		lda #229  //char that we want to print
        ldy #x0 //offset
        sta (position), y 
		
		//Here we will call check function 
		jsr checkColorsAndPositionsMain
      	jmp rnd1

addrHasChar:

		lda #229  //char that we want to print
        ldy #x0 //offset
        sta (old_position), y 
		
		//Here we will call check function 
		jsr checkColorsAndPositionsMain
      	jmp rnd1


addr1IsBigger:
        //lda #3     //(space char)
        //ldx #0
      	//sta $0400,x     //(print it)

delaypos:
		//we need to make copy of current position
		
		jsr clearOldPositionColor1

		lda position
        sta old_position 
		lda position+1
        sta old_position+1 
		//----------------------------------------

		jmp loop1				  				

exit:	rts
			
}

AnimateLeftMove: {

	    //we are animate from b to c
	    //a b
	    //c d
		//.byte	$00,$00,$00,$00,$07,$0F,$0D,$0F	// #252 $FC [left up]
		//.byte	$00,$00,$00,$00,$E0,$F0,$B0,$F0	// #253 $FD [right up]
		//.byte	$0F,$0F,$0E,$0F,$07,$00,$00,$00	// #254 $FE [left down]
		//.byte	$F0,$F0,$70,$F0,$E0,$00,$00,$00	// #255 $FF [right down]
		//---------------------------------------------------
		// a -- (old_position-1) - #252 - temp_position4
		// b -- old_position - #253
		// c -- position - #254
		// d -- (position+1) - #255  - temp_position3

		/*
		setTempPositionColor3
		clearTempPositionColor3

		setTempPositionColor4
		clearTempPositionColor4

		.var temp_position3 = $60
		.var temp_position4 = $62
		*/

		//here we delete old position and switch to new position
		//Left switch
		

		ldy #0
		sty temp_var

		clc
		ldx old_position
		stx temp_position4
		ldx old_position+1
		stx temp_position4+1
				

		lda temp_position4
		sec
	    sbc #1
	    sta temp_position4
		bne tquitk4
		dec temp_position4+1
tquitk4:
		//lda temp_position4+1
		//sbc #0 
	    //sta temp_position4+1		


		clc
		ldx position
		stx temp_position3
		ldx position+1
		stx temp_position3+1


		inc temp_position3
		bne tzrepc1
		inc temp_position3+1
tzrepc1:
	

		jsr setDelay2

		

		ldy #0
		lda (temp_position3),y
		cmp #$20
		bne donotchangethisposition1

		ldx #1
		stx temp_var

		lda #255  //char that we want to print
        ldy #0 //offset
        sta (temp_position3), y
        
        jsr setTempPositionColor3

donotchangethisposition1:


		lda #252  //char that we want to print
        ldy #0 //offset
        sta (temp_position4), y

		lda #253  //char that we want to print
        ldy #0 //offset
        sta (old_position), y

		lda #254  //char that we want to print
        ldy #x0 //offset
        sta (position), y 

		jsr setPositionColor1
		jsr setTempPositionColor4


		jsr setDelay1
		//jsr setDelay3
		//--------------------------------------------------------------------------------HERE WE DEFINE SPEED!!!!

		lda #$20  //char that we want to print
        ldy #x0 //offset
        sta (old_position), y
        sta (temp_position4), y        

		ldx temp_var
		cpx #1
		bne donotclearthisposition1


		lda #$20  //char that we want to print
        ldy #x0 //offset
        sta (temp_position3), y
        jsr clearTempPositionColor3

donotclearthisposition1:
		lda #228  //char that we want to print
        ldy #x0 //offset
        sta (position), y

        jsr clearOldPositionColor1
		jsr clearTempPositionColor4      

		jsr setDelay2
		//jsr setDelay3
		//--------------------------------------------------------------------------------HERE WE DEFINE SPEED!!!!
		//---------------------------------------------------
		/*
		lda position
        sta old_position 
		lda position+1
        sta old_position+1
        */
        rts
}


AnimateRightMove: {

	    //we are animate from a to d
	    //a b
	    //c d
		//.byte	$00,$00,$00,$00,$07,$0F,$0D,$0F	// #252 $FC [left up]
		//.byte	$00,$00,$00,$00,$E0,$F0,$B0,$F0	// #253 $FD [right up]
		//.byte	$0F,$0F,$0E,$0F,$07,$00,$00,$00	// #254 $FE [left down]
		//.byte	$F0,$F0,$70,$F0,$E0,$00,$00,$00	// #255 $FF [right down]
		//---------------------------------------------------
		// a -- old_position - #252 
		// b -- (old_position+1) - #253 - temp_position3
		// c -- (position-1) - #254 - temp_position4
		// d -- position - #255  

		/*
		setTempPositionColor3
		clearTempPositionColor3

		setTempPositionColor4
		clearTempPositionColor4

		.var temp_position3 = $60
		.var temp_position4 = $62
		*/

		//here we delete old position and switch to new position
		//Left switch
		

		ldy #0
		sty temp_var

		clc
		ldx position
		stx temp_position4
		ldx position+1
		stx temp_position4+1
				

		lda temp_position4
		sec
	    sbc #1
	    sta temp_position4
		bne tquitkzu64
		dec temp_position4+1
tquitkzu64:
		//lda temp_position4+1
		//sbc #0 
	    //sta temp_position4+1		


		clc
		ldx old_position
		stx temp_position3
		ldx old_position+1
		stx temp_position3+1


		inc temp_position3
		bne tzrepcx169a
		inc temp_position3+1
tzrepcx169a:
	

		jsr setDelay2
		//jsr setDelay3

		ldy #0
		lda (temp_position4),y
		cmp #$20
		bne donotchangethisposition2

		ldx #1
		stx temp_var

		lda #254  //char that we want to print
        ldy #0 //offset
        sta (temp_position4), y
        
        jsr setTempPositionColor4

donotchangethisposition2:


		lda #253  //char that we want to print
        ldy #0 //offset
        sta (temp_position3), y

		lda #252  //char that we want to print
        ldy #0 //offset
        sta (old_position), y

		lda #255  //char that we want to print
        ldy #x0 //offset
        sta (position), y 

		jsr setPositionColor1
		jsr setTempPositionColor3


		jsr setDelay1
		//jsr setDelay3
		//--------------------------------------------------------------------------------HERE WE DEFINE SPEED!!!!

		lda #$20  //char that we want to print
        ldy #x0 //offset
        sta (old_position), y
        sta (temp_position3), y        

		ldx temp_var
		cpx #1
		bne donotclearthisposition2


		lda #$20  //char that we want to print
        ldy #x0 //offset
        sta (temp_position4), y
        jsr clearTempPositionColor4

donotclearthisposition2:
		lda #228  //char that we want to print
        ldy #x0 //offset
        sta (position), y

        jsr clearOldPositionColor1
		jsr clearTempPositionColor3      

		jsr setDelay2
		//jsr setDelay3
		//--------------------------------------------------------------------------------HERE WE DEFINE SPEED!!!!
		//---------------------------------------------------
		
		/*
		lda position
        sta old_position 
		lda position+1
        sta old_position+1
        */

        rts
}


setPositionAndColorIndex: {

//---------------------------------------set position color--------------------
		//Set Next Char color	
		//Save position and transit to color postion!
		//Colors address starts at $d800
		clc
		ldx color_index
		cpx #4
		bne setCharColor

		//Set 1st color	
		lda #0
		sta color_index

setCharColor:		

		ldx color_index
		inx	
		stx color_index

        ldx color_index
        lda colorlist,x //color
        sta char_color

		jsr setPositionColor1
//---------------------------------------set position color--------------------

		rts
	
}

setPositionColor1: {

//---------------------------------------set position color--------------------
		lda position
        sta color_position 
		clc
		lda position+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda char_color
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}



setOldPositionColor1: {

//---------------------------------------set position color--------------------
		lda old_position
        sta color_position 
		clc
		lda old_position+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda char_color
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}

clearOldPositionColor1: {

//---------------------------------------set position color--------------------
		lda old_position
        sta color_position 
		clc
		lda old_position+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda #$ff
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}


setTempPositionColor3: {

//---------------------------------------set position color--------------------
		lda temp_position3
        sta color_position 
		clc
		lda temp_position3+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda char_color
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}

clearTempPositionColor3: {

//---------------------------------------set position color--------------------
		lda temp_position3
        sta color_position 
		clc
		lda temp_position3+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda #$ff
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}

//------------------------------------------------------------------------------

setTempPositionColor4: {

//---------------------------------------set position color--------------------
		lda temp_position4
        sta color_position 
		clc
		lda temp_position4+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda char_color
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}

clearTempPositionColor4: {

//---------------------------------------set position color--------------------
		lda temp_position4
        sta color_position 
		clc
		lda temp_position4+1
        adc #$d4
        sta color_position+1 
        clc
        ldy #0 //offset
        lda #$ff
        sta (color_position),y

        rts
//---------------------------------------set position color--------------------
}



//------------------------------------------------------------------------------
checkIfPositionsAreEmpty: {

	lda #0
	sta positions_taken

	ldx position
	stx temp_position3
	ldx position+1
	stx temp_position3+1

	//check right position
	inc temp_position3
	bne noclc1
	inc temp_position3+1
noclc1:

	//--------------------------
	//ldy #0
	//lda #1
	//sta (temp_position3),y
	//--------------------------

	ldy #0
	lda (temp_position3),y
	cmp #$21
	bcc itisempty1
	
	lda positions_taken
	ora #%00000001
	sta positions_taken
itisempty1:


	ldx position
	stx temp_position3
	ldx position+1
	stx temp_position3+1

	//check left position
	//dec temp_position3
	//bne noclc2
	//dec temp_position3+1

	lda temp_position3
    sec
    sbc #1
    sta temp_position3
	lda temp_position3+1
	sbc #0 
    sta temp_position3+1


//noclc2:

	//--------------------------
	//ldy #0
	//lda #1
	//sta (temp_position3),y
	//--------------------------

	ldy #0
	lda (temp_position3),y
	cmp #$21
	bcc itisempty2
	
	lda positions_taken
	ora #%00000010
	sta positions_taken
itisempty2:

	//check down position
	ldx position
	stx temp_position4
	ldx position+1
	stx temp_position4+1


    lda temp_position3        //get the low byte of the first number
    adc #41     		     //add to it the low byte of the second
    sta temp_position3    //store in the low byte of the result
	bcc skipincd
	inc temp_position3+1
skipincd:
	clc

	//--------------------------
	//ldy #0
	//lda #2
	//sta (temp_position3),y
	//--------------------------

	ldy #0
	lda (temp_position3),y
	cmp #$21
	bcc itisempty3
	
	lda positions_taken
	ora #%00000100
	sta positions_taken

itisempty3:



	//check right position
	inc temp_position3
	bne noclc4
	inc temp_position3+1
noclc4:

	//--------------------------
	//ldy #0
	//lda #3
	//sta (temp_position3),y
	//--------------------------


	ldy #0
	lda (temp_position3),y
	cmp #$21
	bcc itisempty4
	
	lda positions_taken
	ora #%00001000
	sta positions_taken
itisempty4:


	//check left position
	/*
	dec temp_position3
	dec temp_position3
	bne noclc5
	dec temp_position3+1
	*/

	lda temp_position3
    sec
    sbc #2
    sta temp_position3
	lda temp_position3+1
	sbc #0 
    sta temp_position3+1

noclc5:

	//--------------------------
	//ldy #0
	//lda #4
	//sta (temp_position3),y
	//--------------------------


	ldy #0
	lda (temp_position3),y
	cmp #$21
	bcc itisempty5
	
	lda positions_taken
	ora #%00010000
	sta positions_taken
itisempty5:
	
	//jmp itisempty5 

	rts
}

// positions_taken = #% 0 0 0 0           0            0      0       0
//                            [down left] [down right] [down] [right] [left]  

dropdownallAbove: {

	//temp_position4
	//jsr getPositionAtXY

	clc
	ldx y2_pos
    stx counter
	//stx $0430

nextup:

	clc
	ldx counter
	dex
	stx counter
    clc

    sec
    lda temp_position4         //get the low byte of the first number
    sbc #40     		     //add to it the low byte of the second
    sta temp_position5    //store in the low byte of the result
    lda temp_position4+1     		//get the high byte of the first number
	sbc #0
    sta temp_position5+1     //store in high byte of the result
    clc

	clc
	lda temp_position5
    sta temp_color_position_5 
	lda temp_position5+1
    adc #$d4
    sta temp_color_position_5+1	    

	clc
	lda temp_position4
    sta temp_color_position_4 
	lda temp_position4+1
    adc #$d4
    sta temp_color_position_4+1	    

    clc
    ldy #0
    lda (temp_position5),y  
    sta (temp_position4),y

    lda (temp_color_position_5),y
    sta (temp_color_position_4),y

    clc
    lda temp_position5         //get the low byte of the first number
    sta temp_position4    //store in the low byte of the result
    lda temp_position5+1     		//get the high byte of the first number
   	sta temp_position4+1     //store in high byte of the result
    clc

	clc
	ldx counter
	//stx $0400
	cpx #1
	bne nextup

	ldy #0
	lda #$20
    sta (temp_position5),y 
    lda #$ff
    sta (temp_color_position_5),y

	rts
}

dropdownOneAbove: {

	//temp_position4
	//jsr getPositionAtXY

	clc
	ldx y2_pos
    stx counter
	//stx $0430

    lda temp_position4         //get the low byte of the first number
    sta temp_position5    //store in the low byte of the result
    lda temp_position4+1     		//get the high byte of the first number
    sta temp_position5+1     //store in high byte of the result

	/*
	clc
	ldy #0
	lda temp_position4
    sta temp_color_position_4 
	lda temp_position4+1
    adc #$d4
    sta temp_color_position_4+1	    
    lda #$ff
    sta (temp_color_position_4),y
	*/

nextup:

	/*
	clc
	ldx counter
	dex
	stx counter
    clc
	*/
	dec counter

    sec
    lda temp_position4         //get the low byte of the first number
    sbc #40     		     //add to it the low byte of the second
    sta temp_position4    //store in the low byte of the result
    lda temp_position4+1     		//get the high byte of the first number
	sbc #0
    sta temp_position4+1     //store in high byte of the result
    clc

    //check if empty
	ldy #0
	lda #$20
    lda (temp_position4),y 
    cmp #$20
    beq continuenextposup1


	clc
	lda temp_position5
    sta temp_color_position_5 
	lda temp_position5+1
    adc #$d4
    sta temp_color_position_5+1	    

	clc
	lda temp_position4
    sta temp_color_position_4 
	lda temp_position4+1
    adc #$d4
    sta temp_color_position_4+1	    

    clc

    ldy #0
    lda (temp_position4),y  
    sta (temp_position5),y

    lda (temp_color_position_4),y
    sta (temp_color_position_5),y

	ldy #0
	lda #$20
    sta (temp_position4),y 
    lda #$ff
    sta (temp_color_position_4),y

	jsr playdrop

    jmp we_are_done_here1

continuenextposup1:

	clc
	lda temp_position4
    sta temp_color_position_4 
	lda temp_position4+1
    adc #$d4
    sta temp_color_position_4+1
    
    ldy #0
    lda #$ff 
    sta (temp_color_position_4),y

	clc
	ldx counter
	//stx $0400
	cpx y_pos_min
	bcs nextup

we_are_done_here1:
	
	rts
}

//-----------------------------CHECK 4 COLORS
ChkColorsMatchHorizontal: {

		//lda y_pos_min
		//sta y2_pos
		
		lda #24
		sta y2_pos
		//sta chk_y_pos


looprows:

		jsr ChkColorsMatchHorizontalLine

		dec y2_pos
		lda y2_pos
		cmp y_pos_min
		bcs looprows

		rts
}


ChkColorsMatchHorizontalLine: {


		jsr startLineAtPositionY

		lda temp_position
		sta chk_position
		sta chk_position_temp
		lda temp_position+1
		sta chk_position+1
		sta chk_position_temp+1

		/*
		lda #1
		ldy #0
		sta (chk_position),y
		*/

		jsr ChkGetColor4Pos
		lda chk_temp_color
		sta chk_temp_color_prev

		lda #0
		sta chk_x_pos

//---------------------------------------------
opright:
		//ONE POSTION RIGHT		
		clc
		inc chk_position
		bne jj1
		inc chk_position+1	
jj1:	

	
		jsr ChkGetColor4Pos
		lda chk_temp_color_prev
		cmp chk_temp_color
		bne contright
		//if same color dele them
		
		//Check if empty
		
		ldy #0
    	lda (chk_position),y
		cmp #229
		bne contrightnonew
		
		inc we_have_color_match

contrightnonew:
		ldy #0
    	lda #$20
    	//lda #1
    	sta (chk_position),y
    	sta (chk_position_temp),y
		
		

contright:
		
		lda chk_temp_color
		sta chk_temp_color_prev

		lda chk_position
		sta chk_position_temp
		lda chk_position+1
		sta chk_position_temp+1

		inc chk_x_pos
		lda chk_x_pos
		cmp #39
		bcc opright		
//---------------------------------------------

		rts
			
}
//----------------------------
ChkEmptyPlaces: {
		
		lda #24
		sta y2_pos

looprows:

		jsr ChkEmptyPlaceslLine

		//jsr setDelay2

		dec y2_pos
		lda y2_pos
		cmp y_pos_min
		bcs looprows

		rts




}
//------------------------------------------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ChkEmptyPlaceslLine: {

		jsr startLineAtPositionY

		lda temp_position
		sta chk_position
		lda temp_position+1
		sta chk_position+1

		lda #0
		sta chk_x_pos
//---------------------------------------------
opright33:

		ldy #0
    	lda (chk_position),y
		cmp #$20
		bne contright3

		
			lda chk_position
		    sta temp_color_position_4 
			clc			
			lda chk_position+1
		    adc #$d4
		    sta temp_color_position_4+1	 
		    ldy #0   
		    lda #$ff
		    sta (temp_color_position_4),y
		
			//jsr playdrop
		clc
		sec
		
		lda chk_position
		sta temp_position4
		lda chk_position+1
		sta temp_position4+1		

		jsr dropdownOneAbove
		

contright3:
		
		//ONE POSTION RIGHT		
		/*
		inc chk_position
		bne jj33
		inc chk_position+1	
jj33:
		*/
		clc
		lda chk_position
		adc #1       //add 40 colums
		sta chk_position
	// If carry is set, increment the high byte
		bcc jj33
		inc chk_position+1
jj33:
		inc chk_x_pos
		lda chk_x_pos
		cmp #40
		bcc opright33		
//---------------------------------------------
		


		rts

}

//-----------------------------CHECK 4 COLORS
ChkColorsMatchVertial: {

		//lda y_pos_min
		//sta y2_pos
		
		lda #0
		sta x2_pos
		//sta chk_y_pos


looprows1:

	

		jsr ChkColorsMatchVertialLine


		inc x2_pos

		clc
		lda x2_pos
		cmp #40
		bcc looprows1

		rts
}


ChkColorsMatchVertialLine: {

		lda y_pos_min
		sta y2_pos

		jsr getPositionAtXY

		/*
		ldy #0
		lda #1
		sta (temp_position),y
		*/

		lda temp_position
		sta chk_position
		lda temp_position+1
		sta chk_position+1

		jsr ChkGetColor4Pos
		lda chk_temp_color
		sta chk_temp_color_prev

		lda #0
		sta chk_x_pos
//---------------------------------------------
opright1:
		//ONE POSTION RIGHT		
		lda chk_temp_color
		sta chk_temp_color_prev
		lda chk_position
		sta chk_position_temp
		lda chk_position+1
		sta chk_position_temp+1

	    
	    lda chk_position         //get the low byte of the first number
	    adc #40
	    sta chk_position    //store in the low byte of the result
	    bcc skipopgtzu7
	    inc chk_position+1     //store in high byte of the result
skipopgtzu7:
	    
		jsr ChkGetColor4Pos
		lda chk_temp_color_prev
		cmp chk_temp_color
		bne contright1
		//if same color dele them
	    
		ldy #0
    	lda (chk_position),y
		//cmp #$20
		//beq contrightnonew1
		cmp #229
		bne contright1
		
		inc we_have_color_match

		ldy #0
    	lda #$20
    	//lda #1
    	sta (chk_position),y
    	sta (chk_position_temp),y

contright1:
		


		inc chk_x_pos

		lda chk_x_pos
		cmp #25
		bcc opright1		
//---------------------------------------------
		rts
}
//----------------------------

//----------------------------
ChkGetColor4Pos: {

	clc
	lda chk_position
    sta chk_color_position 
	lda chk_position+1
    adc #$d4
    sta chk_color_position+1	 

    ldy #0
    lda (chk_color_position),y
	and #%00001111
	sta chk_temp_color

	rts
}

ChkDeletePositionAndColor: {

	clc
	lda chk_position
    sta chk_color_position 
	lda chk_position+1
    adc #$d4
    sta chk_color_position+1	 

	clc
    ldy #0
    lda #$20
    sta (chk_position),y

    lda #$ff
    sta (chk_color_position),y

	rts
}

ChkDeletePosition: {

	clc
    ldy #0
    lda #$20
    sta (chk_position),y

	rts
}


//---------------------------------------------------------


calcCurrPosFromColorPos: {

    sec
    lda color_position         //get the low byte of the first number
    sta temp_position    //store in the low byte of the result
    lda color_position+1     		//get the high byte of the first number
	sbc #$d4
    sta temp_position+1     //store in high byte of the result

	rts
}


getPositionAtXY: { 

	clc
	ldx x2_pos 
	stx temp_position
	ldx #$04 
	stx temp_position+1

	ldx #0 
addrow157:
	clc
	lda temp_position
	adc #40       //add 40 colums
	sta temp_position
	bcc skip1188
	inc temp_position+1
skip1188:
	inx
	cpx y2_pos
	bcc addrow157

	rts
}


startLineAtPositionY: { 

	ldx #0 
	stx temp_position
	ldx #$04 
	stx temp_position+1

	ldx #0 
addrow17:
	lda temp_position
	clc
	adc #40    //add 40 colums
	sta temp_position
	bcc skip1199
	inc temp_position+1
skip1199:
	inx
	cpx y2_pos
	bcc addrow17

	rts
}


playdrop: {
		lda #90
		sta $D400
		lda #15
		sta $D401

		lda #%10000001
		sta $D404

		lda #%01000010  // noise waveform, gate bit off
		sta $D405 // voice 1 control register

		lda #%00001010
		sta $D418		

		jsr setDelay2

		lda #%00000000
		sta $D404
		rts
}
//-----------------------TEMPORARY-----------------------------------------------------------------------------



//-----------------------------CHECK 4 COLORS
GenerateColorsHorizontal: {

		lda #24
		sta y2_pos
		//sta chk_y_pos

		lda #0
		sta x2_pos


looprows3:

		jsr GenerateColorsHorizontalLine

		sec	
		dec y2_pos
		lda y2_pos
		cmp #16
		bcs looprows3

		rts
}


GenerateColorsHorizontalLine: {

		jsr startLineAtPositionY

		lda temp_position
		sta chk_position
		lda temp_position+1
		sta chk_position+1

		lda #0
		sta chk_x_pos

//---------------------------------------------
opright6:

		
		lda #229
		//lda chk_x_pos
		ldy #0
		sta (chk_position),y
		
		clc
		lda chk_position
        sta chk_color_position 
		lda chk_position+1
        adc #$d4
        sta chk_color_position+1 
        clc

        //lda #1
        //sta main_deley_speed

rndctz1: 
		lda $D41B
		cmp #5
		bcs rndctz1
		sta color_index

      	
        ldy #0 //offset
        ldx color_index
        lda colorlist,x //color
        sta (chk_color_position),y        					

		//ONE POSTION RIGHT		
		clc
		inc chk_position
		bne jj16
		inc chk_position+1	
jj16:	

		inc chk_x_pos
		lda chk_x_pos
		cmp #40
		bcc opright6	
//---------------------------------------------

		rts
			
}

//main check start 
checkColorsAndPositionsMain: {


	jsr playdrop

	lda y_pos
	cmp y_pos_min
	bcs ccctuf1

	lda y_pos
	sta y_pos_min

	

ccctuf1:
	
	/*
	lda #$20
	sta $0401
	sta $0402
	*/	

	lda #0
    sta we_have_color_match
    sta we_have_row_match

	ldx y_pos
	stx y2_pos

	ldx x_pos
	stx x2_pos

	//lda #1
	//sta $0401

	jsr ChkColorsMatchHorizontal 

	ldx y_pos
	stx y2_pos

	ldx x_pos
	stx x2_pos

	//lda #2
	//sta $0402

	jsr ChkColorsMatchVertial

	ldx y_pos
	stx y2_pos

	ldx x_pos
	stx x2_pos

	/*
	lda we_have_color_match
	sta $0401
	*/

	jsr ChkEmptyPlaces


	lda we_have_color_match
	cmp #1
	bcs ccctuf1
	

	//lda #4
	//sta $0404

	ldx y_pos
	stx y2_pos

	ldx x_pos
	stx x2_pos

	lda #0
    sta we_have_color_match
    sta we_have_row_match


	jsr checkFullRow2 

	//lda row_match_counter
	//sta $0400

	/*
	lda #$20
	sta $0401
	sta $0402
	sta $0403
	*/

	rts
}



checkFullRow2: { 

	jsr startLineAtPositionY

    ldx #0
    stx same_color_counter
    stx column_counter

	ldx #0
	lda #0

nextcolumn2:

	ldy #0
    lda (temp_position),y
  	cmp #$20
	beq nomatchhere

	inc same_color_counter

nomatchhere:
	inc temp_position
	bne skip142
	inc temp_position+1
skip142:
	inc column_counter
	ldx column_counter
	cpx #40
	bcc nextcolumn2

	ldx same_color_counter
	cpx #40
	bcc skipdelay1	
	
	inc we_have_row_match
	
	//inc row_match_counter
	jsr AddAndPrintScore
	//--------------------------------------------_DELAY-------------------------------------
	//jsr setDelay2
	//jsr setDelay1

	//PRINT SCORE ON TOP BAR!!!
	/*
	lda row_match_counter
	adc #175
	sta $0401
	*/
	jsr playbeep



	//END now clear all
	//jsr playBigBeep

	jsr clearColorsInRow3

	jsr playBigBeep

	jsr setDelay1 
	
	jsr clearColorsInRow4

	jsr playBigBeep

	jsr setDelay1 

	jsr clearColorsInRow2

	jsr playbeep

skipdelay1:
	rts
}

clearColorsInRow2: {

	jsr startLineAtPositionY

    ldx #0
    stx column_counter

	ldx #0
	lda #0

nextcol284:

    //(temp_position,x) 
 	
	lda temp_position
    sta temp_color_position_5 
	lda temp_position+1
    clc
    adc #$d4
    sta temp_color_position_5+1	

	lda temp_position
    sta temp_position4 
	lda temp_position+1
    sta temp_position4+1
	
    jsr dropdownallAbove
    
	inc temp_position
	bne skip1252
	inc temp_position+1
skip1252:

	
	/*
	ldx column_counter
	inx
	stx column_counter 
	*/
	inc column_counter 

	ldx column_counter
	cpx #40
	bcc nextcol284

	rts
}


clearColorsInRow3: {

	jsr startLineAtPositionY

    ldx #0
    stx column_counter

	ldx #0
	lda #0

nextcol2841:

    //(temp_position,x) 
 	
	lda temp_position
    sta temp_color_position_5 
	lda temp_position+1
    clc
    adc #$d4
    sta temp_color_position_5+1	

	lda temp_position
    sta temp_position4 
	lda temp_position+1
    sta temp_position4+1
	

    //jsr dropdownallAbove
	//make animation!!!!!===================================================================================================
	lda #$01  //char that we want to print
    ldy #x0 //offset
    sta (temp_color_position_5), y 

    jsr setDelay3

 	//lda #$20  //char that we want to print
    //ldy #x0 //offset
    //sta (temp_position), y    
    
    lda (temp_color_position_5),y
    sta (temp_color_position_4),y


	inc temp_position
	bne skip12521
	inc temp_position+1
skip12521:

	
	inc column_counter 

	ldx column_counter
	cpx #40
	bcc nextcol2841

	rts
}


clearColorsInRow4: {


	//jsr startLineAtPositionY

    ldx #40
    stx column_counter

	ldx #0
	lda #0

nextcol28412:

    ldx column_counter
	stx x2_pos
	jsr getPositionAtXY
 	
	lda temp_position
    sta temp_color_position_5 
	lda temp_position+1
    clc
    adc #$d4
    sta temp_color_position_5+1	

	lda temp_position
    sta temp_position4 
	lda temp_position+1
    sta temp_position4+1

	//make animation!!!!!===================================================================================================


 	lda #$20  //char that we want to print
    ldy #x0 //offset
    sta (temp_position), y    

	jsr setDelay3
    
    lda (temp_color_position_5),y
    sta (temp_color_position_4),y

	clc
	dec column_counter 

	ldx column_counter
	cpx #0
	bne nextcol28412

	rts
}


AddAndPrintScore: {


	clc
	lda score
	adc #1
	sta score
	bcc nocarry1
	inc score+1
nocarry1:

	// Print score on top bar!
	clc  //mode to set x,y postion!
	ldx #0
	ldy #1
	jsr $fff0 //position kernel routine

	// set text color
	lda #7
	sta $0286

	lda score+1 //high byte
	ldx score //low byte
	jsr $BDCD //print to screen	


	clc
	lda $0401
	cmp #160
	beq gonextscorenumber1
	lda $0401
	adc #$80
	sta $0401
gonextscorenumber1:
	lda $0402
	cmp #160
	beq gonextscorenumber2
	lda $0402
	adc #$80
	sta $0402
gonextscorenumber2:
	lda $0403
	cmp #160
	beq gonextscorenumber3
	lda $0403
	adc #$80
	sta $0403
gonextscorenumber3:	

	rts
}


setSIDGenerator:	{
	lda #$FF  // maximum frequency value
	sta $D40E // voice 3 frequency low byte
	sta $D40F // voice 3 frequency high byte
	lda #$80  // noise waveform, gate bit off
	sta $D412 // voice 3 control register
	rts			
}

generateRnd: {

	lda seed+1
	tay // store copy of high byte
	// compute seed+1 ($39>>1 = %11100)
	lsr // shift to consume zeroes on left...
	lsr
	lsr
	sta seed+1 // now recreate the remaining bits in reverse order... %111
	lsr
	eor seed+1
	lsr
	eor seed+1
	eor seed+0 // recombine with original low byte
	sta seed+1
	// compute seed+0 ($39 = %111001)
	tya // original high byte
	sta seed+0
	asl
	eor seed+0
	asl
	eor seed+0
	asl
	asl
	asl
	eor seed+0
	sta seed+0
	
	rts
}


setDelay1: {

		ldx #0
ddt3:
		//lda #500
		lda #0
		cmp $d012
		bne ddt3	

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop


		inx
		cpx main_deley_speed
		bcc ddt3


/*ddt4:
		lda #$a0
		cmp $d012
		bne ddt4
*/

        rts	
}

setDelay2: {

!:
		lda #$12
		cmp $d012
		bne !-

!:
		lda #$10
		cmp $d012
		bne !-
/*
ddz4:
		lda #$a0
		cmp $d012
		bne ddz4
*/
        rts	
}


setDelay3: {

       lda #0
!:     cmp $d012
       bne !-
        rts	
}

playbeep: {

        //    MHBLVVVV	Mute3 / Highpass / Bandpass / Lowpass / Volume (0=silent)
		lda #%01110000
		sta $D418	

		lda #%00110000
		sta $D404	

		lda #90
		sta $D400
		lda #15
		sta $D401

		lda #80
		sta $D402
		lda #08
		sta $D403

		lda #%00010001
		sta $D404

		lda #$87  // noise waveform, gate bit off
		sta $D405 // voice 1 control register

		lda #%00001010
		sta $D418	

		rts
}

playBigBeep: {

        //    MHBLVVVV	Mute3 / Highpass / Bandpass / Lowpass / Volume (0=silent)
		lda #%01110000
		sta $D418	

		lda #%00110000
		sta $D404		

		lda #90
		sta $D400
		lda #15
		sta $D401

		lda #80
		sta $D402
		lda #28
		sta $D403

		lda #%00110001
		sta $D404

		lda #$81  // noise waveform, gate bit off
		sta $D405 // voice 1 control register

		lda #10
		sta $D407

        //    MHBLVVVV	Mute3 / Highpass / Bandpass / Lowpass / Volume (0=silent)
		lda #%00001010
		sta $D418	

		rts
}


main_deley_speed: .byte 10
same_color_counter: .byte 0
column_counter: .byte 0

we_have_color_match: .byte 0
we_have_row_match: .byte 0

temp_var: .byte 0

counter: .byte 0
x_pos: .byte 0
x2_pos: .byte 0
x_offset: .byte 0
y_pos: .byte 0
y_pos_min: .byte $24
y2_pos: .byte 0
positions_taken: .byte %00000000
char_color: .byte 0
color_index: .byte 0
seed: .byte 2       // initialize 16-bit seed to any value except 0
colorlist: .byte $04,$05,$08,$07,$03
//row_matches: .byte 228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,$20,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228,228
score: .byte 0,0
//color memory range: $D800 through $DBE7.
//screen memory range: $0400 to $07E8
//----------------------------------------------------
chk_x_pos: .byte 0
chk_y_pos: .byte 0
chk_temp_color: .byte 0
chk_temp_color_prev: .byte 0
//-------------------------------------------------------
top_bar: .byte 218,176,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,218
/*
21: DB20
22: DB48 
23: DB70
24: DB98
25: DBC0
-------------------
problem, zadnji red, 30 pozicija ($DBDD)
$DBDD

$0798
$07C0
$07E7
*/

* = $3c00 "Map1 data, $3FE7" 
screen: 
.byte 218,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,218
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,236,226,226,226,226,226,226,226,226,226,226,226,226,226,226,251, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 97, 32, 67, 15, 12, 15, 18, 32, 66, 12, 15,  3, 11, 19, 32,225, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,252, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98,254, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 67, 15, 14, 20, 18, 15, 12, 12, 32,  6,  1, 12, 12,  9, 14,  7, 32,  2, 12, 15,  3, 11, 19, 46, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 65,  4, 10,  1,  3,  5, 14, 20, 32,  2, 12, 15,  3, 11, 19, 32, 23,  9, 20,  8, 32, 19,  1, 13,  5, 32,  3, 15, 12, 15, 18, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32,  1, 18,  5, 32,  3,  1, 14,  3,  5, 12,  5,  4, 46, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 71,  5, 20, 32, 16, 15,  9, 14, 20, 32,  6, 15, 18, 32,  5, 22,  5, 18, 25, 32,  6,  9, 12, 12,  5,  4, 32, 12,  9, 14,  5, 46, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 67, 15, 14, 20, 18, 15, 12, 12, 19, 58, 32, 10, 15, 25, 19, 20,  9,  3, 11, 44, 32, 16, 15, 18, 20, 32, 66, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 16, 18,  5, 19, 19, 32, 19, 16,  1,  3,  5, 32, 20, 15, 32,  3, 15, 14,  9, 14, 21,  5, 46, 46, 46, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte 111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
.byte  32, 10, 15, 19,  9, 16, 46, 11,  1, 12,  5,  2,  9,  3,  0,  7, 13,  1,  9, 12, 46,  3, 15, 13, 32, 32, 32, 32, 26,  1,  4,  1, 18, 44, 32, 50, 48, 50, 49, 32
.byte  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32

/*
; character codes (1000 bytes)
BYTE 218,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,160,218
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,236,226,226,226,226,226,226,226,226,226,226,226,226,226,226,251, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 97, 32, 67, 15, 12, 15, 18, 32, 66, 12, 15,  3, 11, 19, 32,225, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,252, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98,254, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 67, 15, 14, 20, 18, 15, 12, 12, 32,  6,  1, 12, 12,  9, 14,  7, 32,  2, 12, 15,  3, 11, 19, 46, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 65,  4, 10,  1,  3,  5, 14, 20, 32,  2, 12, 15,  3, 11, 19, 32, 23,  9, 20,  8, 32, 19,  1, 13,  5, 32,  3, 15, 12, 15, 18, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32,  1, 18,  5, 32,  3,  1, 14,  3,  5, 12,  5,  4, 46, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 71,  5, 20, 32, 16, 15,  9, 14, 20, 32,  6, 15, 18, 32,  5, 22,  5, 18, 25, 32,  6,  9, 12, 12,  5,  4, 32, 12,  9, 14,  5, 46, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 67, 15, 14, 20, 18, 15, 12, 12, 19, 58, 32, 10, 15, 25, 19, 20,  9,  3, 11, 44, 32, 16, 15, 18, 20, 32, 66, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 16, 18,  5, 19, 19, 32, 19, 16,  1,  3,  5, 32, 20, 15, 32,  3, 15, 14,  9, 14, 21,  5, 46, 46, 46, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE 111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
BYTE  32, 10, 15, 19,  9, 16, 46, 11,  1, 12,  5,  2,  9,  3,  0,  7, 13,  1,  9, 12, 46,  3, 15, 13, 32, 32, 32, 32, 26,  1,  4,  1, 18, 44, 32, 50, 48, 50, 49, 32
BYTE  32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32

*/
* = $2800 "Charset" 
charset: 
.byte	$3C, $66, $6E, $6E, $60, $62, $3C, $00
.byte	$18, $3C, $66, $7E, $66, $66, $66, $00
.byte	$7C, $66, $66, $7C, $66, $66, $7C, $00
.byte	$3C, $66, $60, $60, $60, $66, $3C, $00
.byte	$78, $6C, $66, $66, $66, $6C, $78, $00
.byte	$7E, $60, $60, $78, $60, $60, $7E, $00
.byte	$7E, $60, $60, $78, $60, $60, $60, $00
.byte	$3C, $66, $60, $6E, $66, $66, $3C, $00
.byte	$66, $66, $66, $7E, $66, $66, $66, $00
.byte	$3C, $18, $18, $18, $18, $18, $3C, $00
.byte	$1E, $0C, $0C, $0C, $0C, $6C, $38, $00
.byte	$66, $6C, $78, $70, $78, $6C, $66, $00
.byte	$60, $60, $60, $60, $60, $60, $7E, $00
.byte	$63, $77, $7F, $6B, $63, $63, $63, $00
.byte	$66, $76, $7E, $7E, $6E, $66, $66, $00
.byte	$3C, $66, $66, $66, $66, $66, $3C, $00
.byte	$7C, $66, $66, $7C, $60, $60, $60, $00
.byte	$3C, $66, $66, $66, $66, $3C, $0E, $00
.byte	$7C, $66, $66, $7C, $78, $6C, $66, $00
.byte	$3C, $66, $60, $3C, $06, $66, $3C, $00
.byte	$7E, $18, $18, $18, $18, $18, $18, $00
.byte	$66, $66, $66, $66, $66, $66, $3C, $00
.byte	$66, $66, $66, $66, $66, $3C, $18, $00
.byte	$63, $63, $63, $6B, $7F, $77, $63, $00
.byte	$66, $66, $3C, $18, $3C, $66, $66, $00
.byte	$66, $66, $66, $3C, $18, $18, $18, $00
.byte	$7E, $06, $0C, $18, $30, $60, $7E, $00
.byte	$3C, $30, $30, $30, $30, $30, $3C, $00
.byte	$0C, $12, $30, $7C, $30, $62, $FC, $00
.byte	$3C, $0C, $0C, $0C, $0C, $0C, $3C, $00
.byte	$00, $18, $3C, $7E, $18, $18, $18, $18
.byte	$00, $10, $30, $7F, $7F, $30, $10, $00
.byte	$00, $00, $00, $00, $00, $00, $00, $00
.byte	$18, $18, $18, $18, $00, $00, $18, $00
.byte	$66, $66, $66, $00, $00, $00, $00, $00
.byte	$66, $66, $FF, $66, $FF, $66, $66, $00
.byte	$18, $3E, $60, $3C, $06, $7C, $18, $00
.byte	$62, $66, $0C, $18, $30, $66, $46, $00
.byte	$3C, $66, $3C, $38, $67, $66, $3F, $00
.byte	$06, $0C, $18, $00, $00, $00, $00, $00
.byte	$0C, $18, $30, $30, $30, $18, $0C, $00
.byte	$30, $18, $0C, $0C, $0C, $18, $30, $00
.byte	$00, $66, $3C, $FF, $3C, $66, $00, $00
.byte	$00, $18, $18, $7E, $18, $18, $00, $00
.byte	$00, $00, $00, $00, $00, $18, $18, $30
.byte	$00, $00, $00, $7E, $00, $00, $00, $00
.byte	$00, $00, $00, $00, $00, $18, $18, $00
.byte	$00, $03, $06, $0C, $18, $30, $60, $00
.byte	$3C, $66, $6E, $76, $66, $66, $3C, $00
.byte	$18, $18, $38, $18, $18, $18, $7E, $00
.byte	$3C, $66, $06, $0C, $30, $60, $7E, $00
.byte	$3C, $66, $06, $1C, $06, $66, $3C, $00
.byte	$06, $0E, $1E, $66, $7F, $06, $06, $00
.byte	$7E, $60, $7C, $06, $06, $66, $3C, $00
.byte	$3C, $66, $60, $7C, $66, $66, $3C, $00
.byte	$7E, $66, $0C, $18, $18, $18, $18, $00
.byte	$3C, $66, $66, $3C, $66, $66, $3C, $00
.byte	$3C, $66, $66, $3E, $06, $66, $3C, $00
.byte	$00, $00, $18, $00, $00, $18, $00, $00
.byte	$00, $00, $18, $00, $00, $18, $18, $30
.byte	$0E, $18, $30, $60, $30, $18, $0E, $00
.byte	$00, $00, $7E, $00, $7E, $00, $00, $00
.byte	$70, $18, $0C, $06, $0C, $18, $70, $00
.byte	$3C, $66, $06, $0C, $18, $00, $18, $00
.byte	$00, $00, $00, $FF, $FF, $00, $00, $00
.byte	$08, $1C, $3E, $7F, $7F, $1C, $3E, $00
.byte	$18, $18, $18, $18, $18, $18, $18, $18
.byte	$00, $00, $00, $FF, $FF, $00, $00, $00
.byte	$00, $00, $FF, $FF, $00, $00, $00, $00
.byte	$00, $FF, $FF, $00, $00, $00, $00, $00
.byte	$00, $00, $00, $00, $FF, $FF, $00, $00
.byte	$30, $30, $30, $30, $30, $30, $30, $30
.byte	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C
.byte	$00, $00, $00, $E0, $F0, $38, $18, $18
.byte	$18, $18, $1C, $0F, $07, $00, $00, $00
.byte	$18, $18, $38, $F0, $E0, $00, $00, $00
.byte	$C0, $C0, $C0, $C0, $C0, $C0, $FF, $FF
.byte	$C0, $E0, $70, $38, $1C, $0E, $07, $03
.byte	$03, $07, $0E, $1C, $38, $70, $E0, $C0
.byte	$FF, $FF, $C0, $C0, $C0, $C0, $C0, $C0
.byte	$FF, $FF, $03, $03, $03, $03, $03, $03
.byte	$00, $3C, $7E, $7E, $7E, $7E, $3C, $00
.byte	$00, $00, $00, $00, $00, $FF, $FF, $00
.byte	$36, $7F, $7F, $7F, $3E, $1C, $08, $00
.byte	$60, $60, $60, $60, $60, $60, $60, $60
.byte	$00, $00, $00, $07, $0F, $1C, $18, $18
.byte	$C3, $E7, $7E, $3C, $3C, $7E, $E7, $C3
.byte	$00, $3C, $7E, $66, $66, $7E, $3C, $00
.byte	$18, $18, $66, $66, $18, $18, $3C, $00
.byte	$06, $06, $06, $06, $06, $06, $06, $06
.byte	$08, $1C, $3E, $7F, $3E, $1C, $08, $00
.byte	$18, $18, $18, $FF, $FF, $18, $18, $18
.byte	$C0, $C0, $30, $30, $C0, $C0, $30, $30
.byte	$18, $18, $18, $18, $18, $18, $18, $18
.byte	$00, $00, $03, $3E, $76, $36, $36, $00
.byte	$FF, $7F, $3F, $1F, $0F, $07, $03, $01
.byte	$00, $00, $00, $00, $00, $00, $00, $00
.byte	$F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
.byte	$00, $00, $00, $00, $FF, $FF, $FF, $FF
.byte	$FF, $00, $00, $00, $00, $00, $00, $00
.byte	$00, $00, $00, $00, $00, $00, $00, $FF
.byte	$C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
.byte	$CC, $CC, $33, $33, $CC, $CC, $33, $33
.byte	$03, $03, $03, $03, $03, $03, $03, $03
.byte	$00, $00, $00, $00, $CC, $CC, $33, $33
.byte	$FF, $FE, $FC, $F8, $F0, $E0, $C0, $80
.byte	$03, $03, $03, $03, $03, $03, $03, $03
.byte	$18, $18, $18, $1F, $1F, $18, $18, $18
.byte	$00, $00, $00, $00, $0F, $0F, $0F, $0F
.byte	$18, $18, $18, $1F, $1F, $00, $00, $00
.byte	$00, $00, $00, $F8, $F8, $18, $18, $18
.byte	$00, $00, $00, $00, $00, $00, $FF, $FF
.byte	$00, $00, $00, $1F, $1F, $18, $18, $18
.byte	$18, $18, $18, $FF, $FF, $00, $00, $00
.byte	$00, $00, $00, $FF, $FF, $18, $18, $18
.byte	$18, $18, $18, $F8, $F8, $18, $18, $18
.byte	$C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
.byte	$E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0
.byte	$07, $07, $07, $07, $07, $07, $07, $07
.byte	$FF, $FF, $00, $00, $00, $00, $00, $00
.byte	$FF, $E7, $FF, $7E, $00, $00, $00, $00
.byte	$00, $00, $00, $00, $7E, $FF, $DB, $FF
.byte	$03, $03, $03, $03, $03, $03, $FF, $FF
.byte	$00, $00, $00, $00, $F0, $F0, $F0, $F0
.byte	$0F, $0F, $0F, $0F, $00, $00, $00, $00
.byte	$18, $18, $18, $F8, $F8, $00, $00, $00
.byte	$F0, $F0, $F0, $F0, $00, $00, $00, $00
.byte	$F0, $F0, $F0, $F0, $0F, $0F, $0F, $0F
.byte	$C3, $99, $91, $91, $9F, $99, $C3, $FF
.byte	$E7, $C3, $99, $81, $99, $99, $99, $FF
.byte	$83, $99, $99, $83, $99, $99, $83, $FF
.byte	$C3, $99, $9F, $9F, $9F, $99, $C3, $FF
.byte	$87, $93, $99, $99, $99, $93, $87, $FF
.byte	$81, $9F, $9F, $87, $9F, $9F, $81, $FF
.byte	$81, $9F, $9F, $87, $9F, $9F, $9F, $FF
.byte	$C3, $99, $9F, $91, $99, $99, $C3, $FF
.byte	$99, $99, $99, $81, $99, $99, $99, $FF
.byte	$C3, $E7, $E7, $E7, $E7, $E7, $C3, $FF
.byte	$E1, $F3, $F3, $F3, $F3, $93, $C7, $FF
.byte	$99, $93, $87, $8F, $87, $93, $99, $FF
.byte	$9F, $9F, $9F, $9F, $9F, $9F, $81, $FF
.byte	$9C, $88, $80, $94, $9C, $9C, $9C, $FF
.byte	$99, $89, $81, $81, $91, $99, $99, $FF
.byte	$C3, $99, $99, $99, $99, $99, $C3, $FF
.byte	$83, $99, $99, $83, $9F, $9F, $9F, $FF
.byte	$C3, $99, $99, $99, $99, $C3, $F1, $FF
.byte	$83, $99, $99, $83, $87, $93, $99, $FF
.byte	$C3, $99, $9F, $C3, $F9, $99, $C3, $FF
.byte	$81, $E7, $E7, $E7, $E7, $E7, $E7, $FF
.byte	$99, $99, $99, $99, $99, $99, $C3, $FF
.byte	$99, $99, $99, $99, $99, $C3, $E7, $FF
.byte	$9C, $9C, $9C, $94, $80, $88, $9C, $FF
.byte	$99, $99, $C3, $E7, $C3, $99, $99, $FF
.byte	$99, $99, $99, $C3, $E7, $E7, $E7, $FF
.byte	$81, $F9, $F3, $E7, $CF, $9F, $81, $FF
.byte	$C3, $CF, $CF, $CF, $CF, $CF, $C3, $FF
.byte	$F3, $ED, $CF, $83, $CF, $9D, $03, $FF
.byte	$C3, $F3, $F3, $F3, $F3, $F3, $C3, $FF
.byte	$FF, $E7, $C3, $81, $E7, $E7, $E7, $E7
.byte	$FF, $EF, $CF, $80, $80, $CF, $EF, $FF
.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte	$E7, $E7, $E7, $E7, $FF, $FF, $E7, $FF
.byte	$99, $99, $99, $FF, $FF, $FF, $FF, $FF
.byte	$99, $99, $00, $99, $00, $99, $99, $FF
.byte	$E7, $C1, $9F, $C3, $F9, $83, $E7, $FF
.byte	$9D, $99, $F3, $E7, $CF, $99, $B9, $FF
.byte	$C3, $99, $C3, $C7, $98, $99, $C0, $FF
.byte	$F9, $F3, $E7, $FF, $FF, $FF, $FF, $FF
.byte	$F3, $E7, $CF, $CF, $CF, $E7, $F3, $FF
.byte	$CF, $E7, $F3, $F3, $F3, $E7, $CF, $FF
.byte	$FF, $99, $C3, $00, $C3, $99, $FF, $FF
.byte	$FF, $E7, $E7, $81, $E7, $E7, $FF, $FF
.byte	$FF, $FF, $FF, $FF, $FF, $E7, $E7, $CF
.byte	$FF, $FF, $FF, $81, $FF, $FF, $FF, $FF
.byte	$FF, $FF, $FF, $FF, $FF, $E7, $E7, $FF
.byte	$FF, $FC, $F9, $F3, $E7, $CF, $9F, $FF
.byte	$C3, $99, $91, $89, $99, $99, $C3, $FF
.byte	$E7, $E7, $C7, $E7, $E7, $E7, $81, $FF
.byte	$C3, $99, $F9, $F3, $CF, $9F, $81, $FF
.byte	$C3, $99, $F9, $E3, $F9, $99, $C3, $FF
.byte	$F9, $F1, $E1, $99, $80, $F9, $F9, $FF
.byte	$81, $9F, $83, $F9, $F9, $99, $C3, $FF
.byte	$C3, $99, $9F, $83, $99, $99, $C3, $FF
.byte	$81, $99, $F3, $E7, $E7, $E7, $E7, $FF
.byte	$C3, $99, $99, $C3, $99, $99, $C3, $FF
.byte	$C3, $99, $99, $C1, $F9, $99, $C3, $FF
.byte	$FF, $FF, $E7, $FF, $FF, $E7, $FF, $FF
.byte	$FF, $FF, $E7, $FF, $FF, $E7, $E7, $CF
.byte	$F1, $E7, $CF, $9F, $CF, $E7, $F1, $FF
.byte	$FF, $FF, $81, $FF, $81, $FF, $FF, $FF
.byte	$8F, $E7, $F3, $F9, $F3, $E7, $8F, $FF
.byte	$C3, $99, $F9, $F3, $E7, $FF, $E7, $FF
.byte	$FF, $FF, $FF, $00, $00, $FF, $FF, $FF
.byte	$F7, $E3, $C1, $80, $80, $E3, $C1, $FF
.byte	$E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7
.byte	$FF, $FF, $FF, $00, $00, $FF, $FF, $FF
.byte	$FF, $FF, $00, $00, $FF, $FF, $FF, $FF
.byte	$FF, $00, $00, $FF, $FF, $FF, $FF, $FF
.byte	$FF, $FF, $FF, $FF, $00, $00, $FF, $FF
.byte	$CF, $CF, $CF, $CF, $CF, $CF, $CF, $CF
.byte	$F3, $F3, $F3, $F3, $F3, $F3, $F3, $F3
.byte	$FF, $FF, $FF, $1F, $0F, $C7, $E7, $E7
.byte	$E7, $E7, $E3, $F0, $F8, $FF, $FF, $FF
.byte	$E7, $E7, $C7, $0F, $1F, $FF, $FF, $FF
.byte	$3F, $3F, $3F, $3F, $3F, $3F, $00, $00
.byte	$3F, $1F, $8F, $C7, $E3, $F1, $F8, $FC
.byte	$FC, $F8, $F1, $E3, $C7, $8F, $1F, $3F
.byte	$00, $00, $3F, $3F, $3F, $3F, $3F, $3F
.byte	$00, $00, $FC, $FC, $FC, $FC, $FC, $FC
.byte	$FF, $C3, $81, $81, $81, $81, $C3, $FF
.byte	$FF, $FF, $FF, $FF, $FF, $00, $00, $FF
.byte	$C9, $80, $80, $80, $C1, $E3, $F7, $FF
.byte	$9F, $9F, $9F, $9F, $9F, $9F, $9F, $9F
.byte	$FF, $FF, $FF, $F8, $F0, $E3, $E7, $E7
.byte	$3C, $18, $81, $C3, $C3, $81, $18, $3C
.byte	$FF, $C3, $81, $99, $99, $81, $C3, $FF
.byte	$E7, $E7, $99, $99, $E7, $E7, $C3, $FF
.byte	$F9, $F9, $F9, $F9, $F9, $F9, $F9, $F9
.byte	$F7, $E3, $C1, $80, $C1, $E3, $F7, $FF
.byte	$E7, $E7, $E7, $00, $00, $E7, $E7, $E7
.byte	$3F, $3F, $CF, $CF, $3F, $3F, $CF, $CF
.byte	$E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7
.byte	$FF, $FF, $FC, $C1, $89, $C9, $C9, $FF
.byte	$00, $80, $C0, $E0, $F0, $F8, $FC, $FE
.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte	$0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
.byte	$FF, $FF, $FF, $FF, $00, $00, $00, $00
.byte	$00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.byte	$7E, $FF, $DB, $FF, $FF, $E7, $FF, $7E
.byte	$7E, $FF, $DB, $FF, $FF, $DB, $E7, $7E
.byte	$33, $33, $CC, $CC, $33, $33, $CC, $CC
.byte	$FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC
.byte	$FF, $FF, $FF, $FF, $33, $33, $CC, $CC
.byte	$00, $01, $03, $07, $0F, $1F, $3F, $7F
.byte	$FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC
.byte	$E7, $E7, $E7, $E0, $E0, $E7, $E7, $E7
.byte	$FF, $FF, $FF, $FF, $F0, $F0, $F0, $F0
.byte	$E7, $E7, $E7, $E0, $E0, $FF, $FF, $FF
.byte	$FF, $FF, $FF, $07, $07, $E7, $E7, $E7
.byte	$FF, $FF, $FF, $FF, $FF, $FF, $00, $00
.byte	$FF, $FF, $FF, $E0, $E0, $E7, $E7, $E7
.byte	$E7, $E7, $E7, $00, $00, $FF, $FF, $FF
.byte	$FF, $FF, $FF, $00, $00, $E7, $E7, $E7
.byte	$E7, $E7, $E7, $07, $07, $E7, $E7, $E7
.byte	$3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F
.byte	$07, $0F, $0E, $0F, $0F, $0E, $0F, $07
.byte	$E0, $F0, $D0, $F0, $F0, $70, $F0, $E0
.byte	$07, $0F, $0B, $0F, $0F, $0E, $0F, $07
.byte	$E0, $F0, $70, $F0, $F0, $70, $F0, $E0
.byte	$FF, $FF, $FF, $FF, $FF, $00, $00, $00
.byte	$FC, $FC, $FC, $FC, $FC, $FC, $00, $00
.byte	$FF, $FF, $FF, $FF, $0F, $0F, $0F, $0F
.byte	$00,$00,$00,$00,$07,$0F,$0D,$0F	// #252 $FC [left up]
.byte	$00,$00,$00,$00,$E0,$F0,$B0,$F0	// #253 $FD [right up]
.byte	$0F,$0F,$0E,$0F,$07,$00,$00,$00	// #254 $FE [left down]
.byte	$F0,$F0,$70,$F0,$E0,$00,$00,$00	// #255 $FF [right down]
