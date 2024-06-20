`timescale 1ns/1ns 

module tb_MIPS ();

   parameter CLK_PERIOD = 20;
   parameter DIV_CLK = 25;

   reg                 sys_clk;        
   reg                 sys_rst_n;

   initial begin
       sys_clk     <= 1'b0;
       sys_rst_n   <= 1'b0;
       #100
       sys_rst_n   <= 1'b1;

//       IR          <= 32'b001000_00000_00000_0000_0000_1100_0010;   // addi r0 r0 00c2
//       #120
//       IR          <= 32'b001000_00000_00000_0000_0101_0101_0101;   // addi r0 r0 0555
//       #120
//       IR          <= 32'b000000_00001_00000_00001_00000_100000;    // add  r1 r0 r1
//       #120
//       IR          <= 32'b001000_00001_00001_0000_0000_0000_0011;   // addi r1 r1 0003
//       #120
//       IR          <= 32'b000000_00000_00001_00010_00000_100100;    // and  r0 r1 r2
   end


   always  #(CLK_PERIOD / 2)   sys_clk = ~sys_clk;

   MIPS u_MIPS (
       .sys_clk        (sys_clk    ),
       .sys_rst_n      (sys_rst_n  )
   );

endmodule
