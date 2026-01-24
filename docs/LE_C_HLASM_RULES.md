# Правила C(LE) ↔ HLASM для non-XPLINK (OS linkage / up-stack)
#
# Copyright (c) 2026
#
# Objects
# - rules: Набор обязательных правил для сопряжения C(LE) и HLASM в non-XPLINK.
# - checklist: Контрольный список для ревью и приёмки.

## Область применения

Документ описывает правила для связки **C(LE) ↔ HLASM** в режиме
**non-XPLINK (OS linkage / up-stack)**, когда ассемблерная подпрограмма
входит в LE-enclave и вызывается из C/COBOL/PL/I под LE.

Если используется XPLINK или смешанная модель, требуется отдельный мост
(OS_UPSTACK/OS_DOWNSTACK/OS_NOSTACK и ILC) и эти правила применимы
только частично.

## Правила

1) LE-conforming ассемблер

- Ассемблерный модуль обязан быть LE-conforming.
- Используйте `CEEENTRY` для пролога и `CEETERM` для эпилога/возврата.
- Подключайте `CEEPPA` и маппинги `CEECAA`/`CEEDSA` по требованиям `CEEENTRY`.
- Для подпрограммы в активном enclave указывайте `MAIN=NO`.
- Имя entrypoint для `CEEENTRY` задавайте в **label-поле** (это обязательное имя entry). Не задавайте имя в операнде `CEEENTRY` — это приводит к `TEMPNAME` и MNOTE. 
- При наличии **нескольких `CEEENTRY` в одном ассемблерном модуле** обязательно выполняйте `DROP` базовых регистров/USING, установленных предыдущим `CEEENTRY`, прежде чем начать следующий.

2) Соглашения по регистрам (non-XPLINK, LE-conforming)

- На входе **R1** указывает на список параметров (или 0).
- **R13** содержит DSA/save area.
- **R12** на call-points содержит CAA (за исключением оговорённых LE-ситуаций).
- Сохраняйте/восстанавливайте регистры строго по LE-конвенциям.

3) Сторона C (XL C/C++)

- Объявляйте OS linkage для entrypoint:
  - C: `#pragma linkage(name, OS)`
  - C++: `extern "OS" { ... }`
- Если имя entrypoint в асме отличается — фиксируйте это на C-стороне
  (например, через `#pragma map`).
- Translation unit с entrypoint OS linkage должен компилироваться
  **NOXPLINK**, иначе ABI будет несовместим.

4) Передача параметров (OS linkage)

- В R1 передаётся **parameter list** (plist).
- Для **by-value** аргументов (например, `int`, `long long`) plist содержит
  **адрес ячейки с значением**, поэтому требуется **двойное разыменование**:
  сначала адрес ячейки, затем значение.
- Для **pointer** аргументов (`char *`, `struct *`) в реальной связке XL C
  **NOXPLINK** (подтверждено UT_C2A) plist содержит **само значение указателя**,
  поэтому после снятия HOB можно **использовать адрес сразу**
  (без дополнительного разыменования).
- Не полагайтесь на VL-bit у последнего аргумента.
  Для переменного числа параметров передавайте `count` явно.

5) Возврат и RC/ошибки

- Возвратный код задаётся через `CEETERM`, который кладёт RC в **R15**.
- Для ошибочных ситуаций возвращайте определённые RC
  и документируйте их в контракте.
- `CEETERM` принимает RC как константу/переменную/регистр 2–12; для исключения проблем с literal pool используйте форму `RC=(R2)` и заранее загрузите RC в регистр.

6) 64-битные значения

- Для `long long` и других 64-битных данных предпочтителен **out-parameter**.
- При работе в AMODE 31 избегайте 64-битных загрузок/сохранений,
  если нет гарантированного 8-байтного выравнивания.
- Учитывайте **big-endian** порядок байт на z/Architecture.

7) Режимы адресации и линковка

- Для LE-conforming non-XPLINK обычно используйте **AMODE 31 / RMODE ANY**.
- Не смешивайте XPLINK и non-XPLINK без явного мостика ILC.

8) Вызовы C из HLASM (LE, non-XPLINK)

- Вызываемая C-функция обязана быть объявлена как **OS linkage** и
  скомпилирована **NOXPLINK**.
- В LE-conforming HLASM **R1 указывает на parameter list**;
  допустимо вызывать C с тем же plist без его перестройки.
