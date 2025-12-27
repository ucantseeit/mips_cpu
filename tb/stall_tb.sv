`timescale 1ns / 1ps


// TODO: 为单周期CPU添加更多RI指令，使得支持这个tb
module tb_cpu;
	typedef enum int { SingleCyc, MultiCyc, Pipeline } CpuType;
	localparam CpuType ct = Pipeline;

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
            initial $readmemh("test_programs/stall.hex", dut.i_ram.mem);
        end else if (ct == SingleCyc) begin : cpu_inst
            single_cycle_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/stall.hex", dut.instr_ram.mem);
		end else begin
			pipeline_cpu #(.MEM_DEPTH(MEM_DEPTH)) dut (
                .clk(clk),
                .reset(reset),
                .regs_debug(regs),
                .pc_debug(pc),
                .instr_debug(instr)
            );
            initial $readmemh("test_programs/stall.hex", dut.instr_ram.mem);		
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

		assert (regs[8] == 32'h0000000A) else $error("should get 0xA, but got $t0 = %0d", regs[8]);
		assert (regs[9] == 32'h00000014) else $error("should get 0x14, but got $t1 = %0d", regs[9]);
		assert (regs[10] == 32'h0000000A) else $error("should get 0xA, but got $t2 = %0d", regs[10]);
		assert (regs[11] == 32'h0000001E) else $error("should get 0xA, but got $t3 = %0d", regs[11]);

		$display("reach stall test end!");
	$finish;
    end
endmodule