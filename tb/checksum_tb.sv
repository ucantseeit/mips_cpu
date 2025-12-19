`timescale 1ns / 1ps


// TODO: 为单周期CPU添加更多RI指令，使得支持这个tb
module tb_cpu;
	typedef enum int { SingleCyc, MultiCyc } CpuType;
	localparam CpuType ct = MultiCyc;

    localparam int MEM_DEPTH = 2048;
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
            initial $readmemh("test_programs/checksum.hex", dut.i_ram.mem);
        end else begin : cpu_inst
            single_cycle_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/checksum.hex", dut.instr_ram.mem);
        end
    endgenerate

    initial begin
        $display("Starting CPU test with file-based memory...");

        clk = 0;
        reset = 1;
        wait_cycles(2);
        reset = 0;
		if (ct == MultiCyc)
			wait_cycles(300);
		else
    	    wait_cycles(50);  // Run all instructions

		assert (regs[2] == 32'h000000AA) else $error("should get 0xAA, but got $v0 = %0d", regs[2]);

		$display("reach checksum test end!");
		$finish;
    end
endmodule