- Если нужна другая сигнатура или константы — создавайте свои клетки
  аргументов и новый plist; в plist кладутся **адреса клеток аргументов**.
- Для аргумента-указателя в plist кладётся **адрес клетки**, где хранится
  значение указателя (двойное разыменование).
- RC возвращается в **R15** по правилам MVS linkage; передавайте RC через `CEETERM`.

9) Вызов C без `CALL` макроса

- Если `CALL` не используется, то схема та же: **R1 → plist**, затем
  `L R15,=V(name)` и `BALR 14,15`.
- Не используйте `CALL ...,VL` для фиксированной C-сигнатуры.

10) База адресации и literal pool (практика UT_C2A)

- После `CEEENTRY` **не используйте `USING *,11`**, если затем есть обращения
  к литералам вида `=X'...'` — это может рассинхронизировать базу и привести
  к обращению к неверной памяти.
- Используйте **`USING <entry_label>,11`**, где `<entry_label>` — имя entrypoint.
- Для снятия HOB с адреса используйте **иммедиатное** `NILF` вместо литералов:
  `NILF rX,X'7FFFFFFF'` (это исключает зависимость от literal pool).

11) AMODE/RMODE при несовпадении CSECT и entrypoint

- Если имя CSECT отличается от имени entrypoint, обязательно задавайте
  `AMODE`/`RMODE` **на имя CSECT** (иначе в ESD может остаться `RMODE(24)`
  и binder даст `IEW2646W` при `MODE RMODE(ANY)`).

## Практика отладки в batch (JCL/FTP)

Эффективная отладка без интерактивного TSO/ISPF строится на двух принципах:
1) максимум информации из дампов и листингов,  
2) короткий цикл "собрал -> запустил -> забрал спул -> сопоставил offset".

### 1) Ускорение цикла: submit + автоматический сбор спула

- Всегда используйте FTP JES mode и скрипты для скачивания спулов.
- Разведите JCL по целям:
  - быстрый RUN (только запуск готового load module),
  - полный rebuild (CC/ASM/LKED/RUN),
  - диагностический RUN (максимальные runopts и дампы).

### 2) Обязательные DD для дампов

Минимальный набор в RUN step:

```jcl
//RUN     EXEC PGM=A2CTEST,REGION=0M
//CEEDUMP DD SYSOUT=*
//SYSMDUMP DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//CEEOPTS DD *
  RPTOPTS(ON),
  RPTSTG(ON),
  TRAP(ON,SPIE),
  TERMTHDACT(UADUMP),
  ABTERMENC(ABEND)
/*
```

Что это дает:
- `CEEDUMP` почти всегда содержит traceback и регистры LE.
- `SYSMDUMP` помогает, когда `CEEDUMP` не успевает сформироваться.

### 3) Привязка offset к исходнику

Порядок действий:
1. В дампе найдите `ACTIVE MODULE NAME=... OFFSET=...`.
2. В binder MAP/LIST найдите CSECT и его смещения.
3. По offset найдите инструкцию в HLASM листинге.
4. Сверьте PSW и GPR (R1 plist, R13 save area, R12 CAA).

Для этого:
- В binder включайте `MAP,LIST,XREF`.
- В ASMA90 и компиляторе C всегда делайте LIST.

### 4) "Трассировка без дебаггера"

ASM:
- `WTO` метки "дошел сюда" и печать ключевых регистров.
- Логируйте R1/R13/R12 на входе и перед каждым `BALR` в C.
- Делайте защитные проверки: `LTR rx,rx / BZ fail`, снятие HOB,
  проверка выравнивания перед разыменованием.

C:
- `fprintf(stderr, ...)` (обычно уходит в SYSOUT в batch).
- Проверяйте входные указатели и возвращайте RC != 0 с диагностикой.

### 5) "Debug build" как стандарт

C (LE, non-XPLINK):
- включайте listing и карты смещений,
- используйте binder MAP/XREF,
- на RUN включайте `RPTOPTS/RPTSTG/TRAP`.

HLASM:
- `ASMA90 PARM='OBJECT,LIST,XREF'`,
- держите `LTORG` в досягаемости,
- не используйте `USING *,11` без синхронизации баз.

### 6) Если есть продукты отладки

Используйте, если доступны:
- IBM Fault Analyzer,
- Abend-AID,
- IBM Debug Tool (batch режим).

Обычно достаточно корректных DD в RUN step, чтобы получить подробный отчет.

### 7) Минимальный стандарт для каждого UT

