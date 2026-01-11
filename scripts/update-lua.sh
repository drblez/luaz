#!/usr/bin/env sh
# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# Update Lua upstream sources and refresh local VM copy.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | update_lua | procedure | Sync upstream into third_party and lua-vm |

set -eu

UPSTREAM_DIR="third_party/lua-src"
VM_DIR="lua-vm"
VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "LUZ-20001 missing Lua version (e.g., 5.5.0)"
  exit 1
fi

SRC_DIR="$UPSTREAM_DIR/lua-$VERSION"
if [ ! -d "$SRC_DIR" ]; then
  echo "LUZ-20002 upstream dir not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$VM_DIR"
rsync -a --delete "$SRC_DIR/" "$VM_DIR/"

echo "LUZ-20003 Lua VM updated from $SRC_DIR"
