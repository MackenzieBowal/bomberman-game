bomberman: bomberman1.o bomberman2.o
		gcc bomberman1.o bomberman2.o -o bomberman

bomberman1.o: bomberman1.s
		as bomberman1.s -o bomberman1.o

bomberman2.o: bomberman2.s
		as bomberman2.s -o bomberman2.o

bomberman1.s: bomberman1.asm
		m4 bomberman1.asm > bomberman1.s

bomberman2.s: bomberman2.asm
		m4 bomberman2.asm > bomberman2.s
