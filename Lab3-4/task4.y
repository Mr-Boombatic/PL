%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<stdbool.h>

	void yyerror(const char * str) {
    printf("dsa");
		fprintf(stderr, "error: %s\n", str);
	}

	int yywrap() {
		return 1;
	}

	//Хранит все открытые тэги, которые еще не закрыли
	char openedTags[100] = "";
	char lastTag[10] = "";
	//Финальный код
	char result[1024] = "\\usepackage{multirow}\n\\usepackage{xcolor}\n";
	//Пока считаем столбцы, пишим сюда, потом закинуть в lastTag
	char tagResult[1024] = "";
	//Счетчик столбцов
	int columnCounter = 0;
	int maxColumn = 0;
	char beginTable[100] = "\\begin{table}[]\n\\begin{tabular}";
	char endTable[100] = "\\end{tabular}\n\\end{table}\n";
	//Хрнаится инфа о необходимых сдвигах из за rowspanne
  int countAttr=0;
	bool useSpawnColumn = false;
	bool useSpawnRow = false;


	void HadleAttribute(char* tagName) {
    //printf("\n Вход в функцию");
    char* tagValue = strtok(NULL, "\"");
		// Определяем rowspan
		if (strcmp(tagName, "rowspan") == 0) {
			char* value = strtok(NULL, "\""); // поулчаем значение тега
			// формируем значение multirow
			strcat(tagResult, "\\multirow{");
			strcat(tagResult, value);
			strcat(tagResult, "}{*}");
			useSpawnRow = true;

		} else if (strcmp(tagName, "colspan") == 0) {
			char* value = strtok(NULL, "\"");
			strcat(tagResult, "\\multicolumn{");
			strcat(tagResult, value);
			columnCounter += atoi(value);
			strcat(tagResult, "}{c}");
			useSpawnColumn = true;
		}	else if (strcmp(tagName, "style") == 0) {
      char* partTagValue = strtok(tagValue, ":");
      while(partTagValue != NULL){
				// обработка свойства color
				if (strcmp(partTagValue, "color") == 0) {
          char* value = strtok(NULL, ";\"");
          memmove(value, value + 1, strlen(value));
					strcat(tagResult, "\\textcolor[HTML]{");
					strcat(tagResult, value);
          strcat(tagResult, "}");
          countAttr++;
          partTagValue = strtok(NULL, ";\":");
				}
				// обработка свойства background-color
				else if (strcmp(partTagValue, "background-color") == 0) {
					char* value = strtok(NULL, ";\"");
					memmove(value, value + 1, strlen(value));
					strcat(tagResult, "\\colorbox[HTML]{");
					strcat(tagResult, value);
          strcat(tagResult, "}");
          countAttr++;
          partTagValue = strtok(NULL, ";\":");
				}
			}
		}
	}

	main() {
		yyparse();
	}

%}

%token OPENTAG CLOSETAG VALUE END

%%

commands:
/* empty */
| commands command;

command: opentag | closetag | value | end;
opentag: OPENTAG {
	char startTag[100];
	sprintf(startTag, "%s", $1); // помещаем в буфер занчение тега
	if (startTag[0] == '<')
    memmove(startTag, startTag + 1, strlen(startTag));
	char* tagName;

	tagName = strtok(startTag, " ");
	strcpy(lastTag, tagName);

	//Удаляем > в конце тега
	if (lastTag[strlen(lastTag) - 1] == '>')
    lastTag[strlen(lastTag) - 1] = '\0';

  //printf("\n %s", lastTag);

	//Проверка на валидный tag
	if (strcmp(lastTag, "table") != 0 && strcmp(lastTag, "tr") != 0 && strcmp(lastTag, "th") != 0 && strcmp(lastTag, "td") != 0 && strcmp(lastTag, "span") != 0) {
		printf("Неверный тег: !%s!\n", lastTag);
		return;
	}

	// просматриваем атрибуты
	int tagColumnNumber = 1;
	if ((tagName = strtok(NULL, "=")) != NULL){
    HadleAttribute(tagName);
  }

	strcat(openedTags, lastTag);
	strcat(openedTags, " ");
	//Если tag новой строки, обнуляем счетчик столбцов
	if (strcmp(lastTag, "tr") == 0) {
		if (maxColumn < columnCounter) maxColumn = columnCounter;
		columnCounter = 0;
	} else
	// Если td
	if (strcmp(lastTag, "td") == 0) {
		if (!(useSpawnRow || useSpawnColumn)) {
		}
		strcat(tagResult, "{");
		columnCounter += tagColumnNumber;
	}
	// Если th
	else if (strcmp(lastTag, "th") == 0) {
		strcat(tagResult, "{\\textbf{");
		columnCounter += tagColumnNumber;
	}
	// Если table
	else if (strcmp(lastTag, "table") == 0) {
		strcat(result, beginTable);
	}
	// Если span
	else if (strcmp(lastTag, "span") == 0) {
		strcat(tagResult, "{");
		columnCounter += tagColumnNumber;
	}

};

