module ALU(input1,input2,oper,result,overflow,underflow,exception);

input [31:0]input1,input2;
input [1:0]oper;
output [31:0] result;
output overflow,underflow,exception;

wire overflowadd_sub,overflowmul,overflowdiv,underflowadd_sub,underflowmul,underflowdiv,tpt1_excep,tpt1_over,tpt1_under;
wire exceptionadd_sub,exceptionmul,exceptiondiv;
wire [31:0] resultadd_sub,resultmul,resultdiv,tempresult,result1;

add_sub ab(.input1(input1),.input2(input2),.sub(|(oper[1:0])),.opt(resultadd_sub[31:0]),.overflow(overflowadd_sub),.underflow(underflowadd_sub),.exception(exceptionadd_sub));
multi mul(.input1(input1),.input2(input2),.opt(resultmul[31:0]),.overflow(overflowmul),.underflow(underflowmul),.exception(exceptionmul));
divider div(.input1(input1),.input2(input2),.opt(resultdiv[31:0]),.overflow(overflowdiv),.underflow(underflowdiv),.exception(exceptiondiv));

assign tempresult[31:0] = (oper[1]) ? resultmul[31:0] : resultadd_sub[31:0];
assign result1[31:0] = (&(oper[1:0])) ? resultdiv[31:0] : tempresult[31:0];

assign tpt1_over = (oper[1]) ? overflowmul:overflowadd_sub;
assign tpt1_under = (oper[1]) ? underflowmul:underflowadd_sub;
assign tpt1_excep = (oper[1]) ? exceptionmul:exceptionadd_sub;

assign overflow = (&(oper[1:0])) ? overflowdiv:tpt1_over;
assign underflow = (&(oper[1:0])) ? underflowdiv:tpt1_under;
assign exception = (&(oper[1:0])) ? exceptiondiv:tpt1_excep;

