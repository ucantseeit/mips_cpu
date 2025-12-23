
module multi_cycle_cpu #(
    parameter int MEM_DEPTH = 1024
) (
	input logic clk,
	input logic reset,

	output logic [31:0] regs_debug [0:31],
    output logic [31:0] pc_debug,
    output logic [31:0] instr_debug
);

import MultcycCtrl::*;

logic [31:0] instr;
logic mem_addr_sel, ir_we,
	alu_srca_sel, 
	mem_rd, mem_wr, 
	reg_we, pc_we, 
	wreg_dst_sel, wrbck_data_sel;
logic [1:0] alu_srcb_sel;
logic [3:0] aluop;
logic [1:0] nxt_pc_sel;
logic is_beq, is_jmp;
multicyc_mcu cu(clk, reset, instr[31:26],
	mem_addr_sel, ir_we,
	alu_srca_sel, alu_srcb_sel, 
	aluop, 
	mem_rd, mem_wr, 
	reg_we, pc_we, 
	wreg_dst_sel, wrbck_data_sel
);

logic [3:0] alu_ctrl;
alu_cu i_alu_cu(aluop, instr[5:0], alu_ctrl);

// 注意：next_pc的选择。
/*
	在一开始的时候，我们只知道next_pc的一个选择是aluout
	但是，next_pc和aluout应该是两个信号
	为了后续扩展方便，使用了这样的写法
	其它信号也可以仿照
*/
logic [31:0] aluout;
logic [31:0] next_pc, pc;
always_comb begin 
	next_pc = aluout;
end

// pc的定义，并不需要单独的module，因为pc逻辑相对比较简单
always_ff @( posedge clk ) begin
	if (reset) pc <= 32'b0;
	else if (pc_we) pc <= next_pc;
end


endmodule