/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

assign pout=pin[3]&pin[2]&pin[1]&pin[0];
assign gout=(pin[3]&pin[2]&pin[1]&gin[0])|(pin[3]&pin[2]&gin[1])|(pin[3]&gin[2])|gin[3];
assign cout[0]=gin[0]|(pin[0]&cin);
assign cout[1]=(pin[1]&pin[0]&cin)|(pin[1]&gin[0])|gin[1];
assign cout[2]=(pin[2]&pin[1]&pin[0]&cin)|(pin[2]&pin[1]&gin[0])|(pin[2]&gin[1])|gin[2];

endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);
// Add the required wire definitions and instances of the gp1 and gp4 modules
wire  [15:0]gin, pin, cout;
wire gout1, pout1,gout2, pout2,gout3, pout3,gout4, pout4,gout5, pout5;

// Instance gp1 for every bit in the 16-bit adder

gp1 g1_0(.a(a[0]), .b(b[0]), .g(gin[0]), .p(pin[0]));
gp1 g1_1(.a(a[1]), .b(b[1]), .g(gin[1]), .p(pin[1]));
gp1 g1_2(.a(a[2]), .b(b[2]), .g(gin[2]), .p(pin[2]));
gp1 g1_3(.a(a[3]), .b(b[3]), .g(gin[3]), .p(pin[3]));
gp4 g4_0(.gin(gin[3:0]), .pin(pin[3:0]),.cin(cin), .gout(gout1), .pout(pout1), .cout(cout[2:0]));
gp1 g1_4(.a(a[4]), .b(b[4]), .g(gin[4]), .p(pin[4]));
gp1 g1_5(.a(a[5]), .b(b[5]), .g(gin[5]), .p(pin[5]));
gp1 g1_6(.a(a[6]), .b(b[6]), .g(gin[6]), .p(pin[6]));
gp1 g1_7(.a(a[7]), .b(b[7]), .g(gin[7]), .p(pin[7]));
gp4 g4_1(.gin(gin[7:4]), .pin(pin[7:4]), .cin(cout[3]), .gout(gout2), .pout(pout2), .cout(cout[6:4]));
gp1 g1_8(.a(a[8]), .b(b[8]), .g(gin[8]), .p(pin[8]));
gp1 g1_9(.a(a[9]), .b(b[9]), .g(gin[9]), .p(pin[9]));
gp1 g1_10(.a(a[10]), .b(b[10]), .g(gin[10]), .p(pin[10]));
gp1 g1_11(.a(a[11]), .b(b[11]), .g(gin[11]), .p(pin[11]));
gp4 g4_2(.gin(gin[11:8]), .pin(pin[11:8]), .cin(cout[7]), .gout(gout3), .pout(pout3), .cout(cout[10:8]));
gp1 g1_12(.a(a[12]), .b(b[12]), .g(gin[12]), .p(pin[12]));
gp1 g1_13(.a(a[13]), .b(b[13]), .g(gin[13]), .p(pin[13]));
gp1 g1_14(.a(a[14]), .b(b[14]), .g(gin[14]), .p(pin[14]));
gp1 g1_15(.a(a[15]), .b(b[15]), .g(gin[15]), .p(pin[15]));
gp4 g4_3(.gin(gin[15:12]), .pin(pin[15:12]), .cin(cout[11]), .gout(gout4), .pout(pout4), .cout(cout[14:12]));

gp4 g4_4(.gin({gout4,gout3,gout2,gout1}), .pin({pout4,pout3,pout2,pout1}), .cin(cin), .gout(gout5), .pout(pout5), .cout({cout[11],cout[7],cout[3]}));

assign sum=a^b^{cout[14:0],cin};


endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
   wire [N-1:0] g, p;
   assign g[0]=gin[0];
   assign p[0]=pin[0];
   assign cout[0]=gin[0]|(pin[0]&cin);
   genvar i;
   wire [N-1:0]gn;
   wire [N-1:0]pn;
   for ( i = 1; i <= (N-1); i=i+1) begin
    assign gn[i]=gin[i]|(pin[i] & gin[i-1]);
    assign pn[i]=pin[i-1] & pin[i];
    assign g[i] = (i<2)? (gin[1]|pin[1]&gin[0]):(gn[i] | (pn[i] & g[i-2]));
    assign p[i] = (i<2)? (pin[1]&pin[0]):(pn[i]&p[i-2]);
    
end
 for ( i = 1; i <= (N-2); i=i+1) begin
    // assign cout[i]=g[i-1]|(p[i-1]&cin);
    assign cout[i]=cout[i-1]&pin[i]|gin[i];
end
assign gout=g[N-1];
assign pout=p[N-1];


endmodule
