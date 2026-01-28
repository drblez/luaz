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
# | ut_dsopen  | target | Run UTDOPEN after buildinc |
# | ut_dsnopen | target | Run UTDSNOPEN after buildinc |
# | ut_dsmem   | target | Run UTDMEM after buildinc |
# | ut_dsrem   | target | Run UTDSREM after buildinc |
# | ut_dsren   | target | Run UTDSREN after buildinc |
# | ut_dstmp   | target | Run UTDSTMP after buildinc |
# | ut_dsinf   | target | Run UTDSINF after buildinc |
# | ut_tscmd   | target | Run UTTCMD after buildinc |
# | ut_tsaf    | target | Run UTTAF after buildinc |
# | ut_tsmsg   | target | Run UTTMSG after buildinc |
# | clean_out  | target | Remove local JCL .out artifacts |
#
# Change Note: Replace local build rules with FTP-based sync/build/test
# targets to match the z/OS workflow and reduce manual steps.

BUILDINC_JCL ?= jcl/BUILDINC.jcl
ITTSO_JCL ?= jcl/ITTSO.jcl
ITLUACFG_JCL ?= jcl/IT_LUACFG.jcl
ITLUACMD_JCL ?= jcl/IT_LUACMD.jcl
ITLFB80_JCL ?= jcl/IT_LUAIN_FB80.jcl
UTDSOPEN_JCL ?= jcl/UTDOPEN.jcl
UTDSNOPEN_JCL ?= jcl/UTDSNOPEN.jcl
UTDMEM_JCL ?= jcl/UTDMEM.jcl
UTDSREM_JCL ?= jcl/UTDSREM.jcl
UTDSREN_JCL ?= jcl/UTDSREN.jcl
UTDSTMP_JCL ?= jcl/UTDSTMP.jcl
UTDSINF_JCL ?= jcl/UTDSINF.jcl
UTTSCMD_JCL ?= jcl/UTTCMD.jcl
UTTSAF_JCL ?= jcl/UTTAF.jcl
UTTSMSG_JCL ?= jcl/UTTMSG.jcl
HLQ ?=
REBUILD ?=
REBUILD_FILE ?=
SYNC_ARGS ?=
SUBMIT_ARGS ?=
FORCE ?= 0
FORCE_DEP :=
ifeq ($(FORCE),1)
FORCE_DEP := force
endif

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
SYNC_TEST_FILES := $(shell rg --files tests -g '*.lua')
SYNC_MAP_FILES := $(wildcard pds-map-*.csv)
SYNC_INPUTS := $(SYNC_SRC_FILES) $(SYNC_ASM_FILES) $(SYNC_INC_FILES) \
	$(SYNC_LUA_FILES) $(SYNC_JCL_FILES) $(SYNC_REXX_FILES) \
	$(SYNC_TEST_FILES) $(SYNC_MAP_FILES)

.PHONY: fmt sync-full sync clean_out it_tso it_luacfg it_luacmd it_luain_fb80 \
	ut_dsopen ut_dsnopen ut_dsmem ut_dsrem ut_dsren ut_dstmp ut_dsinf \
	ut_tscmd ut_tsaf ut_tsmsg force

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
$(STAMP_DIR)/it_$(1): $(FORCE_DEP)
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

# Change note: add UT targets with the same stamp-based behavior as IT.
# Problem: UT jobs had no Makefile targets and had to be submitted manually.
# Expected effect: UT jobs can be executed via make with change detection.
# Impact: UT targets submit only when sources/JCL change (or FORCE=1).
define ut_rule
ut_$(1): $(STAMP_DIR)/ut_$(1)

$(STAMP_DIR)/ut_$(1): $(SYNC_ALL_STAMP) $(BUILDINC_STAMP) $$(UT_$(1)_JCL) $$(UT_$(1)_DEPS)
$(STAMP_DIR)/ut_$(1): $(FORCE_DEP)
	@mkdir -p $(STAMP_DIR)
	@if [ "$(FORCE)" = "1" ] || [ ! -f "$$@" ] || [ "$$(UT_$(1)_JCL)" -nt "$$@" ] || \
		{ [ -f "$(SYNC_CODE_STAMP)" ] && [ "$(SYNC_CODE_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_TEST_STAMP)" ] && [ "$(SYNC_TEST_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_LUA_STAMP)" ] && [ "$(SYNC_LUA_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_REXX_STAMP)" ] && [ "$(SYNC_REXX_STAMP)" -nt "$$@" ]; } || \
		{ [ -f "$(SYNC_JCL_STAMP)" ] && [ "$(SYNC_JCL_STAMP)" -nt "$$@" ]; }; then \
		./scripts/ftp_submit.sh $(SUBMIT_ARGS) -j $$(UT_$(1)_JCL); \
		touch "$$@"; \
	else \
		echo "No test changes; skipping ut_$(1)."; \
		touch "$$@"; \
	fi
endef

UT_dsopen_JCL := $(UTDSOPEN_JCL)
UT_dsopen_DEPS :=
$(eval $(call ut_rule,dsopen))

UT_dsnopen_JCL := $(UTDSNOPEN_JCL)
UT_dsnopen_DEPS := tests/unit/lua/UTDSNOPEN.lua
$(eval $(call ut_rule,dsnopen))

UT_dsmem_JCL := $(UTDMEM_JCL)
UT_dsmem_DEPS := tests/unit/lua/UTDMEM.lua
$(eval $(call ut_rule,dsmem))

UT_dsrem_JCL := $(UTDSREM_JCL)
UT_dsrem_DEPS := tests/unit/lua/UTDSREM.lua
$(eval $(call ut_rule,dsrem))

UT_dsren_JCL := $(UTDSREN_JCL)
UT_dsren_DEPS := tests/unit/lua/UTDSREN.lua
$(eval $(call ut_rule,dsren))

UT_dstmp_JCL := $(UTDSTMP_JCL)
UT_dstmp_DEPS := tests/unit/lua/UTDSTMP.lua
$(eval $(call ut_rule,dstmp))

UT_dsinf_JCL := $(UTDSINF_JCL)
UT_dsinf_DEPS := tests/unit/lua/UTDSINF.lua
$(eval $(call ut_rule,dsinf))

UT_tscmd_JCL := $(UTTSCMD_JCL)
UT_tscmd_DEPS := tests/unit/lua/UTTCMD.lua
$(eval $(call ut_rule,tscmd))

UT_tsaf_JCL := $(UTTSAF_JCL)
UT_tsaf_DEPS := tests/unit/lua/UTTAF.lua
$(eval $(call ut_rule,tsaf))

UT_tsmsg_JCL := $(UTTSMSG_JCL)
UT_tsmsg_DEPS := tests/unit/lua/UTTMSG.lua
$(eval $(call ut_rule,tsmsg))

# Change Note: add local cleanup target for JCL spool artifacts.
clean_out:
	rm -f jcl/*.out

force:
	@true
