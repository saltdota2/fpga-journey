#==============================================================
# FPGA journey — build automation
#==============================================================

# --- Configuration ---------------------------------------------
TOP      ?= led_blink
PART     ?= xc7a35ticsg324-1L
BUILD    := build
RTL_DIR  := rtl
TB_DIR   := tb
SCRIPTS  := scripts

VIVADO   ?= vivado
VIVADO_FLAGS := -mode batch -nojournal -nolog -notrace

RTL_SRCS := $(wildcard $(RTL_DIR)/*.sv)
XDC      := constr/arty_a7_35t.xdc

BIT      := $(BUILD)/$(TOP).bit

# --- Default ---------------------------------------------------
.PHONY: all
all: bit

# --- Help (self-documenting) -----------------------------------
.PHONY: help
help:
	@echo "Targets:"
	@echo "  make lint    - Verilator lint on all RTL"
	@echo "  make synth   - synthesis only, reports to $(BUILD)/"
	@echo "  make bit     - full flow to bitstream"
	@echo "  make timing  - show post-route WNS/WHS"
	@echo "  make clean   - remove generated files"
	@echo ""
	@echo "Overrides:  make bit TOP=my_module"

# --- Lint ------------------------------------------------------
.PHONY: lint
lint:
	verilator --lint-only -Wall --timing -Irtl $(RTL_DIR)/$(TOP).sv --top-module $(TOP)

# --- Synthesis only --------------------------------------------
.PHONY: synth
synth:
	$(VIVADO) $(VIVADO_FLAGS) -source $(SCRIPTS)/build.tcl -tclargs $(TOP) synth

# --- Full flow to bitstream ------------------------------------
.PHONY: bit
bit: $(BIT)

$(BIT): $(RTL_SRCS) $(XDC) $(SCRIPTS)/build.tcl
	$(VIVADO) $(VIVADO_FLAGS) -source $(SCRIPTS)/build.tcl -tclargs $(TOP) impl

# --- Timing summary --------------------------------------------
.PHONY: timing
timing:
	@grep -A3 "Design Timing Summary" $(BUILD)/post_route_timing.rpt || \
	 echo "No timing report. Run 'make bit' first."

# --- Clean -----------------------------------------------------
.PHONY: clean
clean:
	rm -rf $(BUILD) .Xil obj_dir sim_build
	rm -f  vivado*.jou vivado*.log usage_statistics_webtalk*