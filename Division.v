module divider(input1,input2,opt,overflow,underflow,exception);

input [31:0]input1,input2;
input sub;
output overflow,underflow,exception;
output [31:0]opt;

wire sign,one_gtthan_two,redand1,redand2,redor1,redor2,nore2;
wire [24:0]divout;
wire [7:0]cmp_I2,exsel;
wire [8:0]temp1,temp2,temp;
wire [7:0]subE;
wire [22:0]finalM;

//if all the bits of exponent are 1 that means invalid input and exception is raised.
assign redand1 = &(input1[30:23]);
assign redand2 = &(input2[30:23]);
assign nore2 = ~(|(input2));
assign exception = redand1 | redand2 | nore2;

//it identifies whether all the bits are zero if all are zero then denormalised number.
assign redor1 = |(input1[30:23]);
assign redor2 = |(input2[30:23]);

//sign bit for final result
assign sign = input1[31] ^ input2[31];

//finding difference of E1 and E2
assign cmp_I2[7:0] = ~(input2[30:23]);
assign {one_gtthan_two,subE} = input1[7:0] + cmp_I2[7:0] + 8'b00000001;

//ALU
divid div(.a({redor1,input1[22:0],24'b0}),.b({redor2,input2[22:0]}),.opt(divout[24:0]));

//calculations for finding final exponent value
  assign temp1[8:0] = (one_gtthan_two) ? {1'b0,subE[7:0]} : ({1'b1,subE[7:0]});
assign finalM[22:0] = (divout[24]) ? divout[23:1] : divout[22:0];
assign temp[8:0] = (divout[24]) ? 9'b001111111 : 9'b001111110;
assign {carryD,temp2[8:0]} = temp[8:0] + temp1[8:0];

//final outputs
assign opt[31:0] = {sign,temp2[7:0],finalM[22:0]};
assign underflow = ~(carryD);
assign overflow = carryD & temp2[8]; 

endmodule
