`include "define.v"
`timescale 1ns/1ns 

module tb_MIPS ();

    parameter CLK_PERIOD = 20;
    parameter DIV_CLK = 25;

    reg                 sys_clk;        
    reg                 sys_rst_n;

    reg                 wea     ;
    reg     [4:0]       ra      ;
    reg     [31:0]      dina    ;
    reg     [31:0]      A       ;
    reg     [4:0]       rb      ;
    reg     [31:0]      B       ;

    initial begin
        sys_clk     <= 1'b0;
        sys_rst_n   <= 1'b0;
        #100
        sys_rst_n   <= 1'b1;
        #40

        wea         <= 1'b1;
        ra          <= 5'd0;
        A           <= 32'h1111;
        #40

        wea         <= 1'b1;
        ra          <= 5'd1;
        rb          <= 5'd0;
        A           <= 32'h2222;
        #40

        wea         <= 1'b1;
        ra          <= 5'd2;
        rb          <= 5'b1;
        A           <= 32'h3333;
        #40

        wea         <= 1'b1;
        ra          <= 5'd3;
        rb          <= 5'd2;
        A           <= 32'h4444;
        #40

        wea         <= 1'b0;
        ra          <= 5'd0;
        rb          <= 5'd1;
        #40

        wea         <= 1'b0;
        ra          <= 5'd2;
        rb          <= 5'd3;
    end


    always  #(CLK_PERIOD / 2)   sys_clk = ~sys_clk;

    blk_mem_gen_0 reg_0 (
        .clka       (sys_clk    ),  // input  wire clka
        .ena        (`VCC       ),  // input  wire ena           a端口使能
        .wea        (wea        ),  // input  wire [0 : 0] wea   写使能
        .addra      (ra         ),  // input  wire [4 : 0] addra
        .dina       (dina       ),  // input  wire [31 : 0] dina
        .douta      (A          ),  // output wire [31 : 0] douta

        .clkb       (sys_clk    ),  // input  wire clkb
        .enb        (`VCC       ),  // input  wire enb           b端口使能
        .web        (`GND       ),  // input  wire [0 : 0] web   写使能
        .addrb      (rb         ),  // input  wire [4 : 0] addrb
        .dinb       (           ),  // input  wire [31 : 0] dinb
        .doutb      (B          )   // output wire [31 : 0] doutb
    );

endmodule