module add_sub(input1,input2,sub,otp,overflow,underflow,exception);

input [31:0]input1,input2;
input sub;
output overflow,underflow,exception;
output [31:0]opt;

wire opr,sign,rcarry;
wire one_gtthan_two,redand1,redand2,redor1,redor2;
wire [7:0]tmpexpdff,oneaddedE,newE,cmp_tempexpdff,expdff,E,cmp_I2,shiftcmp;
wire [8:0]finalE;
wire [22:0]finalM;
wire [4:0]shiftE;
wire [23:0] M1,M2,cmp_M2,CMP_rslt,M_result,M_result2,new_M2;



//if all the bits of exponent are 1 that means invalid input and exception is raised.
assign redand1 = &(input1[30:23]);
assign redand1 = &(input2[30:23]);
assign exception = redand1 | redand2;


//it identifies whether all the bits are zero if all are zero then denormalised number.
assign redor1 = |(input1[30:23]);
assign redor2 = |(input2[30:23]);


//EX1-EX2 and finding which is greater also 2s complementing the found result if it is negative in order to find difference.
assign  cmp_I2[7:0] = ~(input2[30:23]);
assign {one_gtthan_two,tmpexpdff[7:0]} = input1[30:23] + cmp_I2[7:0] + 8'b00000001;
assign cmp_tempexpdff = ~(tmpexpdff[7:0]) +8'b00000001;

//selecting the difference based on mod(E1-E2) and selecting the bigger Exponent
assign expdff[7:0] = (one_gtthan_two) ? tmpexpdff[7:0] : cmp_tempexpdff[7:0];
assign E[7:0] = (one_gtthan_two) ? input1[30:23] : input2[30:23];

//adding the implied bit and shifting the mantissa
assign M1 = (one_gtthan_two) ? {redor1,input1[22:0]} : {redor2,input2[22:0]} >> expdff;
assign M2 = (one_gtthan_two) ? {redor2,input1[22:0]} >> expdff : {redor2,input2[22:0]};

//signal to 2s complement thi 2nd mantisaa
assign opr = sub ^ input1[31] ^ input2[31];

//ALU unit
assign cmp_M2[23:0] = ~(M2[23:0]);
assign new_M2[23:0] = (opr) ? cmp_M2[23:0] : M2[23:0];
assign {rcarry,M_result[23:0]} = M1[23:0] + new_M2[23:0] + (opr);

//sign bit of final result
assign sign = (rcarry & input1[31]) | (~(opr) & input1[31]) | (~(rcarry) & ~(input1[31]) & opr);

//addition of one in the case of M1+M2 and selecting new exponent if a carry is generated
assign oneaddedE[7:0] = E[7:0] + 8'b00000001;
assign newE[7:0] = (rcarry & ~(opr)) ? oneaddedE[7:0] : E[7:0];

//complementing result and selectiong the correct one
assign CMP_rslt[23:0] = ~(M_result[23:0]);
assign M_result2[23:0] = (opr & ~(rcarry)) ? CMP_rslt[23:0] : M_result[23:0];

//normalize the output
normalizefunc nm(.M_result(M_result2),.cin(rcarry),.opr(opr),.opt(finalM),.shift(shiftE));
assign shiftcmp[7:0] = ~{3'b000,shiftE[4:0]};

//calculation of final shift value
assign finalE[8:0] = newE[7:0] + shiftcmp[7:0] + 8'b000000001;

//final outputs
assign opt[31:0] = {sign,finalE[7:0],finalM[22:0]};
assign underflow = ~(finalE[8]);
assign overflow = (&(oneaddedE) & ~(|shiftE)); 


endmodule



