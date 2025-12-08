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
        $display("Starting CPU test with file-based memory...");

        clk = 0;
        reset = 1;
        wait_cycles(2);
        reset = 0;
        wait_cycles(25);  // Run all 22 instructions

		// I-type results
		assert (regs[8]  == 32'h0000000A) else $error("Error: li $t0 = 10 failed: got %0d", regs[8]);      // $t0
		assert (regs[9]  == 32'h00000014) else $error("Error: li $t1 = 20 failed: got %0d", regs[9]);      // $t1
		assert (regs[16] == 32'h00000003) else $error("Error: li $s0 = 3 failed: got %0d", regs[16]);      // $s0
		assert (regs[4]  == 32'h00000003) else $error("Error: li $a0 = 3 failed: got %0d", regs[4]);       // $a0
		assert (regs[5]  == 32'hFFFFFFFF) else $error("Error: li $a1 = -1 failed: got %0d", regs[5]);       // $a1

		// I-type arithmetic
		assert (regs[10] == 32'h0000001E) else $error("Error: addi $t2 = 10+20 failed: got %0d", regs[10]); // $t2
		assert (regs[11] == 32'h00000010) else $error("Error: addi $t3 = 20-4 failed: got %0d", regs[11]);  // $t3
		assert (regs[12] == 32'hFFFFFFF6) else $error("Error: addi (subi) $t4 = 10-20 failed: got %0d", $signed(regs[12])); // $t4

		// R-type ALU
		assert (regs[20] == 32'h0000001E) else $error("Error: add $s4 = 10+20 failed: got %0d", regs[20]);  // $s4
		assert (regs[21] == 32'h0000001E) else $error("Error: addu $s5 = 10+20 failed: got %0d", regs[21]); // $s5
		assert (regs[22] == 32'hFFFFFFF6) else $error("Error: sub $s6 = 10-20 failed: got %0d", $signed(regs[22])); // $s6
		assert (regs[23] == 32'hFFFFFFF6) else $error("Error: subu $s7 = 10-20 failed: got %0d", regs[23]); // $s7

		// slt / sltu
		assert (regs[14] == 32'h00000000) else $error("Error: slt (10<0) failed: got %0d", regs[14]);       // $t6
		assert (regs[15] == 32'h00000000) else $error("Error: sltu (10<0) failed: got %0d", regs[15]);      // $t7
		assert (regs[26] == 32'h00000001) else $error("Error: slt (10<20) failed: got %0d", regs[26]);      // $k0
		assert (regs[27] == 32'h00000001) else $error("Error: sltu (3<0xFFFFFFFF) failed: got %0d", regs[27]); // $k1

		// Shifts
		assert (regs[17] == 32'h00000050) else $error("Error: sll $s1 = 10<<3 failed: got %0d", regs[17]);  // $s1 = 80
		assert (regs[18] == 32'h00000001) else $error("Error: srl $s2 = 3>>1 failed: got %0d", regs[18]);   // $s2 = 1
		assert (regs[19] == 32'h00000001) else $error("Error: sra $s3 = 3>>>1 failed: got %0d", regs[19]);  // $s3 = 1
		assert (regs[2]  == 32'h00000050) else $error("Error: sllv $v0 = 10<<3 failed: got %0d", regs[2]);  // $v0 = 80
	$finish;
    end
endmodule

