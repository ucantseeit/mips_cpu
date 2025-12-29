module pipeline_cpu #(
    parameter int MEM_DEPTH = 1024
) (
	input logic clk,
	input logic reset,

	output logic [31:0] regs_debug [0:31],
    output logic [31:0] pc_debug,
    output logic [31:0] instr_debug
);

import SinglecycCtrl::*;
import PipelineHazardCtrl::*;

logic [31:0] instr_decode;
logic [4:0] rs_exe;
logic [4:0] rt_exe;
logic [4:0] wreg_dst_dm;
logic [4:0] wreg_dst_wrbck;
logic wreg_data_sel_exe;
logic reg_we_dm;
logic reg_we_wrbck;
logic [1:0] forward_srca_sel_exe;
logic [1:0] forward_srcb_sel_exe;

logic is_beq;
logic reg_we_exe;
logic wreg_data_sel_dm;
logic [4:0] wreg_dst_exe;

logic stall_fetch;
logic stall_decode;
logic clear_exe;
pipeline_hazard_unit i_hu(
	instr_decode[25:21],
	instr_decode[20:16],
	rs_exe,
	rt_exe,
	wreg_data_sel_exe,
	wreg_dst_dm,
	wreg_dst_wrbck,
	reg_we_dm,
	reg_we_wrbck,

	is_beq,
	reg_we_exe,
	wreg_dst_exe,
	wreg_data_sel_dm,

	stall_fetch,
	stall_decode,
	clear_exe,
	forward_srca_sel_exe,
	forward_srcb_sel_exe
);

// Fetch
logic [31:0] next_pc, pc;
always_ff @( posedge clk ) begin 
	if (reset) pc <= 32'b0;
	else if (stall_fetch) ;
	else pc <= next_pc;
end

logic [31:0] instr;
rom #(MEM_DEPTH) 
	instr_ram(.addr(pc), .data(instr));

logic [31:0] pc_plus4;
assign pc_plus4 = pc + 32'b100;

// logic [31:0] instr_decode;
logic [31:0] pc_plus4_decode;
logic clear_decode;
always_ff @( posedge clk ) begin
	if (clear_decode) begin
		{instr_decode, pc_plus4_decode} = 0;
	end
	else if (stall_decode) ;
	else begin
		instr_decode <= instr;
		pc_plus4_decode <= pc_plus4;
	end
end

assign pc_debug = pc;
assign instr_debug = instr;



// Decode
logic wreg_dst_sel, reg_we, alu_srcb_sel, 
	  mem_we, wreg_data_sel, 
	//   is_beq, 
	  is_jmp;
logic [3:0] aluop;
singlecyc_mcu i_mcu(
	instr_decode[31:26],  
	alu_srcb_sel,  
	mem_we, 
	reg_we, 
	wreg_dst_sel, 
	wreg_data_sel, 
	is_beq, is_jmp, 
	aluop
);

logic [3:0] alu_ctrl;
alu_cu i_alu_cu(aluop, instr_decode[5:0], alu_ctrl);

logic [31:0] r_data1;
logic [31:0] r_data2;
logic [31:0] wrbck_data;
// logic [4:0]  wreg_dst_wrbck;
reg_file i_reg_file(.clk(clk), 				   
					.we(reg_we_wrbck), 
					.r_reg1(instr_decode[25:21]), 
					.r_reg2(instr_decode[20:16]), 
					.w_reg(wreg_dst_wrbck), 		   
					.w_data(wrbck_data), 
					.r_data1(r_data1), 	   
					.r_data2(r_data2),
					.regs_debug(regs_debug));
// wrbck->decode forward
logic [31:0] r_data1_decode;
logic [31:0] r_data2_decode;
always_comb begin 
	if (reg_we_wrbck && wreg_dst_wrbck == instr_decode[25:21])
		r_data1_decode = wrbck_data;
	else  r_data1_decode = r_data1;
	if (reg_we_wrbck && wreg_dst_wrbck == instr_decode[20:16])
		r_data2_decode = wrbck_data;
	else  r_data2_decode = r_data2;
end

logic [31:0] sign_imm_decode;
assign sign_imm_decode = $signed(instr_decode[15:0]);

