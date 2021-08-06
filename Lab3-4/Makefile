example: lex.yy.c y.tab.c
	gcc lex.yy.c y.tab.c -o example

lex.yy.c: example.l
	flex example.l

y.tab.c: task4.y
	yacc -d task4.y

clean:
	rm example lex.yy.c y.tab.c

.PHONY: clean
