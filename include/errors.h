/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * LUZ error codes for Lua/TSO C core stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | LUZ_E_* | macro | Numeric error codes for stub returns |
 */
#ifndef ERRORS_H
#define ERRORS_H

#define LUZ_E_CORE_INIT 30001
#define LUZ_E_CORE_SHUTDOWN 30002
#define LUZ_E_TSO_CMD 30003
#define LUZ_E_TSO_ALLOC 30004
#define LUZ_E_TSO_FREE 30005
#define LUZ_E_TSO_MSG 30024
#define LUZ_E_TSO_EXIT 30025
#define LUZ_E_DS_OPEN 30006
#define LUZ_E_DS_READ 30007
#define LUZ_E_DS_WRITE 30008
#define LUZ_E_DS_CLOSE 30009
#define LUZ_E_ISPF_QRY 30010
#define LUZ_E_ISPF_EXEC 30011
#define LUZ_E_AXR_REQUEST 30012
#define LUZ_E_TLS_CONNECT 30013
#define LUZ_E_TLS_LISTEN 30014
#define LUZ_E_TIME_NOW 30015
#define LUZ_E_TIME_LOCAL 30016
#define LUZ_E_TIME_GMT 30017
#define LUZ_E_POLICY_GET 30018
#define LUZ_E_TIME_CLOCK 30019
#define LUZ_E_PATH_LOOKUP 30020
#define LUZ_E_PATH_LOAD 30021
#define LUZ_E_TIME_DATE 30022
#define LUZ_E_TIME_TIME 30023
#define LUZ_E_DS_REMOVE 30026
#define LUZ_E_DS_RENAME 30027
#define LUZ_E_DS_TMPNAME 30028
#define LUZ_E_DS_MEMBER 30029
#define LUZ_E_DS_INFO 30037

#endif /* ERRORS_H */
