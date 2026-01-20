# Lua/TSO

## English

Lua/TSO is a scripting platform for z/OS aimed at replacing system REXX for automation. It provides a Lua VM with host APIs for TSO/ISPF/datasets/AXR and TLS via System SSL, designed to work with datasets and core z/OS services.

### Goals

- Provide a modern scripting runtime for z/OS automation.
- Integrate with core services: TSO, ISPF (without panels), datasets, AXR.
- Run TSO commands under TMP (IKJEFT01) to guarantee command output to SYSTSPRT.
- Support secure connectivity via z/OS System SSL.

### Status

Draft (v3). This repository currently contains the RFC and project scaffolding.

### Documentation

- RFC (English): docs/RFC_MAIN_EN.md
- RFC (Russian): docs/RFC_MAIN.md

### License

Apache-2.0. See LICENSE and NOTICE.

### Contributing

See CONTRIBUTING.md.

---

## Русский

Lua/TSO — это скриптовая платформа для z/OS, предназначенная для замены system REXX в автоматизации. Она предоставляет Lua VM с host‑API для TSO/ISPF/datasets/AXR и TLS через System SSL, ориентированную на работу с datasets и сервисами z/OS.

### Цели

- Предоставить современную скриптовую среду для автоматизации на z/OS.
- Интеграция с базовыми сервисами: TSO, ISPF (без панелей), datasets, AXR.
- Запуск TSO‑команд под TMP (IKJEFT01) для гарантированного вывода в SYSTSPRT.
- Безопасные соединения через z/OS System SSL.

### Статус

Черновик (v3). Сейчас в репозитории находится RFC и базовые материалы проекта.

### Документация

- RFC (EN): docs/RFC_MAIN_EN.md
- RFC (RU): docs/RFC_MAIN.md

### Лицензия

Apache-2.0. См. LICENSE и NOTICE.

### Участие

См. CONTRIBUTING.md.
