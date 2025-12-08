
// 默认是有符号加法Adder
// 可以用于无符号的加减法
module adder (
        input logic [31:0] a, b,
        input logic 	   cin,
        output logic [31:0] sum
    );

assign sum = a + b + {31'b0, cin};


endmodule
