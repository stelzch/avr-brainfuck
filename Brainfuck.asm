; Brainfuck Interpreter on ASM
; Uses PORTD for Input and PORTB for Output

.device atmega8
; Initalize SRAM storage
.DEF CELL=r20
.DEF INSTR=r21

.EQU CELLS=0x60

; Initialize Stack pointer
ldi r16, LOW(RAMEND)
out SPL, r16
ldi r17, HIGH(RAMEND)
out SPH, r17

; Initialize Cell (Y) pointer
ldi YL, LOW(CELLS)
ldi YH, HIGH(CELLS)

; Initialize Instruction (Z) pointer
ldi ZL, 0x00
ldi ZH, 0x00

; Overwrite all cells with 0
ldi r16, 0x00
RESET_CELLS:
    st Y+, r16

    cpi YL, LOW(CELLS+10) ;LOW(CELLS+512)
    brne RESET_CELLS
    cpi YH, HIGH(CELLS+10) ;HIGH(CELLS+512)
    brne RESET_CELLS

    ldi YL, LOW(CELLS)
    ldi YH, HIGH(CELLS)

MAINLOOP:
    rcall LOAD_INSTR
    rcall LOAD_CELL
    cpi INSTR, 0x00 ; If reached end of program, terminate
    breq END

    rcall EXECUTE_INSTR
    rcall NEXT_INSTR
    rjmp MAINLOOP

; Initialize I/O
ldi r16, 0xff
out DDRB, r16
ldi r16, 0x00
out DDRD, r16

END:
    nop
    rjmp END

LOAD_CELL:
    ld CELL, Y
    ret

STORE_CELL:
    st Y, CELL
    ret

PREV_INSTR:
    ; Decrement Z
    sbiw ZL:ZH, 1
    ret

NEXT_INSTR:
    ; Increment Z
    adiw ZL:ZH, 1
    ret

LOAD_INSTR:
    ; Wait until eeprom is ready
    sbic EECR, EEWE
    rjmp LOAD_INSTR
    out EEARH, ZH
    out EEARL, ZL
    sbi EECR, EERE
    in INSTR, EEDR
    ret


; Now for the "tricky" bit: loops
SEEK_PAR:
    ; Asserts we are currently sitting on a loop (Either [ or ])
    ; Continue to search the instructions until we find a closing parenthesis
    ; Expects one parameter in r16, that specifies the direction:
    ; (0x00 = LEFT, 0xff = RIGHT)
    ; Use register r17 to store the number of opened parenthesis
    mov r18, r16
    ldi r17, 0x00

    SEEK_PAR_LOOP:
    rcall LOAD_INSTR

    ; Increment parenthesis counter on [
    cpi INSTR, '['
    brne PC+2
    inc r17

    ; Decrement parenthesis counter on ]
    cpi INSTR, ']'
    brne PC+2
    dec r17

    cpi r17, 0x00
    breq SEEK_PAR_EXIT   ; if we reached the matching bracket, exit the routine
    sbrc r18, 0
    rcall NEXT_INSTR         ; otherwise either look left
    sbrs r18, 0
    rcall PREV_INSTR         ; or right

    rjmp SEEK_PAR_LOOP   ; and repeat this.

    SEEK_PAR_EXIT:
    ret

INCREMENT_CELL:
    inc CELL
    rcall STORE_CELL
    ret

DECREMENT_CELL:
    dec CELL
    rcall STORE_CELL
    ret

OUTPUT:
    ;rcall DELAY_100ms
    out PORTB, CELL
    ret

INPUT:
    in CELL, PORTD
    ret

EXECUTE_INSTR:
    ; Execute the currently read instruction
    ; Push the return address to the stack
    ldi r16, LOW(EXECUTE_INSTR_EXIT)
    ldi r17, HIGH(EXECUTE_INSTR_EXIT)
    push r16
    push r17

    cpi INSTR, '['
    breq OPENING_PAR

    cpi INSTR, ']'
    breq CLOSING_PAR

    cpi INSTR, '<'
    breq PREV_CELL

    cpi INSTR, '>'
    breq NEXT_CELL

    cpi INSTR, '+'
    breq INCREMENT_CELL

    cpi INSTR, '-'
    breq DECREMENT_CELL

    cpi INSTR, '.'
    breq OUTPUT

    cpi INSTR, ','
    breq INPUT

    EXECUTE_INSTR_EXIT:
    ret

OPENING_PAR:
    ; Compare if the current cell is != 0
    cpi CELL, 0x00
    brne PC+3
    ldi r16, 0xff
    rcall SEEK_PAR       ; If the CELL == 0, go to the matching parenthesis
    ret                  ; Return if cell is != zero

CLOSING_PAR:
    ; Compare if the current cell is != 0
    cpi CELL, 0x00
    breq PC+3
    ldi r16, 0x00
    rcall SEEK_PAR
    ret

PREV_CELL:
    ; Decrement Y
    sbiw YL:YH, 1

    ; Check for cell underflow
    cpi YL, LOW(CELLS-1)
    brne PREV_CELL_EXIT
    cpi YH, HIGH(CELLS-1)
    brne PREV_CELL_EXIT

    ; Y == CELLS - 1
    ldi YL, LOW(CELLS + 511)
    ldi YH, HIGH(CELLS + 511)
    PREV_CELL_EXIT:
    ret

NEXT_CELL:
    ; Increment Y
    adiw YL:YH, 1

    ; Check for cell overflow
    cpi YL, LOW(CELLS+512)
    brne NEXT_CELL_EXIT
    cpi YH, HIGH(CELLS+512)
    brne NEXT_CELL_EXIT

    ; Y == CELLS + 512
    ldi YL, LOW(CELLS)
    ldi YH, HIGH(CELLS)
    NEXT_CELL_EXIT:
    ret

; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 100 000 cycles
; 100ms at 1.0 MHz

;DELAY_100ms:
;    ldi  r16, 130
;    ldi  r17, 222
;L1: dec  r17
;    brne L1
;    dec  r16
;    brne L1
;    nop

;    ret


; Initialize EEPROM
.eseg
.org 0x00
.db "[>+.<]+++++.", 0x00
