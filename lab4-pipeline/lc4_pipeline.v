/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/
   assign led_data = switch_data;
   
   wire [2:0] r1sel,r2sel,wsel,wsel_back,next_nzp,nzp;
   wire r1re,r2re, regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn;
   wire [15:0] o_result,o_rs_data,o_rt_data,i_wdata;
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   np,np1,next_pc,  pc_plus_one,pp; // Next program counter (you compute this and feed it into next_pc)
   
   


   ///fetch
   wire [1:0]F_stall,F1_stall;
   assign np=(load_stall==1'b1)?pc:next_pc;
   Nbit_reg #(2, 2'b0) Fstall (.in(2'b0), .out(F_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg (.in(np), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   cla16 s(.a(pc),.b(16'b0),.cin(1'b1),.sum(pc_plus_one));
   assign o_cur_pc=pc;
   assign F1_stall=(mis_prediction)?2'b10:F_stall;
   
   ///decode
   wire [1:0]D_stall;
   wire [15:0]   pc1,pc_plus_one1;
   wire [15:0]  Dinsn_inp,i_cur_insn1;
   assign Dinsn_inp=(load_stall==1'b1)?i_cur_insn1:i_cur_insn;
   assign np1=(load_stall==1'b1)?pc1:pc;
   assign pp=(load_stall==1'b1)?pc_plus_one1:pc_plus_one;
   
   Nbit_reg #(2, 2'b10) Dstall (.in(F1_stall), .out(D_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg1 (.in(np1), .out(pc1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus (.in(pc_plus_one), .out(pc_plus_one1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru (.in(Dinsn_inp), .out(i_cur_insn1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   lc4_decoder decode( .insn(i_cur_insn1), .r1sel(r1sel), .r1re(r1re), .r2sel(r2sel),  .r2re(r2re),               // does this instruction read from rt?
                   .wsel(wsel), .regfile_we(regfile_we), .nzp_we(nzp_we),  .select_pc_plus_one(select_pc_plus_one), // write PC+1 to the regfile?
                   .is_load(is_load), .is_store(is_store), .is_branch(is_branch),          // is this a branch instruction?
                   .is_control_insn(is_control_insn)     
                   );
   wire [15:0] os_f,ot_f;
   wire immed;
   assign immed =((i_cur_insn1[15:12]==4'b0001||i_cur_insn1[15:12]==4'b0101)&&i_cur_insn1[5]==1'b1)?1'b1:
   ((i_cur_insn1[15:12]==4'b1010&&i_cur_insn1[5:4]!=2'b11)?1'b1:1'b0);
   //register file 
   lc4_regfile #(16) reg1(.clk(clk), .gwe(gwe),.rst(rst),.i_rs(r1sel), .o_rs_data(o_rs_data), // rs contents
    .i_rt(r2sel),   .o_rt_data(o_rt_data), .i_rd(wsel_back),  .i_wdata(i_wdata),   // data to write
    .i_rd_we(decode_info3[5])    // write enable
    ); 
   assign os_f=(r1sel==wsel_back&&decode_info3[5]==1'b1)?i_wdata:o_rs_data;
   assign ot_f=(r2sel==wsel_back&&decode_info3[5]==1'b1)?i_wdata:o_rt_data;
   wire [14:0] decode_info;
   wire regfile_we_with_stall;
   assign regfile_we_with_stall=(D1_stall==2'b10)?0:regfile_we;
   assign decode_info={r1sel,r2sel,wsel,regfile_we_with_stall,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn};
   
   wire load_stall;
   assign load_stall=
   (pc2==pc1)?1'b0:
   ((decode_info1[3]==1'b1&&X_stall==0)?
         (((decode_info[14:12]==decode_info1[8:6]&&r1re==1'b1)||(decode_info[1]))?
            1'b1:
            ((decode_info[3]==1'b0&&decode_info[2]==1'b0)? 
            ((immed==1'b1)?
               1'b0:
               (((decode_info[11:9]==decode_info1[8:6])&&r2re)?
                  1'b1:
                  1'b0)):
               1'b0)) 
   :1'b0);

   assign D1_stall=(load_stall==1'b1&&mis_prediction==1'b0)?2'b11:((mis_prediction&&X_stall!=2'b11)?2'b10:D_stall);
   //info1==load?(info==store?0: (load?(r1==info1[wel])?1:0)conditions ):0

   ////execution
   assign Xinsn_inp=i_cur_insn1;
   
   wire[1:0] X_stall,D1_stall;
   wire [1:0] readre,readre1,readre2;
   assign readre={r1re,r2re};
   wire [15:0]   pc2,pc_plus_one2;
   wire [15:0]  i_cur_insn2,Xinsn_inp;
   wire [15:0] o_rs_data1,o_rt_data1;
   wire [14:0] decode_info1,decode_info_select;
   // assign decode_info_select=()?
   wire nzp_we1;
   
   
   Nbit_reg #(2, 2'b00) read_re (.in(readre), .out(readre1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg (.in(nzp_we), .out(nzp_we1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Xstall (.in(D1_stall), .out(X_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus1 (.in(pc_plus_one1), .out(pc_plus_one2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info (.in(decode_info), .out(decode_info1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg2 (.in(pc1), .out(pc2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru1 (.in(Xinsn_inp), .out(i_cur_insn2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ort (.in(ot_f), .out(o_rt_data1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ors (.in(os_f), .out(o_rs_data1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   ///logic for bypassing
   wire [15:0] alu_inp1,alu_inp2,inp2;
   //wx and mx bypassing
   assign alu_inp1=(M_stall!=2'b10&&decode_info2[2]!=1'b1&&readre1[1]==1'b1&&decode_info1[14:12]==decode_info2[8:6]&&decode_info2[5]==1'b1&&(pc2!=pc3))? o_result1:(W_stall!=2'b10&&decode_info3[2]!=1'b1&&readre1[1]==1'b1&&decode_info1[14:12]==decode_info3[8:6]&&decode_info3[5]==1'b1)?i_wdata:o_rs_data1;
   assign alu_inp2=(M_stall!=2'b10&&decode_info2[2]!=1'b1&&readre1[0]==1'b1&&decode_info1[11:9]==decode_info2[8:6]&&decode_info2[5]==1'b1&&(pc2!=pc3))? o_result1:(W_stall!=2'b10&&decode_info3[2]!=1'b1&&readre1[0]==1'b1&&decode_info1[11:9]==decode_info3[8:6]&&decode_info3[5]==1'b1)?i_wdata:o_rt_data1;
   assign inp2=(decode_info1[2]==1'b1)?((decode_info1[11:9]==decode_info3[8:6]&&readre1[0]==1'b1&&decode_info3[5]==1'b1)?i_wdata:o_rt_data1):o_rt_data1;
   ///over///

   lc4_alu alu(.i_insn(i_cur_insn2),.i_pc(pc2),.i_r1data(alu_inp1), .i_r2data(alu_inp2),
               .o_result(o_result));
   //nzp
   assign next_nzp0 = (nzp_we1)?((o_result[15] == 1'b1) ? 3'b100 : ((o_result == 16'b0) ? 3'b010 : 3'b001)):nzp1;
   wire [2:0] nzp_bypass,nzp0;
   assign nzp_bypass=(decode_info1[1])?nzp1:next_nzp0;
   assign next_pc = (decode_info1[0]&&X_stall!=2'b10&&X_stall!=2'b11) ? o_result :
                  ((decode_info1[1]&&X_stall!=2'b10&&X_stall!=2'b11) ? (((i_cur_insn2[9]==1'b1 && nzp_bypass[0]==1'b1)||((i_cur_insn2[10]==1'b1 && nzp_bypass[1]==1'b1))||((i_cur_insn2[11]==1'b1 && nzp_bypass[2]==1'b1))) ? o_result :
                                 pc_plus_one) : pc_plus_one);
  //is_branch?(next_pc==pc+1)?nop:change fetch  
   wire mis_prediction;
   assign mis_prediction=(decode_info1[0]&&X_stall!=2'b10)?1'b1:((decode_info1[1]&&X_stall!=2'b10)?((((i_cur_insn2[9]==1'b1 && nzp_bypass[0]==1'b1)||((i_cur_insn2[10]==1'b1 && nzp_bypass[1]==1'b1))||((i_cur_insn2[11]==1'b1 && nzp_bypass[2]==1'b1))))?1'b1:1'b0):1'b0);
   assign nzp0=((X_stall)==2'b10)?nzp1:next_nzp0;


   ///memory
   wire [1:0]M_stall;
   wire [14:0] decode_info2;
   wire WMbypass;
   
   wire [15:0]  pc3,o_result1,o_rt_data2,i_cur_insn3,Minsn_inp,pc_plus_one3;
   wire [2:0] nzp1;
   Nbit_reg #(2, 2'b10) Mstall (.in(X_stall), .out(M_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   wire nzp_we2;
   Nbit_reg #(2, 2'b00) read_re1 (.in(readre1), .out(readre2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzpwereg1 (.in(nzp_we1), .out(nzp_we2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3,3'b000) nzp_reg1 (.in(nzp0), .out(nzp1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign Minsn_inp=i_cur_insn2;
   Nbit_reg #(16, 16'd0) pc_plus2 (.in(pc_plus_one2), .out(pc_plus_one3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(15, 15'd0) deco_info1 (.in(decode_info1), .out(decode_info2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg3 (.in(pc2), .out(pc3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru2 (.in(Minsn_inp), .out(i_cur_insn3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) ort1 (.in(inp2), .out(o_rt_data2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) oresult (.in(o_result), .out(o_result1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   assign WMbypass=(decode_info2[2]==1'b1)?((decode_info2[11:9]==wsel_back)&&(readre2[0]==1'b1&&decode_info3[5]==1'b1)?1'b1:1'b0)
      :1'b0;
   assign o_dmem_we = (M_stall!=0)?1'b0:decode_info2[2];
   assign o_dmem_addr=((decode_info2[3]||decode_info2[2])?o_result1:16'b0);
   assign o_dmem_towrite=((decode_info2[2])? ((WMbypass==1'b1)?i_wdata:o_rt_data2):16'b0);

   assign Winsn_inp=i_cur_insn3;
   
   ///write back

   wire [15:0] o_dmem_towrite1;
   wire [1:0]W_stall;
   wire [2:0] next_nzp1,next_nzp0;
   wire [14:0] decode_info3;
   wire [2:0] nzp2;
   wire [15:0]  o_result2,i_cur_insn4,i_cur_dmem_data1,Winsn_inp,pc4,pc_plus_one4;
   wire nzp_we3;
   Nbit_reg #(1, 1'b0) nzpwereg2 (.in(nzp_we2), .out(nzp_we3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) Wstall (.in(M_stall), .out(W_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_plus3 (.in(pc_plus_one3), .out(pc_plus_one4), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3,3'b000) nzp_reg2 (.in(nzp1), .out(nzp2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //Nbit_reg #(3,3'b000) next_nnnzp (.in(next_nzp), .out(next_nzp1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) pc_reg4 (.in(pc3), .out(pc4), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(15, 15'd0) deco_info2 (.in(decode_info2), .out(decode_info3), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) oresult1 (.in(o_result1), .out(o_result2), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) instru3 (.in(Winsn_inp), .out(i_cur_insn4), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'd0) mem_data (.in(i_cur_dmem_data), .out(i_cur_dmem_data1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'd0) odmemdata (.in(o_dmem_towrite), .out(o_dmem_towrite1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //W-D bypass 
   assign i_wdata=(decode_info3[4])?(pc_plus_one4):((decode_info3[3])? i_cur_dmem_data1: o_result2);
   ///decode_info3[3] load, 2 -> store
   //Nbit_reg #(3,3'b000) nzp_reg (.in(nzp2), .out(nzp), .clk(clk), .we(nzp_we2), .gwe(gwe), .rst(rst));
   //assign next_nzp = (o_result1[15] == 1'b1) ? 3'b100 : ((o_result1 == 16'b0) ? 3'b010 : 3'b001);
   
   wire [2:0] final_nzp;
   assign final_nzp=(nzp_we3)?(((i_wdata[15] == 1'b1) ? 3'b100 : ((i_wdata == 16'b0) ? 3'b010 : 3'b001))):0;
   assign test_cur_pc=pc4;
   assign test_cur_insn=i_cur_insn4;
   assign test_stall=W_stall;
   assign test_regfile_we=decode_info3[5];
   assign wsel_back=decode_info3[8:6];
   assign test_regfile_wsel=decode_info3[8:6];
   assign test_regfile_data=i_wdata;
   assign test_nzp_we=nzp_we3;
   assign test_nzp_new_bits=final_nzp;
   assign test_dmem_we=decode_info3[2];
   assign test_dmem_addr=(decode_info3[3]||decode_info3[2])?o_result2:16'b0;
   assign test_dmem_data=(decode_info3[3])?i_cur_dmem_data1:o_dmem_towrite1;    


`ifndef NDEBUG
    //reg [15:0] counter = 0;
   always @(posedge gwe) begin
      
       // if (counter>1785&&counter<1796) begin
      // //  //$display("  insn: %b pc:%h stall: %d nzpwe:%b  nzp:%d reg_in:%h we: %b wsel: %d pc2 %h result %h rs: %h rt: %h" ,  test_cur_insn,test_cur_pc,test_stall,nzp_we3,test_nzp_new_bits,test_regfile_data,test_regfile_we,test_regfile_wsel,pc2,o_result,alu_inp1,alu_inp2);
      // //  //$display("  EXE: insn: %b pc:%h  o_result:%h wsel:%d", i_cur_insn1, pc1,o_result,decode_info1[8:6]);
      //  $display(" cycle %d fetch :  insn: %b  pc:%h   Fstall    : %d, ",counter,i_cur_insn,pc,F_stall);
      //  $display(" cycle %d decode:  insn: %b  pc:%h   load_stall: %d Dstall: %d r1: %d  r2: %d, wsel:%d, rt_data:%h, rs_data:%h,wselback:%d, iwdata:%h, nzp_we:%d",counter,i_cur_insn1,pc1,load_stall,D1_stall,decode_info[14:12],decode_info[11:9],wsel,ot_f,os_f,wsel_back,i_wdata,nzp_we);
      //   $display(" cycle %d EXE   :  insn: %b  pc:%h   o_result  : %h wsel  : %d we: %d  Xstall: %d, aluinp1:%h, aluinp2:%h, rtdata:%h,rsdata:%h mispre:%d,next_pc:%h, nzpbypass %d, nzp_we1:%d,next_nzp0:%d,pc_plus_one:%h", counter,i_cur_insn2, pc2,o_result,decode_info1[8:6],decode_info1[5],X_stall,alu_inp1,alu_inp2,o_rt_data1,o_rs_data1,mis_prediction,next_pc,nzp_bypass,nzp_we1,next_nzp0,pc_plus_one2);
      //  $display(" cycle %d Mem   :  insn: %b  pc:%h   o_result  : %h wsel  : %d Mstall: %d WMbypass:%b,o_dmem_addr%h,i_cur_dmem_data:%h,o_dmem_we: %d,o_dmem_towrite %h,nzp_we2 :%d, next_nzp:%d",counter, i_cur_insn3, pc3,o_result1,decode_info2[8:6],M_stall,WMbypass,o_dmem_addr,i_cur_dmem_data,o_dmem_we,o_dmem_towrite,nzp_we2 ,nzp1);
      //  $display(" cycle %d  WB   :  insn: %b  pc:%h   o_result  : %h wsel  : %d i_wdata:%h test_dmem_data:%h o_dmem_towrite: %h,Wstall: %d,i_cur_dmem_data1:%h,test_dmem_addr:%h ,test_dmem_we%d, nzpwe:%d,next_nzp:%d,test_regfile_we:%d",counter, i_cur_insn4, pc4,o_result2,decode_info3[8:6],i_wdata,test_dmem_data,o_dmem_towrite1,W_stall,i_cur_dmem_data1,test_dmem_addr,test_dmem_we,nzp_we3,nzp2,test_regfile_we );
      //  //$display("Time: %d %h %h %h %h %h %h %h ", $time,pc3, i_cur_dmem_data, o_dmem_towrite, test_dmem_data, o_dmem_addr,test_dmem_addr, o_dmem_we);
      //  $display("-------------------------------------------");
      //  end
      //  counter+=1;
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      //  if ($time<500)
      //   $display("is %d", D_stall);

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
      // run it for that many nano-seconds, then set
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
`endif
endmodule
