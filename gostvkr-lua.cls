\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{gostvkr-lua}[2026/03/14 v0.4 LuaLaTeX-first GOST VKR class (sample-first profile)]

% -----------------------------------------------------------------------------
% КАРТА КЛАССА (для быстрого входа новичка)
% 1) Опции класса: degree, language, bibstyle.
% 2) Проверка обязательных локальных шрифтов PT Astra Serif.
% 3) Базовая типографика: поля, интервал, абзац, заголовки и оглавление.
% 4) Настройка титульного листа через \gostsetup{...}.
% 5) Публичные команды: \maketitlepage, \frontchapter, \makeintroduction,
%    \makeconclusion, \makeabstractru, \makeabstracten,
%    \printgostbibliography, \makeappendicesblock, \appendixchapterfirst,
%    \appendixchapternext.
%
% Внутренние макросы с префиксом \gostvkr@ являются служебными:
% их можно читать как справку, но в пользовательской работе редактировать не нужно.
% -----------------------------------------------------------------------------

% Движок строго фиксирован: шаблон рассчитан только на LuaLaTeX.
\RequirePackage{iftex}
\ifLuaTeX\else
  \ClassError{gostvkr-lua}{Класс требует движок LuaLaTeX}{Запускайте сборку командой lualatex или через latexmk с ключом -lualatex.}
\fi

% Опции класса и ключи конфигурации.
\RequirePackage{kvoptions}
\RequirePackage{xkeyval}
\RequirePackage{etoolbox}
\RequirePackage{expl3}

\SetupKeyvalOptions{family=gostvkr,prefix=gostvkr@}
\DeclareStringOption[bachelor]{degree}
\DeclareStringOption[ru-en]{language}
\DeclareStringOption[gost-numeric]{bibstyle}
\DeclareStringOption[]{fontpolicy}
\DeclareDefaultOption{\PassOptionsToClass{\CurrentOption}{extbook}}
\ProcessKeyvalOptions*

