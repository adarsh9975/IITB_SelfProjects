// Code your design here
module booth_datapath(LoadOperands,Reset,Shift,Clk,Mplr,Mcnd,Add,Sub,ConcatRegState);

parameter MULTIPLICAND_SIZE = 4;
parameter MULTIPLIER_SIZE = 4;
localparam ACCUMULATOR_SIZE = MULTIPLICAND_SIZE;

input [MULTIPLIER_SIZE-1 : 0] Mplr;
input [MULTIPLICAND_SIZE-1 : 0] Mcnd;
input LoadOperands;
input Reset;
input Shift;
input Clk;
input Add;
input Sub;
output [MULTIPLIER_SIZE + MULTIPLICAND_SIZE : 0]ConcatRegState; /* Did not do -1 in index delibrately*/
reg [MULTIPLIER_SIZE + MULTIPLICAND_SIZE : 0]ConcatRegState;
reg [ACCUMULATOR_SIZE-1 : 0] Accumulator;
reg [MULTIPLICAND_SIZE-1 : 0] Multiplicand;
reg [MULTIPLIER_SIZE-1 : 0] Multiplier;
reg MplrOld = 0;

assign ConcatRegState = {Accumulator,Multiplier,MplrOld}; 
  
  always @ (Reset,LoadOperands,Add,Sub,Shift)
