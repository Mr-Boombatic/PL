%{
#include <stdio.h>
#include "y.tab.h"
%}
%%
[<][A-z]+[ ]*([ ]*[A-z]+[=][\"]([0-9]|[A-z]|[#]|[-]|[:]|[;])+[\"])*[>]    {yylval=strdup(yytext); return OPENTAG;}
[<][/][A-z]+[>] {yylval=strdup(yytext); return CLOSETAG;}
([A-z]*[0-9]*)+         {yylval=strdup(yytext); return VALUE;}
<<EOF>>             return END;
([A-z]+[ ])*            {yylval=strdup(yytext); return VALUE;}
[A-z]+          {yylval=strdup(yytext); return VALUE;}
[0-9]+          {yylval=strdup(yytext); return VALUE;}
%%
