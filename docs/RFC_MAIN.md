# RFC: Lua/TSO — скриптовая платформа для z/OS

Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)

## 0. Статус

Черновик (v3). Лицензия: Apache-2.0.

---

## 1. Цель и область применения

### 1.1. Основная цель

Платформа Lua/TSO предназначена для замены “system REXX” как языка системной автоматизации на z/OS при условиях:

* запуск и отладка обязаны быть возможны **без интерактивного TSO**, только через **JCL**;
* нужен **ISPF без панелей**, но с доступом к сервисам;
* нужна интеграция с **AXR (System REXX)**.

### 1.2. Ограничения

* **OMVS/USS недоступен** → скрипты/модули/конфиги живут в **datasets (PS/PDS/PDSE)**, доступ через **DDNAME**.
* Нельзя опираться на OpenSSL из USS.

---

## 2. Модель выполнения

### 2.1. Запуск в batch через TMP (IKJEFT01)

Платформа Lua/TSO обязана поддерживать запуск в batch через TSO Terminal Monitor Program и подачу команд через `SYSTSIN`. ([IBM][1])

### 2.2. ISPF в batch через ISPSTART

Для использования ISPF services платформа обязана поддерживать “ISPF in batch”: `IKJEFT01` + аллокации ISPF datasets + `ISPSTART` для установления ISPF environment. ([IBM][2])

### 2.3. Foreground TSO

Если доступен, платформа может предоставлять TSO command processor `LUA`, но это не является обязательным.

---

## 3. Архитектура

### 3.1. Компоненты

1. **LUAEXEC (C Core, load module)**
   Lua VM + загрузчик + хост-API: `tso`, `ds`, `ispf`, `axr` (опц.), `tls`, `crypto` (опц.).

2. **Runtime libraries (Lua-модули в PDS/PDSE)**
   `tso.lua`, `ds.lua`, `ispf.lua`, `tls.lua`, `crypto.lua`, `rexxlike.lua`, утилиты (parse/stack/…).

3. **Policy/Config (datasets)**
   Белые списки команд, режимы кодировок, политика TLS/crypto, лимиты.

---

## 4. Загрузка скриптов и модулей без OMVS

### 4.1. Источники

Платформа обязана уметь читать основной скрипт:

* из PDS/PDSE member (`HLQ.LUA.APP(MYJOB)`), или
* из DDNAME (`LUAIN`).

### 4.1.1. Параметры `LUAEXEC`

`LUAEXEC` принимает параметры запуска и аргументы скрипта следующими путями:

1) **PARM=** (основной способ для batch).
   - Короткие флаги и аргументы, ограниченные длиной PARM.
2) **LUAIN DD** (основной скрипт по RFC 4.1).
3) **LUACFG DD** (опционально, файл настроек).
   - Формат: `key=value`, одна запись на строку.
   - Примеры ключей: `encoding`, `luapath`, `loglevel`.
4) **DSN=...** (явный путь к скрипту в PARM).

Правила:
* Если указан `DSN=...`, он имеет приоритет над `LUAIN`.
* Аргументы после `--` передаются в Lua‑скрипт без обработки.
* Ошибки параметров должны быть LUZ‑кодированы.

### 4.2. `require`

`require` обязан искать модули в конкатенации `LUAPATH` (PDS/PDSE) в заданном порядке.

---

## 5. ISPF без панелей

### 5.1. Требование

Платформа обязана обеспечивать ISPF services без панелей (без `DISPLAY PANEL(...)`/TBDISPL), включая:

* variable pool: `VDEFINE/VGET/VPUT/VRESET/...`
* LM-сервисы: `LMINIT/LMOPEN/LMGET/LMFREE/...`
* таблицы: `TBCREATE/TBOPEN/TBADD/TBGET/TBPUT/TBCLOSE/...`
* file tailoring: `FTOPEN/FTINCL/FTCLOSE/...`
* `LIBDEF`.

### 5.2. Интерфейс

Платформа обязана предоставить:

* `ispf.exec(cmdline)` — общий вызов ISPF командой (строка формата ISPEXEC),
* `ispf.qry()` — проверка, поднята ли ISPF-среда.

(Запуск ISPF в batch — см. раздел 2.2.) ([IBM][2])

---

## 6. AXR (System REXX) интеграция

### 6.1. Режим A (обязательный): AXR → Lua через REXX-шлюз

