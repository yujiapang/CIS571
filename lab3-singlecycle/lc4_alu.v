/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      wire [15:0] result_0001,result_0010;
      
      wire [15:0] o_remainder;
      wire [15:0] result_0101;
      wire [15:0] result_1010;
      wire [15:0] cla_inp0,cla_inp1,sum,cla_inp1_0010;
      wire cin;
      wire [3:0] shiftby=i_insn[3:0];
      //for 1010
      wire [15:0] s_r1=$signed(i_r1data[15:0])>>>i_insn[3:0] ;
      
        assign result_1010 = (i_insn[5:4] == 2'b00) ? i_r1data<<i_insn[3:0] :
                              (i_insn[5:4] == 2'b01) ? s_r1:
                              (i_insn[5:4] == 2'b10) ? i_r1data>>i_insn[3:0] :
                              o_remainder;
      

      assign cla_inp1_0010 = (i_insn[8:7] == 2'b00) ? ~i_r2data :
                  (i_insn[8:7] == 2'b01) ? ~i_r2data :
                  (i_insn[8:7] == 2'b10) ? ~{5'b0,i_insn[6:0]} :
                  ~{5'b0,i_insn[6:0]};

     
      assign result_0101 = (i_insn[5:3] == 3'b000) ? (i_r1data & i_r2data) :
      (i_insn[5:3] == 3'b001) ? ( ~i_r1data ) :
      (i_insn[5:3] == 3'b010) ? (i_r1data | i_r2data) :
      (i_insn[5:3] == 3'b011) ? (i_r1data ^ i_r2data) :
      (i_r1data & {{12{i_insn[4]}}, i_insn[3:0]});  
      wire [15:0] o_quotient;
      lc4_divider d(.i_dividend(i_r1data),.i_divisor(i_r2data),.o_remainder(o_remainder),.o_quotient(o_quotient));
      assign result_0001 = (i_insn[5:3] == 3'b001) ? (i_r2data * i_r1data) :
      (i_insn[5:3] == 3'b011) ? (o_quotient) :
      (sum);

    assign result_0010 = (i_insn[8]==0)?((i_insn[7]==1) ? ((i_r1data < i_r2data) ? 16'b1111111111111111 : 
    ((i_r1data == i_r2data) ? 16'b0000000000000000 : 16'b0000000000000001)) : 
    ((i_r1data[15]==0) ? ((i_r2data[15]==1) ? 16'b0000000000000001 : 
    ((i_r1data < i_r2data) ? 16'b1111111111111111 : 
    ((i_r1data == i_r2data) ? 16'b0000000000000000 : 16'b0000000000000001))) : 
    ((i_r2data[15]==0) ? 16'b1111111111111111 : ((i_r1data < i_r2data) ? 16'b1111111111111111 : 
    ((i_r1data == i_r2data) ? 16'b0000000000000000 : 16'b0000000000000001))))):
    //immediate
    ((i_insn[7]==1)?((i_r1data < {{9{1'b0}},i_insn[6:0]}) ? 16'b1111111111111111 : 
    (i_r1data == {{9{1'b0}},i_insn[6:0]}) ? 16'b0000000000000000 : 16'b0000000000000001):
    ((i_r1data[15]==0) ? ((i_insn[6]==1) ? 16'b0000000000000001 : 
    ((i_r1data < {{10{i_insn[6]}},i_insn[5:0]}) ? 16'b1111111111111111 : 
    ((i_r1data == {{10{i_insn[6]}},i_insn[5:0]}) ? 16'b0000000000000000 : 16'b0000000000000001))) : 
    ((i_insn[6]==0) ? 16'b1111111111111111 : ((i_r1data < {{10{i_insn[6]}},i_insn[5:0]}) ? 16'b1111111111111111 : 
    ((i_r1data == {{10{i_insn[6]}},i_insn[5:0]}) ? 16'b0000000000000000 : 16'b0000000000000001))))
    );
      
assign o_result = (i_insn[15:12] == 4'b0000) ? sum :
                  (i_insn[15:12] == 4'b0001) ? result_0001 :
                  (i_insn[15:12] == 4'b0010) ? result_0010 :
                  (i_insn[15:12] == 4'b0100) ? (i_insn[11] == 0) ? i_r1data : ((i_pc & 16'h8000) | (i_insn[10:0] << 4)) :
                  (i_insn[15:12] == 4'b0101) ? result_0101 :
                  (i_insn[15:12] == 4'b0110) ? sum :
                  (i_insn[15:12] == 4'b0111) ? sum :
                  (i_insn[15:12] == 4'b1000) ?  i_r1data:
                  (i_insn[15:12] == 4'b1001) ? {{8{i_insn[8]}},i_insn[7:0]} :
                  (i_insn[15:12] == 4'b1010) ? result_1010 :
                  (i_insn[15:12] == 4'b1100) ? (i_insn[11] == 0) ? i_r1data : sum :
                  (i_insn[15:12] == 4'b1101) ? (i_r1data & 8'hff) | (i_insn[7:0] << 8) :
                  (i_insn[15:12] == 4'b1111) ? 16'h8000 | i_insn[7:0] :
                  0;

assign cla_inp0 = (i_insn[15:12] == 4'b0000) ? i_pc :
                  (i_insn[15:12] == 4'b0001) ? i_r1data :
                  (i_insn[15:12] == 4'b0010) ? i_r1data :
                  (i_insn[15:12] == 4'b0110) ? i_r1data :
                  (i_insn[15:12] == 4'b0111) ? i_r1data :
                  (i_insn[15:12] == 4'b1010) ? 15'd15 :
                  (i_insn[15:12] == 4'b1100) ? i_pc :
                  0;

assign cin = (i_insn[15:12] == 4'b0000) ? 1'b1 :
            (i_insn[15:12] == 4'b0001) ? ((i_insn[5] == 0)?((i_insn[4] == 1)? 1'b1:1'b0):1'b0) :
            (i_insn[15:12] == 4'b0010) ? 1'b1 :
             (i_insn[15:12] == 4'b1100) ? 1'b1 :
             (i_insn[15:12] == 4'b1010) ? 1'b1 :
             1'b0;

assign cla_inp1 = (i_insn[15:12] == 4'b0000) ?  {{8{i_insn[8]}}, i_insn[7:0]} :
                  (i_insn[15:12] == 4'b0001) ? ((i_insn[5] == 0) ? ((i_insn[4] == 0) ? i_r2data : ~i_r2data):{{12{i_insn[4]}},i_insn[3:0]}):
                  (i_insn[15:12] ==4'b0010) ?cla_inp1_0010:
                  (i_insn[15:12] ==4'b0110) ?({{11{i_insn[5]}},i_insn[4:0]}):
                  (i_insn[15:12] ==4'b0111) ?({{11{i_insn[5]}},i_insn[4:0]}):
                  (i_insn[15:12] == 4'b1010) ? ~i_insn[3:0] :
                  (i_insn[15:12] ==4'b1100) ?{{6{i_insn[10]}},i_insn[9:0]}:16'b0;

     //assign cla
      cla16 s(.a(cla_inp0),.b(cla_inp1),.cin(cin),.sum(sum));


      /*** YOUR CODE HERE ***/

endmodule
