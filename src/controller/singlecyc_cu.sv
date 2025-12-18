/* 
wreg_dst_sel控制将被写入的寄存器的编号的来源，
	0来自Instr[20:16](Rt)，1来自Instr[15:11](Rd)
wrbck_sel控制将被写入的寄存器的数据的来源
	0来自aluout，1来自内存输出
*/
module singlecyc_mcu (
	input logic [5:0] opcode,
	output logic wreg_dst_sel, reg_we, is_alub_imm, 
	mem_rd, mem_wr, wrbck_sel, 
	is_beq, jmp,
	output logic [1:0] aluop
);

import ALUops::*;
import Opcodes::*;

always_comb begin
    // 默认全0（包括 aluop = ADD）
    {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp} = 8'b0;
    aluop = ALUop_ADD;

    case (opcode)
        RR: begin 
			{wreg_dst_sel, reg_we} = 2'b11; 
			aluop = ALUop_RR;  end
        LW: begin 
			{reg_we, is_alub_imm, mem_rd, wrbck_sel} = 4'b1111; 
    		aluop = ALUop_ADD; end
        SW: begin 
			{is_alub_imm, mem_wr} = 2'b11; 
    		aluop = ALUop_ADD; end
        BR: begin 
			is_beq = 1'b1; 
			aluop = ALUop_SUB; end
        J: begin 
			jmp = 1'b1; 
    		aluop = ALUop_ADD; end
        ADDI: begin 
			{reg_we, is_alub_imm} = 2'b11; 
    		aluop = ALUop_ADD; end
        ADDIU: begin 
			{reg_we, is_alub_imm} = 2'b11; 
			aluop = ALUop_ADDU; end
        default:;
    endcase
end
	
endmodule