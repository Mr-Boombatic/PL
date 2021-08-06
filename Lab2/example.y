%{
#include <stdio.h>
#include <string.h>

void yyerror(const char *str)
{
}


int days[31] = {0};
int pointer;
int signal = 1;
int counterDay = 0;

int counterForDayOfWeek = 0;
char *dayOfWeek[7];
int year;

int year;
char *month;

int yywrap()
{
    printf("%s %d \n", month, year);

    for(int i=0; i < 7;i++)
    {
        printf("%s", dayOfWeek[i]);
        if (i < pointer)
                printf("    ");

        for(int j=0; j < 5;j++)
        {
        

            if (j == 0 && i >= 2 && i <= 6 && i - 2 <= 30){
                printf(" %2d ", days[i - 2]);
                continue;
            }

            if (days[(8-pointer+i)+((j-1)*7)] == 0)
                continue;

            if ((8-pointer+i)+((j-1)*7) <=30)
                printf(" %2d ", days[(8-pointer+i)+((j-1)*7)]);
        }

        printf("\n");
    }

    return 1;
}

main()
{
    yyparse();
}

%}

%token DAY_OF_WEEK YEAR DAY MONTH SIGNAL

%%

commands: /* empty */
    |commands command
    ;

command:
    recognize_day
    |
    recognize_header
    |
    recognize_day_of_week
    |
    recognize_signal
    ;

    recognize_day:
        DAY
        {
            days[counterDay] = $1;
            counterDay += 1;
        }
        ;

    recognize_header:
        MONTH YEAR
        {
            month = $1;
            year = $2;
        }
        ;
    
    recognize_day_of_week:
        DAY_OF_WEEK
        {
            dayOfWeek[counterForDayOfWeek] = $1;
            counterForDayOfWeek += 1;
            if (counterForDayOfWeek == 7){
                    counterForDayOfWeek = 0;
                }
        }
        ;

    recognize_signal:
        SIGNAL
        {
            if (counterDay != 0 && signal)
            {
                signal = 0;
                pointer = 7 - (counterDay - 1);
            }
        }
        ;