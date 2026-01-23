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

- В R1 передаётся **parameter list**, содержащий **адреса аргументов**.
- Для аргумента-указателя требуется **двойное разыменование**:
  сначала адрес ячейки, затем значение указателя.
- Не полагайтесь на VL-bit у последнего аргумента.
  Для переменного числа параметров передавайте `count` явно.

5) Возврат и RC/ошибки

- Возвратный код задаётся через `CEETERM`, который кладёт RC в **R15**.
- Для ошибочных ситуаций возвращайте определённые RC
  и документируйте их в контракте.

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

## Контрольный список

- [ ] HLASM использует `CEEENTRY`/`CEETERM` и соответствует LE-конвенциям.
- [ ] `MAIN=NO` для подпрограммы, вызываемой из C(LE).
- [ ] C entrypoint объявлен как OS linkage (`#pragma linkage` / `extern "OS"`).
- [ ] Translation unit для OS linkage собран с **NOXPLINK**.
- [ ] Разыменование параметров соответствует OS linkage (двойное для указателей).
- [ ] RC/ошибки возвращаются через `CEETERM` и задокументированы.
- [ ] 64-битные значения идут через out-parameter.
- [ ] AMODE/RMODE и линковка соответствуют non-XPLINK.
- [ ] Вызовы C из HLASM передают plist корректно (адреса клеток аргументов).

## Источники

- https://www.ibm.com/docs/en/zos/3.1.0?topic=macros-ceeentry-macro-generate-language-environment-conforming-prolog
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