\ExplSyntaxOn
\msg_new:nnn { gostvkr-lua } { abort } { Сборка~остановлена~после~ошибки~класса. }
\cs_new_protected:Npn \gostvkr@stopnow { \msg_fatal:nn { gostvkr-lua } { abort } }
\ExplSyntaxOff
\newcommand{\gostvkr@fatal}[2]{%
  \ClassError{gostvkr-lua}{#1}{#2}%
  \gostvkr@stopnow
}

\newif\ifgostvkr@optionerror
\let\gostvkr@optionfatal\relax
\newcommand{\gostvkr@setoptionerror}[2]{%
  \ifgostvkr@optionerror\else
    \gostvkr@optionerrortrue
    \gdef\gostvkr@optionfatal{\gostvkr@fatal{#1}{#2}}%
  \fi
}

\newcommand{\gostvkr@normalizeoptions}{%
  \gostvkr@optionerrorfalse
  \global\let\gostvkr@optionfatal\relax
  \ifdefstring{\gostvkr@degree}{bachelor}{}{%
    \ifdefstring{\gostvkr@degree}{master}{}{%
      \gostvkr@setoptionerror{Недопустимое значение опции degree: \gostvkr@degree}{Разрешены значения: bachelor, master.}%
    }%
  }%
  \ifdefstring{\gostvkr@language}{en-ru}{%
    \ClassWarningNoLine{gostvkr-lua}{Опция language=en-ru устарела. Автоматически используется language=ru-en.}%
    \renewcommand{\gostvkr@language}{ru-en}%
  }{}%
  \ifdefstring{\gostvkr@language}{ru-en}{}{%
    \ifdefstring{\gostvkr@language}{ru}{}{%
      \gostvkr@setoptionerror{Недопустимое значение опции language: \gostvkr@language}{Разрешены значения: ru-en, ru. Устаревший алиас: en-ru.}%
    }%
  }%
  \ifdefempty{\gostvkr@fontpolicy}{}{%
    \gostvkr@setoptionerror{Опция fontpolicy удалена}{Удалите fontpolicy из \\documentclass. Шрифты берутся только из локальной папки fonts/ (PT Astra Serif).}%
  }%
}
\gostvkr@normalizeoptions
\gostvkr@optionfatal

% Базовый класс документа: extbook для модели "глава -> раздел -> подраздел".
\LoadClass[a4paper,14pt,oneside,openany]{extbook}

% Пакеты типографики и структуры документа.
\RequirePackage[left=30mm,right=15mm,top=20mm,bottom=20mm,headheight=17pt,headsep=5mm]{geometry}
\RequirePackage{setspace}
\RequirePackage{indentfirst}
\RequirePackage{fontspec}
\RequirePackage{polyglossia}
\RequirePackage{csquotes}
\RequirePackage{microtype}
\RequirePackage{graphicx}
\RequirePackage{amsmath}
\RequirePackage{array}
\RequirePackage{booktabs}
\RequirePackage{longtable}
\RequirePackage{caption}
\RequirePackage{titlesec}
\RequirePackage{tocloft}
\RequirePackage{enumitem}
\RequirePackage{xparse}
\RequirePackage{hyperref}
\RequirePackage{fancyhdr}

\defaultfontfeatures{Ligatures=TeX,Scale=MatchLowercase}

% Локальный шрифтовой контракт: текстовый слой всегда PT Astra Serif.
\newcommand{\gostvkr@fontsdir}{fonts/}
\newcommand{\gostvkr@mainfontselected}{PT Astra Serif}

\newcommand{\gostvkr@requirefontfile}[1]{%
  \IfFileExists{\gostvkr@fontsdir#1}{}{%
    \gostvkr@fatal{Не найден обязательный файл шрифта: \gostvkr@fontsdir#1}{Скопируйте файлы PT Astra Serif в локальную папку fonts/.}%
  }%
}

\gostvkr@requirefontfile{pt-astra-serif_regular.ttf}
\gostvkr@requirefontfile{pt-astra-serif_bold.ttf}
\gostvkr@requirefontfile{pt-astra-serif_italic.ttf}
\gostvkr@requirefontfile{pt-astra-serif_bold-italic.ttf}

\newcommand{\gostvkr@fontbasename}{pt-astra-serif_regular}
\newcommand{\gostvkr@fontsetupoptions}{%
  Path=\gostvkr@fontsdir,
  Extension=.ttf,
  UprightFont=pt-astra-serif_regular,
  BoldFont=pt-astra-serif_bold,
  ItalicFont=pt-astra-serif_italic,
  BoldItalicFont=pt-astra-serif_bold-italic
}

\setmainfont[\gostvkr@fontsetupoptions]{\gostvkr@fontbasename}
\setsansfont[\gostvkr@fontsetupoptions]{\gostvkr@fontbasename}
\setmonofont[\gostvkr@fontsetupoptions]{\gostvkr@fontbasename}

\newfontfamily\cyrillicfont[\gostvkr@fontsetupoptions]{\gostvkr@fontbasename}
\newfontfamily\cyrillicfontsf[\gostvkr@fontsetupoptions]{\gostvkr@fontbasename}
\newfontfamily\cyrillicfonttt[\gostvkr@fontsetupoptions]{\gostvkr@fontbasename}

% Языковая схема: русский основной, английский опциональный.
\newcommand{\gostvkr@setuplanguage}{%
  \setmainlanguage{russian}%
  \ifdefstring{\gostvkr@language}{ru-en}{%
    \setotherlanguage{english}%
  }{}%
}
\gostvkr@setuplanguage

% Абзацная модель и колонтитул.
\onehalfspacing
\raggedbottom
\fancyhf{}
\fancyhead[C]{\thepage}
\renewcommand{\headrulewidth}{0pt}
\pagestyle{fancy}
\fancypagestyle{plain}{%
  \fancyhf{}
  \fancyhead[C]{\thepage}
  \renewcommand{\headrulewidth}{0pt}
}
\setlength{\parindent}{1.25cm}
\setlength{\parskip}{0pt}
\setlength{\emergencystretch}{3em}
\setlist{nosep,topsep=0.5\baselineskip,leftmargin=1.6\parindent}

\clubpenalty=10000
\widowpenalty=10000
\displaywidowpenalty=10000
\vfuzz=10pt

% Формат нумерации и заголовков главы/разделов.
\setcounter{secnumdepth}{3}
\setcounter{tocdepth}{2}
\renewcommand{\chaptername}{Глава}
\renewcommand{\thechapter}{\arabic{chapter}}
\renewcommand{\thesection}{\thechapter.\arabic{section}}
\renewcommand{\thesubsection}{\thesection.\arabic{subsection}}
\renewcommand{\thesubsubsection}{\thesubsection.\arabic{subsubsection}}

\titleformat{\chapter}[block]{\normalfont\bfseries\normalsize\centering}{\MakeUppercase{\chaptername}\ \thechapter.}{0.5em}{\MakeUppercase}
\titleformat{name=\chapter,numberless}[block]{\normalfont\bfseries\normalsize\centering}{}{0pt}{\MakeUppercase}
\titlespacing*{\chapter}{0pt}{\baselineskip}{\baselineskip}
\titleformat{\section}[block]{\normalfont\bfseries\normalsize\centering}{\thesection}{1em}{\MakeUppercase}
\titlespacing*{\section}{0pt}{\baselineskip}{0.5\baselineskip}
\titleformat{\subsection}[block]{\normalfont\bfseries\normalsize}{\thesubsection}{1em}{}
\titlespacing*{\subsection}{\parindent}{\baselineskip}{0.5\baselineskip}
\titleformat{\subsubsection}[block]{\normalfont\bfseries\normalsize}{\thesubsubsection}{1em}{}
\titlespacing*{\subsubsection}{\parindent}{0.75\baselineskip}{0.5\baselineskip}

% Содержание всегда на отдельной странице и в центре.
\renewcommand{\contentsname}{Содержание}
\gappto\captionsrussian{\renewcommand{\contentsname}{Содержание}}
\AtBeginDocument{%
  \renewcommand{\contentsname}{Содержание}%
  \renewcommand{\tableofcontents}{%
    \clearpage
    \chapter*{\contentsname}
    \@starttoc{toc}
    \clearpage
  }%
}
\renewcommand{\cfttoctitlefont}{\centering\bfseries\normalsize}
\renewcommand{\cftaftertoctitle}{\par}
\renewcommand{\cftchapfont}{\normalfont}
\renewcommand{\cftchappagefont}{\normalfont}
\renewcommand{\cftsecfont}{\normalfont}
\renewcommand{\cftsecpagefont}{\normalfont}
\setlength{\cftbeforechapskip}{0pt}
\setlength{\cftbeforesecskip}{0pt}
\setlength{\cftbeforesubsecskip}{0pt}
\renewcommand{\cftchappresnum}{\chaptername\ }
\renewcommand{\cftchapaftersnum}{.\ }
\settowidth{\cftchapnumwidth}{\chaptername\ 10.\ }

% Подписи объектов и гиперссылки.
\captionsetup{font=normalfont,labelfont=normalfont,singlelinecheck=false}
\captionsetup[figure]{name=Рисунок,labelsep=endash,justification=centering}
\captionsetup[table]{name=Таблица,labelsep=endash,justification=centering}

\hypersetup{
  unicode=true,
  pdfencoding=auto,
  hidelinks,
  breaklinks=true
}
\urlstyle{same}
\Urlmuskip=0mu\relax

\edef\gostvkr@biblatexoptions{%
  backend=biber,
  style=\gostvkr@bibstyle,
  sorting=none,
  language=auto,
  autolang=other,
  bibencoding=utf8
}
\expandafter\RequirePackage\expandafter[\gostvkr@biblatexoptions]{biblatex}

% Формат даты обращения: «дата обращения: ДД.ММ.ГГГГ» вместо «дата обр. ...»
\AtEndPreamble{%
  \DefineBibliographyStrings{russian}{urlseen = {дата обращения}}%
  \DeclareFieldFormat{urldate}{\mkbibparens{\bibstring{urlseen}\addcolon\space#1}}%
}

% ----------------------- Данные титульного листа -----------------------------
% Значения по умолчанию можно переопределить через \gostsetup{...}.
\newcommand{\gostvkr@defaultworktype}{Выпускная квалификационная работа}
\newif\ifgostvkr@showreviewer
\gostvkr@showreviewerfalse
\ifdefstring{\gostvkr@degree}{master}{\gostvkr@showreviewertrue}{}

\newcommand{\gostvkr@ministry}{МИНИСТЕРСТВО ПРОСВЕЩЕНИЯ РОССИЙСКОЙ ФЕДЕРАЦИИ}
\newcommand{\gostvkr@universitylineone}{ФЕДЕРАЛЬНОЕ ГОСУДАРСТВЕННОЕ БЮДЖЕТНОЕ\\ОБРАЗОВАТЕЛЬНОЕ УЧРЕЖДЕНИЕ ВЫСШЕГО ОБРАЗОВАНИЯ}
\newcommand{\gostvkr@universitylinetwo}{«РОССИЙСКИЙ ГОСУДАРСТВЕННЫЙ}
\newcommand{\gostvkr@universitylinethree}{ПЕДАГОГИЧЕСКИЙ УНИВЕРСИТЕТ им. А. И. ГЕРЦЕНА»}
\newcommand{\gostvkr@direction}{09.03.01 Информатика и вычислительная техника}
\newcommand{\gostvkr@profile}{Технологии разработки программного обеспечения}
\newcommand{\gostvkr@worktype}{\gostvkr@defaultworktype}
\newcommand{\gostvkr@course}{4}
\newcommand{\gostvkr@studyform}{очной}
\newcommand{\gostvkr@fullname}{Фамилии Имени Отчества}
\newcommand{\gostvkr@theme}{Здесь надо написать тему ВКР (смотрите правильные формулировки в приказах)}
\newcommand{\gostvkr@supervisor}{Учёная степень, учёное звание, должность руководителя ВКР\\Фамилия Имя Отчество}
\newcommand{\gostvkr@reviewer}{Доктор педагогических наук, зав.\,кафедрой информатики и вычислительной техники\\Барахсанова Елизавета Афанасьевна}
\newcommand{\gostvkr@city}{Санкт-Петербург}
\newcommand{\gostvkr@year}{\the\year}
\newcommand{\gostvkr@logopath}{assets/logo-rgpu-herzen.png}

\define@key{gostvkrsetup}{ministry}{\renewcommand{\gostvkr@ministry}{#1}}
\define@key{gostvkrsetup}{universitylineone}{\renewcommand{\gostvkr@universitylineone}{#1}}
\define@key{gostvkrsetup}{universitylinetwo}{\renewcommand{\gostvkr@universitylinetwo}{#1}}
\define@key{gostvkrsetup}{universitylinethree}{\renewcommand{\gostvkr@universitylinethree}{#1}}
\define@key{gostvkrsetup}{direction}{\renewcommand{\gostvkr@direction}{#1}}
\define@key{gostvkrsetup}{profile}{\renewcommand{\gostvkr@profile}{#1}}
\define@key{gostvkrsetup}{worktype}{\renewcommand{\gostvkr@worktype}{#1}}
\define@key{gostvkrsetup}{course}{\renewcommand{\gostvkr@course}{#1}}
\define@key{gostvkrsetup}{studyform}{\renewcommand{\gostvkr@studyform}{#1}}
\define@key{gostvkrsetup}{fullname}{\renewcommand{\gostvkr@fullname}{#1}}
\define@key{gostvkrsetup}{theme}{\renewcommand{\gostvkr@theme}{#1}}
\define@key{gostvkrsetup}{supervisor}{\renewcommand{\gostvkr@supervisor}{#1}}
\define@key{gostvkrsetup}{reviewer}{\renewcommand{\gostvkr@reviewer}{#1}}
\define@key{gostvkrsetup}{city}{\renewcommand{\gostvkr@city}{#1}}
\define@key{gostvkrsetup}{year}{\renewcommand{\gostvkr@year}{#1}}
\define@key{gostvkrsetup}{logopath}{\renewcommand{\gostvkr@logopath}{#1}}

% Публичный конфиг-интерфейс:
% \gostsetup{theme={...}, fullname={...}, city={...}, year={...}, ...}
\newcommand{\gostsetup}[1]{\setkeys{gostvkrsetup}{#1}}

\newcommand{\gostvkr@requiretitleasset}[1]{%
  \IfFileExists{#1}{}{%
    \gostvkr@fatal{Не найден файл логотипа титульного листа: #1}{Добавьте файл логотипа по указанному пути или измените ключ logopath в \string\gostsetup.}%
  }%
}
\newcommand{\gostvkr@titlebottomraise}{2mm}

% Вспомогательная команда для ненумеруемых разделов с добавлением в TOC.
\newcommand{\gostvkr@unnumberedchapter}[1]{%
  \chapter*{#1}
  \addcontentsline{toc}{chapter}{#1}
}

% Публичная команда: ненумеруемый крупный раздел уровня главы.
\NewDocumentCommand{\frontchapter}{m}{%
  \gostvkr@unnumberedchapter{#1}
}

% Публичные семантические обертки для структуры ВКР.
\NewDocumentCommand{\makeintroduction}{}{%
  \frontchapter{ВВЕДЕНИЕ}
}
\NewDocumentCommand{\makeconclusion}{}{%
  \frontchapter{ЗАКЛЮЧЕНИЕ}
}

% Публичная команда: титульный лист.
\NewDocumentCommand{\maketitlepage}{}{
  \gostvkr@requiretitleasset{\gostvkr@logopath}
  \begin{titlepage}
    \thispagestyle{empty}
    \begin{spacing}{1.0}
    \enlargethispage{\dimexpr\footskip+\gostvkr@titlebottomraise\relax}
    \vbox to \dimexpr\textheight+\footskip+\gostvkr@titlebottomraise\relax{%
      \begin{center}
        \gostvkr@ministry\par
        \vspace{0.5\baselineskip}
        \gostvkr@universitylineone\par
        \gostvkr@universitylinetwo\par
        \gostvkr@universitylinethree\par
        \vspace{0.5\baselineskip}
        \includegraphics[width=44mm]{\gostvkr@logopath}
      \end{center}

      \vspace{\baselineskip}

      \begin{center}
        Направление подготовки\par
        \gostvkr@direction\par
        \vspace{0.5\baselineskip}
        направленность (профиль)\par
        «\gostvkr@profile»\par
      \end{center}

      \vspace{\baselineskip}

      \begin{center}
        \fontsize{16pt}{16pt}\selectfont\textbf{\gostvkr@worktype}\par
        \vspace{\baselineskip}
        \gostvkr@theme
      \end{center}

      \vspace{1.5\baselineskip}

      \begin{flushright}
        \begin{minipage}{0.58\textwidth}
          \fontsize{12pt}{12pt}\selectfont
          Обучающегося \underline{\gostvkr@course}\ курса\par
          \underline{\gostvkr@studyform}\ формы обучения\par
          \gostvkr@fullname\par
          \vspace{\baselineskip}
          Руководитель выпускной квалификационной\par
          работы:\par
          \gostvkr@supervisor
          \ifgostvkr@showreviewer
            \ifstrempty{\gostvkr@reviewer}{}{%
              \par\vspace{\baselineskip}
              Рецензент:\par
              \gostvkr@reviewer
            }%
          \fi
        \end{minipage}
      \end{flushright}

      \vfill

      \begin{center}
        \fontsize{11pt}{11pt}\selectfont
        \gostvkr@city\par
        \gostvkr@year
      \end{center}%
    }
    \end{spacing}
  \end{titlepage}
  \setcounter{page}{2}
}

% Публичная команда: русскоязычный реферат (опционально).
\NewDocumentCommand{\makeabstractru}{m}{%
  \gostvkr@unnumberedchapter{РЕФЕРАТ}
  #1
}

% Публичная команда: англоязычный реферат (опционально).
\NewDocumentCommand{\makeabstracten}{m}{%
  \gostvkr@unnumberedchapter{ABSTRACT}
  \ifdefstring{\gostvkr@language}{ru-en}{%
    \begin{english}
      #1
    \end{english}
  }{%
    \ClassWarningNoLine{gostvkr-lua}{Команда \string\makeabstracten вызвана при language=ru. Текст печатается без переключения на английский язык.}%
    #1
  }%
}

% Публичная команда: список литературы с ГОСТ-профилем.
\NewDocumentCommand{\printgostbibliography}{}{%
  \gostvkr@unnumberedchapter{Список литературы}
  \printbibliography[heading=none]
}

% Публичные команды для блока приложений.
\newcommand{\gostvkr@appendixchaptertitle}[2]{%
  \phantomsection
  \addcontentsline{toc}{chapter}{Приложение #1. #2}
  \vspace{\baselineskip}
  \begin{center}
    \normalfont\bfseries\normalsize Приложение #1. #2
  \end{center}
  \vspace{0.75\baselineskip}
}

\NewDocumentCommand{\makeappendicesblock}{}{%
  \gostvkr@unnumberedchapter{ПРИЛОЖЕНИЯ}
}

\NewDocumentCommand{\appendixchapterfirst}{m m}{%
  \gostvkr@appendixchaptertitle{#1}{#2}
}

\NewDocumentCommand{\appendixchapternext}{m m}{%
  \clearpage
  \gostvkr@appendixchaptertitle{#1}{#2}
}

\newcommand{\gostreportmeta}{%
  Опция degree: \texttt{\gostvkr@degree};
  опция language: \texttt{\gostvkr@language};
  выбранный основной шрифт: \texttt{\gostvkr@mainfontselected};
  стиль библиографии: \texttt{\gostvkr@bibstyle}.
}

\endinput
