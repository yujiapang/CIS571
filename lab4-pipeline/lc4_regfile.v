/* TODO: name and PennKeys of all group members here
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

   /***********************
    * TODO YOUR CODE HERE *
    ***********************/
    wire [15:0]out_data1,out_data2,out_data3,out_data4,out_data5,out_data6,out_data7,out_data8;
    assign o_rs_data=(i_rs==3'b000)?out_data1 :(i_rs==3'b001)?out_data2:(i_rs==3'b010)? out_data3:(i_rs==3'b011)?out_data4:(i_rs==3'b100)?out_data5:(i_rs==3'b101)?out_data6:(i_rs==3'b110)?out_data7:out_data8;
    assign o_rt_data=(i_rt==3'b000)?out_data1 :(i_rt==3'b001)?out_data2:(i_rt==3'b010)? out_data3:(i_rt==3'b011)?out_data4:(i_rt==3'b100)?out_data5:(i_rt==3'b101)?out_data6:(i_rt==3'b110)?out_data7:out_data8;
   
    Nbit_reg  #(16) r1 ( .in(i_wdata), .out(out_data1), .clk(clk), .we(i_rd_we && (i_rd==3'b000)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r2 ( .in(i_wdata), .out(out_data2), .clk(clk), .we(i_rd_we && (i_rd==3'b001)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r3 ( .in(i_wdata), .out(out_data3), .clk(clk), .we(i_rd_we && (i_rd==3'b010)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r4 ( .in(i_wdata), .out(out_data4), .clk(clk), .we(i_rd_we && (i_rd==3'b011)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r5 ( .in(i_wdata), .out(out_data5), .clk(clk), .we(i_rd_we && (i_rd==3'b100)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r6 ( .in(i_wdata), .out(out_data6), .clk(clk), .we(i_rd_we && (i_rd==3'b101)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r7 ( .in(i_wdata), .out(out_data7), .clk(clk), .we(i_rd_we && (i_rd==3'b110)), .gwe(gwe), .rst(rst) );
    Nbit_reg  #(16) r8 ( .in(i_wdata), .out(out_data8), .clk(clk), .we(i_rd_we && (i_rd==3'b111)), .gwe(gwe), .rst(rst) );
    
endmodule