// branch & jump logic
logic [31:0] pc_branch;
assign pc_branch = $signed({instr_decode[15:0], 2'b00}) + pc_plus4_decode;
// branch forward
logic take_beq;
logic [31:0] forward_rdata1;
logic [31:0] forward_rdata2;
logic is_forward_rdata1, is_forward_rdata2;
// logic wreg_data_sel_dm;
assign is_forward_rdata1 = reg_we_dm && 
						   (wreg_data_sel_dm == MemData) &&
						   (wreg_dst_dm == instr_decode[25:21]);
assign is_forward_rdata2 = reg_we_dm && 
						   (wreg_data_sel_dm == MemData) &&
						   (wreg_dst_dm == instr_decode[20:16]);
assign take_beq = is_beq && (r_data1 == r_data2);
// jump logic
logic [31:0] jmp_pc;
assign jmp_pc = {pc_plus4[31:28], instr_decode[25:0], 2'b0};
// set next_pc
always_comb begin
	if (is_jmp)	next_pc = jmp_pc;
	else if (take_beq) next_pc = pc_branch;
	else next_pc = pc_plus4;
end
// set clear_decode
assign clear_decode = is_jmp || take_beq;




logic [31:0] r_data1_exe;
logic [31:0] r_data2_exe;
// logic [4:0]  rs_exe;
// logic [4:0]  rt_exe;
logic [4:0]  rd_exe;
logic [31:0] sign_imm_exe;
logic [31:0] instr_exe;
always_ff @( posedge clk ) begin 
	if (clear_exe)
		{
			r_data1_exe, r_data2_exe,
			rs_exe, rt_exe,
			rd_exe, sign_imm_exe, 
			instr_exe
		} = 0;
	else begin
		r_data1_exe <= r_data1_decode;
		r_data2_exe <= r_data2_decode;
		rs_exe <= instr_decode[25:21];
		rt_exe <= instr_decode[20:16];
		rd_exe <= instr_decode[15:11];	
		sign_imm_exe <= sign_imm_decode;
		instr_exe <= instr_decode;
	end
end

logic alu_srcb_sel_exe, 
	mem_we_exe, 
	// reg_we_exe, 
	wreg_dst_sel_exe, 
	// wreg_data_sel_exe, 
	is_beq_exe, is_jmp_exe;
logic [3:0] alu_ctrl_exe;
always_ff @( posedge clk ) begin 
	if (clear_exe) 
		{
			alu_srcb_sel_exe,
			mem_we_exe, reg_we_exe, 
			wreg_dst_sel_exe, wreg_data_sel_exe,
			is_beq_exe, is_jmp_exe, alu_ctrl_exe
		} <= 0;
	else begin
		alu_srcb_sel_exe <= alu_srcb_sel;
		mem_we_exe <= mem_we;
		reg_we_exe <= reg_we;
		wreg_dst_sel_exe <= wreg_dst_sel;
		wreg_data_sel_exe <= wreg_data_sel;
		is_beq_exe <= is_beq;
		is_jmp_exe <= is_jmp;
		alu_ctrl_exe <= alu_ctrl;
	end
end




// Execute
logic [31:0] alu_res_dm;
logic [31:0] alu_res_wrbck;
logic [31:0] alu_srca_forwarded;
logic [31:0] alu_srcb_forwarded;
always_comb begin 
	case (forward_srca_sel_exe)
		RsExe: alu_srca_forwarded = r_data1_exe;
		ALUoutDm_a: alu_srca_forwarded = alu_res_dm;
		WrbckData_a: alu_srca_forwarded = alu_res_wrbck;
	endcase
end
always_comb begin 
	case (forward_srcb_sel_exe)
		RtExe: alu_srcb_forwarded = r_data2_exe;
		ALUoutDm_b: alu_srcb_forwarded = alu_res_dm;
		WrbckData_b: alu_srcb_forwarded = wrbck_data;
	endcase
end

logic [31:0] b;
always_comb begin 
	case (alu_srcb_sel_exe)
		SrcbRt : b = alu_srcb_forwarded;
		SrcbImm : b = sign_imm_exe;
	endcase
end
logic [31:0] alu_res;
logic eq, overflow;
alu i_alu(
	.a(alu_srca_forwarded), 
	.b(b), 
	.shamt(instr_exe[10:6]),
	.alu_ctrl(alu_ctrl_exe), 
	.c(alu_res), 
	.eq(eq), .overflow(overflow));

// logic [4:0] wreg_dst_exe;
always_comb begin 
	case (wreg_dst_sel_exe)
		WrRt :  wreg_dst_exe = rt_exe;
		WrRd :  wreg_dst_exe = rd_exe;
	endcase
end

logic [31:0] wr_mem_data_exe;
always_comb begin 
	wr_mem_data_exe = alu_srcb_forwarded;
end


// logic [31:0] alu_res_dm;
logic [31:0] wr_mem_data_dm;
// logic [4:0]  wreg_dst_dm;
logic [31:0] pc_branch_dm;
always_ff @( posedge clk ) begin 
	alu_res_dm <= alu_res;
	wr_mem_data_dm <= wr_mem_data_exe;
	wreg_dst_dm <= wreg_dst_exe;
end

logic mem_rd_dm, 
	mem_we_dm, 
	// reg_we_dm, 
	// wreg_data_sel_dm, 
	is_beq_dm, 
	is_jmp_dm;
always_ff @( posedge clk ) begin
	mem_we_dm <= mem_we_exe;
	reg_we_dm <= reg_we_exe;
	wreg_data_sel_dm <= wreg_data_sel_exe;
	is_beq_dm <= is_beq_exe;
	is_jmp_dm <= is_jmp_exe;
end




// Data Memory
logic [31:0] mem_rd_data;
ram #(MEM_DEPTH) data_ram(
	.addr(alu_res_dm), 
	.w_data(wr_mem_data_dm), 
	.clk(clk), 
	.we(mem_we_dm), 
	.data(mem_rd_data));

// logic [31:0] alu_res_wrbck;
logic [31:0] mem_rd_data_wrbck;
always_ff @( posedge clk ) begin
	alu_res_wrbck = alu_res_dm;
	mem_rd_data_wrbck = mem_rd_data;
	wreg_dst_wrbck = wreg_dst_dm;	
end

logic 
	// reg_we_wrbck, 
	wreg_data_sel_wrbck;
always_ff @( posedge clk ) begin
	reg_we_wrbck <= reg_we_dm;
	wreg_data_sel_wrbck <= wreg_data_sel_dm;
end



// Write Back
always_comb begin 
	case (wreg_data_sel_wrbck)
		ALUout: wrbck_data = alu_res_wrbck;
		MemData: wrbck_data = mem_rd_data_wrbck;
	endcase
end




	
endmodule