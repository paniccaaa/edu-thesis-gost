# Руководство по классу `gostvkr-lua.cls`

Класс уже содержит типографику и служебные настройки ВКР.  
Новичку не нужно править ядро класса: обычно достаточно `config/metadata.tex` и файлов в `content/`.

## 1) Что в классе считается публичным API
- Опции `\documentclass`:
  - `degree=bachelor|master`
  - `language=ru-en|ru`
  - `bibstyle=<стиль biblatex-gost>`
- Команда настройки метаданных:
  - `\gostsetup{...}`
- Команды документа:
  - `\maketitlepage`
  - `\frontchapter{<заголовок>}`
  - `\makeintroduction`
  - `\makeconclusion`
  - `\printgostbibliography`
  - `\makeappendicesblock`
  - `\appendixchapterfirst{<буква>}{<название>}`
  - `\appendixchapternext{<буква>}{<название>}`
  - `\makeabstractru{...}` и `\makeabstracten{...}` (опционально)

### Глава-first политика
- Введение и заключение оформляются как ненумеруемые chapter-уровневые блоки:
  - `\makeintroduction`, `\makeconclusion` (или универсальная `\frontchapter{...}`).
- Нумеруемые главы основной части: только две.
- Для приложений используется отдельный блок:
  - `\makeappendicesblock`;
  - `\appendixchapterfirst` для приложения А (на той же странице, что блок);
  - `\appendixchapternext` для приложений Б/В/Г (каждое с новой страницы).
- Внутри глав используется иерархия `\section + \subsection`.

## 2) Что можно настраивать через `\gostsetup`
- Титул и организация:
  - `ministry`, `universitylineone`, `universitylinetwo`, `universitylinethree`
- Параметры работы:
  - `direction`, `profile`, `worktype`, `theme`
- Данные обучающегося:
  - `course`, `studyform`, `fullname`
- Данные руководителя/рецензента:
  - `supervisor`, `reviewer`
- Нижний блок титула:
  - `city`, `year`
- Логотип:
  - `logopath`

## 3) Что считается внутренним API (не редактировать без необходимости)
- Макросы с префиксом `\gostvkr@...`.
- Внутренние проверки ошибок и файлов шрифтов.
- Переопределение `\tableofcontents`, настройки `titlesec/tocloft`.
- Служебные макросы титульного листа.

## 4) Где что меняется
- Меняется часто:
  - `config/metadata.tex` (метаданные титула),
  - `content/*.tex` (текст ВКР),
  - `references.bib` (источники).
- Меняется редко:
  - `main.tex` (подключение файлов и пакетов).
- Почти никогда:
  - `gostvkr-lua.cls` (ядро класса).

## 5) Типовые ошибки и быстрые действия
- Ошибка о PT Astra Serif:
  - проверьте, что в `fonts/` лежат 4 файла `pt-astra-serif_*.ttf`.
- Ошибка о Fira Code:
  - проверьте `fonts/fira-code/FiraCode-*.ttf`.
- Ошибка по логотипу титула:
  - проверьте путь `logopath` в `\gostsetup`.
- Необновленные ссылки:
  - запустите `make build` повторно.

## 6) Как проверять результат
1. `make build`
2. `make check`
3. `make ci`

Если все три команды проходят, базовый технический контроль шаблона выполнен.
