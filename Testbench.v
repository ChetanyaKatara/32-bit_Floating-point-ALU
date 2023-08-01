module test();

reg [31:0]input1,input2;
reg [1:0]oper;

wire [31:0]result;
wire overflow,underflow,exception;

ALU DUT(.input1(input1),.input2(input2),.oper(oper[1:0]),.result(result[31:0]),.overflow(overflow),.underflow(underflow),.exception(exception));

initial 
begin
  input1 = 32'b11000000101100100101000100011010;    // -5.5724
  input2 = 32'b01000011000100010110010100000101;    // 145.3946


		oper = 2'd0; 
        #50;
        $display("Addtion result : %b",result);
		$display("overflow : %b , underflow : %b , exception : %b",overflow,underflow,exception);
        
        oper = 2'd1; #50;

		$display("Subtraction result : %b",result);
		$display("overflow : %b , underflow : %b , exception : %b",overflow,underflow,exception);

        oper = 2'd2; #50;

		$display("Multiplication result : %b",result);
		$display("overflow : %b , underflow : %b , exception : %b",overflow,underflow,exception);

        oper = 2'd3; #50;

		$display("Division result : %b",result);
		$display("overflow : %b , underflow : %b , exception : %b",overflow,underflow,exception);



	end
      
	  initial begin
	  $dumpfile("dumprdr.vcd");
        $dumpvars(0);
    end 
endmodule
