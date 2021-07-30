// Datapath Module
module GCD_datapath(gt, lt, eqt, ldA, ldB, sel1, sel2, sel_in, data_in, clk);

input ldA,ldB,sel1,sel2,sel_in,clk;
input [15:0] data_in;
output gt,lt,eqt;
wire [15:0] Aout,Bout,x,y,Bus,Subout;

PIPO A(Aout,Bus,ldA,clk);
PIPO B(Bout,Bus,ldB,clk);
MUX mux_in1 (x,Aout,Bout,sel1);
MUX mux_in2 (y,Aout,Bout,sel2);
MUX mux_load (BUS,Subout,data_in,sel_in);
SUB sb(Subout, x, y);
COMPARE comp(lt,gt,eqt,Aout,Bout);

endmodule

// For Register
module PIPO(data_out, data_in, load, clk);

input [15:0] data_in;
input load,clk;
output reg[15:0] data_out;

always @(posedge clk)
 if(load)
  data_out <= data_in;

endmodule

// For Subtractor
module SUB(out, in1, in2);

input [15:0] in1, in2;
output reg[15:0] out;

always @(*)
 out = in1 - in2;

endmodule

// For Comparator
module COMPARE(lt, gt, eq, data1, data2);

input [15:0] data1, data2;
output lt, gt, eq;

assign lt = data1<data2;
assign gt = data1>data2;
assign eq = data1==data2;

endmodule

// For Multiplexer
module MUX(out, in0, in1, sel);

input [15:0] in0, in1;
input sel;
output [15:0] out;

assign out = sel? in1: in0;

endmodule

// Contoller Module
module controller(ldA, ldB, sel1, sel2, sel_in, done, clk, lt, gt, eq, start);

input clk, lt, gt, eq, start;
output reg ldA, ldB, sel1, sel2, sel_in, done;

reg[2:0] state;
parameter S0 = 3'b000, S1 = 3'b001, S2 = 3'b010,  S3 = 3'b011, S4 = 3'b100, S5 = 3'b101;

always @(posedge clk)
  begin
    case(state)
      S0: if(start) state <= S1;
      S1: state <= S2;
      S2: #2 if(eq) state <= S5;
             else if(lt) state <= S3;
             else if(gt) state <= S4;
      S3: #2 if(eq) state <= S5;
             else if(lt) state <= S3;
             else if(gt) state <= S4;
      S4: #2 if(eq) state <= S5;
             else if(lt) state <= S3;
             else if(gt) state <= S4;
      S5: state <= S5;
      default: state <= S0;
    endcase
  end

always @(state)
   begin
    case(state)
      S0: begin sel_in = 1;
                ldA = 1; ldB = 0; done = 0;
          end
      S1: begin sel_in = 1;
                ldA = 0; ldB = 1; 
          end
      S2: if(eq) done=1;
          else if(lt)
             begin sel1 = 1; sel2 = 0; sel_in = 0;
                #1 ldA = 0; ldB = 1; 
             end
          else if(gt)
             begin sel1 = 0; sel2 = 1; sel_in = 0;
                #1 ldA = 1; ldB = 0; 
             end
      S3: if(eq) done=1;
          else if(lt)
             begin sel1 = 1; sel2 = 0; sel_in = 0;
                #1 ldA = 0; ldB = 1; 
             end
          else if(gt)
             begin sel1 = 0; sel2 = 1; sel_in = 0;
                #1 ldA = 1; ldB = 0; 
             end
      S4: if(eq) done=1;
          else if(lt)
             begin sel1 = 1; sel2 = 0; sel_in = 0;
                #1 ldA = 0; ldB = 1; 
             end
          else if(gt)
             begin sel1 = 0; sel2 = 1; sel_in = 0;
                #1 ldA = 1; ldB = 0; 
             end
      S5: begin
           done = 1; sel1 = 0; sel2 = 0; ldA = 0; ldB = 0;
          end
      default: begin
                ldA = 0; ldB=0;
               end
    endcase
   end

endmodule


// Test Bench
module GCD_test;
reg [15:0] data_in;
reg clk, start;
wire done;

reg [15:0] A,B;

GCD_datapath DP(gt, lt, eqt, ldA, ldB, sel1, sel2, sel_in, data_in, clk);
controller CON(ldA, ldB, sel1, sel2, sel_in, done, clk, lt, gt, eq, start);

initial
  begin
   clk = 1'b0;
   #3 start = 1'b1;
   #1000 $finish;
  end

always #5 clk = ~clk;
 initial
   begin
   #12 data_in = 143;
   #10 data_in = 78;
  end

 initial 
   begin
   $monitor($time, "%d %d %b", DP.Aout,DP.Bout,done);
   $dumpfile("gcd.vcd");
   $dumpvars(0, GCD_test);
  end
endmodule
