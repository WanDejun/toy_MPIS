module id_reg (
    input               clk         ,
    input               rst_n       ,
    
    input   wire [31:0] addr_i      ,   // 地址扩展
    input   wire [5:0]  op_i        ,   // 操作符
    input   wire [4:0]  shamt_i     ,   // shamt
    input   wire [5:0]  func_i      ,   // func
    input   wire [15:0] imm_i       ,   // 立即数
    input   wire [31:0] s_imm_i     ,   // 立即数有符号位扩展
    input   wire [31:0] u_imm_i     ,   // 立即数无符号位扩展
    input   wire [1:0]  rw_src_i    ,   // 写使能
    input   wire [4:0]  rw_i        ,   // 操作数rw, 写回寄存器地址
    input   wire        mem_wea_i   ,   // 内存写使能
    input   wire        pcwr_en_i   ,   // 写pc使能


    output  reg  [31:0] addr_o      ,   // 地址扩展
    output  reg  [5:0]  op_o        ,   // 操作符
    output  reg  [4:0]  shamt_o     ,   // shamt
    output  reg  [5:0]  func_o      ,   // func
    output  reg  [15:0] imm_o       ,   // 立即数
    output  reg  [31:0] s_imm_o     ,   // 立即数有符号位扩展
    output  reg  [31:0] u_imm_o     ,   // 立即数无符号位扩展
    output  reg  [1:0]  rw_src_o    ,   // 写使能
    output  reg  [4:0]  rw_o        ,   // 操作数rw, 写回寄存器地址
    output  reg         mem_wea_o   ,   // 内存写使能
    output  reg         pcwr_en_o       // 写pc使能
);

    // 延迟一拍
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_o      <=  32'b0   ; 
            op_o        <=  6'b0    ;
            shamt_o     <=  5'b0    ;
            func_o      <=  6'b0    ;
            imm_o       <=  16'b0   ;
            s_imm_o     <=  32'b0   ;
            u_imm_o     <=  32'b0   ;
            rw_src_o    <=  `RW_NONE;
            rw_o        <=  5'b0    ;
            mem_wea_o   <=  1'b0    ;
            pcwr_en_o   <=  1'b0    ;
        end
        else begin
            addr_o      <=  addr_i      ;  
            op_o        <=  op_i        ;    
            shamt_o     <=  shamt_i     ; 
            func_o      <=  func_i      ;  
            imm_o       <=  imm_i       ; 
            s_imm_o     <=  s_imm_i     ; 
            u_imm_o     <=  u_imm_i     ; 
            rw_src_o    <=  rw_src_i    ; 
            rw_o        <=  rw_i        ;   
            mem_wea_o   <=  mem_wea_i   ;
            pcwr_en_o   <=  pcwr_en_i   ;
        end
    end

endmodule