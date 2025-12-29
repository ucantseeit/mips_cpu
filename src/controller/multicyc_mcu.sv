/* 
wreg_dst_sel控制将被写入的寄存器的编号的来源，
	0来自Instr[20:16](Rt)，1来自Instr[15:11](Rd)
wreg_data_sel控制将被写入的寄存器的数据的来源
	0来自aluout，1来自内存输出
*/
module multicyc_mcu (
	input logic clk, reset, 
	input logic [5:0] opcode,
	input logic [5:0] funct,

	output logic mem_addr_sel, 
	output logic ir_we,
	output logic alu_srca_sel, 
	output logic [2:0] alu_srcb_sel, 
	output logic [3:0] aluop, 
	output logic mem_we, 
				reg_we, 
				pc_we, 
	output logic [1:0] wreg_dst_sel, 
	output logic [1:0] wreg_data_sel,
	output logic [1:0] nxt_pc_sel, 
	output logic is_beq, is_bne, is_bgeltz, is_blez, is_bgtz,
	output logic is_mul
);

import ALUops::*;
import Opcodes::*;
import MultcycCtrl::*;



logic [4:0] curr_state;
logic [4:0] next_state;

always_ff @( posedge clk ) begin
	if (reset) curr_state <= 'b0;
	else 	   curr_state <= next_state;
end

always_comb begin 
	{
		mem_addr_sel, ir_we, 
		alu_srca_sel, alu_srcb_sel, 
		aluop, mem_we, 
		reg_we, pc_we, 
		wreg_dst_sel, wreg_data_sel,
		nxt_pc_sel,
		is_beq, is_bne, is_bgeltz, is_blez, is_bgtz,
		is_mul
	} = 'b0;

	case (curr_state)
		Fetch: begin
			next_state = Decode;
			mem_addr_sel = AddrPC;
			alu_srca_sel = SrcaPC;
			alu_srcb_sel = Four;
			aluop = ALUop_ADD;
			nxt_pc_sel = PCPlus4;
			ir_we = 1;
			pc_we = 1;	end
		Decode: begin
			case (opcode)
				LW, SW: next_state = MemAddr;
				RR, MUL: 
					if (funct == JALR_funct)	next_state = Jalr;
					else if (funct == JR_funct) next_state = Jr;
					else next_state = RRExec;
				BEQ, BNE, BGELTZ, BLEZ, BGTZ: next_state = Branch;
				J : next_state = Jmp;
				ADDI, ADDIU, ANDI, ORI, XORI: next_state = RIExec;
				LUI: next_state = Lui;
				JAL: next_state = Jal;
				default: next_state = 'b0; 
			endcase
			/* for branch */
			alu_srca_sel = AddrPC;
			alu_srcb_sel = BeqImm;
			aluop = ALUop_ADD; end
		MemAddr: begin
			next_state = opcode == LW ? MemRd : MemWr;
			alu_srca_sel = SrcaRs;
			alu_srcb_sel = SrcbImm;
			aluop = ALUop_ADD; end
		MemRd: begin
			next_state = MemWrbck;
			mem_addr_sel = AddrALUout;
		end
		MemWr: begin
			next_state = Fetch;
			mem_addr_sel = AddrALUout;
			mem_we = 1; end
		MemWrbck: begin
			next_state = Fetch;
			wreg_dst_sel = WrRt;
			wreg_data_sel = MemData;
			reg_we = 1; end
		RRExec: begin
			next_state = RRWrbck;
			alu_srca_sel = SrcaRs;
			alu_srcb_sel = SrcbRt;
			if (opcode == MUL)	is_mul = 1;
			aluop = ALUop_RR; end
		RRWrbck: begin
			next_state = Fetch;
			wreg_dst_sel = WrRd;
			wreg_data_sel = ALUout;
			reg_we = 1; end
		RIExec: begin
			next_state = RIWrbck;
			alu_srca_sel = SrcaRs;
			alu_srcb_sel = SrcbImm;
			case (opcode)
				ADDI:  aluop = ALUop_ADD;
				ADDIU: aluop = ALUop_ADDU;
				ANDI:  aluop = ALUop_AND;
				ORI:   aluop = ALUop_OR;
				XORI:  aluop = ALUop_XOR;
				SLTI:  aluop = ALUop_SLT;
				SLTIU: aluop = ALUop_SLTU;
				default: aluop = 'b0;
			endcase  end
		RIWrbck: begin
			next_state = Fetch;
			wreg_dst_sel = WrRt;
			wreg_data_sel = ALUout;
			reg_we = 1; end
		Branch: begin
			next_state = Fetch;
			alu_srca_sel = SrcaRs;
			aluop = ALUop_SUB;
			nxt_pc_sel = PCBranch;
			case (opcode)
				BEQ: begin 
					is_beq= 1;
					alu_srcb_sel = SrcbRt; end
				BNE: begin
					is_bne = 1;
					alu_srcb_sel = SrcbRt; end
				BGELTZ: begin
					is_bgeltz = 1; 
					alu_srcb_sel = Zero; end
				BLEZ: begin
					is_blez = 1;
					alu_srcb_sel = Zero; end
				BGTZ: begin
					is_bgtz = 1;
					alu_srcb_sel = Zero; end
				default: ;
			endcase end
		Jmp: begin
			next_state = Fetch;
			pc_we = 1;
			nxt_pc_sel = PCJmp; end
		Lui: begin
			next_state = Fetch;
			reg_we = 1;
			wreg_dst_sel = WrRt;
			wreg_data_sel = LuiResult; end
		Jal: begin
			next_state = Fetch;
			/* for write pc */
			pc_we = 1;
			nxt_pc_sel = PCJmp;
			/* for store pc+4 */
			reg_we = 1;
			wreg_dst_sel = WrRa;
			wreg_data_sel = PCPlus4_j; end
		Jalr: begin
			next_state = Fetch;
			/* for write pc */
			pc_we = 1;
			nxt_pc_sel = PCJmp;
			/* for store pc+4 */
			reg_we = 1;
			wreg_dst_sel = WrRd;
			wreg_data_sel = PCPlus4_j; end
		Jr: begin
			next_state = Fetch;
			pc_we = 1;
			nxt_pc_sel = PCRs;
		end
		default: ;
	endcase
end
	
endmodule
