// alu_ctrl的内容与标准教材略有不同，是我精心设计的
module alu_cu (
	input logic [3:0] aluop,
	input logic [5:0] funct,
	output logic [3:0] alu_ctrl
);

import ALUops::*;

// 以下是RR型的funct码
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
	case (aluop)
		ALUop_ADD: alu_ctrl = ALU_ADD;
		ALUop_SUB: alu_ctrl = ALU_SUB;
		ALUop_ADDU: alu_ctrl = ALU_ADDU;
		ALUop_AND: alu_ctrl = ALU_AND;
		ALUop_OR: alu_ctrl = ALU_OR;
		ALUop_XOR: alu_ctrl = ALU_XOR;
		default: begin
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
	endcase
end
	
endmodule
