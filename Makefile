# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# z/OS build and submission helpers.
#
# Object Table:
# | Object     | Kind   | Purpose |
# |------------|--------|---------|
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
HLQ ?=
REBUILD ?=
REBUILD_FILE ?=
SYNC_ARGS ?=
SUBMIT_ARGS ?=

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

.PHONY: sync-full sync buildinc it_tso clean_out

sync-full:
	./scripts/ftp_sync_all.sh --full $(SYNC_ARGS)

sync:
	./scripts/ftp_sync_all.sh $(SYNC_ARGS)

buildinc: sync
	./scripts/ftp_submit.sh $(SUBMIT_ARGS) $(REBUILD_ARGS) -j $(BUILDINC_JCL)

it_tso:
	./scripts/ftp_submit.sh $(SUBMIT_ARGS) -j $(ITTSO_JCL)

# Change Note: add local cleanup target for JCL spool artifacts.
clean_out:
	rm -f jcl/*.out