assign result[31:0] = (overflow) ? {result1[31],31'b11111111_00000000000000000000000} : (underflow) ? {result1[31],31'b00000000_00000000000000000000000} : (exception) ? {result1[31],31'b11111111_11111111111111111111111} : result1[31:0];

endmodule



module add_sub(input1,input2,sub,opt,overflow,underflow,exception);

input [31:0]input1,input2;
input sub;
output overflow,underflow,exception;
output [31:0]opt;

wire opr,sign,rcarry,ecarry;
wire one_lsthan_two,redand1,redand2,redor1,redor2;
wire [7:0]tmpexpdff,oneaddedE,newE,cmp_tempexpdff,expdff,E,cmp_I2,shiftcmp;
wire [7:0]finalE;
wire [22:0]finalM;
wire [4:0]shiftE;
wire [23:0] M1,M2,cmp_M2,CMP_rslt,M_result,M_result2,new_M2;



//if all the bits of exponent are 1 that means invalid input and exception is raised.
assign redand1 = &(input1[30:23]);
assign redand2 = &(input2[30:23]);
assign exception = redand1 | redand2;


//it identifies whether all the bits are zero if all are zero then denormalised number.
assign redor1 = |(input1[30:23]);
assign redor2 = |(input2[30:23]);


//EX1-EX2 and finding which is greater also 2s complementing the found result if it is negative in order to find difference.
assign  cmp_I2[7:0] = ~(input2[30:23]);
assign {one_gtthan_two,tmpexpdff[7:0]} = input1[30:23] + cmp_I2[7:0] + 8'b00000001;
assign cmp_tempexpdff = ~(tmpexpdff[7:0]) + 8'b00000001;

//selecting the difference based on mod(E1-E2) and selecting the bigger Exponent
assign expdff[7:0] = (one_gtthan_two) ? tmpexpdff[7:0] : cmp_tempexpdff[7:0];
assign E[7:0] = (one_gtthan_two) ? input1[30:23] : input2[30:23];

//adding the implied bit and shifting the mantissa
assign M1 = (one_gtthan_two) ? {redor1,input1[22:0]} : {redor2,input1[22:0]} >> expdff;
assign M2 = (one_gtthan_two) ? {redor2,input2[22:0]} >> expdff : {redor2,input2[22:0]};

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
assign {ecarry,finalE[7:0]} = newE[7:0] + shiftcmp[7:0] + 8'b00000001;

//final outputs
assign opt[31:0] = {sign,finalE[7:0],finalM[22:0]};
assign underflow = ~(ecarry);
assign overflow = (&(oneaddedE) & ~(|shiftE)); 


endmodule



module multi(input1,input2,opt,overflow,underflow,exception);

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
assign redand2 = &(input2[30:23]);
assign exception = redand1 | redand2;

//it identifies whether all the bits are zero if all are zero then denormalised number.
assign redor1 = |(input1[30:23]);
assign redor2 = |(input2[30:23]);

//sign bit for final result
assign sign = input1[31] ^ input2[31];

//ALU 
multiplier mult(.a({redor1,input1[22:0]}),.b({redor2,input2[22:0]}),.opt(Mulresult[47:0]));

//Roundoff calculation
assign mul1rd = |(Mulresult[22:0]);
assign mul2rd = |(Mulresult[23:0]);
assign finalround = (Mulresult[47]) ? mul2rd : mul1rd;

//normalising and adding the roundoff value
assign normalizedresult = (Mulresult[47]) ? Mulresult[46:24] : Mulresult[45:23];
assign finalM = normalizedresult[22:0] + finalround;

//adding E1 and E2 and subtracting 127 bias
assign sumE[8:0] = {1'b0,input1[30:23]} + {1'b0,input2[30:23]};
assign {carryE,finalE} = sumE[8:0] + 9'b110000001 + Mulresult[47];

//final outputs
assign opt[31:0] = {sign,finalE[7:0],finalM[22:0]};
assign underflow = ~(carryE);
assign overflow = carryE & finalE[8];

endmodule

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

module multiplier(input [23:0] a,input [23:0] b,output [47:0]opt);
	assign opt = a*b;
endmodule

module divid(input [47:0] a,input [23:0] b,output [24:0]opt);
	wire [47:0] div_temp;
	assign div_temp = a/b;
	assign opt = div_temp[24:0];
endmodule


module normalizefunc(
					input[23:0] M_result,
					input cin,
					input opr,
					output reg [22:0] opt,
					output reg [4:0] shift
					);
			
reg [23:0] M_temp;
			
always @(*)
begin
	if(cin & !opr)
	begin
		opt = M_result[23:1] + {22'b0,M_result[0]};
		shift = 5'd0;
	end
	else
	begin
		casex(M_result)
			24'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx:
			begin
				opt = M_result[22:0];
				shift = 5'd0;
			end
			24'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 1;
				opt = M_temp[22:0];
				shift = 5'd1;
			end
			24'b001x_xxxx_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 2;
				opt = M_temp[22:0];
				shift = 5'd2;
			end			
			24'b0001_xxxx_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 3;
				opt = M_temp[22:0];
				shift = 5'd3;
			end			
			24'b0000_1xxx_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 4;
				opt = M_temp[22:0];
				shift = 5'd4;
			end			
			24'b0000_01xx_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 5;
				opt = M_temp[22:0];
				shift = 5'd5;
			end			
			24'b0000_001x_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 6;
				opt = M_temp[22:0];
				shift = 5'd6;
			end			
			24'b0000_0001_xxxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 7;
				opt = M_temp[22:0];
				shift = 5'd7;
			end			
			24'b0000_0000_1xxx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 8;
				opt = M_temp[22:0];
				shift = 5'd8;
			end			
			24'b0000_0000_01xx_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 9;
				opt = M_temp[22:0];
				shift = 5'd9;
			end			
			24'b0000_0000_001x_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 10;
				opt = M_temp[22:0];
				shift = 5'd10;
			end			
			24'b0000_0000_0001_xxxx_xxxx_xxxx:
			begin
				M_temp = M_result << 11;
				opt = M_temp[22:0];
				shift = 5'd11;
			end			
			24'b0000_0000_0000_1xxx_xxxx_xxxx:
			begin
				M_temp = M_result << 12;
				opt = M_temp[22:0];
				shift = 5'd12;
			end			
			24'b0000_0000_0000_01xx_xxxx_xxxx:
			begin
				M_temp = M_result << 13;
				opt = M_temp[22:0];
				shift = 5'd13;
			end			
			24'b0000_0000_0000_001x_xxxx_xxxx:
			begin
				M_temp = M_result << 14;
				opt = M_temp[22:0];
				shift = 5'd14;
			end			
			24'b0000_0000_0000_0001_xxxx_xxxx:
			begin
				M_temp = M_result << 15;
				opt = M_temp[22:0];
				shift = 5'd15;
			end			
			24'b0000_0000_0000_0000_1xxx_xxxx:
			begin
				M_temp = M_result << 16;
				opt = M_temp[22:0];
				shift = 5'd16;
			end			
			24'b0000_0000_0000_0000_01xx_xxxx:
			begin
				M_temp = M_result << 17;
				opt = M_temp[22:0];
				shift = 5'd17;
			end			
			24'b0000_0000_0000_0000_001x_xxxx:
			begin
				M_temp = M_result << 18;
				opt = M_temp[22:0];
				shift = 5'd18;
			end			
			24'b0000_0000_0000_0001_0001_xxxx:
			begin
				M_temp = M_result << 19;
				opt = M_temp[22:0];
				shift = 5'd19;
			end			
			24'b0000_0000_0000_0000_0000_1xxx:
			begin
				M_temp = M_result << 20;
				opt = M_temp[22:0];
				shift = 5'd20;
			end			
			24'b0000_0000_0000_0000_0000_01xx:
			begin
				M_temp = M_result << 21;
				opt = M_temp[22:0];
				shift = 5'd21;
			end			
			24'b0000_0000_0000_0000_0000_001x:
			begin
				M_temp = M_result << 22;
				opt = M_temp[22:0];
				shift = 5'd22;
			end			
			24'b0000_0000_0000_0000_0000_0001:
			begin
				M_temp = M_result << 23;
				opt = M_temp[22:0];
				shift = 5'd23;
			end			
			default:
			begin
				opt = 23'b0;
				shift = 5'd0;
			end			
		endcase	
	end
end
endmodule
