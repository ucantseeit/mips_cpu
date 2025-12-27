module  pipeline_hazard_unit (
	input logic [4:0] rs_decode,
	input logic [4:0] rt_decode,
	input logic [4:0] rs_exe,
	input logic [4:0] rt_exe,
	input logic wrbck_data_sel_exe,
	input logic [4:0] wreg_dst_dm,
	input logic [4:0] wreg_dst_wrbck,
	input logic reg_we_dm,
	input logic reg_we_wrbck,

	output logic stall_fetch,
	output logic stall_decode,
	output logic clear_exe,
	output logic [1:0] forward_srca_sel_exe,
	output logic [1:0] forward_srcb_sel_exe
);
	import PipelineHazardCtrl::*;
	import SinglecycCtrl::*;

	// forward logic
	always_comb begin 
		if (rs_exe != 0 && 
		    rs_exe == wreg_dst_dm && 
			reg_we_dm)
			forward_srca_sel_exe = ALUoutDm_a;
		else if (rs_exe != 0 && 
				 rs_exe == wreg_dst_wrbck && 
				 reg_we_wrbck)
			forward_srca_sel_exe = WrbckData_a;
		else forward_srca_sel_exe = RtExe;
	end

	always_comb begin 
		if (rt_exe != 0 && 
		    rt_exe == wreg_dst_dm && 
			reg_we_dm)
			forward_srcb_sel_exe = ALUoutDm_b;
		else if (rt_exe != 0 && 
				 rt_exe == wreg_dst_wrbck && 
				 reg_we_wrbck)
			forward_srcb_sel_exe = WrbckData_b;
		else forward_srcb_sel_exe = RtExe;
	end

	// stall logic
	logic is_stall;
	assign is_stall = (wrbck_data_sel_exe == MemData) && 
					(rs_decode == rt_exe || rt_decode == rt_exe);
	assign stall_fetch = is_stall;
	assign stall_decode = is_stall;
	assign clear_exe = is_stall;

endmodule