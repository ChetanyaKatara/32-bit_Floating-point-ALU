module multi(input1,input2,otp,overflow,underflow,exception);

input [31:0]input1,input2;
input sub;
output overflow,underflow,exception;
output [31:0]opt;

wire [8:0] sumE,finalE;
wire [47:0] Mulresult;
wire [22:0] normalizedresult;
wire [22:0] finalM;
wire sign,redand1,redand2,redor1,redor2,carryE,mul1rd,mul2rd,finalround;

//if all the bits of exponent are 1 that means invalid input and exception is raised.
assign redand1 = &(input1[30:23]);
assign redand1 = &(input2[30:23]);
assign exception = redand1 | redand2;

//it identifies whether all the bits are zero if all are zero then denormalised number.
assign redor1 = |(input1[30:23]);
assign redor2 = |(input2[30:23]);

//sign bit for final result
assign sign = input1[31] ^ input2[31];

//ALU 
multiplier mult(.a{redor1,input1[22:0]},.b{redor2,input2[22:0]},.opt(Mulresult[47:0]));

//Roundoff calculation
assign mul1rd = |(Mulresult[22:0]);
assign mul2rd = |(Mulresult[23:0]);
assign finalround = (Mulresult[47]) ? mul2rd : mul1rd;

assign normalizedresult = (Mulresult[47]) ? Mulresult[46:24] : Mulresult[45:23];
assign finalM = normalizedresult[22:0] + finalround;

assign sumE[8:0] = {1'b0,input1[30:23]} + {1'b0,input2[30:23]};

assign {carryE,finalE} = sumE[8:0] + 9'b110000001 + Mulresult[47];


assign opt[31:0] = {sign,finalE[7:0],finalM[22:0]};
assign underflow = ~(carryE);
assign overflow = carryE & finalE[8];

endmodule