begin
	if (Reset == 1'b1)
	begin
		Accumulator <= {ACCUMULATOR_SIZE{1'b0}};
		Multiplicand <= {MULTIPLICAND_SIZE{1'b0}};
		Multiplier <= {MULTIPLIER_SIZE{1'b0}};
		MplrOld <= 1'b0;
	end
	else if (LoadOperands == 1'b1)
	begin
		Multiplicand <= Mcnd;
		Multiplier <= Mplr;
	end
	else if (Add == 1'b1)
		Accumulator <= Accumulator + Multiplicand;
	else if (Sub == 1'b1)
		Accumulator <= Accumulator + ((~ Multiplicand) +1'b1);
	else if (Shift == 1'b1)
	begin
		/*Arithmetic right shift of Accumulator*/
      Accumulator <= {Accumulator[ACCUMULATOR_SIZE-1],Accumulator[ACCUMULATOR_SIZE-1 : 1]};
		Multiplier[MULTIPLIER_SIZE-1] <= Accumulator[0];
		Multiplier [MULTIPLIER_SIZE-2 : 0] <= Multiplier [MULTIPLIER_SIZE-1 : 1];
		MplrOld <= Multiplier[0];
	end	
end
endmodule

module booth_controller(LoadOperands,Reset,Shift,Clk,Add,Sub,Mplr2LSB,Start,done);

parameter MULTIPLIER_SIZE = 4;

output LoadOperands;
output Reset;
output Shift;
output Add;
output Sub;
output done;
input [1:0] Mplr2LSB;
reg LoadOperands;
reg Reset;
reg Shift;
reg Add;
reg Sub;
//reg Mplr2LSB;
reg done;
input Clk;
input Start;
integer InternalState = 0;
integer counter = MULTIPLIER_SIZE; 

  always @ (posedge Clk)
begin
	
  if (counter > 1'b0)
	begin
		
		case (InternalState)
		0: /*Reset state*/
		begin
          	if (Start == 1'b1)
            begin
				InternalState <= 1; /*LoadOperands state*/
                Reset <= 1'b1;
                done <= 1'b0;
            end
			 
			LoadOperands <= 1'b0;
			Shift <= 1'b0;
			Add <= 1'b0;
			Sub	<= 1'b0;
			counter <= MULTIPLIER_SIZE;
		end
		
		1: /*LoadOperands state*/
		begin
			InternalState <= 5; /*Branch state*/
			Reset <= 1'b0; 
			LoadOperands <= 1'b1;
			Shift <= 1'b0;
			Add <= 1'b0;
			Sub	<= 1'b0;  
		end
		
		2: /*Add state*/
		begin
			Reset <= 1'b0; 
			LoadOperands <= 1'b0;
			Shift <= 1'b0;
			Add <= 1'b1;
			Sub	<= 1'b0;  
			InternalState <= 4;	/*Shift state*/
		end
		3: /*Sub state*/
		begin
			Reset <= 1'b0; 
			LoadOperands <= 1'b0;
			Shift <= 1'b0;
			Add <= 1'b0;
			Sub	<= 1'b1;  
			InternalState <= 4;  /*Shift state*/
		end
		4: /*Shift state*/
		begin
			Reset <= 1'b0; 
			LoadOperands <= 1'b0;
			Shift <= 1'b1;
			Add <= 1'b0;
			Sub	<= 1'b0;  
			InternalState <= 5;  /*Branch state*/
			counter <= counter - 1;
		end
		5: /*Branch state*/
		begin
            Reset <= 1'b0; 
			LoadOperands <= 1'b0;
			Shift <= 1'b0;
			Add <= 1'b0;
			Sub	<= 1'b0;
			if (Mplr2LSB == 2'b10)
				InternalState <= 3; /*Sub state*/
			else if (Mplr2LSB == 2'b01)
				InternalState <= 2; /*Add state*/
			else
				InternalState <= 4; /*Shift state*/
		end
		default: 
			InternalState <= 0;
	endcase
				
	end
	else
      begin
		done <= 1'b1;
  		InternalState <= 0;
        counter <= MULTIPLIER_SIZE;
      end
  		
			
end
	
endmodule

module booth_top (Start, Mplr, Mcnd, Clk, Result,done);

	parameter MULTIPLICAND_SIZE = 4;
	parameter MULTIPLIER_SIZE = 4;
	localparam RESULT_SIZE = MULTIPLICAND_SIZE + MULTIPLIER_SIZE;
	
	input Start;
	input [MULTIPLIER_SIZE-1 : 0] Mplr; 
	input [MULTIPLICAND_SIZE-1 : 0] Mcnd;
	input Clk; 
	output [RESULT_SIZE-1 : 0] Result;
	output done;
	
	wire LoadOperands;
	wire Reset; 
	wire Shift;
	wire Add;
	wire Sub;
    wire [MULTIPLIER_SIZE + MULTIPLICAND_SIZE : 0] ConcatRegState;
	
	booth_datapath #(.MULTIPLICAND_SIZE(MULTIPLICAND_SIZE), .MULTIPLIER_SIZE(MULTIPLIER_SIZE)) boda (LoadOperands,Reset,Shift,Clk,Mplr,Mcnd,Add,Sub,ConcatRegState);
	booth_controller #(.MULTIPLIER_SIZE(MULTIPLIER_SIZE)) boctrl (LoadOperands,Reset,Shift,Clk,Add,Sub,ConcatRegState[1:0],Start,done);
  
  assign Result = ConcatRegState[MULTIPLIER_SIZE + MULTIPLICAND_SIZE : 1];
	
endmodule

// Code your testbench here
// or browse Examples
module boothTB ();
	
	wire [7:0]Result;
	wire done;
	reg Start;
	reg [3 : 0]Mplr;
	reg [3 : 0]Mcnd;
	reg Clk=0;
	
	always #10 Clk = ~ Clk;

	initial
	begin
      $dumpvars();
	
		Mplr = 4'b1001;
		Mcnd = 4'b1011;
		#400;
		Mplr = 4'b1010;
		Mcnd = 4'b0011;
		#400;
		Mplr = 4'b0011 ;
		Mcnd = 4'b1010; 
		#400;
		Mplr = 4'b0011 ;
		Mcnd = 4'b0010;
		#1000;
      $finish;
		
	end
	
	initial
	begin
		Start = 1'b0;
		#10;
		Start = 1'b1;
		#10;
		Start = 1'b0;
      	#400;
      	Start = 1'b0;
		#10;
		Start = 1'b1;
		#10;
		Start = 1'b0;
      	#400;
      	Start = 1'b0;
		#10;
		Start = 1'b1;
		#10;
		Start = 1'b0;
      	#400;
      	Start = 1'b0;
		#10;
		Start = 1'b1;
		#10;
		Start = 1'b0;
      	#400;
		
	end
	
	booth_top #(.MULTIPLICAND_SIZE(4),.MULTIPLIER_SIZE(4)) dut (Start, Mplr, Mcnd, Clk, Result,done);
	
endmodule	