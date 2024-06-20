`timescale 1ns/1ns 

module tb_ALU ();

    parameter CLK_PERIOD = 20;
    parameter DIV_CLK = 25;

    reg                 sys_clk;        
    reg                 sys_rst_n;
    
    reg     [31:0]      addr_i  ;

    reg     [5:0]       stall   ;
    reg     [5:0]       op      ;
    reg     [5:0]       func    ;
    reg     [15:0]      imm     ;
    reg     [31:0]      A       ;
    reg     [31:0]      B       ;

    wire    [31:0]      F       ;
    wire    [31:0]      address ;
    wire    [31:0]      s_imm   ;
    wire    [31:0]      u_imm   ;

    wire                overflow;
    wire                zero    ;
    wire                carryout;


    assign  s_imm   = {{16{imm[15]}}, imm[15:0]};    // �������з���λ��չ
    assign  u_imm   = {{16{1'b0}},    imm[15:0]};    // �������޷���λ��չ

    initial begin
        sys_clk     <= 1'b0;
        sys_rst_n   <= 1'b0;
        stall       <= 6'b0;
        #100
        sys_rst_n   <= 1'b1;
        #40

        op          <= 6'b000000; // ADD
        func        <= 6'b100000;
        addr_i      <= 31'h0;
        imm         <= 16'h0000;
        A           <= 32'h7FFFFFFF;
        B           <= 32'h11111111;
        #50

        op          <= 6'b000000; // AND
        func        <= 6'b100100;
        addr_i      <= 31'h0;
        imm         <= 16'h0000;
        A           <= 32'd15;
        B           <= 32'd61;
        #50

        op          <= 6'b000010; // j
        func        <= 6'b000000;
        addr_i      <= 31'hcab020;
        imm         <= 16'h0000;
        A           <= 32'd15;
        B           <= 32'd61;
        #50

        op          <= 6'b000100; // beq
        func        <= 6'b000000;
        addr_i      <= 31'h0;
        imm         <= 16'h3434;
        A           <= 32'd15;
        B           <= 32'd61;
        #50

        op          <= 6'b001000; // addi
        func        <= 6'b000000;
        addr_i      <= 31'h0;
        imm         <= 16'h3434;
        A           <= 32'd15;
        B           <= 32'd61;

    end


    always  #(CLK_PERIOD / 2)   sys_clk = ~sys_clk;

    ALU ALU_0 (
        .clk        (sys_clk    ),
        .rst_n      (sys_rst_n  ),
        .stall_i    (stall      ),   // �����־λ

        .addr_i     (addr_i     ),   // ��ַ��չ
        .op_i       (op         ),   // ������
        .shamt_i    (           ),   // shamt
        .func_i     (func       ),   // func
        .imm_i      (imm        ),   // ������
        .s_imm_i    (s_imm      ),   // �������з���λ��չ
        .u_imm_i    (u_imm      ),   // �������޷���λ��չ

        .rw_en_i    (1'b0       ),   // дʹ��
        .rw_i       (           ),   // ������rw, д�ؼĴ�����ַ
        .mem_wea_i  (           ),   // �ڴ�дʹ��
        .pcwr_en_i  (1'b0       ),   // дpcʹ��

        .A_i        (A          ),   // ������A
        .B_i        (B          ),   // ������B

        // �Ĵ洫��
        .rw_en_o    (           ),   // дʹ��
        .rw_o       (           ),   // ������rw, д�ؼĴ�����ַ
        .mem_wea_o  (           ),   // �ڴ�дʹ��
        .pcwr_en_o  (           ),   // дpcʹ��

        // ALU������
        .address_o  (address    ),   // ת�ƻ�ô�ָ��ĵ�ַ
        .F_o        (F          ),   // ALU���
        .overflow_o (overflow   ),   // �����־λ
        .zero_o     (zero       ),   // ���־λ
        .carryout_o (carryout   )    // ��λ
    );

endmodule