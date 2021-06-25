.PHONY: clean
cc = gcc
objects = sym_table.o parser.tab.o main.o lex.yy.o
c_files = parser.tab.c parser.tab.h lex.yy.c lex.yy.h
%.o: %.c
	$(cc) -g -c -o $@ $<

compiler: parser.tab.o sym_table.o lex.yy.o main.o
	$(cc) -o $@ parser.tab.o sym_table.o -lm lex.yy.o main.o

parser.tab.c: parser.y
	bison -d parser.y

lex.yy.c: scanner.l
	flex scanner.l

clean:
	-rm compiler $(objects) $(c_files)
