# brainfuck-avr
A Brainfuck Interpreter for AVR Microcontrollers in just 118 words.

The goal was to write an interpreter that is as small as possible, uses 8-bit wide cells and supports all 8 brainfuck [commands](https://en.wikipedia.org/wiki/Brainfuck#Commands).

The current version was designed for the AVR ATmega8.

## Assembling and uploading
Download [gavrasm](http://www.avr-asm-tutorial.net/gavrasm/index_en.html) to assemble the binary. Then use [avrdude](https://learn.adafruit.com/usbtinyisp/avrdude) to upload it to the microcontroller.

## Design choices
  * The interpreter expects the program to be stored in the EEPROM, starting at address 0. The ATmega8's EEPROM is 512 Bytes large.
  * All cells are stored in the SRAM, the interpreter is currently limited to 512 cells. If you execute a `>` when on the last cell, you will end up on the first cell.
