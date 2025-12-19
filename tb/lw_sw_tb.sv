`timescale 1ns / 1ps


module tb_cpu;
	typedef enum int { SingleCyc, MultiCyc } CpuType;
	localparam CpuType ct = SingleCyc;

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
            initial $readmemh("test_programs/lw_sw.hex", dut.i_ram.mem);
        end else begin : cpu_inst
            single_cycle_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/lw_sw.hex", dut.instr_ram.mem);
        end
    endgenerate

    initial begin
        $display("Starting CPU test with file-based memory...");

        clk = 0;
        reset = 1;
        wait_cycles(2);
        reset = 0;

		if (ct == MultiCyc)
			wait_cycles(110);
		else
    	    wait_cycles(25);  // Run all 22 instructions

		assert (regs[8]  == 32'h1234) else $error("Error: $t0 ($8) should be 0x1234, got %0h", regs[8]);   // $t0 未被修改
		assert (regs[9]  == 32'h1234) else $error("Error: $t1 ($9) should be loaded value 0x1234, got %0h", regs[9]); // $t1 = lw result
		assert (regs[16] == 32'h00000000) else $error("Error: $s0 ($16) should be 0 (sub result), got %0h", regs[16]);     // $s0 = $t0 - $t1 = 0
		assert (regs[2]  == 32'h0000000A) else $error("Error: $v0 ($2) should be 10, got %0h", regs[2]);               // li $v0, 10

		$display("reach lw and sw tests end!");
		$finish;
    end
endmodule
