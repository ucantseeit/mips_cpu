
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
	mem_we, 
	reg_we, pc_we, 
	wreg_dst_sel;
logic [1:0] wreg_data_sel;
logic [2:0] alu_srcb_sel;
logic [3:0] aluop;
logic [1:0] nxt_pc_sel;
logic is_beq, is_bne, is_bgeltz, is_blez, is_bgtz;
logic is_jmp;
multicyc_mcu cu(
	clk, reset, instr[31:26],

	mem_addr_sel, 
	ir_we,
	alu_srca_sel, 
	alu_srcb_sel, 
	aluop, 
	mem_we, 
	reg_we, 
	pc_we, 
	wreg_dst_sel, 
	wreg_data_sel,
	nxt_pc_sel,
	is_beq, is_bne, is_bgeltz, is_blez, is_bgtz,
	is_jmp
);

logic [3:0] alu_ctrl;
alu_cu i_alu_cu(aluop, instr[5:0], alu_ctrl);

logic [31:0] aluout, aluout_nxt;
logic [31:0] next_pc, pc;
always_comb begin 
	case (nxt_pc_sel)
		PCPlus4 : next_pc = aluout;
		PCBranch : next_pc = aluout_nxt;
		PCJmp : next_pc = {pc[31:28], instr[25:0], 2'b00};
		default : next_pc = pc;
	endcase
end

logic eq, lt;
always_ff @( posedge clk ) begin
	if (reset) pc <= 32'b0;
	else if (pc_we) pc <= next_pc;
	else if (is_beq && eq) pc <= next_pc;
	else if (is_bne && !eq) pc <= next_pc;
	else if (is_bgeltz) begin
		if (instr[20:16] == 5'b0_0001 && !lt)
			pc <= next_pc;
		else if (instr[20:16] == 'b0 && lt)
			pc <= next_pc;
		else ;
	end
	else if (is_blez && (lt || eq)) pc <= next_pc;
	else if (is_bgtz && !(lt || eq)) pc <= next_pc;
	else ;
end

logic [31:0] mem_addr;
always_comb begin 
	case (mem_addr_sel)
		AddrPC: mem_addr = pc;
		AddrALUout: mem_addr = aluout_nxt; 
	endcase
end

logic [31:0] r_data2_nxt, mem_data;
ram #(MEM_DEPTH) 
	i_ram(.addr(mem_addr), .w_data(r_data2_nxt),
		  .clk(clk), .we(mem_we), .data(mem_data));

always_ff @( posedge clk ) begin 
	if (ir_we) instr <= mem_data;
end

logic [31:0] mem_data_nxt;
always_ff @( posedge clk ) begin 
	mem_data_nxt <= mem_data;
end

logic [4:0] w_reg;
always_comb begin 
	case (wreg_dst_sel)
		WrRt: w_reg = instr[20:16];
		WrRd: w_reg = instr[15:11];
	endcase
end

logic [31:0] wreg_data;
always_comb begin 
	case (wreg_data_sel)
		ALUout: wreg_data = aluout_nxt;
		MemData: wreg_data = mem_data_nxt;
		LuiResult: wreg_data = {instr[15:0], 16'b0};
	endcase
end

logic [31:0] r_data1, r_data2;
reg_file i_reg_file(.clk(clk), .we(reg_we),
					.r_reg1(instr[25:21]), .r_reg2(instr[20:16]),
					.w_reg(w_reg), .w_data(wreg_data),
					.r_data1(r_data1), .r_data2(r_data2),
					.regs_debug(regs_debug));

logic [31:0] r_data1_nxt;
always_ff @( posedge clk ) begin 
	r_data1_nxt <= r_data1;
	r_data2_nxt <= r_data2;
end

logic [31:0] alu_srca, alu_srcb;
always_comb begin 
	case (alu_srca_sel)
		SrcaPC: alu_srca = pc;
		SrcaRs: alu_srca = r_data1_nxt;
	endcase
end

always_comb begin 
	case (alu_srcb_sel)
		SrcbRt:  alu_srcb = r_data2_nxt;
		Four:    alu_srcb = 32'b100;
		SrcbImm: alu_srcb = $signed(instr[15:0]);
		BeqImm:  alu_srcb = $signed({instr[15:0], 2'b00});
		Zero:    alu_srcb = 32'b0;
		default: alu_srcb = 32'b0;
	endcase
end

logic overflow;
alu i_alu(alu_srca, alu_srcb, instr[10:6],
		  alu_ctrl, aluout, eq, lt, overflow);

always_ff @( posedge clk ) begin
	aluout_nxt <= aluout;
end

assign pc_debug = pc;
assign instr_debug = instr;

endmodule