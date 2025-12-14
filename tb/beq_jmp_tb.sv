`timescale 1ns / 1ps
`include "src/single_cycle_cpu.sv"

module tb_cpu;
    localparam int MEM_DEPTH = 256;
	logic clk, reset;
    always #5 clk = ~clk;
    task wait_cycles(int n);
        repeat (n) @(posedge clk);
    endtask
	
    logic [31:0] regs [0:31];
    
    // 调试信号
    logic [31:0] pc, instr;

    single_cycle_cpu #(.MEM_DEPTH(256)) dut (
        .clk(clk),
        .reset(reset),
        .regs_debug(regs),
        .pc_debug(pc),
        .instr_debug(instr)
    );

	initial begin
    	$readmemh("test_programs/beq_jmp.hex", dut.instr_ram.mem);
	end

    initial begin
        $display("Starting CPU test with file-based memory...");

        clk = 0;
        reset = 1;
        wait_cycles(2);
        reset = 0;
        wait_cycles(25);  // Run all 22 instructions

		// 注意, 若执行了j指令, pc值会突然变大(h0000028->h00400030), 但不影响结果
		// 这不是错误，因为mars得到的机械码实际会把零地址放到h00400000, 而我们的iram不够大，自动忽略了高位。
		assert (regs[16] == 32'h0000002A) else $error("beq taken failed: $s0 = %0d", regs[16]);
		assert (regs[17] == 32'h00000058) else $error("beq not-taken failed: $s1 = %0d", regs[17]);
		assert (regs[18] == 32'h0000004D) else $error("j failed: $s2 = %0d", regs[18]);
		assert (regs[19] == 32'h00000000) else $error("error path taken: $s3 should be 0, got %0d", regs[19]);

		$display("reach beq and j tests end!");
		$finish;
    end
endmodule

