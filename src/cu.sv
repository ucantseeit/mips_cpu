module mcu (
	input logic [5:0] opcode,
	output logic wreg_dst_sel, reg_we, is_alub_imm, 
	mem_rd, mem_wr, wrbck_sel, 
	is_beq, jmp,
	output logic [1:0] aluop
);

localparam RR = 6'b00_0000;
localparam LW = 6'b10_0011;
localparam SW = 6'b10_1011;
localparam BR = 6'b00_0100;
localparam J  = 6'b00_0010;

localparam ADDI  = 6'b00_1000;
localparam ADDIU = 6'b00_1001;
localparam ANDI  = 6'b00_1100;
// localparam LUI   = 6'b00_1111;
// localparam ORI   = 6'b00_1101;
// localparam SLTI  = 6'b00_1010;
// localparam SLTIU = 6'b00_1011;
// localparam XORI  = 6'b00_1110;

localparam BEQ   = 6'b00_0100;

// alu_op: 00是有符号加，01是有符号减，10是无符号加，11是RR型
always_comb begin 
	case (opcode)
		RR : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b11_0000_0011;
		LW : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b01_1101_0000;
		SW : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b00_1010_0000;
		BR : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b00_0000_1001;
		J  : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b00_0000_0100;

		ADDI  : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b01_1000_0000;
		ADDIU : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b01_1000_0010;
		default : {wreg_dst_sel, reg_we, is_alub_imm, mem_rd, mem_wr, wrbck_sel, is_beq, jmp, aluop} = 10'b00_0000_0000;
	endcase
end
	
endmodule




// alu_ctrl的内容与标准教材略有不同，是我精心设计的
module alu_cu (
	input logic [1:0] aluop,
	input logic [5:0] funct,
	output logic [3:0] alu_ctrl
);

// 以下是funct码
localparam ADD  = 6'b10_0000;
localparam ADDU = 6'b10_0001;
localparam SUB  = 6'b10_0010;
localparam SUBU = 6'b10_0011;

localparam AND  = 6'b10_0100;
localparam OR   = 6'b10_0101;
localparam XOR  = 6'b10_0110;
localparam NOR  = 6'b10_0111;

// localparam DIV  = 6'b01_1010;
// localparam DIVU = 6'b01_1011;
// localparam MULT = 6'b01_1000;
// localparam MULTU= 6'b01_1001;
localparam SLT  = 6'b10_1010;
localparam SLTU = 6'b10_1011;


localparam SLL  = 6'b00_0000;
localparam SLLV = 6'b00_0100;
localparam SRA  = 6'b00_0011;
localparam SRAV = 6'b00_0111;
localparam SRL  = 6'b00_0010;
localparam SRLV = 6'b00_0110;

// 以下是alu_ctrl码
localparam ALU_ADD  = 4'b0000;
localparam ALU_ADDU = 4'b0001;
localparam ALU_SUB  = 4'b0010;
localparam ALU_SUBU = 4'b0011;

localparam ALU_AND  = 4'b0100;
localparam ALU_OR   = 4'b0101;
localparam ALU_XOR  = 4'b0110;
localparam ALU_NOR  = 4'b0111;

localparam ALU_SLT  = 4'b1000;
localparam ALU_SLTU = 4'b1001;

localparam ALU_SLL  = 4'b1010;
localparam ALU_SLLV = 4'b1011;
localparam ALU_SRL  = 4'b1100;
localparam ALU_SRLV = 4'b1101;
localparam ALU_SRA  = 4'b1110;
localparam ALU_SRAV = 4'b1111;

always_comb begin 
	if (aluop == 2'b00) alu_ctrl = ALU_ADD;			// 为了LW与SW
	else if (aluop == 2'b01) alu_ctrl = ALU_SUB;	// 为了BEQ
	else if (aluop == 2'b10) alu_ctrl = ALU_ADDU;	// 为了ADDUI
	else begin										// RR型
		case (funct)
			ADD  : alu_ctrl = ALU_ADD;
			ADDU : alu_ctrl = ALU_ADDU;
			SUB  : alu_ctrl = ALU_SUB;
			SUBU : alu_ctrl = ALU_SUBU;
			AND  : alu_ctrl = ALU_AND;
			OR   : alu_ctrl = ALU_OR;
			XOR  : alu_ctrl = ALU_XOR;
			NOR  : alu_ctrl = ALU_NOR;
			SLT  : alu_ctrl = ALU_SLT;
			SLTU : alu_ctrl = ALU_SLTU;

			SLL  : alu_ctrl = ALU_SLL;
			SLLV : alu_ctrl = ALU_SLLV;
			SRL  : alu_ctrl = ALU_SRL;
			SRLV : alu_ctrl = ALU_SRLV;
			SRA  : alu_ctrl = ALU_SRA;
			SRAV : alu_ctrl = ALU_SRAV;
			default: alu_ctrl = 4'b1111;
		endcase
	end
end
	
endmodule
