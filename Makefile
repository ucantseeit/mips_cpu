# Makefile for ModelSim/QuestaSim

# Tools
VSIM   ?= vsim
VLIB   ?= vlib
VLOG   ?= vlog

# Library
WORKLIB = work

# Source files
SRC_DIR      = src
DATAPATH_DIR = $(SRC_DIR)/datapath
CTRL_DIR     = $(SRC_DIR)/controller

# 所有 Verilog/SystemVerilog 源文件（按编译顺序！）
# 无依赖模块最先
DATAPATH_SRC = \
	$(DATAPATH_DIR)/adder.sv \
	$(DATAPATH_DIR)/comparator.sv \
	$(DATAPATH_DIR)/mem.sv \
	$(DATAPATH_DIR)/reg_reset.sv

# ALU 依赖 adder/comparator
ALU_SRC = $(DATAPATH_DIR)/alu.sv

# Controller common package (必须最先编译，因其他 module import 它)
CTRL_DEFS = $(CTRL_DIR)/cu_defs.sv

# 控制器模块（依赖 cu_defs）
CTRL_SRC = \
	$(CTRL_DIR)/alu_cu.sv \
	$(CTRL_DIR)/singlecyc_cu.sv \
	$(CTRL_DIR)/multicyc_mcu.sv

# 顶层 CPU（依赖 controller + datapath）
CPU_SRC = \
	$(SRC_DIR)/single_cycle_cpu.sv \
	$(SRC_DIR)/multi_cycle_cpu.sv

# Testbenches
BASIC_TB  = tb/basic_tb.sv
ARITH_TB  = tb/arith_tb.sv
BEQJMP_TB = tb/beq_jmp_tb.sv
LWSW_TB   = tb/lw_sw_tb.sv
CHECKSUM_TB = tb/checksum_tb.sv

# All source in correct compile order
SRC_FILES = \
	$(CTRL_DEFS) \
	$(DATAPATH_SRC) \
	$(ALU_SRC) \
	$(CTRL_SRC) \
	$(CPU_SRC)

# 默认目标
.PHONY: all sim clean compile

all: compile

# 创建 work 库
$(WORKLIB):
	$(VLIB) $(WORKLIB)

# 编译所有源文件
compile: $(WORKLIB)
	$(VLOG) -work $(WORKLIB) -sv $(SRC_FILES)

# 编译 tb
compile_basic: compile
	$(VLOG) -work $(WORKLIB) -sv $(BASIC_TB)

compile_arith: compile
	$(VLOG) -work $(WORKLIB) -sv $(ARITH_TB)

compile_beqjmp: compile
	$(VLOG) -work $(WORKLIB) -sv $(BEQJMP_TB)

compile_lwsw: compile
	$(VLOG) -work $(WORKLIB) -sv $(LWSW_TB)

compile_checksum: compile
	$(VLOG) -work $(WORKLIB) -sv $(CHECKSUM_TB)
	
# 清理
clean:
	rm wlft* transcript vsim.wlf