1. RUN всегда содержит `CEEDUMP` и `CEEOPTS` (TRAP/RPT*).
2. LKED всегда печатает MAP/XREF.
3. ASM/C всегда имеют listing/offset.
4. В ASM перед вызовами C логируйте plist и значения ячеек.
5. FTP submit+fetch обязателен для короткого цикла.

## Контрольный список

- [ ] HLASM использует `CEEENTRY`/`CEETERM` и соответствует LE-конвенциям.
- [ ] `MAIN=NO` для подпрограммы, вызываемой из C(LE).
- [ ] Имя entrypoint задано в label-поле `CEEENTRY` (нет `TEMPNAME`).
- [ ] При нескольких `CEEENTRY` выполнены `DROP` всех баз предыдущего entry.
- [ ] C entrypoint объявлен как OS linkage (`#pragma linkage` / `extern "OS"`).
- [ ] Translation unit для OS linkage собран с **NOXPLINK**.
- [ ] Разыменование параметров соответствует OS linkage (двойное для by-value,
      одиночное для pointer-аргументов, подтверждено UT_C2A).
- [ ] RC/ошибки возвращаются через `CEETERM` и задокументированы.
- [ ] 64-битные значения идут через out-parameter.
- [ ] AMODE/RMODE и линковка соответствуют non-XPLINK.
- [ ] Вызовы C из HLASM передают plist корректно (адреса клеток аргументов).
- [ ] `USING <entry_label>,11` применяется до любых ссылок на literal pool.
- [ ] HOB снимается через `NILF`, а не через литералы.

## Практически подтверждённые результаты (UT_C2A, 2026-01-23)

### Результат прогона

```
LUZ40100 UTC2A start
LUZ40101 UTC2A add2 ok
LUZ40102 UTC2A strlen ok
LUZ40103 UTC2A sum ok
LUZ40104 UTC2A add64 ok
LUZ40109 UTC2A success
```

### Итоги по формату plist (наблюдение на XL C NOXPLINK)

- `int a, int b`: plist содержит **адреса ячеек**, требуется двойное разыменование.
- `const char *s`, `struct *p`: plist содержит **значение указателя**,
  достаточно одинарного разыменования после снятия HOB.
- `long long a, b`: plist содержит **адреса 8-байтных ячеек** (hi/lo),
  двойное разыменование (через адрес ячейки) требуется.
- `long long *out`: plist содержит **значение указателя** (single deref),
  без промежуточной ячейки.

### Ошибка 0C4 и исправление

Симптом: защита 0C4 при `L rY,0(rX)` сразу после `N rX,=X'7FFFFFFF'`.

Причина: обращение к литералу `=X'7FFFFFFF'` шло с неправильной базой
(`USING *,11` был рассинхронизирован с реальным значением R11 после `CEEENTRY`).

Исправление:

- `USING <entry_label>,11` вместо `USING *,11`.
- `NILF rX,X'7FFFFFFF'` вместо `N rX,=X'7FFFFFFF'`.

### Проверенные шаблоны (фрагменты)

#### C2AADD2 (by-value int)

```asm
C2AADD2S CSECT
C2AADD2S AMODE 31
C2AADD2S RMODE ANY
ADD2PPA  CEEPPA EPNAME=C2AADD2
C2AADD2  CEEENTRY PPA=ADD2PPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
         USING C2AADD2,11
         USING CEECAA,12
         USING CEEDSA,13
         L     3,0(,1)            * plist[0] -> &a
         NILF  3,X'7FFFFFFF'
         L     4,0(3)             * a
         L     3,4(,1)            * plist[1] -> &b
         NILF  3,X'7FFFFFFF'
         L     5,0(3)             * b
         AR    4,5
         LR    2,4
         CEETERM RC=(2)
```

#### C2ASTRL (pointer argument)

```asm
C2ASTRLS CSECT
C2ASTRLS AMODE 31
C2ASTRLS RMODE ANY
STRLPPA  CEEPPA EPNAME=C2ASTRL
C2ASTRL  CEEENTRY PPA=STRLPPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
         USING C2ASTRL,11
         USING CEECAA,12
         USING CEEDSA,13
         L     3,0(,1)            * plist[0] -> s (pointer value)
         NILF  3,X'7FFFFFFF'
         SR    2,2
STRLLOOP CLI   0(3),X'00'
         BE    STRLDONE
         LA    3,1(3)
         LA    2,1(2)
         B     STRLLOOP
STRLDONE CEETERM RC=(2)
```

