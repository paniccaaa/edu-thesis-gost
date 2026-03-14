SHELL := /bin/bash

MAIN ?= main
LATEXMK ?= latexmk
LUALATEX ?= lualatex
BIBER ?= biber
CHKTEX ?= chktex
LACHECK ?= lacheck
PDFTEXT ?= pdftotext
PDFFONTS ?= pdffonts

CHKTEX_FLAGS ?= -q -n1 -n8 -n13 -n36 -n46

TEX_SOURCES := gostvkr-lua.cls main.tex config/metadata.tex $(wildcard content/*.tex)
LINT_DIR := .reports
FONT_DIR := fonts
REQUIRED_FONTS := pt-astra-serif_regular.ttf pt-astra-serif_bold.ttf pt-astra-serif_italic.ttf pt-astra-serif_bold-italic.ttf
REQUIRED_CODE_FONTS := fira-code/FiraCode-Regular.ttf fira-code/FiraCode-Medium.ttf fira-code/FiraCode-Bold.ttf fira-code/FiraCode-Retina.ttf

CHKTEX_REPORT := $(LINT_DIR)/chktex.log
LACHECK_REPORT := $(LINT_DIR)/lacheck.log
FONTCHECK_POS_LOG := $(LINT_DIR)/fontcheck-positive.log
FONTCHECK_NEG_LOG := $(LINT_DIR)/fontcheck-negative.log
FONTCHECK_NEG_CODE_LOG := $(LINT_DIR)/fontcheck-negative-code.log
PDFTEXT_REPORT := $(LINT_DIR)/main.txt

.PHONY: help build rebuild clean distclean watch lint check fontcheck ci release-check

help:
	@echo "Доступные цели:"
	@echo "  build         - собрать $(MAIN).pdf через latexmk (lualatex + biber)"
	@echo "  rebuild       - полная очистка и пересборка"
	@echo "  clean         - удалить промежуточные файлы (PDF сохранить)"
	@echo "  distclean     - удалить все артефакты сборки, отчеты и PDF"
	@echo "  watch         - непрерывная сборка без предпросмотра (latexmk -pvc)"
	@echo "  lint          - запустить chktex + lacheck (блокируют только ошибки chktex)"
	@echo "  check         - проверить чистоту лога, контракты ассетов и маркеры в PDF"
	@echo "  fontcheck     - проверить локальные шрифты и сценарии немедленной остановки при ошибке"
	@echo "  ci            - build + lint + check + fontcheck"
	@echo "  release-check - distclean + ci + build"

build:
	$(LATEXMK) -pdf -lualatex $(MAIN).tex

rebuild: distclean build

clean:
	$(LATEXMK) -c $(MAIN).tex

distclean:
	$(LATEXMK) -C $(MAIN).tex
	rm -rf $(LINT_DIR)

watch:
	$(LATEXMK) -pvc -view=none -pdf -lualatex $(MAIN).tex

lint:
	@mkdir -p $(LINT_DIR)
	@set -o pipefail; \
	$(CHKTEX) $(CHKTEX_FLAGS) $(TEX_SOURCES) > $(CHKTEX_REPORT) 2>&1 || true
	@$(LACHECK) gostvkr-lua.cls main.tex content/*.tex > $(LACHECK_REPORT) 2>&1 || true
	@echo "== Отчет chktex =="
	@cat $(CHKTEX_REPORT)
	@echo "== Отчет lacheck =="
	@cat $(LACHECK_REPORT)
	@if grep -Eq '^Error [0-9]+' $(CHKTEX_REPORT); then \
		echo "Проверка lint не пройдена: chktex обнаружил ошибки"; \
		exit 1; \
	fi

check: build
	@mkdir -p $(LINT_DIR)
	@test -f $(MAIN).log || (echo "Проверка check не пройдена: файл $(MAIN).log не найден" && exit 1)
	@if grep -Eq 'LaTeX Error|Undefined|Overfull|Underfull|Warning' $(MAIN).log; then \
		echo "Проверка check не пройдена: в $(MAIN).log есть ошибки или предупреждения"; \
		egrep -n 'LaTeX Error|Undefined|Overfull|Underfull|Warning' $(MAIN).log; \
		exit 1; \
	fi
	@$(PDFTEXT) $(MAIN).pdf $(PDFTEXT_REPORT)
	@for marker in \
		"Оглавление" \
		"ВВЕДЕНИЕ" \
		"Глава 1." \
		"Аналитическая часть" \
		"Глава 2." \
		"Проектная часть" \
		"ЗАКЛЮЧЕНИЕ" \
		"Демонстрация формул" \
		"Демонстрация рисунков" \
		"Демонстрация таблиц" \
		"Демонстрация длинной таблицы" \
		"Демонстрация листингов" \
		"Демонстрация алгоритмов" \
		"Композитный кейс 1" \
		"Композитный кейс 2" \
		"ПРИЛОЖЕНИЯ" \
		"Приложение А." \
		"Приложение Б." \
		"Приложение В." \
		"Приложение Г." \
		"Список литературы"; do \
		if ! grep -q "$$marker" $(PDFTEXT_REPORT); then \
			echo "Проверка check не пройдена: маркер '$$marker' не найден в тексте PDF"; \
			exit 1; \
		fi; \
		done
	@bash -lc 'set -euo pipefail; \
		txt="$(PDFTEXT_REPORT)"; \
		flat=$$(tr "\f\n" "  " < "$$txt" | tr -s " "); \
		if ! echo "$$flat" | grep -Eq "Глава[[:space:]]*1\\.[[:space:]]*Аналитическая[[:space:]]+часть"; then \
			echo "Проверка check не пройдена: не найден заголовок Глава 1. Аналитическая часть"; \
			exit 1; \
		fi; \
		if ! echo "$$flat" | grep -Eq "Глава[[:space:]]*2\\.[[:space:]]*Проектная[[:space:]]+часть"; then \
			echo "Проверка check не пройдена: не найден заголовок Глава 2. Проектная часть"; \
			exit 1; \
		fi; \
		if echo "$$flat" | grep -Eq "Глава[[:space:]]*3\\.|Глава[[:space:]]*4\\."; then \
			echo "Проверка check не пройдена: в документе обнаружены лишние нумеруемые главы (допустимы только 1 и 2)"; \
			exit 1; \
		fi; \
		if echo "$$flat" | grep -Eq "Глава[[:space:]]*1\\.[[:space:]]*ВВЕДЕНИЕ"; then \
			echo "Проверка check не пройдена: введение не должно нумероваться как глава"; \
			exit 1; \
		fi; \
		if echo "$$flat" | grep -Eq "Глава[[:space:]]*[0-9]+\\.[[:space:]]*ЗАКЛЮЧЕНИЕ"; then \
			echo "Проверка check не пройдена: заключение не должно нумероваться как глава"; \
			exit 1; \
		fi'
	@bash -lc 'set -euo pipefail; \
		txt="$(PDFTEXT_REPORT)"; \
		page_block=$$(awk -v RS="\f" '\''/ПРИЛОЖЕНИЯ/{p=NR} END{if(p) print p}'\'' "$$txt"); \
		page_a=$$(awk -v RS="\f" -v start="$$page_block" '\''NR>=start && /Приложение А\./{print NR; exit}'\'' "$$txt"); \
		page_b=$$(awk -v RS="\f" -v start="$$page_block" '\''NR>=start && /Приложение Б\./{print NR; exit}'\'' "$$txt"); \
		page_v=$$(awk -v RS="\f" -v start="$$page_block" '\''NR>=start && /Приложение В\./{print NR; exit}'\'' "$$txt"); \
		page_g=$$(awk -v RS="\f" -v start="$$page_block" '\''NR>=start && /Приложение Г\./{print NR; exit}'\'' "$$txt"); \
		if [ -z "$$page_block" ] || [ -z "$$page_a" ] || [ -z "$$page_b" ] || [ -z "$$page_v" ] || [ -z "$$page_g" ]; then \
			echo "Проверка check не пройдена: не удалось определить страницы блока приложений"; \
			exit 1; \
		fi; \
		if [ "$$page_block" -ne "$$page_a" ]; then \
			echo "Проверка check не пройдена: ПРИЛОЖЕНИЯ и Приложение А должны быть на одной странице"; \
			exit 1; \
		fi; \
		if [ "$$page_b" -le "$$page_a" ] || [ "$$page_v" -le "$$page_b" ] || [ "$$page_g" -le "$$page_v" ]; then \
			echo "Проверка check не пройдена: приложения Б/В/Г должны идти после А в правильном порядке страниц"; \
			exit 1; \
		fi; \
		if [ "$$page_b" -eq "$$page_v" ] || [ "$$page_b" -eq "$$page_g" ] || [ "$$page_v" -eq "$$page_g" ]; then \
			echo "Проверка check не пройдена: приложения Б, В и Г должны начинаться на разных страницах"; \
			exit 1; \
		fi'
	@if rg -n 'title-2025-logo' content/*.tex >/dev/null; then \
		echo "Проверка check не пройдена: логотип титульного листа нельзя использовать в главах"; \
		rg -n 'title-2025-logo' content/*.tex; \
		exit 1; \
	fi
	@if rg -n 'otex-|OTeX' main.tex content/*.tex docs/*.md README.md >/dev/null; then \
		echo "Проверка check не пройдена: найдено устаревшее именование otex/OTeX"; \
		rg -n 'otex-|OTeX' main.tex content/*.tex docs/*.md README.md; \
		exit 1; \
	fi
	@if rg -n '\bstyle=' content/*.tex >/dev/null; then \
		echo "Проверка check не пройдена: style=... запрещен в lstlisting внутри content"; \
		rg -n '\bstyle=' content/*.tex; \
		exit 1; \
	fi
	@if rg -n 'language=Python' content/*.tex >/dev/null; then \
		echo "Проверка check не пройдена: language=Python нельзя задавать локально в content (он уже глобальный)"; \
		rg -n 'language=Python' content/*.tex; \
		exit 1; \
	fi
	@if ! rg -n 'language=Python' main.tex >/dev/null; then \
		echo "Проверка check не пройдена: в main.tex отсутствует глобальный language=Python для listings"; \
		exit 1; \
	fi
	@if ! $(PDFFONTS) $(MAIN).pdf | grep -qi 'Fira'; then \
		echo "Проверка check не пройдена: шрифт Fira Code не встроен в PDF-листинги"; \
		$(PDFFONTS) $(MAIN).pdf; \
		exit 1; \
	fi
	@test -f docs/assets-sources.md || (echo "Проверка check не пройдена: файл docs/assets-sources.md не найден" && exit 1)
	@bash -lc 'shopt -s nullglob; imgs=(assets/images/fig-*); \
		if [ $${#imgs[@]} -lt 4 ] || [ $${#imgs[@]} -gt 6 ]; then \
			echo "Проверка check не пройдена: в assets/images/fig-* должно быть от 4 до 6 тематических изображений"; \
			exit 1; \
		fi; \
		for img in "$${imgs[@]}"; do \
			base=$$(basename "$$img"); \
			if ! grep -Fq "| \`$$base\` |" docs/assets-sources.md; then \
				echo "Проверка check не пройдена: для $$base нет записи в docs/assets-sources.md"; \
				exit 1; \
			fi; \
		done'
	@echo "Проверка check пройдена: лог чистый, маркеры и контракты соблюдены"

fontcheck:
	@mkdir -p $(LINT_DIR)
	@set -euo pipefail; \
	pos_log="$(CURDIR)/$(FONTCHECK_POS_LOG)"; \
	neg_log="$(CURDIR)/$(FONTCHECK_NEG_LOG)"; \
	neg_code_log="$(CURDIR)/$(FONTCHECK_NEG_CODE_LOG)"; \
	for font in $(REQUIRED_FONTS) $(REQUIRED_CODE_FONTS); do \
		if [ ! -f "$(FONT_DIR)/$$font" ]; then \
			echo "Проверка fontcheck не пройдена: отсутствует обязательный файл шрифта $(FONT_DIR)/$$font"; \
			exit 1; \
		fi; \
	done; \
	tmpdir="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	cp -r gostvkr-lua.cls main.tex config content references.bib latexmkrc assets $(FONT_DIR) "$$tmpdir"/; \
	cd "$$tmpdir"; \
	$(LATEXMK) -C $(MAIN).tex >/dev/null 2>&1 || true; \
	if ! $(LATEXMK) -pdf -lualatex $(MAIN).tex > "$$pos_log" 2>&1; then \
		echo "Проверка fontcheck не пройдена: позитивная сборка с полным набором fonts/ должна быть успешной"; \
		cat "$$pos_log"; \
		exit 1; \
	fi; \
	mv "$(FONT_DIR)/pt-astra-serif_regular.ttf" "$(FONT_DIR)/pt-astra-serif_regular.ttf.missing"; \
	$(LATEXMK) -C $(MAIN).tex >/dev/null 2>&1 || true; \
	if $(LATEXMK) -pdf -lualatex $(MAIN).tex > "$$neg_log" 2>&1; then \
		echo "Проверка fontcheck не пройдена: негативный сценарий должен падать при отсутствии файла PT Astra Serif"; \
		exit 1; \
	fi; \
	if ! grep -q 'Class gostvkr-lua Error:' "$$neg_log" || ! grep -q 'pt-astra-serif_regular.ttf' "$$neg_log"; then \
		echo "Проверка fontcheck не пройдена: в логе нет ожидаемой ClassError о недостающем шрифте PT Astra Serif"; \
		cat "$$neg_log"; \
		exit 1; \
	fi; \
	mv "$(FONT_DIR)/pt-astra-serif_regular.ttf.missing" "$(FONT_DIR)/pt-astra-serif_regular.ttf"; \
	mv "$(FONT_DIR)/fira-code/FiraCode-Regular.ttf" "$(FONT_DIR)/fira-code/FiraCode-Regular.ttf.missing"; \
	$(LATEXMK) -C $(MAIN).tex >/dev/null 2>&1 || true; \
	if $(LATEXMK) -pdf -lualatex $(MAIN).tex > "$$neg_code_log" 2>&1; then \
		echo "Проверка fontcheck не пройдена: негативный сценарий должен падать при отсутствии файла Fira Code"; \
		exit 1; \
	fi; \
	if ! grep -q 'Package main Error:' "$$neg_code_log" || ! grep -q 'FiraCode-Regular.ttf' "$$neg_code_log"; then \
		echo "Проверка fontcheck не пройдена: в логе нет ожидаемой ошибки о недостающем файле Fira Code"; \
		cat "$$neg_code_log"; \
		exit 1; \
	fi
	@echo "Проверка fontcheck пройдена"

ci: build lint check fontcheck

release-check: distclean ci build
