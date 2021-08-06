/**
 * Программа копирования входного потока в выходной.
 *
 * Copyright (c) 2017, Student Name <student@cs.karelia.ru>
 *
 * This code is licensed under a MIT-style license.
 */

/* Секция, которая копируется без изменений */

%{
#include <stdio.h>
%}

%%

[0-9] printf(""); /* Любой символ - на выход. */ 

%%


int main() {
    yylex(); /* Вызов функции для лексического анализатора. */
    return 1;
}

/**
 *  Вызов обработчика ошибок.
 */

int yywrap() {
    return 1;
}
