// 可以读时写的寄存器组
// 时钟在一个周期内是先低后高
/*
理解verilog中的时序赋值模型: 
1. 低电平时，只有组合逻辑推进
2. 当上升沿到来：
	activation(always_comb与assign推进)->
	NBA(寄存器实际赋值，即always_ff)->
	delta(由于寄存器输出端口q的值变化，与之相关的组合逻辑随之变化)
*/	
/*
两个原则确保了一定有意义
	1. 同一个logic端口只会被赋值一次
	2. 时序逻辑中的寄存器不会有回环
*/

module reg_file (
    input logic clk, we,
    input logic [4:0] r_reg1, r_reg2, w_reg,
    input logic [31:0] w_data,
    output logic [31:0] r_data1, r_data2,
    output logic [31:0] regs_debug [0:31]	// iverilog对 logic [31:0] regs_debug [0:31] 基本不支持！
);

logic [31:0] regs [0:31];

assign r_data1 = (r_reg1 == 5'b0) ? 32'b0 : regs[r_reg1];
assign r_data2 = (r_reg2 == 5'b0) ? 32'b0 : regs[r_reg2];
assign regs_debug = regs;

always_ff @(posedge clk) begin 
    // 写入 $zero 寄存器 (reg[0]) 的操作会被忽略
    if (w_reg != 5'b0 && we) regs[w_reg] <= w_data;
end
    
endmodule



module rom #(
    parameter int DEPTH = 1024
) (
    input  logic [31:0] addr,   // byte address
    output logic [31:0] data
);
    logic [31:0] mem [0:DEPTH-1];
	localparam AW = $clog2(DEPTH);
	logic [AW-1:0] mem_addr;
	assign mem_addr = addr[AW+1:2]; 

    assign data = mem[mem_addr];
	
	initial begin
        $readmemh("arith_test.hex", mem);
		$display("ROM[0] = %h", mem[0]);
    	$display("ROM[1] = %h", mem[1]);
    end
endmodule



module ram #(
    parameter DEPTH = 1024
) (
    input  logic [31:0] addr,
    input  logic [31:0] w_data,
    input  logic        clk,
    input  logic        we,
    output logic [31:0] data
);
    logic [31:0] mem [0:DEPTH-1];
	localparam AW = $clog2(DEPTH);
	logic [AW-1:0] mem_addr;
	assign mem_addr = addr[AW+1:2]; 

    always_ff @(posedge clk) begin
        if (we) mem[mem_addr] <= w_data;
    end

    assign data = mem[mem_addr];
endmodule






