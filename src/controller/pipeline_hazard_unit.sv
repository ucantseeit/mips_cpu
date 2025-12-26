module  pipeline_hazard_unit (
	input logic [4:0] rs_exe,
	input logic [4:0] rt_exe,
	input logic [4:0] wreg_dst_dm,
	input logic [4:0] wreg_dst_wrbck,
	input logic reg_we_dm,
	input logic reg_we_wrbck,

	output logic [1:0] forward_srca_exe,
	output logic [1:0] forward_srcb_exe
);
	import PipelineHazardCtrl::*;

	always_comb begin 
		if (rs_exe != 0 && 
		    rs_exe == wreg_dst_dm && 
			reg_we_dm)
			forward_srca_exe = ALUoutDm_a;
		else if (rs_exe != 0 && 
				 rs_exe == wreg_dst_wrbck && 
				 reg_we_wrbck)
			forward_srca_exe = ALUoutWrbck_a;
		else forward_srca_exe = RtExe;
	end

	always_comb begin 
		if (rt_exe != 0 && 
		    rt_exe == wreg_dst_dm && 
			reg_we_dm)
			forward_srcb_exe = ALUoutDm_b;
		else if (rt_exe != 0 && 
				 rt_exe == wreg_dst_wrbck && 
				 reg_we_wrbck)
			forward_srcb_exe = ALUoutWrbck_b;
		else forward_srcb_exe = RtExe;
	end

	
endmodule