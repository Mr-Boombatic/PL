%{
#include <stdio.h>
#include "y.tab.h"
%}
%%
[A-ZА-Яa-zа-я]{2}    yylval=strdup(yytext); return DAY_OF_WEEK;
[0-9]{4}             yylval=atoi(yytext); return YEAR;
[0-9]{1,2}             yylval=atoi(yytext); return DAY;
[A-ZА-Яa-zа-я]{2,10}   yylval=strdup(yytext); return MONTH;


\n               return SIGNAL;/* ignore end of line */;
[\t ]+           /* ignore whitespace */;

%%
