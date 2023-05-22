`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/
assign led_data = switch_data;
   
   wire [2:0] r1sel_A,r1sel_B,r2sel_A,r2sel_B,wsel_A,wsel_B,wsel_back_A,wsel_back_B,next_nzp_A,next_nzp_B,nzp_A,nzp_B;
   wire r1re_A,r1re_B,r2re_A,r2re_B, regfile_we_A,regfile_we_B,nzp_we_A,nzp_we_B,select_pc_plus_one,select_pc_plus_two,is_load_A,is_load_B,is_store_A,is_store_B,is_branch_A,is_branch_B,is_control_insn_A,is_control_insn_B;
   wire [15:0] o_result_A,o_result_B,o_rs_data_A,o_rs_data_B,o_rt_data_A,o_rt_data_B,i_wdata_A,i_wdata_B;
   wire [15:0]   pc_A,pc_B;      // Current program counter (read out from pc_reg)
   wire [15:0]   np_A,np_B,np1_A,np1_B,next_pc_A,next_pc_B,  pc_plus_one,pc_plus_two; // Next program counter (you compute this and feed it into next_pc)
   
   ///decode: 8200 8201
   ///
   ///fetch
   wire [1:0]F_stall_A,F_stall_B,F1_stall_A,F1_stall_B;
   assign np_A=(load_stall_A==1'b1&&(!mis_prediction_A&&!mis_prediction_B))?pc_A:((B_depend_on_A==1'b1&&F1_stall_B==0)||(load_stall_B==1'b1&&!load_stall_A&&!mis_prediction_A&&!mis_prediction_B))?pc_B:next_pc_A;
   assign np_B=((load_stall_A))?pc_B:(B_depend_on_A||(load_stall_B==1'b1&&!load_stall_A))?pc_A:next_pc_B;
   Nbit_reg #(2, 2'b0) Fstall_A (.in(2'b0), .out(F_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) Fstall_B (.in(2'b0), .out(F_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg_A (.in(np_A), .out(pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   cla16 s(.a(pc_A),.b(16'b0),.cin(1'b1),.sum(pc_B));
   cla16 s0(.a(pc_A),.b(16'b1),.cin(1'b0),.sum(pc_plus_one));
   cla16 s1(.a(pc_B),.b(16'b0),.cin(1'b1),.sum(pc_plus_two));
   assign o_cur_pc=pc_A;
   assign F1_stall_A=(mis_prediction_A||mis_prediction_B)?2'b10:F_stall_A;
   assign F1_stall_B=(mis_prediction_B||mis_prediction_A)?2'b10:F_stall_B;
   
   ///decode
   wire [1:0]D_stall_A,D_stall_B;
   wire [15:0]   pc1_A,pc1_B,pc_plus_one1,pc_plus_two1,pc_plus_onef,pc_plus_twof;
   wire [15:0]  Dinsn_inp_A,Dinsn_inp_B,i_cur_insn1_A,i_cur_insn1_B;
   assign Dinsn_inp_A=(load_stall_A==1'b1)?i_cur_insn1_A:(B_depend_on_A==1'b1||(load_stall_B==1'b1&&!load_stall_A))?i_cur_insn1_B:i_cur_insn_A;
   assign Dinsn_inp_B=(load_stall_A==1'b1)?i_cur_insn1_B:(B_depend_on_A==1'b1||(load_stall_B==1'b1&&!load_stall_A))?i_cur_insn_A:i_cur_insn_B;
   assign np1_A=(load_stall_A==1'b1)?pc1_A:(B_depend_on_A==1'b1||(load_stall_B==1'b1&&!load_stall_A))?pc1_B:pc_A;
   assign np1_B=(load_stall_A==1'b1)?pc1_B:(B_depend_on_A==1'b1||(load_stall_B==1'b1&&!load_stall_A))?pc_A:pc_B;
   assign pc_plus_onef=(load_stall_A==1'b1)?pc_plus_one1:(B_depend_on_A==1'b1||(load_stall_B==1'b1&&!load_stall_A))?pc_plus_two1:pc_plus_one;
    assign pc_plus_twof=(load_stall_A==1'b1)?pc_plus_two1:(B_depend_on_A==1'b1||(load_stall_B==1'b1&&!load_stall_A))?pc_plus_one:pc_plus_two;
   Nbit_reg #(2, 2'b10) Dstall_A (.in(F1_stall_A), .out(D_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Dstall_B (.in(F1_stall_B), .out(D_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg1_A (.in(np1_A), .out(pc1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg1_B (.in(np1_B), .out(pc1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus_1 (.in(pc_plus_onef), .out(pc_plus_one1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus_2 (.in(pc_plus_twof), .out(pc_plus_two1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru_A (.in(Dinsn_inp_A), .out(i_cur_insn1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru_B (.in(Dinsn_inp_B), .out(i_cur_insn1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   lc4_decoder decode_A( .insn(i_cur_insn1_A), .r1sel(r1sel_A), .r1re(r1re_A), .r2sel(r2sel_A),  .r2re(r2re_A),               // does this instruction read from rt?
                   .wsel(wsel_A), .regfile_we(regfile_we_A), .nzp_we(nzp_we_A),  .select_pc_plus_one(select_pc_plus_one), // write PC+1 to the regfile?
                   .is_load(is_load_A), .is_store(is_store_A), .is_branch(is_branch_A),          // is this a branch instruction?
                   .is_control_insn(is_control_insn_A)     
                   );
   lc4_decoder decode_B( .insn(i_cur_insn1_B), .r1sel(r1sel_B), .r1re(r1re_B), .r2sel(r2sel_B),  .r2re(r2re_B),               // does this instruction read from rt?
                   .wsel(wsel_B), .regfile_we(regfile_we_B), .nzp_we(nzp_we_B),  .select_pc_plus_one(select_pc_plus_two), // write PC+1 to the regfile?
                   .is_load(is_load_B), .is_store(is_store_B), .is_branch(is_branch_B),          // is this a branch instruction?
                   .is_control_insn(is_control_insn_B)     
                   );
   wire B_depend_on_A=((D_stall_B==0&&D_stall_A==0)&&((r1re_B&&r1sel_B==wsel_A&&regfile_we_A)||(!is_store_B&&r2sel_B==wsel_A&&r2re_B&&regfile_we_A)))||(is_branch_B&&D_stall_B==0&&!is_store_A&&!is_branch_A)||((D_stall_B==0&&D_stall_A==0)&&is_load_A&&(is_load_B||is_store_B))||((D_stall_B==0&&D_stall_A==0)&&is_store_A&&(is_store_B||is_load_B));
   wire [15:0] os_f_A,os_f_B,ot_f_A,ot_f_B;
   wire immed_A,immed_B;
   assign immed_A =((i_cur_insn1_A[15:12]==4'b0001||i_cur_insn1_A[15:12]==4'b0101)&&i_cur_insn1_A[5]==1'b1)?1'b1:
   ((i_cur_insn1_A[15:12]==4'b1010&&i_cur_insn1_A[5:4]!=2'b11)?1'b1:1'b0);
   assign immed_B =((i_cur_insn1_B[15:12]==4'b0001||i_cur_insn1_B[15:12]==4'b0101)&&i_cur_insn1_B[5]==1'b1)?1'b1:
   ((i_cur_insn1_B[15:12]==4'b1010&&i_cur_insn1_B[5:4]!=2'b11)?1'b1:1'b0);
   
    lc4_regfile_ss #(16) reg1(.clk(clk), .gwe(gwe),.rst(rst),.i_rs_A(r1sel_A), .o_rs_data_A(o_rs_data_A), // rs contents
    .i_rt_A(r2sel_A),   .o_rt_data_A(o_rt_data_A),.i_rs_B(r1sel_B), .o_rs_data_B(o_rs_data_B), // rs contents
    .i_rt_B(r2sel_B),   .o_rt_data_B(o_rt_data_B),  .i_rd_A(wsel_back_A),  .i_wdata_A(i_wdata_A),   // data to write
    .i_rd_we_A(decode_info3_A[5]),.i_rd_B(wsel_back_B),  .i_wdata_B(i_wdata_B),   // data to write
    .i_rd_we_B(decode_info3_B[5]));
    
   wire [14:0] decode_info_A,decode_info_B;
   wire regfile_we_with_stall_A,regfile_we_with_stall_B;
   assign regfile_we_with_stall_A=(D1_stall_A!=0)?0:regfile_we_A;
   assign regfile_we_with_stall_B=(D1_stall_B!=0)?0:regfile_we_B;
   assign decode_info_A={r1sel_A,r2sel_A,wsel_A,regfile_we_with_stall_A,select_pc_plus_one,is_load_A,is_store_A,is_branch_A,is_control_insn_A};
   assign decode_info_B={r1sel_B,r2sel_B,wsel_B,regfile_we_with_stall_B,select_pc_plus_two,is_load_B,is_store_B,is_branch_B,is_control_insn_B};
  //assign decode_info_B1=()?{r1sel_B,r2sel_B,wsel_B,regfile_we_with_stall_B,select_pc_plus_two,is_load_B,is_store_B,is_branch_B,is_control_insn_B},deco_info_B;
  ///b_depend_on_a, execpt branch condition A||(A&&B)
   wire load_stall_A,load_stall_B;
   assign load_stall_A=
   (pc2_A==pc1_A)||(decode_info1_B[3]==1'b0&&(((decode_info_A[14:12]==decode_info1_B[8:6]&&r1re_A==1'b1)&&(decode_info_A[14:12]==decode_info1_A[8:6]))||((decode_info_A[11:9]==decode_info1_B[8:6]&&r2re_A==1'b1)&&(decode_info_A[11:9]==decode_info1_A[8:6]&&r2re_A==1'b1)))&&X_stall_B==0&&decode_info1_B[5]==1'b1)?1'b0://add load to store without lTU-A
   (decode_info1_A[3]&&decode_info_A[2]==1'b1&&(decode_info_A[14:12]==decode_info1_A[8:6])&&r1re_A==1'b1&&X_stall_A==0&&decode_info1_A[5]==1'b1)||((decode_info1_A[3]==1'b1&&X_stall_A==0)&&(((decode_info_A[14:12]==decode_info1_A[8:6]&&r1re_A)||(!decode_info_A[2]&&decode_info_A[11:9]==decode_info1_A[8:6]&&r2re_A==1'b1))&&X_stall_A==0&&decode_info1_A[5]==1'b1))||((decode_info1_B[3]==1'b1&&X_stall_B==0)&&(((decode_info_A[14:12]==decode_info1_B[8:6]&&r1re_A==1'b1)||(decode_info_A[11:9]==decode_info1_B[8:6]&&r2re_A==1'b1&&!decode_info_A[2]))&&decode_info1_B[5]==1'b1))||(((decode_info1_A[3]==1'b1&&X_stall_A==0&&(X_stall_B!=0))||(decode_info1_B[3]==1'b1&&X_stall_B==0))&&decode_info_A[1])?
            1'b1:
            1'b0;
///(is_branch_B&&D_stall_B==0&&!is_branch_A)
   assign load_stall_B=
   (pc2_B==pc1_B)||(decode_info1_B[3]==1'b0&&(((decode_info_B[14:12]==decode_info1_B[8:6]&&r1re_B==1'b1)&&(decode_info_B[14:12]==decode_info1_A[8:6]))||((decode_info_B[11:9]==decode_info1_B[8:6]&&r2re_B==1'b1)&&(decode_info_B[11:9]==decode_info1_A[8:6]&&r2re_B==1'b1)))&&X_stall_B==0&&decode_info1_B[5]==1'b1)?1'b0:
   (decode_info1_B[3]&&X_stall_B==0)||(decode_info1_A[3]==1'b1&&X_stall_A==0)?
   (((((decode_info_B[14:12]==decode_info1_B[8:6]&&r1re_B==1'b1)||(!decode_info_B[2]&&decode_info_B[11:9]==decode_info1_B[8:6]&&r2re_B==1'b1))&&X_stall_B==0&&decode_info1_B[5]&&(decode_info1_B[3]&&X_stall_B==0))||((decode_info1_A[3]==1'b1&&X_stall_A==0)&&((decode_info_B[14:12]==decode_info1_A[8:6]&&r1re_B==1'b1)||(!decode_info_B[2]&&decode_info_B[11:9]==decode_info1_A[8:6]&&r2re_B==1'b1))&&decode_info1_A[5]&&X_stall_A==0)||(((decode_info1_A[3]==1'b1&&X_stall_A==0&&(X_stall_B!=0))||(decode_info1_B[3]==1'b1&&X_stall_B==0))&&(decode_info_B[1])))?1'b1:0):0;
            
////load branch 0 1 
////store branch 0 3   

   assign D1_stall_A=(load_stall_A==1'b1&&mis_prediction_A==1'b0&&mis_prediction_B==1'b0)?2'b11:((mis_prediction_A&&X_stall_A==0||mis_prediction_B&&X_stall_B==0)?2'b10:D_stall_A);
   assign D1_stall_B=(load_stall_A==1'b0&&load_stall_B==1'b1&&mis_prediction_B==1'b0&&B_depend_on_A==1'b0&&mis_prediction_A==1'b0)?2'b11:((mis_prediction_B&&X_stall_B==0)||(mis_prediction_A&&X_stall_A==0))?2'b10:(B_depend_on_A==1'b1&&D_stall_B==0)||(load_stall_A==1'b1&&B_depend_on_A==1'b0)?2'b01:D_stall_B;
   //info1==load?(info==store?0: (load?(r1==info1[wel])?1:0)conditions ):0
///delete &&load_stall_A==1'b0&&load_stall_B==1'b0 in D1_stall_B
   //execution
   assign Xinsn_inp_A=i_cur_insn1_A;
   assign Xinsn_inp_B=(B_depend_on_A)?0:i_cur_insn1_B;
   assign pc1_B_f=(B_depend_on_A)?0:pc1_B;
   wire[1:0] X_stall_A,X_stall_B,D1_stall_A,D1_stall_B,X_stall_Bf,X1_stall_A;
   wire [1:0] readre_A,readre_B,readre1_A,readre1_B,readre2_A,readre2_B;
   assign readre_A={r1re_A,r2re_A};
   assign readre_B={r1re_B,r2re_B};
   wire [15:0]   pc2_A,pc2_B,pc1_B_f,pc_plus_one2,pc_plus_two2;
   wire [15:0]  i_cur_insn2_A,i_cur_insn2_B,Xinsn_inp_A,Xinsn_inp_B;
   wire [15:0] o_rs_data1_A,o_rs_data1_B,o_rt_data1_A,o_rt_data1_B,o_rt_data_A_bypass;
   wire [14:0] decode_info1_A,decode_info1_B,decode_info_select_A,decode_info_select_B;
   wire nzp_we1_A,nzp_we1_B;
   
   Nbit_reg #(2, 2'b00) read_re_A (.in(readre_A), .out(readre1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b00) read_re_B (.in(readre_B), .out(readre1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg_A (.in(nzp_we_A), .out(nzp_we1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg_B (.in(nzp_we_B), .out(nzp_we1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Xstall_A (.in(D1_stall_A), .out(X_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Xstall_B (.in(D1_stall_B), .out(X_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus1_A (.in(pc_plus_one1), .out(pc_plus_one2), .clk(clk), .we(D1_stall_A==0), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus1_B (.in(pc_plus_two1), .out(pc_plus_two2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info_A (.in(decode_info_A), .out(decode_info1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info_B (.in(decode_info_B), .out(decode_info1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg2_A (.in(pc1_A), .out(pc2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg2_B (.in(pc1_B_f), .out(pc2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru1 (.in(Xinsn_inp_A), .out(i_cur_insn2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru2 (.in(Xinsn_inp_B), .out(i_cur_insn2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ort_A (.in(o_rt_data_A), .out(o_rt_data1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ort_B (.in(o_rt_data_B), .out(o_rt_data1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ors_A (.in(o_rs_data_A), .out(o_rs_data1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ors_B (.in(o_rs_data_B), .out(o_rs_data1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign o_rt_data_A_bypass=
   (W_stall_A==0&&decode_info3_A[2]!=1'b1&&readre1_A[0]==1'b1&&decode_info1_A[14:12]==decode_info3_A[8:6]&&decode_info3_A[5]==1'b1)?i_wdata_A:
   (W_stall_B==0&&decode_info3_B[2]!=1'b1&&readre1_A[0]==1'b1&&decode_info1_A[14:12]==decode_info3_B[8:6]&&decode_info3_B[5]==1'b1)?i_wdata_B:
   o_rt_data_A;
   ///logic for bypassing
   wire [15:0] alu_inp1_A,alu_inp1_B,alu_inp2_A,alu_inp2_B,pc2_Bf;
   //wx and mx bypassing
   assign alu_inp1_A=
   (M_stall_A==2'b00&&decode_info2_A[2]!=1'b1&&readre1_A[1]==1'b1&&decode_info1_A[14:12]==decode_info2_A[8:6]&&decode_info2_A[5]==1'b1&&(pc2_A!=pc3_A))? o_result1_f_A:
   (M_stall_B==2'b00&&decode_info2_B[2]!=1'b1&&readre1_A[1]==1'b1&&decode_info1_A[14:12]==decode_info2_B[8:6]&&decode_info2_B[5]==1'b1&&(pc2_A!=pc3_B))?o_result1_B:
   (W_stall_A==2'b00&&W_stall_A!=2'b01&&decode_info3_A[2]!=1'b1&&readre1_A[1]==1'b1&&decode_info1_A[14:12]==decode_info3_A[8:6]&&decode_info3_A[5]==1'b1)?i_wdata_fA:
   (W_stall_B==2'b00&&decode_info3_B[2]!=1'b1&&readre1_A[1]==1'b1&&decode_info1_A[14:12]==decode_info3_B[8:6]&&decode_info3_B[5]==1'b1)?i_wdata_B:
   o_rs_data1_A;

   assign alu_inp1_B=
   (M_stall_B==0&&decode_info2_B[2]!=1'b1&&readre1_B[1]==1'b1&&decode_info1_B[14:12]==decode_info2_B[8:6]&&decode_info2_B[5]==1'b1&&(pc2_B!=pc3_B))? o_result1_B:
   (M_stall_A==0&&decode_info2_A[2]!=1'b1&&readre1_B[1]==1'b1&&decode_info1_B[14:12]==decode_info2_A[8:6]&&decode_info2_A[5]==1'b1&&(pc2_B!=pc3_A))? o_result1_A:
   (W_stall_B==0&&decode_info3_B[2]!=1'b1&&readre1_B[1]==1'b1&&decode_info1_B[14:12]==decode_info3_B[8:6]&&decode_info3_B[5]==1'b1)?i_wdata_B:
   (W_stall_A==0&&decode_info3_A[2]!=1'b1&&readre1_B[1]==1'b1&&decode_info1_B[14:12]==decode_info3_A[8:6]&&decode_info3_A[5]==1'b1)?i_wdata_A:
   o_rs_data1_B;
 
   assign alu_inp2_A=
   (M_stall_A==0&&decode_info2_A[2]!=1'b1&&readre1_A[0]==1'b1&&decode_info1_A[11:9]==decode_info2_A[8:6]&&decode_info2_A[5]==1'b1&&(pc2_A!=pc3_A))? (decode_info2_A[3])?(i_cur_dmem_data):o_result1_f_A:
   (M_stall_B==0&&decode_info2_B[2]!=1'b1&&readre1_A[0]==1'b1&&decode_info1_A[11:9]==decode_info2_B[8:6]&&decode_info2_B[5]==1'b1&&(pc2_A!=pc3_B))? (decode_info2_B[3])?(i_cur_dmem_data):o_result1_B:
   (W_stall_A==0&&decode_info3_A[2]!=1'b1&&readre1_A[0]==1'b1&&decode_info1_A[11:9]==decode_info3_A[8:6]&&decode_info3_A[5]==1'b1)?i_wdata_fA:
   (W_stall_B==0&&decode_info3_B[2]!=1'b1&&readre1_A[0]==1'b1&&decode_info1_A[11:9]==decode_info3_B[8:6]&&decode_info3_B[5]==1'b1)?i_wdata_B:
   o_rt_data1_A;
   assign alu_inp2_B=
   (M_stall_B==0&&decode_info2_B[2]!=1'b1&&readre1_B[0]==1'b1&&decode_info1_B[11:9]==decode_info2_B[8:6]&&decode_info2_B[5]==1'b1&&(pc2_B!=pc3_B))? o_result1_B:
   (M_stall_A==0&&decode_info2_A[2]!=1'b1&&readre1_B[0]==1'b1&&decode_info1_B[11:9]==decode_info2_A[8:6]&&decode_info2_A[5]==1'b1&&(pc2_B!=pc3_A))? o_result1_A:
   (W_stall_B==0&&decode_info3_B[2]!=1'b1&&readre1_B[0]==1'b1&&decode_info1_B[11:9]==decode_info3_B[8:6]&&decode_info3_B[5]==1'b1)?i_wdata_B:
   (W_stall_A==0&&decode_info3_A[2]!=1'b1&&readre1_B[0]==1'b1&&decode_info1_B[11:9]==decode_info3_A[8:6]&&decode_info3_A[5]==1'b1)?i_wdata_A:
   o_rt_data1_B;

  
   
   ///over///
   
   lc4_alu alu_A(.i_insn(i_cur_insn2_A),.i_pc(pc2_A),.i_r1data(alu_inp1_A), .i_r2data(alu_inp2_A),
               .o_result(o_result_A));
   lc4_alu alu_B(.i_insn(i_cur_insn2_B),.i_pc(pc2_B),.i_r1data(alu_inp1_B), .i_r2data(alu_inp2_B),
               .o_result(o_result_B));
   //nzp
   assign next_nzp0_A = (nzp_we1_A)?((o_result_A[15] == 1'b1) ? 3'b100 : ((o_result_A == 16'b0) ? 3'b010 : 3'b001)):nzp1_B;
   assign next_nzp0_B = (nzp_we1_B)?((o_result_B[15] == 1'b1) ? 3'b100 : ((o_result_B == 16'b0) ? 3'b010 : 3'b001)):next_nzp0_A;
   wire [2:0] nzp_bypass_A,nzp_bypass_B,nzp0_A,nzp0_B;
   assign nzp_bypass_A=(decode_info1_A[1])?((M_stall_B)?nzp1_A:nzp1_B):next_nzp0_A;
   assign nzp_bypass_B=(decode_info1_B[1])?next_nzp0_A:next_nzp0_B;
   assign next_pc_A = (decode_info1_A[0]&&X_stall_A==0)?o_result_A:
                  (decode_info1_B[0]&&X_stall_Bf==0&&((decode_info1_A[0]==0&&X_stall_A==0)||X_stall_A)) ? o_result_B :
                  (decode_info1_A[1]&&X_stall_A==0&&((decode_info1_B[1]==0&&X_stall_Bf==0)||X_stall_Bf!=0))&&((i_cur_insn2_A[9]==1'b1 && nzp_bypass_A[0]==1'b1)||((i_cur_insn2_A[10]==1'b1 && nzp_bypass_A[1]==1'b1))||((i_cur_insn2_A[11]==1'b1 && nzp_bypass_A[2]==1'b1))) ? o_result_A :
                  (X_stall_Bf==0&&decode_info1_B[1]&&((i_cur_insn2_B[9]==1'b1 && nzp_bypass_B[0]==1'b1)||((i_cur_insn2_B[10]==1'b1 && nzp_bypass_B[1]==1'b1))||((i_cur_insn2_B[11]==1'b1 && nzp_bypass_B[2]==1'b1))))?o_result_B: pc_plus_two;
   ///problem
   assign next_pc_B = (decode_info1_B[0]&&X_stall_B==0) ? o_result_B :
                  ((decode_info1_B[1]&&X_stall_B==0) ? (((i_cur_insn2_B[9]==1'b1 && nzp_bypass_B[0]==1'b1)||((i_cur_insn2_B[10]==1'b1 && nzp_bypass_B[1]==1'b1))||((i_cur_insn2_B[11]==1'b1 && nzp_bypass_B[2]==1'b1))) ? o_result_B :
                                 pc_plus_two) : pc_plus_two);
  //is_branch?(next_pc==pc+1)?nop:change fetch  
   wire mis_prediction_A,mis_prediction_B;
   assign mis_prediction_A=(decode_info1_A[0]&&X_stall_A==0)?1'b1:(decode_info1_A[1]&&(X_stall_A==0)?((((i_cur_insn2_A[9]==1'b1 && nzp_bypass_A[0]==1'b1)||((i_cur_insn2_A[10]==1'b1 && nzp_bypass_A[1]==1'b1))||((i_cur_insn2_A[11]==1'b1 && nzp_bypass_A[2]==1'b1))))?1'b1:1'b0):1'b0);
   assign mis_prediction_B=(decode_info1_B[0]&&X_stall_B==0)?1'b1:((decode_info1_B[1]&&X_stall_B==0)?((((i_cur_insn2_B[9]==1'b1 && nzp_bypass_B[0]==1'b1)||((i_cur_insn2_B[10]==1'b1 && nzp_bypass_B[1]==1'b1))||((i_cur_insn2_B[11]==1'b1 && nzp_bypass_B[2]==1'b1))))?1'b1:1'b0):1'b0);
   assign nzp0_A=((X_stall_A)==2'b10)?nzp1_A:nzp_bypass_A;
   assign nzp0_B=((X_stall_B)==2'b10)?nzp1_B:nzp_bypass_B;
   assign pc2_Bf=(mis_prediction_A)? 0 :pc2_B;
   wire [14:0] decode_info1_Bf=(mis_prediction_A)?decode_info_B&14'b11111111101111:decode_info1_B;
   assign X1_stall_A=(mis_prediction_A)?2'b00:X_stall_A;

   ///memory
   wire [1:0]M_stall_A,M_stall_B;
   wire [14:0] decode_info2_A,decode_info2_B;
   wire [15:0] WMbypass_A,WMbypass_B;
   assign o_result1_f_A=(M_stall_B==0&&(decode_info2_A[8:6]==decode_info2_B[8:6])&&decode_info2_A[5]&&decode_info2_B[5])?o_result1_B:o_result1_A;
   assign X_stall_Bf=(mis_prediction_A)?2'b10:X_stall_B;
   wire [15:0]  o_result1_f_A,pc3_A,pc3_B,o_result1_A,o_result1_B,o_rt_data2_A,o_rt_data2_B,i_cur_insn3_A,i_cur_insn3_B,Minsn_inp_A,Minsn_inp_B,pc_plus_one3,pc_plus_two3,o_dmem_towrite_A,o_dmem_towrite_B;
   wire [2:0] nzp1_A,nzp1_B;
   Nbit_reg #(2, 2'b10) Mstall_A(.in(X1_stall_A), .out(M_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Mstall_B(.in(X_stall_Bf), .out(M_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   wire nzp_we2_A,nzp_we2_B;
   Nbit_reg #(2, 2'b00) read_re1_A (.in(readre1_A), .out(readre2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b00) read_re1_B (.in(readre1_B), .out(readre2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg1_A (.in(nzp_we1_A), .out(nzp_we2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg1_B (.in(nzp_we1_B), .out(nzp_we2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3,3'b000) nzp_reg1_A (.in(nzp0_A), .out(nzp1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3,3'b000) nzp_reg1_B (.in(nzp0_B), .out(nzp1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign Minsn_inp_A=i_cur_insn2_A;
   assign Minsn_inp_B=i_cur_insn2_B;
   Nbit_reg #(16, 16'd0) pc_plus2_A (.in(pc_plus_one2), .out(pc_plus_one3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus2_B (.in(pc_plus_two2), .out(pc_plus_two3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info1_A (.in(decode_info1_A), .out(decode_info2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info1_B (.in(decode_info1_Bf), .out(decode_info2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg3_A (.in(pc2_A), .out(pc3_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg3_B (.in(pc2_Bf), .out(pc3_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru2_A (.in(Minsn_inp_A), .out(i_cur_insn3_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru2_B (.in(Minsn_inp_B), .out(i_cur_insn3_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ort1_A (.in(alu_inp2_A), .out(o_rt_data2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ort1_B (.in(alu_inp2_B), .out(o_rt_data2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) oresult_A (.in(o_result_A), .out(o_result1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) oresult_B (.in(o_result_B), .out(o_result1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   assign WMbypass_A=(decode_info2_A[2]==1'b1)?((decode_info2_A[11:9]==wsel_back_A)&&(readre2_A[0]==1'b1&&decode_info3_A[5]==1'b1)&&!((decode_info2_A[11:9]==wsel_back_B)&&(readre2_A[0]==1'b1&&decode_info3_B[5]==1'b1))?i_wdata_A: ((decode_info2_A[11:9]==wsel_back_B)&&(readre2_A[0]==1'b1&&decode_info3_B[5]==1'b1))?i_wdata_B:0)
      :0;
   assign WMbypass_B=(decode_info2_B[2]==1'b1)?((decode_info2_B[11:9]==wsel_back_B)&&(readre2_B[0]==1'b1&&decode_info3_B[5]==1'b1)?i_wdata_B:((decode_info2_B[11:9]==wsel_back_A)&&(readre2_B[0]==1'b1&&decode_info3_A[5]==1'b1))?i_wdata_A:0)
      :0;


   ///A load(r1<=r2) B store(r1->r3) ???
   ///A's destination == B's source, A destination's data -> B'data
   wire MMbypass=(decode_info2_B[2]&&decode_info2_A[3]!=1'b1)?(((decode_info2_A[8:6]==decode_info2_B[11:9])&&decode_info2_A[5]&&readre2_B[1])?1'b1:1'b0):0;
   assign o_dmem_we = (M_stall_A==0&&decode_info2_A[2])?decode_info2_A[2]:(M_stall_B==0&&decode_info2_B[2])?decode_info2_B[2]:0;
   //assign o_dmem_we_B = (M_stall_B!=0)?1'b0:decode_info2_B[2];
   assign o_dmem_addr=(decode_info2_A[3]||decode_info2_A[2])?o_result1_A:(decode_info2_B[3]||decode_info2_B[2])?o_result1_B:16'b0;
   //assign o_dmem_addr_B=((decode_info2_B[3]||decode_info2_B[2])?o_result1_B:16'b0);
    assign o_dmem_towrite_A=((decode_info2_A[2])? ((WMbypass_A!=0)?WMbypass_A:o_rt_data2_A):16'b0);
    assign o_dmem_towrite_B=(decode_info2_B[2])? ((MMbypass)?o_result1_A:((WMbypass_B!=0)?WMbypass_B:o_rt_data2_B)):0;
   ///meixie!!!!
   assign o_dmem_towrite=(decode_info2_A[2]||decode_info2_A[3])?o_dmem_towrite_A:o_dmem_towrite_B;
   assign Winsn_inp_A=i_cur_insn3_A;
   assign Winsn_inp_B=i_cur_insn3_B;
   
   ///write back

   wire [15:0] o_dmem_towrite1_A,o_dmem_towrite1_B;
   wire [1:0]W_stall_A,W_stall_B;
   wire [2:0] next_nzp1_A,next_nzp1_B,next_nzp0_A,next_nzp0_B;
   wire [14:0] decode_info3_A,decode_info3_B;
   wire [2:0] nzp2_A,nzp2_B;
   wire [15:0]  i_wdata_fA,o_result2_A,o_result2_B,i_cur_insn4_A,i_cur_insn4_B,i_cur_dmem_data1_A,i_cur_dmem_data1_B,Winsn_inp_A,Winsn_inp_B,pc4_A,pc4_B,pc_plus_one4,pc_plus_two4;
   wire nzp_we3_A,nzp_we3_B;
   Nbit_reg #(1, 1'b0) nzpwereg2_A (.in(nzp_we2_A), .out(nzp_we3_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg2_B (.in(nzp_we2_B), .out(nzp_we3_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Wstall_A (.in(M_stall_A), .out(W_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Wstall_B (.in(M_stall_B), .out(W_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus3_A (.in(pc_plus_one3), .out(pc_plus_one4), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus3_B (.in(pc_plus_two3), .out(pc_plus_two4), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //Nbit_reg #(3,3'b000) nzp_reg2_A (.in(nzp1_A), .out(nzp2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //Nbit_reg #(3,3'b000) nzp_reg2_B (.in(nzp1_B), .out(nzp2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //Nbit_reg #(3,3'b000) next_nnnzp (.in(next_nzp), .out(next_nzp1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg4_A (.in(pc3_A), .out(pc4_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg4_B (.in(pc3_B), .out(pc4_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info2_A (.in(decode_info2_A), .out(decode_info3_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info2_B (.in(decode_info2_B), .out(decode_info3_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) oresult1_A (.in(o_result1_A), .out(o_result2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) oresult1_B (.in(o_result1_B), .out(o_result2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru3_A (.in(Winsn_inp_A), .out(i_cur_insn4_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru3_B (.in(Winsn_inp_B), .out(i_cur_insn4_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) mem_data_A (.in(i_cur_dmem_data), .out(i_cur_dmem_data1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) mem_data_B (.in(i_cur_dmem_data), .out(i_cur_dmem_data1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) odmemdata_A (.in(o_dmem_towrite_A), .out(o_dmem_towrite1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) odmemdata_B (.in(o_dmem_towrite_B), .out(o_dmem_towrite1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //W-D bypass 
   
   assign i_wdata_fA=(W_stall_B==0&&(decode_info3_A[8:6]==decode_info3_B[8:6])&&decode_info3_A[5]&&decode_info3_B[5])?i_wdata_B:i_wdata_A;
   assign i_wdata_A=(decode_info3_A[4]&&W_stall_A==0)?(pc_plus_one4):((decode_info3_A[3]&&W_stall_A==0)? i_cur_dmem_data1_A: o_result2_A);
   assign i_wdata_B=(decode_info3_B[4]&&W_stall_B==0)?(pc_plus_two4):((decode_info3_B[3]&&W_stall_B==0)? i_cur_dmem_data1_A: o_result2_B);
   ///decode_info3[3] load, 2 -> store
   //Nbit_reg #(3,3'b000) nzp_reg (.in(nzp2), .out(nzp), .clk(clk), .we(nzp_we2), .gwe(gwe), .rst(rst));
   //assign next_nzp = (o_result1[15] == 1'b1) ? 3'b100 : ((o_result1 == 16'b0) ? 3'b010 : 3'b001);
   
   wire [2:0] final_nzp_A,final_nzp_B;
   assign final_nzp_A=(nzp_we3_A)?(((i_wdata_A[15] == 1'b1) ? 3'b100 : ((i_wdata_A == 16'b0) ? 3'b010 : 3'b001))):0;
   assign final_nzp_B=(nzp_we3_B)?(((i_wdata_B[15] == 1'b1) ? 3'b100 : ((i_wdata_B == 16'b0) ? 3'b010 : 3'b001))):0;
   assign test_cur_pc_A=pc4_A;
   assign test_cur_pc_B=pc4_B;
   assign test_cur_insn_A=i_cur_insn4_A;
   assign test_cur_insn_B=i_cur_insn4_B;
   assign test_stall_A=W_stall_A;
   assign test_stall_B=W_stall_B;
   assign test_regfile_we_A=decode_info3_A[5];
   assign test_regfile_we_B=decode_info3_B[5];
   assign wsel_back_A=decode_info3_A[8:6];
   assign wsel_back_B=decode_info3_B[8:6];
   assign test_regfile_wsel_A=decode_info3_A[8:6];
   assign test_regfile_wsel_B=decode_info3_B[8:6];
   assign test_regfile_data_A=i_wdata_A;
   assign test_regfile_data_B=i_wdata_B;
   assign test_nzp_we_A=nzp_we3_A;
   assign test_nzp_we_B=nzp_we3_B;
   assign test_nzp_new_bits_A=final_nzp_A;
   assign test_nzp_new_bits_B=final_nzp_B;
   assign test_dmem_we_A=decode_info3_A[2];
   assign test_dmem_we_B=decode_info3_B[2];
   assign test_dmem_addr_A=(decode_info3_A[3]||decode_info3_A[2])?o_result2_A:16'b0;
   assign test_dmem_addr_B=(decode_info3_B[3]||decode_info3_B[2])?o_result2_B:16'b0;
   assign test_dmem_data_A=(decode_info3_A[3])?i_cur_dmem_data1_A:(decode_info3_A[2])?o_dmem_towrite1_A:16'd0;  
   assign test_dmem_data_B=(decode_info3_B[3])?i_cur_dmem_data1_B:(decode_info3_B[2])?o_dmem_towrite1_B:16'd0;    
   

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */

    reg [15:0] counter = 0;
      always @(posedge gwe) begin
      //   if (counter>51&&counter<83) begin
      // $display("-----------------------------------------------");
      // $display("fetch pc_A: %h pc_B:%h insn_A:%h insn_B:%h pc_plus_oneA:%h", pc_A, pc_B,i_cur_insn_A,i_cur_insn_B,pc_plus_one); 
      // $display("decode pc_A: %h pc_B:%h %h %h  nextpc_A: %h B_depend_on_A: %h wsel_A:%h r1selb:%h, o_rs_data_A:%h os_f_A:%h DstallA:%h DstallB:%h pc_plus_one:%h,pc_plus_two:%h load_stall_A:%h load_stall_B:%h", pc1_A, pc1_B,i_cur_insn1_A,i_cur_insn1_B, next_pc_A,B_depend_on_A,wsel_back_A,r1sel_B,o_rs_data_A,os_f_A,D_stall_A,D_stall_B,pc_plus_one1,pc_plus_two1,load_stall_A,load_stall_B);
      // $display("exe pcA:%h pcB:%h insnA:%h insnB:%h o_resultA:%h  inp 1B:%h o_resultB:%h inp1A:%h, inp2A:%h o_rs_data1_A:%h o_rt_data1_A:%h o_rt_data1_B:%h o_result1_f_A:%h, mis_prediction_A:%b mis_prediction_B:%b next_pc_A:%h next_pc_B: %h stallA:%h stallB:%h, nzp_bypass__A,%d,nzp_bypass_B:%d nzp_we1_A:%h,nzp_we1_B:%h readre1_A[0]:%b inp2A:%h",pc2_A,pc2_B,i_cur_insn2_A,i_cur_insn2_B,o_result_A,alu_inp1_B,o_result_B,alu_inp1_A,alu_inp2_A,o_rs_data1_A,o_rt_data1_A,o_rt_data1_B,o_result1_f_A,mis_prediction_A,mis_prediction_B,next_pc_A,next_pc_B,X_stall_A,X_stall_B,nzp_bypass_A,nzp_bypass_B,nzp_we1_A,nzp_we1_B,(decode_info1_A[11:9]!=decode_info3_B[8:6]),inp2_A);
      // $display("mem pcA:%h pcB:%h stallA:%h stallB:%h oresult: %h pc_plus_one3:%h nzpA:%h, nzpb:%h o_dmem_addr:%h o_dmem_towrite:%h o_dmem_towriteA:%h o_dmem_towriteB:%h o_rt_data2_A:%h o_rt_data2_B:%h WMbypassA:%h WMbypassB:%h",pc3_A,pc3_B,M_stall_A,M_stall_B,o_result1_B,pc_plus_one2,nzp1_A,nzp1_B,o_dmem_addr,o_dmem_towrite,o_dmem_towrite_A,o_dmem_towrite_B,o_rt_data2_A,o_rt_data2_B,WMbypass_A,WMbypass_B);
      // $display("wb pcA:%h pcB:%h insnA:%h insnB:%h stallA:%h stallB:%h i_wdataA:%h iWdataB:%h o_resultA:%h o_resultB:%h, test_nzp_new_bits_A:%d,test_nzp_new_bits_B,%d pc_plus_one4:%h i_cur_dmem_data1_A:%h i_cur_dmem_data1_B:%h o_dmem_towrite1_A:%h o_dmem_towrite1_B:%h test_regfile_we_A:%h test_regfile_we_B:%h",test_cur_pc_A,test_cur_pc_B,test_cur_insn_A, test_cur_insn_B,test_stall_A,test_stall_B,test_regfile_data_A,test_regfile_data_B,o_result2_A,o_result2_B,test_nzp_new_bits_A,test_nzp_new_bits_B,pc_plus_one4,i_cur_dmem_data1_A,i_cur_dmem_data1_B,o_dmem_towrite1_A, o_dmem_towrite1_B,test_regfile_we_A,test_regfile_we_B);
      // end
      //     counter+=1;
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display();
   end
endmodule
///ld-> o_result should be address of the data to read. 