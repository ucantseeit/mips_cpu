`timescale 1ns / 1ps


module tb_cpu;
	typedef enum int { SingleCyc, MultiCyc, Pipeline } CpuType;
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
            initial $readmemh("test_programs/basic_nohazard.hex", dut.i_ram.mem);
        end else begin : cpu_inst
            single_cycle_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/basic_nohazard.hex", dut.instr_ram.mem);
        end
    endgenerate

    initial begin
        $display("Starting CPU test with file-based memory...");

        clk = 0;
        reset = 1;
        wait_cycles(2);
        reset = 0;

		if (ct == MultiCyc)
			wait_cycles(50);
		else if (ct == Pipeline)
			wait_cycles(30);
		else
    	    wait_cycles(20);

		assert (regs[8]  == 32'h8) else $error("Error: $t0 ($8) should be 0x8, got %0h", regs[8]); 
		assert (regs[9]  == 32'h7) else $error("Error: $t1 ($9) should be 0x7, got %0h", regs[9]);
		assert (regs[10]  == 32'hF) else $error("Error: $t2 ($8) should be 0xF, got %0h", regs[8]); 
		assert (regs[11]  == 32'h1) else $error("Error: $t3 ($8) should be 0x1, got %0h", regs[8]); 

		$display("reach basic test end!");
		$finish;
    end
endmodule