/* 
wreg_dst_sel控制将被写入的寄存器的编号的来源，
	0来自Instr[20:16](Rt)，1来自Instr[15:11](Rd)
wrbck_data_sel控制将被写入的寄存器的数据的来源
	0来自aluout，1来自内存输出
*/
module singlecyc_mcu (
	input logic [5:0] opcode,

	output logic alu_srcb_sel, 
	mem_rd, mem_we, 
	reg_we, 
	wreg_dst_sel, 
	wrbck_data_sel, 
	is_beq, jmp,
	output logic [3:0] aluop
);

import ALUops::*;
import Opcodes::*;
import SinglecycCtrl::*;

always_comb begin
    // 默认全0（包括 aluop = ADD）
    {wreg_dst_sel, reg_we, alu_srcb_sel, mem_rd, mem_we, wrbck_data_sel, is_beq, jmp} = 8'b0;
    aluop = ALUop_ADD;

    case (opcode)
        RR: begin 
			reg_we = 1;
			wreg_dst_sel = WrRd;
			aluop = ALUop_RR;  end
        LW: begin 
			mem_rd = 1;
			alu_srcb_sel = SrcbImm;
			reg_we = 1;
			wreg_dst_sel = WrRt;
			wrbck_data_sel = MemData;
    		aluop = ALUop_ADD; end
        SW: begin 
			alu_srcb_sel = SrcbImm;
			mem_we = 1;
    		aluop = ALUop_ADD; end
        BEQ: begin 
			is_beq = 1; 
			aluop = ALUop_SUB; end
        J: begin 
			jmp = 1; 
    		aluop = ALUop_ADD; end
        ADDI: begin 
			alu_srcb_sel = SrcbImm;
			reg_we = 1;
    		aluop = ALUop_ADD; end
        ADDIU: begin 
			alu_srcb_sel = SrcbImm;
			reg_we = 1;
			aluop = ALUop_ADDU; end
        default:;
    endcase
end
	
endmodule