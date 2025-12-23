/* 
wreg_dst_sel 控制将被写入的寄存器的编号的来源，
	0来自Instr[20:16](Rt)，1来自Instr[15:11](Rd)
wrbck_data_sel 控制将被写入的寄存器的数据的来源
	0来自aluout，1来自内存输出
*/

// 注意：mcu的控制信号并没有完全列出，需根据书的内容补充
module multicyc_mcu (
	input logic clk, reset, 
	input logic [5:0] opcode,

	output logic mem_addr_sel, ir_we,
	output logic alu_srca_sel, 
	output logic [1:0]alu_srcb_sel, 
	output logic [3:0] aluop, 
	output logic mem_rd, mem_wr, 
				reg_we, pc_we, 
				wreg_dst_sel, wrbck_data_sel
);

import ALUops::*;
import Opcodes::*;
import MultcycCtrl::*;



logic [3:0] curr_state;
logic [3:0] next_state;

always_ff @( posedge clk ) begin
	if (reset) curr_state <= 4'b0000;
	else 	   curr_state <= next_state;
end

always_comb begin 
	{mem_addr_sel, ir_we} = 2'b0;
	{alu_srca_sel, alu_srcb_sel, aluop} = 5'b0;
	{mem_rd, mem_wr, reg_we, pc_we, wreg_dst_sel, wrbck_data_sel} = 6'b0;

	case (curr_state)
		// 状态机的例子
		Fetch: begin
			next_state = Decode;
			mem_addr_sel = AddrPC;
			alu_srca_sel = SrcaPC;
			alu_srcb_sel = Four;
			aluop = ALUop_ADD;
			ir_we = 1;
			pc_we = 1;	end

	endcase
end
	
endmodule