Платформа обязана поддержать схему “AXR запускает Lua” через один стабильный REXX exec-шлюз (например `LUAXR`) в REXXLIB:

* вход: имя Lua-скрипта (DSN(member)) + args,
* действие: запуск `LUAEXEC` load module,
* выход: RC обратно в AXR.

Операторное управление AXR (запуск/статус/отмена) выполняется штатными средствами System REXX.

### 6.2. Режим B (опциональный): Lua → AXR через AXREXX

Если нужно программно запускать/отменять exec’и или читать REXXLIB, платформа может включать `axr.*`, реализованный через сервис **AXREXX** (`REQUEST=EXECUTE|CANCEL|GETREXXLIB`). ([IBM][3])

---

## 7. Host API (минимальная спецификация)

### 7.1. `tso`

Обязано:

* `tso.cmd(cmd) -> rc, lines[]`
* `tso.alloc(spec) -> rc`, `tso.free(spec) -> rc`
* `tso.msg(text, level?)`
* `tso.exit(rc)`

### 7.2. `ds`

Обязано:

* `ds.open_dd(ddname, {mode="r|w|a"}) -> handle`
* `handle:readline()` / `handle:lines()` / `handle:writeline()` / `handle:close()`

### 7.3. `ispf`

Обязано:

* `ispf.qry()`
* `ispf.exec(cmdline)`
* `ispf.vget(names, opts)`, `ispf.vput(map, opts)`
* базовые обёртки для LM/TB/FT.

### 7.4. `tls` (обязательный модуль при требованиях TLS)

Обязано:

* `tls.connect{host,port,profile=...} -> conn`
* `conn:read(n)` / `conn:write(buf)` / `conn:close()`
* `conn:peer_cert()` (минимум: subject/issuer/serial/алгоритмы, в виде структуры/строк)

Желательно:

* серверный режим (`tls.listen/accept`) — если нужны входящие TLS-соединения.

---

## 8. Кодировки (EBCDIC)

Платформа обязана корректно обрабатывать EBCDIC при чтении/выводе (конверсия источников скриптов и вывода сообщений задаётся конфигом).

---

## 9. TLS/SSL и криптография без OpenSSL/USS (System SSL — основной путь)

### 9.1. Основной путь: z/OS System SSL (GSK APIs) внутри C Core

TLS в Lua/TSO должен реализовываться через **z/OS System SSL** как основной механизм (а не через OpenSSL). System SSL является компонентом z/OS Cryptographic Services и включает наборы API и утилиты/сервисы управления сертификатами. ([IBM][4])

Практические требования:

* `tls.*` реализуется в C Core через GSK API (инициализация, настройка атрибутов, handshake, чтение/запись).
* Хранилище ключей/сертификатов: предпочтительно **SAF key ring** или **z/OS PKCS #11 token** (это не требует USS-файлов). При сборке приложения имя key database / PKCS#12 / PKCS#11 token / SAF key ring должно соответствовать `GSK_KEYRING_FILE`, заданному через `gsk_attribute_set_buffer()`. ([IBM][5])
* Если нужна “openssl-подобная” обработка сертификатов/контейнеров, платформа может задействовать **CMS (Certificate Management Services) API** System SSL (в документации System SSL отдельно выделяется CMS API reference). ([IBM][6])

### 9.2. AT-TLS (дополнительный/альтернативный режим развёртывания)

Платформа должна допускать развёртывание, где TLS обеспечивается **Application Transparent TLS (AT-TLS)** на уровне TCP/IP стека через Policy Agent (PAGENT), а приложение работает поверх обычных сокетов. PAGENT действует внутри стека и выбирает политику по правилам. ([IBM][7])
AT-TLS зависит от “currency” System SSL (например, в некоторых сценариях требуется GSKSRVR). ([IBM][8])

Роль AT-TLS в данном RFC: облегчить внедрение TLS без изменения прикладной логики, но **не заменять** System SSL как базовую TLS-реализацию в продукте.

### 9.3. Криптопримитивы и “прочие openssl-штуки”

Для хэшей/HMAC/подписей/PKCS#11 платформа желательно использует **ICSF** (z/OS Integrated Cryptographic Service Facility), который работает с аппаратной криптографией и RACF и предоставляет API для криптосервисов. ([IBM][9])

---

## 10. Тестирование и наблюдаемость (JCL-only)

