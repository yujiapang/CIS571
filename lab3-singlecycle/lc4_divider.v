/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
  
      wire [15:0] t_dividend,t1_dividend,t2_dividend,t3_dividend,t4_dividend,t5_dividend,t6_dividend,t7_dividend,t8_dividend,t9_dividend,
      t10_dividend,t11_dividend,t12_dividend,t13_dividend,t14_dividend,t15_dividend;

      wire [15:0] t_remainder,t1_remainder,t2_remainder,t3_remainder,t4_remainder,t5_remainder,t6_remainder,t7_remainder,t8_remainder,
      t9_remainder,t10_remainder,t11_remainder,t12_remainder,t13_remainder,t14_remainder,t15_remainder;

      wire [15:0] t_quotient,t1_quotient,t2_quotient,t3_quotient,t4_quotient,t5_quotient,t6_quotient,t7_quotient,t8_quotient,t9_quotient,
      t10_quotient,t11_quotient,t12_quotient,t13_quotient,t14_quotient,t15_quotient;
      
      lc4_divider_one_iter m(.i_dividend(i_dividend),.i_divisor(i_divisor),
                              .i_remainder(16'b0),.i_quotient(16'b0),.o_dividend(t_dividend),
                              .o_remainder(t_remainder),.o_quotient(t_quotient));
      lc4_divider_one_iter m1(.i_dividend(t_dividend),.i_divisor(i_divisor),
                              .i_remainder(t_remainder),.i_quotient(t_quotient),.o_dividend(t1_dividend),
                              .o_remainder(t1_remainder),.o_quotient(t1_quotient));
      
      lc4_divider_one_iter m2(.i_dividend(t1_dividend),.i_divisor(i_divisor),
                              .i_remainder(t1_remainder),.i_quotient(t1_quotient),.o_dividend(t2_dividend),
                              .o_remainder(t2_remainder),.o_quotient(t2_quotient));
      lc4_divider_one_iter m3(.i_dividend(t2_dividend),.i_divisor(i_divisor),
                              .i_remainder(t2_remainder),.i_quotient(t2_quotient),.o_dividend(t3_dividend),
                              .o_remainder(t3_remainder),.o_quotient(t3_quotient));

      lc4_divider_one_iter m4(.i_dividend(t3_dividend),.i_divisor(i_divisor),
                              .i_remainder(t3_remainder),.i_quotient(t3_quotient),.o_dividend(t4_dividend),
                              .o_remainder(t4_remainder),.o_quotient(t4_quotient));

      lc4_divider_one_iter m5(.i_dividend(t4_dividend),.i_divisor(i_divisor),
                              .i_remainder(t4_remainder),.i_quotient(t4_quotient),.o_dividend(t5_dividend),
                              .o_remainder(t5_remainder),.o_quotient(t5_quotient));
      
      lc4_divider_one_iter m6(.i_dividend(t5_dividend),.i_divisor(i_divisor),
                              .i_remainder(t5_remainder),.i_quotient(t5_quotient),.o_dividend(t6_dividend),
                              .o_remainder(t6_remainder),.o_quotient(t6_quotient));
      lc4_divider_one_iter m7(.i_dividend(t6_dividend),.i_divisor(i_divisor),
                              .i_remainder(t6_remainder),.i_quotient(t6_quotient),.o_dividend(t7_dividend),
                              .o_remainder(t7_remainder),.o_quotient(t7_quotient));
      lc4_divider_one_iter m8(.i_dividend(t7_dividend),.i_divisor(i_divisor),
                              .i_remainder(t7_remainder),.i_quotient(t7_quotient),.o_dividend(t8_dividend),
                              .o_remainder(t8_remainder),.o_quotient(t8_quotient));
      lc4_divider_one_iter m9(.i_dividend(t8_dividend),.i_divisor(i_divisor),
                              .i_remainder(t8_remainder),.i_quotient(t8_quotient),.o_dividend(t9_dividend),
                              .o_remainder(t9_remainder),.o_quotient(t9_quotient));
      lc4_divider_one_iter m10(.i_dividend(t9_dividend),.i_divisor(i_divisor),
                              .i_remainder(t9_remainder),.i_quotient(t9_quotient),.o_dividend(t10_dividend),
                              .o_remainder(t10_remainder),.o_quotient(t10_quotient));
      lc4_divider_one_iter m11(.i_dividend(t10_dividend),.i_divisor(i_divisor),
                              .i_remainder(t10_remainder),.i_quotient(t10_quotient),.o_dividend(t11_dividend),
                              .o_remainder(t11_remainder),.o_quotient(t11_quotient));
      lc4_divider_one_iter m12(.i_dividend(t11_dividend),.i_divisor(i_divisor),
                              .i_remainder(t11_remainder),.i_quotient(t11_quotient),.o_dividend(t12_dividend),
                              .o_remainder(t12_remainder),.o_quotient(t12_quotient));
      lc4_divider_one_iter m13(.i_dividend(t12_dividend),.i_divisor(i_divisor),
                              .i_remainder(t12_remainder),.i_quotient(t12_quotient),.o_dividend(t13_dividend),
                              .o_remainder(t13_remainder),.o_quotient(t13_quotient));
      lc4_divider_one_iter m14(.i_dividend(t13_dividend),.i_divisor(i_divisor),
                              .i_remainder(t13_remainder),.i_quotient(t13_quotient),.o_dividend(t14_dividend),
                              .o_remainder(t14_remainder),.o_quotient(t14_quotient));
      lc4_divider_one_iter m15(.i_dividend(t14_dividend),.i_divisor(i_divisor),
                              .i_remainder(t14_remainder),.i_quotient(t14_quotient),.o_dividend(t15_dividend),
                              .o_remainder(t15_remainder),.o_quotient(t15_quotient));
      
      assign o_quotient=(i_divisor==0)? 16'b0:t15_quotient;
      assign o_remainder=(i_divisor==0)? 16'b0:t15_remainder;

endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] t_remainder= (i_remainder<<1) | ((i_dividend >> 15)& 1);
      assign o_quotient = (t_remainder<i_divisor)? (i_quotient<<1): ((i_quotient << 1) | 1);
      assign o_remainder = (t_remainder<i_divisor)? (t_remainder): (t_remainder-i_divisor);
      assign o_dividend =i_dividend<<1;

endmodule