#### C2ASUM (pointer to struct)

```asm
C2ASUMS  CSECT
C2ASUMS  AMODE 31
C2ASUMS  RMODE ANY
SUMPPA   CEEPPA EPNAME=C2ASUM
C2ASUM   CEEENTRY PPA=SUMPPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),     X
               AMODE=31,RMODE=ANY
         USING C2ASUM,11
         USING CEECAA,12
         USING CEEDSA,13
         L     3,0(,1)            * plist[0] -> p (pointer value)
         NILF  3,X'7FFFFFFF'
         L     4,0(3)
         L     5,4(3)
         AR    4,5
         ST    4,8(3)
         SR    2,2
         CEETERM RC=(2)
```

#### C2AADD64 (long long через out-parameter)

```asm
C2A64S   CSECT
C2A64S   AMODE 31
C2A64S   RMODE ANY
ADD64PPA CEEPPA EPNAME=C2AADD64
C2AADD64 CEEENTRY PPA=ADD64PPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),   X
               AMODE=31,RMODE=ANY
         USING C2AADD64,11
         USING CEECAA,12
         USING CEEDSA,13
         L     3,0(,1)            * plist[0] -> &a (8 bytes)
         NILF  3,X'7FFFFFFF'
         L     4,0(3)             * a_hi
         L     5,4(3)             * a_lo
         L     3,4(,1)            * plist[1] -> &b
         NILF  3,X'7FFFFFFF'
         L     6,0(3)             * b_hi
         L     7,4(3)             * b_lo
         LR    8,5
         ALR   8,7
         SR    9,9
         CLR   8,5
         BNL   ADD64NC
         LHI   9,1
ADD64NC  DS    0H
         LR    10,4
         ALR   10,6
         ALR   10,9
         L     3,8(,1)            * plist[2] -> out (pointer value)
         NILF  3,X'7FFFFFFF'
         LTR   3,3
         BZ    ADD64ERR
         ST    10,0(3)
         ST    8,4(3)
         SR    2,2
         CEETERM RC=(2)
ADD64ERR LHI   2,8
         CEETERM RC=(2)
```

## Практически подтверждённые результаты (UT_A2C, 2026-01-23)

### Результат прогона

```
LUZ40110 UTA2C start
LUZ40111 UTA2C cscale ok
LUZ40112 UTA2C cstrlen ok
LUZ40113 UTA2C cadd64 ok
LUZ40119 UTA2C success
```

### Итоги по формату plist (наблюдение на XL C NOXPLINK)

- `int a, int b`: plist содержит **адреса ячеек** с значениями.
- `int *out`: plist содержит **значение указателя** (адрес OUT1), без "ячейки указателя".
- `const char *s`: plist содержит **значение указателя** (адрес STR1), без дополнительного разыменования.
- `long long *out`: plist содержит **значение указателя** (адрес OUT64).

### Ключевая ошибка и исправление (ASM->C)

Симптом: `cscale value mismatch`, при этом C пишет корректно `*out=63`.

Причина: plist передавал **адрес ячейки указателя**, а не сам адрес буфера.
В результате C писал в ячейку, а ASM проверял другое место.

Исправление:
- Для pointer-аргументов в plist передавать **значение указателя напрямую**.
- Не использовать "pointer cell" для `T *p`, если C ожидает OS linkage.

### Пример: правильный plist для ASM->C

#### C-сторона (OS linkage)

```c
#pragma map(a2c_scale, "A2CSCAL")
#pragma linkage(a2c_scale, OS)
int a2c_scale(int a, int b, int *out);
```

#### HLASM-сторона (plist)

```asm
* a, b по значению: plist содержит адреса ячеек A1/B1.
* out - указатель: plist содержит значение указателя (адрес OUT1).
A1       DC    F'7'
B1       DC    F'9'
OUT1     DC    F'0'
PLIST1   DC    A(A1),A(B1),A(OUT1)

         LA    1,PLIST1
         L     15,=V(A2CSCAL)
         ST    11,SAV11
         BALR  14,15
         L     11,SAV11
```

### Пример: строка (pointer аргумент)

```asm
STR1     DC    C'HELLO',X'00'
PLIST2   DC    A(STR1)
```

### Пример: long long через out-parameter

```asm
         DS    0D
A64      DC    F'0',F'16'
B64      DC    F'0',F'32'
OUT64    DC    F'0',F'0'
PLIST3   DC    A(A64),A(B64),A(OUT64)
```

