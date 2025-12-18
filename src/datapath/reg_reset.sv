module reg_reset (
	input logic clk, reset,
	input logic [31:0] d,
	output logic [31:0] q
);
	always_ff @(posedge clk) begin 
		if (reset) q <= 32'h00000000;
		else 	   q <= d;
	end
	
endmodule


