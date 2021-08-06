
copy: lex.yy.c
	gcc -o copy lex.yy.c

lex.yy.c: scanner.l
	flex scanner.l

clean:
	rm copy lex.yy.c

.PHONY: clean