closetag: CLOSETAG {
	// Обработка ошибки
	if (strlen(openedTags) == 0) {
		lastTag[0] = '\0';
		printf("Вы пытаетесь закрыть тег, который не используется\n");
		return;
	}
	char line[80];
	sprintf(line, "%s", $1);
	// Сохраняем имя тега без </
	if (line[0] == '<') memmove(line, line + 2, strlen(line));
	char * tagName;
	tagName = strtok(line, " ");
	// Убираем > в конце тега
	strtok(tagName, ">");
	// Проверяем получен ли правильный тег
	if (strcmp(tagName, "table") != 0 && strcmp(tagName, "tr") != 0 && strcmp(tagName, "th") != 0 && strcmp(tagName, "td") != 0 && strcmp(tagName, "span") != 0) {
		printf("Неверный тег: %s\n", tagName);
		return;
	}
	char newTags[100];

	// Обработка ошибки
	if (strcmp(tagName, lastTag) != 0) {
		printf("\n%s\nОшибка: Найден закрывающий тег !%s!, а должен быть !%s!\n", openedTags, tagName, lastTag);
		return;
	}

	strncpy(newTags, openedTags, strlen(openedTags) - strlen(lastTag) - 1);
	newTags[strlen(openedTags) - strlen(lastTag) - 1] = '\0';
	strcpy(openedTags, newTags);
	openedTags[strlen(newTags)] = '\0';

	char tagsCopy[100];
	strcpy(tagsCopy, openedTags);
	char * tag;
	tag = strtok(tagsCopy, " ");

	while (tag != NULL) {
		strcpy(lastTag, tag);
		tag = strtok(NULL, " ");
	}
	// Конечный тег
	if (strlen(openedTags) == 0) lastTag[0] = '\0';
	// Если тег table
	if (strcmp(tagName, "table") == 0) {
		char tag[80] = "";
		for (int i = 0; i < maxColumn; i++) {
			strcat(tag, "c");
		}
		// Записываем результ
		strcat(result, "{");
		strcat(result, tag);
		strcat(result, "}\n");
		strcat(result, tagResult);
		strcat(result, endTable);
		// Обнуляем
		tagResult[0] = '\0';
		maxColumn = 0;
		columnCounter = 0;
	}
	// Если тег tr
	else if (strcmp(tagName, "tr") == 0) {
		if (! (strcmp("\\\\\n", tagResult + (strlen(tagResult) - 3)) == 0))
      memmove(tagResult + strlen(tagResult) - 3, "\\\\\n", 3);
      //strcat(tagResult, "\\\\\n");
	}
	// Если тег td
	else if (strcmp(tagName, "td") == 0) {
    strcat(tagResult, "}");

    for (int i = 0; i < countAttr; i++)
      strcat(tagResult, "}");
    countAttr = 0;

    if (useSpawnRow || useSpawnColumn) {
			useSpawnRow = false;
			useSpawnColumn = false;
			strcat(tagResult, "\\\\\n");
		}
		else {
			strcat(tagResult, " & ");
		}
	}
	// Если тег th
	else if (strcmp(tagName, "th") == 0) {
		strcat(tagResult, "}} & ");
	}
	// Если тег spawn
	else if (strcmp(tagName, "span") == 0) {
		strcat(tagResult, "}");
    for (int i = 0; i < countAttr; i++)
      strcat(tagResult, "}");
    countAttr = 0;
	}
};
value: VALUE {
	strcat(tagResult, $1);
};
end: END {
	if (strlen(openedTags) != 0) {
		printf("Вы забыли закрыть тег:\n%s\n", openedTags);
		return;
	}
	// Запись в файл
	FILE * file;
	file = fopen("out.tex", "w");
	fprintf(file, "%s", result);
	fclose(file);
	return;
};
