package Opcodes;
	parameter RR = 6'b00_0000;
	parameter LW = 6'b10_0011;
	parameter SW = 6'b10_1011;
	parameter BEQ = 6'b00_0100;
	parameter J  = 6'b00_0010;

	parameter ADDI  = 6'b00_1000;
	parameter ADDIU = 6'b00_1001;

	parameter ANDI  = 6'b00_1100;
	parameter ORI   = 6'b00_1101;
	parameter XORI  = 6'b00_1110;
	// parameter LUI   = 6'b00_1111;
	// parameter SLTI  = 6'b00_1010;
	// parameter SLTIU  =6'b00_1011;

	// parameter BEQ   = 6'b00_0100;
	// parameter BNE   = 6'b00_0101;
	// parameter BGEZ  = 6'b00_0001;
	// parameter BLTZ  = 6'b00_0001;
	// parameter BLEZ  = 6'b00_0110;
	// parameter BGTZ  = 6'b00_0111;
endpackage

package ALUops;
	typedef enum logic [3:0] {
		ALUop_ADD, ALUop_SUB,
		ALUop_ADDU, 
		ALUop_AND, ALUop_OR,
		ALUop_XOR, ALUop_RR
	} ALUop_t;
endpackage

package SinglecycCtrl;
	typedef enum logic { SrcbRt, SrcbImm } alu_srcb_sel_t;
	typedef enum logic { WrRt, WrRd } wreg_dst_sel_t;
	typedef enum logic { ALUout, MemData } wrbck_data_sel_t;
endpackage

package MultcycCtrl;
	typedef enum logic {AddrPC, AddrALUout} mem_addr_sel_t;
	typedef enum logic {SrcaPC, SrcaRs} alu_srca_sel_t;
	typedef enum logic [1:0] {
		SrcbRt, Four, SrcbImm, BeqImm
	} alu_srcb_sel_t;
	typedef enum logic {WrRt, WrRd} wreg_dst_sel_t;
	typedef enum logic {ALUout, MemData} wrbck_data_sel_t;
	typedef enum logic [1:0] { PCPlus4, PCBranch, PCJmp } nxt_pc_sel;

	typedef enum logic [3:0] {
		Fetch, Decode, MemAddr, MemRd, 
		MemWrbck, MemWr, RRExec, RRWrbck, Beq, Jmp,
		RIExec, RIWrbck
	} state_type;	
endpackage

package PipelineHazardCtrl;
	typedef enum logic [1:0] { 
		RsExe, ALUoutDm_a, WrbckData_a
	 } forward_srca_sel_exe_t;

	typedef enum logic [1:0] { 
		RtExe, ALUoutDm_b, WrbckData_b
	 } forward_srcb_sel_exe_t;
endpackage