### Важное для ASM->C вызовов

- **Сохраняйте базовый регистр** (например, R11) вокруг `BALR` в C.
  C может его перезаписать, что приводит к неверной адресации данных.
- `MAIN=NO` для ASM-подпрограммы; LE инициализируется C main.

## Привязка к тестам и артефактам (UT_C2A и UT_A2C)

### UT_C2A (C -> ASM)

Цель: подтвердить корректность OS linkage для вызовов ASM из C.

- C main: `src/c2a_test.c` (entry `C2ATEST`).
- ASM routines: `src/c2a_asm.asm` (`C2AADD2`, `C2ASTRL`, `C2ASUM`, `C2AADD64`).
- JCL: `jcl/UT_C2A.jcl`.
- Link-edit: `ENTRY CEESTART`, `INCLUDE OBJLIB(C2ATEST)` + `OBJLIB(C2AASM)`.
- Компиляция C: `NOXPLINK`, `#pragma linkage(..., OS)`, `#pragma map`.
- ASM: `CEEENTRY MAIN=NO`, `PLIST=OS`, `PARMREG=1`.

Практика:
- **Не делайте LOAD/BALR на HLL main** под LE. Main должен входить через `CEESTART`.
- В ASM для `by-value` используйте двойное разыменование.
- Для pointer-аргументов в plist хранится **значение указателя** (single deref после снятия HOB).

### UT_A2C (ASM -> C)

Цель: подтвердить корректность OS linkage при вызовах C из ASM.

- C main: `src/a2c_driver.c` (entry `A2CDRVR`), вызывает ASM entry `A2CTEST`.
- ASM entry: `src/a2c_test.asm` (`A2CTEST`).
- C callees: `src/a2c_call.c` (`A2CSCAL`, `A2CSTRL`, `A2CADD64`).
- JCL: `jcl/UT_A2C.jcl`.
- Link-edit: `ENTRY CEESTART`, `INCLUDE OBJLIB(A2CTEST)` + `OBJLIB(A2CCALL)` + `OBJLIB(A2CDRVR)`.
- CEEINT не используется: LE инициализируется через C main.

Практика:
- Для `T *out` и `const char *s` **в plist должен быть сам адрес** (A(OUT1), A(STR1)),
  а не адрес "ячейки указателя".
- Сохраняйте базовый регистр (R11) вокруг `BALR` в C, иначе последующая адресация
  в ASM может использовать неверную базу.
- Тексты `LUZ40164/40165` в `src/a2c_call.c` полезны для диагностики plist,
  их можно временно включать/удалять по необходимости.

### Общие правила для обоих UT

- Запускать RUN step только если CC/ASM/LKED завершились с RC=0.
- Для отладки использовать короткие диагностические сообщения (`WTO`/`fprintf`)
  и проверку ключевых регистров/значений до и после `BALR`.

## Источники

- https://www.ibm.com/docs/en/zos/3.1.0?topic=macros-ceeentry-macro-generate-language-environment-conforming-prolog
- https://www.ibm.com/docs/en/zos/2.5.0?topic=macros-ceeterm-macro-terminate-language-environment-conforming-routine
- https://www.ibm.com/docs/en/zos/3.1.0?topic=considerations-assembler-macros
- https://www.ibm.com/docs/en/zos/2.5.0?topic=conventions-language-environment-conforming-assembler
- https://www.ibm.com/docs/en/zos/2.5.0?topic=programs-specifying-linkage-c-c-assembler
- https://www.ibm.com/docs/en/cics-ts/6.x?topic=applications-language-environment-coding-requirements-assembler-language&utm_source=chatgpt.com
- https://www.ibm.com/docs/en/zos/3.1.0?topic=section-call-description
- https://www.ibm.com/docs/en/zos/2.5.0?topic=applications-ilc-between-xplink-assembler&utm_source=chatgpt.com
- https://www.ibm.com/docs/en/SSLTBW_3.1.0/pdf/cbcpx01_v3r1.pdf
- https://www.ibm.com/docs/en/SSLTBW_2.5.0/pdf/ceea400_v2r5.pdf
- https://www.ibm.com/docs/en/zvm/7.3.0?topic=domains-network-byte-order-host-byte-order&utm_source=chatgpt.com
- https://colinpaice.blog/2022/07/01/using-assembler-services-from-a-64-bit-c-program/?utm_source=chatgpt.com
