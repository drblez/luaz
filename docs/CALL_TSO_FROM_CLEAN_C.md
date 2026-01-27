# Вызов TSO из чистого C (без ASM/USS/REXX)

## Цель

Зафиксировать минимальный и воспроизводимый способ вызова TSO‑команды из C‑программы под z/OS,
используя только системные TSO/E сервисы (IKJTSOEV + IKJEFTSR) и JCL‑аллоцированные DDNAME.

Ограничения:
- без кода на ассемблере;
- без вызовов USS;
- без вызовов REXX;
- вывод команд получать через DDNAME SYSTSPRT.

## Ключевые условия

1) Выполнять под TMP (IKJEFT01), иначе вывод команд не гарантирован.
2) SYSTSIN и SYSTSPRT должны быть аллоцированы в JCL до вызова IKJTSOEV.
3) IKJTSOEV может вернуть RC=24 при запуске под TMP (TSO/E уже инициализировано) — это не ошибка.
4) IKJEFTSR использует SYSTSPRT для текстового вывода, поэтому SYSTSPRT должен быть
   направлен в dataset (PDS/PDSE member), который можно открыть из C.

## Порядок вызова (коротко)

1) В JCL определить SYSTSIN и SYSTSPRT:
   - SYSTSIN — in-stream DD (обычно с CALL).
   - SYSTSPRT — dataset member (например, DRBLEZ.LUA.CTL(TIMEOUT@)).
2) В C вызвать IKJTSOEV.
3) Вызвать IKJEFTSR с флагами 0x00010001 (команда, unisolated).
4) Открыть SYSTSPRT как DDNAME через fopen("//dd:SYSTSPRT","r") и прочитать вывод.

## Пример кода

Файл: `src/tso_c_example.c`
- Чистый C.
- Использует только IKJTSOEV и IKJEFTSR.
- Читает вывод из DDNAME SYSTSPRT.
- Принимает RC=24 от IKJTSOEV как норму для TMP.

## Пример JCL

Файл: `jcl/TSOCEX.jcl`
Основные моменты:
- Компиляция/линковка стандартными PROC/IEWL.
- RUN через IKJEFT01.
- SYSTSPRT направлен в DRBLEZ.LUA.CTL(TIMEOUT@).
- Печать содержимого TIMEOUT@ в спул через IEBGENER (SYSUT2).

## Пример вывода

Из спула SYSUT2 шага PRTTIME:
- строка TIME с текущим временем, например:
  TIME-07:58:03 AM. CPU-00:00:00 SERVICE-20475 SESSION-00:00:01 JANUARY 26,2026

## Обработка кодов возврата

- IKJTSOEV:
  - RC=0 — успешно, CPPL доступен.
  - RC=8 — TSO/E доступно, но REXX окружение не поднялось (не критично для чистого C).
  - RC=24 — запуск из TMP/Service Routines environment; это ожидаемо в batch (IKJEFT01).
- IKJEFTSR:
  - RC=0 — команда выполнена.
  - Иные RC — считать ошибкой и печатать rc/rsn/abend.

## Ссылки на исходники в репозитории

- `src/tso_c_example.c`
- `jcl/TSOCEX.jcl`
- `src/tso_c_example.c.md` (IBM references)

## IBM документация (ссылки)

- IKJTSOEV syntax/parameters:
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjtsoev-syntax-parameter-descriptions
- IKJTSOEV return/reason codes:
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjtsoev-return-reason-codes-from-tsoe-environment-service
- IKJTSOEV environment initialization:
  https://www.ibm.com/docs/en/zos/2.4.0?topic=service-tsoe-environment-initialization-inside-ikjtsoev
- IKJEFTSR parameter list:
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-parameter-list
- DDNAME and dataset I/O in C:
  https://www.ibm.com/docs/en/SSLTBW_2.4.0/com.ibm.zos.v2r4.cbcpx01/mvsddn.htm
  https://www.ibm.com/docs/en/SSLTBW_2.4.0/com.ibm.zos.v2r4.cbcpx01/cbc1p259.htm
  https://www.ibm.com/docs/en/SSLTBW_2.4.0/com.ibm.zos.v2r4.cbcpx01/cbc1p210.htm
