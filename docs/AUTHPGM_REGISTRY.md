# AUTHPGM/AUTHCMD Registry

This registry tracks modules added to TSO authorization lists (AUTHPGM/AUTHCMD).

| Date (YYYY-MM-DD) | Member | List | Modules | Reason | Requested By | Notes |
|---|---|---|---|---|---|---|
| 2026-01-19 | IKJTSO00 | AUTHPGM | TSNENV, TSNOUT, LUAEXEC | TSO native tests and Lua/TSO runtime | drblez | Applied via JOB00419 verification |
| 2026-01-19 | IKJTSO00 | AUTHPGM | TSOAUTH | Authorized TSO attach stub | drblez | Updated SYS1.PARMLIB(IKJTSO00) |
| 2026-01-19 | IKJTSO00 | AUTHTSF | TSOAUTH | Authorized TSO attach stub | drblez | Updated SYS1.PARMLIB(IKJTSO00) |
| 2026-01-20 | IKJTSO00 | AUTHPGM | TSNENV, TSNOUT, LUAEXEC, TSOAUTH | IKJTSO00 snapshot verification | drblez | Source: /tmp/IKJTSO00 |
| 2026-01-20 | IKJTSO00 | AUTHTSF | TSOAUTH | IKJTSO00 snapshot verification | drblez | Source: /tmp/IKJTSO00 (no TSNENV/TSNOUT/LUAEXEC) |
| 2026-01-20 | IKJTSO00 | AUTHPGM | LUAEXEC | Confirm LUAEXEC for PGM/TSO entrypoint | drblez | Applied via UPTSO00 JOB00642 |
