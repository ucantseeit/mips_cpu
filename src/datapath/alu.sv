// 带符号和无符号加减法用同一个adder
// 比较运算通过比较器实现
// 乘法器和除法器独立于ALU存在
// 有趣的是，没有"非"等一系列常见操作，因为可以用其它的实现
// tradeoff: mcu复杂度和alu_cu复杂度(alu中加入了shifter)


module alu (input logic [31:0] a, b,
			input logic [4:0] shamt,
            input logic [3:0] alu_ctrl,
			input logic is_mul,
			
            output logic [31:0] c,
            output logic eq, lt, overflow);

// 以下是alu_ctrl码
localparam ALU_ADD  = 4'b0000;
localparam ALU_ADDU = 4'b0001;
localparam ALU_SUB  = 4'b0010;
localparam ALU_SUBU = 4'b0011;

localparam ALU_AND  = 4'b0100;
localparam ALU_OR   = 4'b0101;
localparam ALU_XOR  = 4'b0110;
localparam ALU_NOR  = 4'b0111;

localparam ALU_SLT  = 4'b1000;
localparam ALU_SLTU = 4'b1001;

localparam ALU_SLL  = 4'b1010;
localparam ALU_SLLV = 4'b1011;
localparam ALU_SRL  = 4'b1100;
localparam ALU_SRLV = 4'b1101;
localparam ALU_SRA  = 4'b1110;
localparam ALU_SRAV = 4'b1111;


// circuits for adder (ADD/SUB/ADDU/SUBU)
logic is_sub, adder_cin;
assign is_sub    = (alu_ctrl == ALU_SUB) || (alu_ctrl == ALU_SUBU);
assign adder_cin = is_sub ? 1'b1 : 1'b0;

logic [31:0] adder_b;
assign adder_b = is_sub ? ~b : b;

logic [31:0] adder_sum;
adder i_adder(
.a(a), .b(adder_b),
.cin(adder_cin), .sum(adder_sum));

logic signed_overflow;
assign signed_overflow = (a[31] == b[31]) && (a[31] != adder_sum[31]);


// circuits for comparator
logic cmp_is_signed;
assign cmp_is_signed = (alu_ctrl == ALU_SLT || alu_ctrl == ALU_SUB);
logic cmp_lt;
comparator i_comparator(
.a(a), .b(b), .is_signed(cmp_is_signed), .lt(cmp_lt)
);
assign lt = cmp_lt;

// for beq
assign eq = (adder_sum == 32'b0);

always_comb begin
    overflow = 1'b0;	// 默认赋值，预防latch推断

	if (is_mul)		c = a * b;
	else begin
		case (alu_ctrl)
			ALU_ADD:  begin
				c        = adder_sum;
				overflow = signed_overflow;
				end
			ALU_ADDU: c = adder_sum;

			ALU_SUB: begin
				c        = adder_sum;
				overflow = signed_overflow;
			end
			ALU_SUBU: begin
				c        = adder_sum;
			end
			
			ALU_SLT, ALU_SLTU:	c = {31'b0, cmp_lt};

			// 注意移位操作数顺序与其它的都不同
			ALU_SLL : c = b << shamt;
			ALU_SLLV: c = b << a[4:0];
			ALU_SRL : c = b >> shamt;
			ALU_SRLV: c = b >> a[4:0];
			ALU_SRA : c = $signed(b) >>> shamt;
			ALU_SRAV: c = $signed(b) >>> a[4:0];

			ALU_AND : c = a & b;
			ALU_OR  : c = a | b;
			ALU_NOR : c = ~(a | b);
			ALU_XOR : c = a ^ b;

			default : c = 32'b0;
		endcase
	end
end

endmodule
