% {#include < stdio.h > #include < string.h > #include < stdlib.h > #include < stdbool.h >

	void yyerror(const char * str) {
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
	char styleResult[1024] = "";
	//Счетчик столбцов
	int columnCounter = 0;
	int maxColumn = 0;
	char beginTable[100] = "\\begin{table}[]\n\\begin{tabular}";
	char endTable[100] = "\\end{tabular}\n\\end{table}\n";
	//Хрнаится инфа о необходимых сдвигах из за rowspan
	int needSpace[1024];

	bool isSpaceNeeded(int num) {
		int i = 0;
		while (needSpace[i] != -1) {
			if (needSpace[i] == num) {
				needSpace[i] = -2;
				return true;
			}
			i++;
		}
		return false;
	}

	void addToSpaceArray(int num) {
		int i = 0;
		while (needSpace[i] != -1) {
			if (needSpace[i] == -2) {
				needSpace[i] = num;
				return;
			}
			i++;

		}
		needSpace[i] = num;
		needSpace[i + 1] = -1;
		return;
	}

	main() {
		yyparse();
	}

	%
}

% token OPENTAG CLOSETAG VALUE END

% %

commands:
/* empty */
| commands command;

command: opentag | closetag | value | end;
opentag: OPENTAG {
	char line[80];
	sprintf(line, "%s", $1); // помещаем в буфер занчение тега
	if (line[0] == '<') memmove(line, line + 1, strlen(line));
	char * tagName;
	//Получаем тег в формате tag>
	tagName = strtok(line, " ");
	strcpy(lastTag, tagName);
	//Удаляем > в конце тега
	if (lastTag[strlen(lastTag) - 1] == '>') lastTag[strlen(lastTag) - 1] = '\0';
	//Проверка на валидный tag
	if (strcmp(lastTag, "table") != 0 && strcmp(lastTag, "tr") != 0 && strcmp(lastTag, "th") != 0 && strcmp(lastTag, "td") != 0 && strcmp(lastTag, "span") != 0) {
		printf("Неверный тег: !%s!\n", lastTag);
		return;
	}
	// Добавляем пробелы
	if (strcmp(lastTag, "th") == 0 || strcmp(lastTag, "td") == 0) {
		if (isSpaceNeeded(columnCounter)) {
			strcat(styleResult, " & ");
		}
	}
	// Удалаем теги, чтобы получить стили css
	tagName = strtok(NULL, " ");
	int styleColumnNumber = 1;
	while (tagName != NULL) {
		if (tagName[strlen(tagName) - 1] == '>') tagName[strlen(tagName) - 1] = '\0';
		char copy[80];
		char * style;
		strcpy(copy, tagName);
		style = strtok(copy, "=");
		// Определяем rowspan
		if (strcmp(style, "rowspan") == 0) {
			style = strtok(NULL, "\"");
			strcat(styleResult, "\\multirow{");
			strcat(styleResult, style);
			strcat(styleResult, "}{*}");
			// Добавляем пробел
			for (int i = 1; i < atoi(style); i++) {
				addToSpaceArray(columnCounter);
			}
			// Иначе colspan
		} else if (strcmp(style, "colspan") == 0) {
			style = strtok(NULL, "\"");
			strcat(styleResult, "\\multicolumn{");
			strcat(styleResult, style);
			styleColumnNumber = atoi(style);
			strcat(styleResult, "}{c}");
		}
		// Иначе style
		else if (strcmp(style, "style") == 0) {
			style = strtok(NULL, ";"); // все совйства вместе со значениями
			while (style != NULL) { // проходимся по каждому из них
				char * property;
				char copystyle[80];
				strcpy(copystyle, style);
				property = strtok(copystyle, ":");

				// обработка свойства color
				if (strcmp(property, "\"color") == 0) {
					property = strtok(NULL, ":");
					memmove(property, property + 1, strlen(property));
					strcat(styleResult, "\\textcolor[HTML]{");
					strcat(styleResult, property);
					strcat(styleResult, "}");
          printf("dsa");
				}
				// обработка свойства background-color
				else if (strcmp(property, "\"background-color") == 0) {
					property = strtok(NULL, ":");
					memmove(property, property + 1, strlen(property));
					strcat(styleResult, "\\colorbox[HTML]{");
					strcat(styleResult, property);
					strcat(styleResult, "}");
				}
				style = strtok(NULL, ";");
			}
		}

		tagName = strtok(NULL, " ");
	}
	strcat(openedTags, lastTag);
	strcat(openedTags, " ");
	//Если tag новой строки, обнуляем счетчик столбцов
	if (strcmp(lastTag, "tr") == 0) {
		if (maxColumn < columnCounter) maxColumn = columnCounter;
		columnCounter = 0;
	}
	// Если td
	else if (strcmp(lastTag, "td") == 0) {
		strcat(styleResult, "{");
		columnCounter += styleColumnNumber;
	}
	// Если th
	else if (strcmp(lastTag, "th") == 0) {
		strcat(styleResult, "{\\textbf{");
		columnCounter += styleColumnNumber;
	}
	// Если table
	else if (strcmp(lastTag, "table") == 0) {
		strcat(result, beginTable);
		needSpace[0] = -1;
	}
	// Если span
	else if (strcmp(lastTag, "span") == 0) {
		strcat(styleResult, "{");
		columnCounter += styleColumnNumber;
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
		char style[80] = "";
		for (int i = 0; i < maxColumn; i++) {
			strcat(style, "c");
		}
		// Записываем результ
		strcat(result, "{");
		strcat(result, style);
		strcat(result, "}\n");
		strcat(result, styleResult);
		strcat(result, endTable);
		// Обнуляем
		styleResult[0] = '\0';
		maxColumn = 0;
		columnCounter = 0;
	}
	// Если тег tr
	else if (strcmp(tagName, "tr") == 0) {
		strcat(styleResult, "\\\\\n");
	}
	// Если тег td
	else if (strcmp(tagName, "td") == 0) {
		strcat(styleResult, "} & ");
	}
	// Если тег th
	else if (strcmp(tagName, "th") == 0) {
		strcat(styleResult, "}} & ");
	}
	// Если тег spawn
	else if (strcmp(tagName, "span") == 0) {
		strcat(styleResult, "}");
	}
};
value: VALUE {
	strcat(styleResult, $1);
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
