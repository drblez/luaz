# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# z/OS build and submission helpers.
#
# Object Table:
# | Object     | Kind   | Purpose |
# |------------|--------|---------|
# | fmt        | target | Format HLASM sources in-place |
# | sync-full  | target | Full FTP sync of all source trees |
# | sync       | target | Incremental FTP sync using state cache |
# | buildinc   | target | Incremental BUILDINC after sync; optional rebuild list |
# | it_tso     | target | Run ITTSO after buildinc |
# | clean_out  | target | Remove local JCL .out artifacts |
#
# Change Note: Replace local build rules with FTP-based sync/build/test
# targets to match the z/OS workflow and reduce manual steps.

BUILDINC_JCL ?= jcl/BUILDINC.jcl
ITTSO_JCL ?= jcl/ITTSO.jcl
ITLUACFG_JCL ?= jcl/IT_LUACFG.jcl
ITLUACMD_JCL ?= jcl/IT_LUACMD.jcl
ITLFB80_JCL ?= jcl/IT_LUAIN_FB80.jcl
HLQ ?=
REBUILD ?=
REBUILD_FILE ?=
SYNC_ARGS ?=
SUBMIT_ARGS ?=
FORCE ?= 0

REBUILD_ARGS :=
ifneq ($(strip $(REBUILD)),)
REBUILD_ARGS += --rebuild $(REBUILD)
endif
ifneq ($(strip $(REBUILD_FILE)),)
REBUILD_ARGS += --rebuild-file $(REBUILD_FILE)
endif
ifneq ($(strip $(HLQ)),)
REBUILD_ARGS += --hlq $(HLQ)
endif

# Change note: add local stamp-based dependencies for MF sync/build/test.
# Problem: Make targets were phony and could not skip unchanged work.
# Expected effect: sync/build/test runs only when input files changed.
# Impact: build/test targets are now stamp-driven instead of always running.
STAMP_DIR := build/.stamp
SYNC_ALL_STAMP := $(STAMP_DIR)/sync_all
SYNC_CODE_STAMP := $(STAMP_DIR)/sync_code
SYNC_TEST_STAMP := $(STAMP_DIR)/sync_test
SYNC_LUA_STAMP := $(STAMP_DIR)/sync_lua
SYNC_JCL_STAMP := $(STAMP_DIR)/sync_jcl
SYNC_REXX_STAMP := $(STAMP_DIR)/sync_rexx
BUILDINC_STAMP := $(STAMP_DIR)/buildinc

SYNC_SRC_FILES := $(shell rg --files src lua-vm/src -g '*.c')
SYNC_ASM_FILES := $(shell rg --files src -g '*.asm')
SYNC_INC_FILES := $(shell rg --files include lua-vm/src -g '*.h' -g '*.inc' -g '*.hpp')
SYNC_LUA_FILES := $(shell rg --files lua -g '*.lua')
SYNC_JCL_FILES := $(shell rg --files jcl -g '*.jcl')
SYNC_REXX_FILES := $(shell rg --files rexx -g '*.rexx')
SYNC_TEST_FILES := $(shell rg --files tests/integration/lua -g '*.lua')
SYNC_MAP_FILES := $(wildcard pds-map-*.csv)
SYNC_INPUTS := $(SYNC_SRC_FILES) $(SYNC_ASM_FILES) $(SYNC_INC_FILES) \
	$(SYNC_LUA_FILES) $(SYNC_JCL_FILES) $(SYNC_REXX_FILES) \
	$(SYNC_TEST_FILES) $(SYNC_MAP_FILES)

.PHONY: fmt sync-full sync clean_out it_tso it_luacfg it_luacmd it_luain_fb80

fmt:
	python3 scripts/asmfmt.py --root src --ext .asm

sync-full: fmt
	@mkdir -p $(STAMP_DIR)
	SYNC_STAMP_DIR=$(STAMP_DIR) ./scripts/ftp_sync_all.sh --full $(SYNC_ARGS)
	@touch $(SYNC_ALL_STAMP)

sync: fmt $(SYNC_ALL_STAMP)

$(SYNC_ALL_STAMP): $(SYNC_INPUTS)
	@mkdir -p $(STAMP_DIR)
	SYNC_STAMP_DIR=$(STAMP_DIR) ./scripts/ftp_sync_all.sh $(SYNC_ARGS)
	@touch $@

buildinc: $(BUILDINC_STAMP)

$(BUILDINC_STAMP): $(SYNC_ALL_STAMP) $(BUILDINC_JCL)
	@mkdir -p $(STAMP_DIR)
	@if [ -n "$(strip $(REBUILD)$(REBUILD_FILE))" ] || [ ! -f "$@" ] || \
		[ "$(BUILDINC_JCL)" -nt "$@" ] || [ ! -f "$(SYNC_CODE_STAMP)" ] || \
		[ "$(SYNC_CODE_STAMP)" -nt "$@" ]; then \
		./scripts/ftp_submit.sh $(SUBMIT_ARGS) $(REBUILD_ARGS) -j $(BUILDINC_JCL); \
		touch "$@"; \
	else \
		echo "No code changes; skipping buildinc."; \
		touch "$@"; \
	fi

define it_rule
it_$(1): $(STAMP_DIR)/it_$(1)

$(STAMP_DIR)/it_$(1): $(SYNC_ALL_STAMP) $(BUILDINC_STAMP) $$(IT_$(1)_JCL) $$(IT_$(1)_DEPS)
	@mkdir -p $(STAMP_DIR)
	@if [ "$(FORCE)" = "1" ] || [ ! -f "$$@" ] || [ "$$(BUILDINC_STAMP)" -nt "$$@" ] || \
		[ "$$(IT_$(1)_JCL)" -nt "$$@" ] || \
		{ [ -f "$(SYNC_TEST_STAMP)" ] && [ "$(SYNC_TEST_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_LUA_STAMP)" ] && [ "$(SYNC_LUA_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_REXX_STAMP)" ] && [ "$(SYNC_REXX_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_JCL_STAMP)" ] && [ "$(SYNC_JCL_STAMP)" -nt "$$@" ]; }; then \
		./scripts/ftp_submit.sh $(SUBMIT_ARGS) -j $$(IT_$(1)_JCL); \
		touch "$$@"; \
	else \
		echo "No test changes; skipping it_$(1)."; \
		touch "$$@"; \
	fi
endef

IT_tso_JCL := $(ITTSO_JCL)
IT_tso_DEPS := tests/integration/lua/ITTSO.lua rexx/LUTSO.rexx
$(eval $(call it_rule,tso))

IT_luacfg_JCL := $(ITLUACFG_JCL)
IT_luacfg_DEPS := tests/integration/lua/ITLUACFG.lua
$(eval $(call it_rule,luacfg))

IT_luacmd_JCL := $(ITLUACMD_JCL)
IT_luacmd_DEPS := tests/integration/lua/ITLUACMD.lua
$(eval $(call it_rule,luacmd))

IT_luain_fb80_JCL := $(ITLFB80_JCL)
IT_luain_fb80_DEPS :=
$(eval $(call it_rule,luain_fb80))

# Change Note: add local cleanup target for JCL spool artifacts.
clean_out:
	rm -f jcl/*.out
