`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/


    wire [15:0]out_data1,out_data2,out_data3,out_data4,out_data5,out_data6,out_data7,out_data8;
    assign o_rs_data_A=(i_rd_we_A==1'b1&&i_rd_A==i_rs_A)?i_final_wdata_A:(i_rs_A==i_rd_B&&i_rd_we_B==1)?i_final_wdata_B:((i_rs_A==3'b000)?out_data1 :(i_rs_A==3'b001)?out_data2:(i_rs_A==3'b010)? out_data3:(i_rs_A==3'b011)?out_data4:(i_rs_A==3'b100)?out_data5:(i_rs_A==3'b101)?out_data6:(i_rs_A==3'b110)?out_data7:out_data8);
    assign o_rt_data_A=((i_rd_we_A==1'b1)&&(i_rd_A==i_rt_A))?i_final_wdata_A:((i_rt_A==i_rd_B)&&(i_rd_we_B==1'b1))?i_final_wdata_B:((i_rt_A==3'b000)?out_data1 :(i_rt_A==3'b001)?out_data2:(i_rt_A==3'b010)? out_data3:(i_rt_A==3'b011)?out_data4:(i_rt_A==3'b100)?out_data5:(i_rt_A==3'b101)?out_data6:(i_rt_A==3'b110)?out_data7:out_data8);
    assign o_rt_data_B=(i_rd_we_B==1'b1&&i_rd_B==i_rt_B)?i_final_wdata_B:(i_rt_B==i_rd_A&&i_rd_we_A==1)?i_final_wdata_A:((i_rt_B==3'b000)?out_data1 :(i_rt_B==3'b001)?out_data2:(i_rt_B==3'b010)? out_data3:(i_rt_B==3'b011)?out_data4:(i_rt_B==3'b100)?out_data5:(i_rt_B==3'b101)?out_data6:(i_rt_B==3'b110)?out_data7:out_data8);
    assign o_rs_data_B=(i_rd_we_B==1'b1&&i_rd_B==i_rs_B)?i_final_wdata_B:(i_rs_B==i_rd_A&&i_rd_we_A==1)?i_final_wdata_A:((i_rs_B==3'b000)?out_data1 :(i_rs_B==3'b001)?out_data2:(i_rs_B==3'b010)? out_data3:(i_rs_B==3'b011)?out_data4:(i_rs_B==3'b100)?out_data5:(i_rs_B==3'b101)?out_data6:(i_rs_B==3'b110)?out_data7:out_data8);
    wire [15:0] i_final_wdata_A,i_final_wdata_B,i_final_wdata1,i_final_wdata2,i_final_wdata3,i_final_wdata4,i_final_wdata5,i_final_wdata6,i_final_wdata7,i_final_wdata8,i_ori_wdata;
    
    assign i_final_wdata_A=((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b000)||(i_rd_we_A==1&&i_rd_A==3'b000))?i_final_wdata1:
    ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b001)||(i_rd_we_A==1&&i_rd_A==3'b001))?i_final_wdata2:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b010)||(i_rd_we_A==1&&i_rd_A==3'b010))?i_final_wdata3:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b011)||(i_rd_we_A==1&&i_rd_A==3'b011))?i_final_wdata4:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b100)||(i_rd_we_A==1&&i_rd_A==3'b100))?i_final_wdata5:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b101)||(i_rd_we_A==1&&i_rd_A==3'b101))?i_final_wdata6:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b110)||(i_rd_we_A==1&&i_rd_A==3'b110))?i_final_wdata7:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b111)||(i_rd_we_A==1&&i_rd_A==3'b111))?i_final_wdata8:0;
    
    assign i_final_wdata_B=((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b000)||(i_rd_we_B==1&&i_rd_B==3'b000))?i_final_wdata1:
    ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b001)||(i_rd_we_B==1&&i_rd_B==3'b001))?i_final_wdata2:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b010)||(i_rd_we_B==1&&i_rd_B==3'b010))?i_final_wdata3:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b011)||(i_rd_we_B==1&&i_rd_B==3'b011))?i_final_wdata4:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b100)||(i_rd_we_B==1&&i_rd_B==3'b100))?i_final_wdata5:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b101)||(i_rd_we_B==1&&i_rd_B==3'b101))?i_final_wdata6:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b110)||(i_rd_we_B==1&&i_rd_B==3'b110))?i_final_wdata7:
   ((i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b111)||(i_rd_we_B==1&&i_rd_B==3'b111))?i_final_wdata8:0;
    assign i_final_wdata1=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b000)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b000)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b000)?i_wdata_A:0));

    assign i_final_wdata2=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b001)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b001)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b001)?i_wdata_A:0));

    assign i_final_wdata3=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b010)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b010)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b010)?i_wdata_A:0));

   assign i_final_wdata4=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b011)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b011)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b011)?i_wdata_A:0));

    assign i_final_wdata5=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b100)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b100)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b100)?i_wdata_A:0));

    assign i_final_wdata6=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b101)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b101)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b101)?i_wdata_A:0));

    assign i_final_wdata7=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b110)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b110)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b110)?i_wdata_A:0));

    assign i_final_wdata8=(i_rd_we_A==1&&i_rd_we_B==1&&(i_rd_A==i_rd_B)&&i_rd_A==3'b111)?i_wdata_B:(
    (i_rd_we_B==1&&i_rd_B==3'b111)?i_wdata_B:
    ((i_rd_we_A==1&&i_rd_A==3'b111)?i_wdata_A:0));
   wire  i_rd1,i_rd2,i_rd3,i_rd4,i_rd5,i_rd6,i_rd7,i_rd8;
    assign i_rd_we=i_rd_we_B||i_rd_we_A;
    wire  i_rd_we; 
    assign i_rd1=(i_rd_we_B==1'b1&&i_rd_B==3'b000)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b000)?1'b1:0;
    assign i_rd2=(i_rd_we_B==1'b1&&i_rd_B==3'b001)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b001)?1'b1:0;
  
    assign i_rd3=(i_rd_we_B==1'b1&&i_rd_B==3'b010)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b010)?1'b1:0;
    assign i_rd4=(i_rd_we_B==1'b1&&i_rd_B==3'b011)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b011)?1'b1:0;
    assign i_rd5=(i_rd_we_B==1'b1&&i_rd_B==3'b100)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b100)?1'b1:0;
   assign i_rd6=(i_rd_we_B==1'b1&&i_rd_B==3'b101)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b101)?1'b1:0;
    assign i_rd7=(i_rd_we_B==1'b1&&i_rd_B==3'b110)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b110)?1'b1:0;
     assign i_rd8=(i_rd_we_B==1'b1&&i_rd_B==3'b111)?1'b1:(i_rd_we_A==1'b1&&i_rd_A==3'b111)?1'b1:0;

    Nbit_reg  #(16) r1 ( .in(i_final_wdata1), .out(out_data1), .clk(clk), .we(i_rd_we && (i_rd1)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r2 ( .in(i_final_wdata2), .out(out_data2), .clk(clk), .we(i_rd_we && (i_rd2)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r3 ( .in(i_final_wdata3), .out(out_data3), .clk(clk), .we(i_rd_we && (i_rd3)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r4 ( .in(i_final_wdata4), .out(out_data4), .clk(clk), .we(i_rd_we && (i_rd4)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r5 ( .in(i_final_wdata5), .out(out_data5), .clk(clk), .we(i_rd_we && (i_rd5)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r6 ( .in(i_final_wdata6), .out(out_data6), .clk(clk), .we(i_rd_we && (i_rd6)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r7 ( .in(i_final_wdata7), .out(out_data7), .clk(clk), .we(i_rd_we && (i_rd7)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r8 ( .in(i_final_wdata8), .out(out_data8), .clk(clk), .we(i_rd_we && (i_rd8)), .gwe(gwe), .rst(rst) );

endmodule
