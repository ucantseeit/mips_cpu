`timescale 1ns / 1ps


module tb_cpu;
	typedef enum int { SingleCyc, MultiCyc, Pipeline } CpuType;
	localparam CpuType ct = MultiCyc;

    localparam int MEM_DEPTH = 1024;
	logic clk, reset;

    always #5 clk = ~clk;
    task wait_cycles(int n);
        repeat (n) @(posedge clk);
    endtask
	
    logic [31:0] regs [0:31];
    
    // 调试信号
    logic [31:0] pc, instr;

    // 只例化一个 DUT —— 使用 generate
    generate
        if (ct == MultiCyc) begin : cpu_inst
            multi_cycle_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/more_instr.hex", dut.i_ram.mem);
        end else begin : cpu_inst
            single_cycle_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/more_instr.hex", dut.instr_ram.mem);
        end
    endgenerate

    initial begin
        $display("Starting CPU test with file-based memory...");

        clk = 0;
        reset = 1;
        wait_cycles(1);
        reset = 0;

		if (ct == MultiCyc)
			wait_cycles(70);
		else
    	    wait_cycles(10);  // Run all 22 instructions

		assert (regs[6] == 32'h0) else $error("Branch test FAILED! $6 = %0h", regs[6]);
		assert (regs[1] == 32'h12340000) else $error("lui error: $1 = %0h", regs[1]);

		$display("reach more instructions test end!");
		$finish;
    end
endmodule