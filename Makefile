# ============================================================================
# Makefile for the Self-triggering Student ID Cyclic Display System
#
# Usage:
#   make sim        - Run Python behavioral simulation
#   make iverilog   - Run Icarus Verilog simulation (if installed)
#   make clean      - Remove generated files
# ============================================================================

.PHONY: sim iverilog clean all

all: sim

# Python behavioral simulation
sim:
	python3 sim/simulate.py

# Icarus Verilog simulation (requires iverilog)
iverilog:
	iverilog -o sim/tb_top_module.vvp src/*.v sim/tb_top_module.v
	vvp sim/tb_top_module.vvp

# Clean generated files
clean:
	rm -f sim/tb_top_module.vvp
	rm -f sim/*.vcd

