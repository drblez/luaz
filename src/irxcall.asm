* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* IRXCALL -- IRXEXEC caller stub (OS linkage, AMODE 31).
*
* Object Table:
* | Object  | Kind  | Purpose |
* |---------|-------|---------|
* | IRXCALL | CSECT | Call IRXEXEC with OS linkage |
*
IRXCALL  CSECT
IRXCALL  AMODE 31
IRXCALL  RMODE ANY
         EXTRN IRXEXEC
         STM   14,12,12(13)
         BASR  12,0
         USING IRXCALL,12
         LA    15,SAVE
         ST    13,4(15)
         ST    15,8(13)
         LR    13,15
*
* C passes a parameter list:
*   1st word -> IRXEXEC parameter block address
*
         L     1,0(1)
         L     15,=V(IRXEXEC)
         BALR  14,15
         L     13,4(13)
         LM    14,12,12(13)
         BR    14
*
SAVE     DS    18F
         END   IRXCALL