### 10.1. Harness

Платформа обязана поставляться с тест-раннером, который возвращает RC≠0 при провале и пишет результаты в SYSOUT/datasets.

### 10.2. Покрытие C Core

Если нужно покрытие для C без USS, рекомендуется использовать **z/OS Debugger Code Coverage**, который поддерживает unattended запуск в batch и выдачу данных/отчётов (в т.ч. через XML). ([IBM][10])

---

## 11. Безопасность и политика

### 11.1. Policy

Платформа обязана иметь конфиг-policy (dataset), задающий:

* whitelist/blacklist для `tso.cmd`,
* включение/отключение `axr`, `crypto`, уровни трассировки,
* лимиты вывода/ресурсов.

---

## 12. Пакетирование: datasets и DDNAME (рекомендуемый профиль)

* `HLQ.LUA.LOAD` — load modules (`LUAEXEC`, …)
* `HLQ.LUA.LIB` — runtime Lua modules
* `HLQ.LUA.APP` — прикладные скрипты
* `HLQ.LUA.TEST` — тесты/эталоны
* `HLQ.LUA.CONF` — конфиги/policy

DDNAME:

* `STEPLIB` → `HLQ.LUA.LOAD`
* `LUAPATH` → concat (`HLQ.LUA.CONF`, `HLQ.LUA.LIB`, `HLQ.LUA.APP`, …)
* `LUACONF` → конфиг/policy member
* (опц.) `LUAIN`, `LUAOUT`

---

## 13. MVP

MVP обязан включать:

1. запуск в batch через IKJEFT01/SYSTSIN ([IBM][1])
2. `tso.cmd` с захватом вывода
3. `ds.open_dd` потоковое чтение/запись
4. `require` из `LUAPATH`
5. ISPF без панелей: `ispf.qry`, `ispf.exec`, `ispf.vget/vput` + минимум LM (через ISPF in batch) ([IBM][2])
6. AXR режим A: REXX-шлюз `LUAXR`
7. TLS: `tls.connect/read/write/close` на базе **System SSL** + поддержка SAF key ring / PKCS#11 token ([IBM][4])

---

## 14. Критерий “заменили system REXX”

Достигнуто, когда:

* типовые сценарии system REXX (ALLOC/чтение/запись datasets/перехват вывода/ISPF services без панелей) реализуются на Lua/TSO в JCL-only режиме;
* AXR продолжает быть точкой входа (через единый `LUAXR`);
* TLS обеспечивается через System SSL как штатный механизм, без зависимости от OpenSSL/USS. ([IBM][4])

[1]: https://www.ibm.com/docs/en/zos/3.1.0?topic=environment-sample-batch-job&utm_source=chatgpt.com "Sample batch job"
[2]: https://www.ibm.com/support/pages/how-use-ispf-batch?utm_source=chatgpt.com "How to use ISPF in batch"
[3]: https://www.ibm.com/docs/en/zos/2.5.0?topic=dyn-axrexx-system-rexx-services&utm_source=chatgpt.com "AXREXX - System REXX services"
[4]: https://www.ibm.com/docs/en/SSLTBW_3.1.0/pdf/gska100_v3r1.pdf?utm_source=chatgpt.com "z/OS System SSL Programming"
[5]: https://www.ibm.com/docs/en/zos/2.5.0?topic=application-building-zos-system-ssl&utm_source=chatgpt.com "Building a z/OS System SSL application"
[6]: https://www.ibm.com/docs/SSLTBW_3.2.0/pdf/gska100_v3r2.pdf?utm_source=chatgpt.com "z/OS System SSL Programming"
[7]: https://www.ibm.com/docs/en/zos/2.5.0?topic=enabler-tls-usage-overview&utm_source=chatgpt.com "AT-TLS usage overview"
[8]: https://www.ibm.com/docs/en/zos/3.1.0?topic=security-tls-currency-system-ssl&utm_source=chatgpt.com "Using AT-TLS currency with System SSL"
[9]: https://www.ibm.com/docs/en/zos/3.1.0?topic=services-zos-cryptographic-icsf-overview&utm_source=chatgpt.com "Abstract for z/OS Integrated Cryptographic Service Facility ..."
[10]: https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=coverage-introduction-zos-debugger-code&utm_source=chatgpt.com "Introduction to z/OS Debugger Code Coverage"
