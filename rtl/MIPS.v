`include "define.v"

module MIPS (
    input               sys_clk,
    input               sys_rst_n,

    output  reg[1:0]    led
);
    wire    [5:0]   stall       ;   // �����־λ
    wire    [31:0]  pc          ;   // ���������
    
    wire    [31:0]  IR          ;   // ָ��Ĵ���

    wire    [4:0]   ra          ;  
    wire    [4:0]   rb          ;

    wire    [31:0]  if_addr     ;   // ��ȡram�ĵ�ַ
    wire    [31:0]  if_data     ;

    // id �� ALU ֮����ݴ�, ����ͬ���Ĵ�������ʱ��
    wire    [31:0]  id_addr     ;
    wire    [5:0]   id_op       ;
    wire    [4:0]   id_shamt    ;
    wire    [5:0]   id_func     ;
    wire    [15:0]  id_imm      ;
    wire    [31:0]  id_s_imm    ;
    wire    [31:0]  id_u_imm    ;
    
    wire    [1:0]   id_rw_src   ;
    wire    [4:0]   id_rw       ;
    wire            id_mem_wea  ; 
    wire            id_pcwr_en  ;

    wire    [31:0]  reg_addr    ;
    wire    [5:0]   reg_op      ;
    wire    [4:0]   reg_shamt   ;
    wire    [5:0]   reg_func    ;
    wire    [15:0]  reg_imm     ;
    wire    [31:0]  reg_s_imm   ;
    wire    [31:0]  reg_u_imm   ;

    wire    [1:0]   reg_rw_src  ;
    wire    [4:0]   reg_rw      ;
    wire            reg_mem_wea ;
    wire            reg_pcwr_en ;

    // �Ĵ��������Ĳ�����
    wire    [31:0]  A;
    wire    [31:0]  B;

    // ALU���ô���ݴ�
    wire    [1:0]   alu_rw_src  ;   // дʹ��
    wire    [4:0]   alu_rw      ;   // ������rw, д�ؼĴ�����ַ
    wire            alu_mem_wea ;   // �ڴ�дʹ��
    wire            alu_pcwr_en ;   // дpcʹ��

    // ALU ������
    wire    [31:0]  alu_address ;   // ת�ƻ�ô�ָ��ĵ�ַ
    wire    [31:0]  alu_F       ;   // ALU���
    wire            alu_overflow;   // �����־λ
    wire            alu_zero    ;   // ���־λ
    wire            alu_carryout;   // ��λ

    // ALU ����������(����ͬ���ô�ʱ��)
    reg     [31:0]  F           ;   // ALU���
    reg     [1:0]   rw_src      ;   // alu�����alu_rw_src
    reg     [4:0]   rw          ;   // Ŀ��Ĵ�����ַ
    reg             pcwr_en     ;   // дpcʹ��
    reg     [31:0]  address     ;   // дpc��ַ
 
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            F       <= 32'b0    ;
            rw_src  <= `RW_NONE ;
            rw      <= 5'b0     ;
            pcwr_en <= 1'b0     ;
            address <= 32'b0    ;
        end
        else begin
            F       <= alu_F        ;
            rw_src  <= alu_rw_src   ;
            rw      <= alu_rw       ;
            pcwr_en <= alu_pcwr_en  ;
            address <= alu_address  ;
        end
    end

    assign IR = (!stall[1]) ? if_data : 32'b0;

    controller controller_0 (
        .clk        (sys_clk    ), 
        .rst_n      (sys_rst_n  ), 
        .stall_o    (stall      )
    );

    pc_ctrl pc_ctrl_0 (
        .clk        (sys_clk    ),
        .rst_n      (sys_rst_n  ),
        .stall_i    (stall      ),

        .address_i  (address    ),
        .pcwr_en_i  (pcwr_en    ),

        .pc_o       (pc         )
    );


    IF IF_0 (
        .clk        (sys_clk    ),
        .rst_n      (sys_rst_n  ),
        .stall_i    (stall      ),

        .addr_i     (alu_address),
        .pc_i       (pc         ),
        .if_addr_o  (if_addr    )
    );

    blk_mem_gen_1 ram_0 (
        .clka   (sys_clk            ),  // input  wire          clka
        .wea    ({4{alu_mem_wea}}   ),  // input  wire [3 : 0]  wea
        .addra  (alu_address        ),  // input  wire [31 : 0] addra
        .dina   (alu_F              ),  // input  wire [31 : 0] dina

        .clkb   (sys_clk            ),  // input  wire          clkb
        .addrb  (if_addr            ),  // input  wire [31 : 0] addrb
        .doutb  (if_data            )   // output wire [31 : 0] doutb
    );

    id id_0 ( // ������
        .clk        (sys_clk    ),
        .rst_n      (sys_rst_n  ),
        .stall_i    (stall      ),   // �����־λ

        .IR_i       (IR         ),   // ָ��Ĵ���
    
        .addr_o     (id_addr    ),   // ��ַ��չ
                             
        .op_o       (id_op      ),   // ������
        .shamt_o    (id_shamt   ),   // shamt
        .func_o     (id_func    ),   // func
        .imm_o      (id_imm     ),   // ������
        .s_imm_o    (id_s_imm   ),   // �������з���λ��չ
        .u_imm_o    (id_u_imm   ),   // �������޷���λ��չ

        .rw_src_o    (id_rw_src ),   // �Ĵ���дʹ��

        .ra_o       (ra         ),   // ������ra
        .rb_o       (rb         ),   // ������rb
        .rw_o       (id_rw      ),   // ������rw, д�ؼĴ�����ַ

        .mem_wea_o  (id_mem_wea ),   // �ڴ�дʹ��
        .pcwr_en_o  (id_pcwr_en )    // дpcʹ��
    ); // id id_0 

    id_reg id_reg_0 (
        .clk         (sys_clk       ),
        .rst_n       (sys_rst_n     ),

        .addr_i      (id_addr       ),   // ��ַ��չ
        .op_i        (id_op         ),   // ������
        .shamt_i     (id_shamt      ),   // shamt
        .func_i      (id_func       ),   // func
        .imm_i       (id_imm        ),   // ������
        .s_imm_i     (id_s_imm      ),   // �������з���λ��չ
        .u_imm_i     (id_u_imm      ),   // �������޷���λ��չ
        .rw_src_i    (id_rw_src     ),   // д�Ĵ�������Դ
        .rw_i        (id_rw         ),   // ������rw, д�ؼĴ�����ַ
        .mem_wea_i   (id_mem_wea    ),   // �ڴ�дʹ��
        .pcwr_en_i   (id_pcwr_en    ),   // дpcʹ��


        .addr_o      (reg_addr      ),   // ��ַ��չ
        .op_o        (reg_op        ),   // ������
        .shamt_o     (reg_shamt     ),   // shamt
        .func_o      (reg_func      ),   // func
        .imm_o       (reg_imm       ),   // ������
        .s_imm_o     (reg_s_imm     ),   // �������з���λ��չ
        .u_imm_o     (reg_u_imm     ),   // �������޷���λ��չ
        .rw_src_o    (reg_rw_src    ),   // д�Ĵ�������Դ
        .rw_o        (reg_rw        ),   // ������rw, д�ؼĴ�����ַ
        .mem_wea_o   (reg_mem_wea   ),   // �ڴ�дʹ��
        .pcwr_en_o   (reg_pcwr_en   )    // дpcʹ��
    ); // id_reg id_reg_0

    wire            wea;
    wire    [31:0]  reg_dina;
    wire    [31:0]  reg_addra;
    assign  wea = (rw_src == `RW_NONE) ? 1'b0 : 1'b1;
    assign  reg_dina = (rw_src == `RW_ALU) ? F : if_data;
    assign  reg_addra = (rw_src == `RW_NONE) ? ra : rw;

    blk_mem_gen_0 reg_0 (
        .clka       (sys_clk    ),  // input  wire clka
        .ena        (`VCC       ),  // input  wire ena           a�˿�ʹ��
        .wea        (wea        ),  // input  wire [0 : 0] weaдʹ��
        .addra      (reg_addra  ),  // input  wire [4 : 0] addra
        .dina       (reg_dina   ),  // input  wire [31 : 0] dina
        .douta      (A          ),  // output wire [31 : 0] douta

        .clkb       (sys_clk    ),  // input  wire clkb
        .enb        (`VCC       ),  // input  wire enb           b�˿�ʹ��
        .web        (`GND       ),  // input  wire [0 : 0] web   дʹ��
        .addrb      (rb         ),  // input  wire [4 : 0] addrb
        .dinb       ({32{`GND}} ),  // input  wire [31 : 0] dinb
        .doutb      (B          )   // output wire [31 : 0] doutb
    );

    ALU ALU_0 (
        .clk        (sys_clk        ),
        .rst_n      (sys_rst_n      ),
        .stall_i    (stall          ),   // �����־λ
        .pc_i       (pc             ),   // pc

        // ������IR
        .addr_i     (reg_addr       ),   // ��ַ��չ
        .op_i       (reg_op         ),   // ������
        .shamt_i    (reg_shamt      ),   // shamt
        .func_i     (reg_func       ),   // func
        .imm_i      (reg_imm        ),   // ������
        .s_imm_i    (reg_s_imm      ),   // �������з���λ��չ
        .u_imm_i    (reg_u_imm      ),   // �������޷���λ��չ

        .rw_src_i   (reg_rw_src     ),   // // д�Ĵ�������Դ
        .rw_i       (reg_rw         ),   // ������rw, д�ؼĴ�����ַ
        .mem_wea_i  (reg_mem_wea    ),   // �ڴ�дʹ��
        .pcwr_en_i  (reg_pcwr_en    ),   // дpcʹ��

        // ���������
        .A_i        (A          ),   // ������A
        .B_i        (B          ),   // ������B

        // �Ĵ洫��
        .rw_src_o   (alu_rw_src ),  // д�Ĵ�������Դ
        .rw_o       (alu_rw     ),   // ������rw, д�ؼĴ�����ַ
        .mem_wea_o  (alu_mem_wea),   // �ڴ�дʹ��
        .pcwr_en_o  (alu_pcwr_en),   // дpcʹ��

        // ALU������
        .address_o  (alu_address    ),   // ת�ƻ�ô�ָ��ĵ�ַ
        .F_o        (alu_F          ),   // ALU���
        .overflow_o (alu_overflow   ),   // �����־λ
        .zero_o     (alu_zero       ),   // ���־λ
        .carryout_o (alu_carryout   )    // ��λ
    );

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) 
            led <=  2'b0;
        else if (alu_mem_wea)
            led <=  2'b11;
        else 
            led <=  2'b0;
    end
    
endmodule