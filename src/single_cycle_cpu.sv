module single_cycle_cpu #(
    parameter int MEM_DEPTH = 1024
) (
	input logic clk,
	input logic reset,

	output logic [31:0] regs_debug [0:31],
    output logic [31:0] pc_debug,
    output logic [31:0] instr_debug
);

logic [31:0] next_pc, pc;
reg_reset pc_reg(.clk(clk), .reset(reset), .d(next_pc), .q(pc));

logic [31:0] instr;
rom #(MEM_DEPTH) 
	instr_ram(.addr(pc), .data(instr));

logic [31:0] pc_plus4;
assign pc_plus4 = pc + 32'b100;

logic wreg_dst_sel, reg_we, alu_srcb_sel, 
	  mem_rd, mem_we, wrbck_data_sel, 
	  is_beq, is_jmp;
logic [3:0] aluop;
singlecyc_mcu i_mcu(
	instr[31:26],  
	alu_srcb_sel,  
	mem_rd, mem_we, 
	reg_we, 
	wreg_dst_sel, 
	wrbck_data_sel, 
	is_beq, is_jmp, 
	aluop
);

logic [3:0] alu_ctrl;
alu_cu i_alu_cu(aluop, instr[5:0], alu_ctrl);

logic [4:0] w_reg;
assign w_reg = wreg_dst_sel ? instr[15:11] : instr[20:16];
logic [31:0] reg_wdata;
logic [31:0] r_data1, r_data2;
reg_file i_reg_file(.clk(clk), 				   .we(reg_we), 
					.r_reg1(instr[25:21]), .r_reg2(instr[20:16]), 
					.w_reg(w_reg), 		   .w_data(reg_wdata), 
					.r_data1(r_data1), 	   .r_data2(r_data2),
					.regs_debug(regs_debug));

logic [31:0] sign_imm, b;
assign sign_imm = { {16{instr[15]}}, instr[15:0] };
assign b = alu_srcb_sel ? sign_imm : r_data2;
logic [31:0] alu_res;
logic eq, overflow;
alu i_alu(.a(r_data1), .b(b), .shamt(instr[10:6]),
		  .alu_ctrl(alu_ctrl), 
		  .c(alu_res), 
		  .eq(eq), .overflow(overflow));

logic [31:0] pc_branch;
assign pc_branch = (sign_imm << 2) + pc_plus4;

logic [31:0] mem_rd_data;
ram #(MEM_DEPTH) data_ram(.addr(alu_res), .w_data(r_data2), .clk(clk), 
			 .we(mem_we), .data(mem_rd_data));

assign reg_wdata = wrbck_data_sel ? mem_rd_data : alu_res;

logic take_beq;
assign take_beq = is_beq && eq;
logic [31:0] jmp_pc;
assign jmp_pc = {pc_plus4[31:28], instr[25:0], 2'b0};
assign next_pc = is_jmp ? jmp_pc :
						  (take_beq ? pc_branch : pc_plus4);

assign pc_debug = pc;
assign instr_debug = instr;

	
endmodule