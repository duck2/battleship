# battleship

An _Introduction to Microprocessors_ project on Tiva TM4C123GH6PM, featuring a game of Battleships on an 5110 screen.

All code is written in assembly with direct register access according to the project specifications.

For now, compiles with Keil only. Open the project in `keil/`.

Roadmap:
- [ ] drivers
	- [ ] get input from two ADCs
	- [ ] unlock buttons
	- [x] drive screen through SPI
		- [ ] make a small display library
			- [ ] draw numbers
			- [ ] draw rectangles
			- [ ] draw cursors
	- [ ] timer
- [ ] build on linux
	- [ ] toy translator from ARM to GAS
	- [ ] Makefile
