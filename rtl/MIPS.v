`include "define.v"

module MIPS (
    input               sys_clk,
    input               sys_rst_n,

    output  reg[1:0]    led
);
    wire    [5:0]   stall       ;   // 挂起标志位
    wire    [31:0]  pc          ;   // 程序计数器
    
    wire    [31:0]  IR          ;   // 指令寄存器

    wire    [4:0]   ra          ;  
    wire    [4:0]   rb          ;

    wire    [31:0]  if_addr     ;   // 读取ram的地址
    wire    [31:0]  if_data     ;

    // id 到 ALU 之间的暂存, 用于同步寄存器访问时序
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

    // 寄存器读出的操作数
    wire    [31:0]  A;
    wire    [31:0]  B;

    // ALU到访存的暂存
    wire    [1:0]   alu_rw_src  ;   // 写使能
    wire    [4:0]   alu_rw      ;   // 操作数rw, 写回寄存器地址
    wire            alu_mem_wea ;   // 内存写使能
    wire            alu_pcwr_en ;   // 写pc使能

    // ALU 运算结果
    wire    [31:0]  alu_address ;   // 转移或访存指令的地址
    wire    [31:0]  alu_F       ;   // ALU输出
    wire            alu_overflow;   // 溢出标志位
    wire            alu_zero    ;   // 零标志位
    wire            alu_carryout;   // 进位

    // ALU 运算结果缓存(用于同步访存时序)
    reg     [31:0]  F           ;   // ALU输出
    reg     [1:0]   rw_src      ;   // alu输出的alu_rw_src
    reg     [4:0]   rw          ;   // 目标寄存器地址
    reg             pcwr_en     ;   // 写pc使能
    reg     [31:0]  address     ;   // 写pc地址
 
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

    id id_0 ( // 译码器
        .clk        (sys_clk    ),
        .rst_n      (sys_rst_n  ),
        .stall_i    (stall      ),   // 挂起标志位

        .IR_i       (IR         ),   // 指令寄存器
    
        .addr_o     (id_addr    ),   // 地址扩展
                             
        .op_o       (id_op      ),   // 操作符
        .shamt_o    (id_shamt   ),   // shamt
        .func_o     (id_func    ),   // func
        .imm_o      (id_imm     ),   // 立即数
        .s_imm_o    (id_s_imm   ),   // 立即数有符号位扩展
        .u_imm_o    (id_u_imm   ),   // 立即数无符号位扩展

        .rw_src_o    (id_rw_src ),   // 寄存器写使能

        .ra_o       (ra         ),   // 操作数ra
        .rb_o       (rb         ),   // 操作数rb
        .rw_o       (id_rw      ),   // 操作数rw, 写回寄存器地址

        .mem_wea_o  (id_mem_wea ),   // 内存写使能
        .pcwr_en_o  (id_pcwr_en )    // 写pc使能
    ); // id id_0 

    id_reg id_reg_0 (
        .clk         (sys_clk       ),
        .rst_n       (sys_rst_n     ),

        .addr_i      (id_addr       ),   // 地址扩展
        .op_i        (id_op         ),   // 操作符
        .shamt_i     (id_shamt      ),   // shamt
        .func_i      (id_func       ),   // func
        .imm_i       (id_imm        ),   // 立即数
        .s_imm_i     (id_s_imm      ),   // 立即数有符号位扩展
        .u_imm_i     (id_u_imm      ),   // 立即数无符号位扩展
        .rw_src_i    (id_rw_src     ),   // 写寄存器数据源
        .rw_i        (id_rw         ),   // 操作数rw, 写回寄存器地址
        .mem_wea_i   (id_mem_wea    ),   // 内存写使能
        .pcwr_en_i   (id_pcwr_en    ),   // 写pc使能


        .addr_o      (reg_addr      ),   // 地址扩展
        .op_o        (reg_op        ),   // 操作符
        .shamt_o     (reg_shamt     ),   // shamt
        .func_o      (reg_func      ),   // func
        .imm_o       (reg_imm       ),   // 立即数
        .s_imm_o     (reg_s_imm     ),   // 立即数有符号位扩展
        .u_imm_o     (reg_u_imm     ),   // 立即数无符号位扩展
        .rw_src_o    (reg_rw_src    ),   // 写寄存器数据源
        .rw_o        (reg_rw        ),   // 操作数rw, 写回寄存器地址
        .mem_wea_o   (reg_mem_wea   ),   // 内存写使能
        .pcwr_en_o   (reg_pcwr_en   )    // 写pc使能
    ); // id_reg id_reg_0

    wire            wea;
    wire    [31:0]  reg_dina;
    wire    [31:0]  reg_addra;
    assign  wea = (rw_src == `RW_NONE) ? 1'b0 : 1'b1;
    assign  reg_dina = (rw_src == `RW_ALU) ? F : if_data;
    assign  reg_addra = (rw_src == `RW_NONE) ? ra : rw;

    blk_mem_gen_0 reg_0 (
        .clka       (sys_clk    ),  // input  wire clka
        .ena        (`VCC       ),  // input  wire ena           a端口使能
        .wea        (wea        ),  // input  wire [0 : 0] wea写使能
        .addra      (reg_addra  ),  // input  wire [4 : 0] addra
        .dina       (reg_dina   ),  // input  wire [31 : 0] dina
        .douta      (A          ),  // output wire [31 : 0] douta

        .clkb       (sys_clk    ),  // input  wire clkb
        .enb        (`VCC       ),  // input  wire enb           b端口使能
        .web        (`GND       ),  // input  wire [0 : 0] web   写使能
        .addrb      (rb         ),  // input  wire [4 : 0] addrb
        .dinb       ({32{`GND}} ),  // input  wire [31 : 0] dinb
        .doutb      (B          )   // output wire [31 : 0] doutb
    );

    ALU ALU_0 (
        .clk        (sys_clk        ),
        .rst_n      (sys_rst_n      ),
        .stall_i    (stall          ),   // 挂起标志位
        .pc_i       (pc             ),   // pc

        // 解析自IR
        .addr_i     (reg_addr       ),   // 地址扩展
        .op_i       (reg_op         ),   // 操作符
        .shamt_i    (reg_shamt      ),   // shamt
        .func_i     (reg_func       ),   // func
        .imm_i      (reg_imm        ),   // 立即数
        .s_imm_i    (reg_s_imm      ),   // 立即数有符号位扩展
        .u_imm_i    (reg_u_imm      ),   // 立即数无符号位扩展

        .rw_src_i   (reg_rw_src     ),   // // 写寄存器数据源
        .rw_i       (reg_rw         ),   // 操作数rw, 写回寄存器地址
        .mem_wea_i  (reg_mem_wea    ),   // 内存写使能
        .pcwr_en_i  (reg_pcwr_en    ),   // 写pc使能

        // 输入操作数
        .A_i        (A          ),   // 操作数A
        .B_i        (B          ),   // 操作数B

        // 寄存传递
        .rw_src_o   (alu_rw_src ),  // 写寄存器数据源
        .rw_o       (alu_rw     ),   // 操作数rw, 写回寄存器地址
        .mem_wea_o  (alu_mem_wea),   // 内存写使能
        .pcwr_en_o  (alu_pcwr_en),   // 写pc使能

        // ALU计算结果
        .address_o  (alu_address    ),   // 转移或访存指令的地址
        .F_o        (alu_F          ),   // ALU输出
        .overflow_o (alu_overflow   ),   // 溢出标志位
        .zero_o     (alu_zero       ),   // 零标志位
        .carryout_o (alu_carryout   )    // 进位
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