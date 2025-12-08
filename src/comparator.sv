module comparator (
	input  logic [31:0] a, b,
	input  logic is_signed,
	output logic lt
);
	// assign eq  = (a == b);
	// assign neq = (a != b);
	assign lt  = is_signed ? ($signed(a) < $signed(b)) : (a < b);
	// assign lte = is_signed ? ($signed(a) <= $signed(b)) : (a <= b);
	// assign gt  = is_signed ? ($signed(a) > $signed(b)) : (a > b);
	// assign gte = is_signed ? ($signed(a) >= $signed(b)) : (a >= b);
	
endmodule