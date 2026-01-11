# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# Build scaffolding for Lua/TSO host API stubs.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | all | target | Build all objects and archive |
# | clean | target | Remove build artifacts |

CC ?= cc
AR ?= ar
CFLAGS ?= -Wall -Wextra -O2

SRC = \
  src/luaz_core.c \
  src/luaz_tso.c \
  src/luaz_ds.c \
  src/luaz_ispf.c \
  src/luaz_axr.c \
  src/luaz_tls.c \
  src/luaz_time.c \
  src/luaz_policy.c \
  src/luaz_path.c \
  src/luaz_platform.c

OBJ = $(SRC:.c=.o)

all: libluaz.a

libluaz.a: $(OBJ)
	$(AR) rcs $@ $(OBJ)

clean:
	rm -f $(OBJ) libluaz.a
