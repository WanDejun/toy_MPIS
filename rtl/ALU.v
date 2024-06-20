module ALU (
    input               clk         ,
    input               rst_n       ,
    input   wire[5:0]	stall_i     ,   // 挂起标志位
    input   wire[31:0]  pc_i        ,   // pc

    // 解析自IR
    input   wire [31:0] addr_i      ,   // 地址扩展
    input   wire [5:0]  op_i        ,   // 操作符
    input   wire [4:0]  shamt_i     ,   // shamt
    input   wire [5:0]  func_i      ,   // func
    input   wire [15:0] imm_i       ,   // 立即数
    input   wire [31:0] s_imm_i     ,   // 立即数有符号位扩展
    input   wire [31:0] u_imm_i     ,   // 立即数无符号位扩展

    input   wire [1:0]  rw_src_i    ,  // 寄存器写数据选择
    input   wire [4:0]  rw_i        ,   // 操作数rw, 写回寄存器地址
    input   wire        mem_wea_i   ,   // 内存写使能
    input   wire        pcwr_en_i   ,   // 写pc使能

    // 输入操作数
    input   wire [31:0] A_i         ,   // 操作数A
    input   wire [31:0] B_i         ,   // 操作数B

    // 寄存传递
    output  reg  [1:0]  rw_src_o    ,   // 寄存器写数据选择
    output  reg  [4:0]  rw_o        ,   // 操作数rw, 写回寄存器地址
    output  reg         mem_wea_o   ,   // 内存写使能
    output  reg         pcwr_en_o   ,   // 写pc使能

    // ALU计算结果
    output  reg  [31:0] address_o   ,   // 转移或访存指令的地址
    output  reg  [31:0] F_o         ,   // ALU输出
    output  reg         overflow_o  ,   // 溢出标志位
    output  reg         zero_o      ,   // 零标志位
    output  reg         carryout_o      // 进位
);

    // 运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            F_o         =  32'b0;
            overflow_o  =  1'b0 ;
            zero_o      =  1'b0 ;
            carryout_o  =  1'b0 ;
            address_o   =  32'b0;
        end
        else if (!stall_i[3]) begin
            case (op_i) 
                6'b000000: begin    // R型运算
                    address_o   =  32'b0; 
                    case(func_i) 
                        6'b100000    :   // ADD
                        begin     
                            F_o         =   A_i + B_i;
                            overflow_o  =   ((A_i[31] == B_i[31]) && (~F_o[31] == A_i[31])) ? 1'b1 : 1'b0;
                            zero_o      =   (F_o == 32'b0) ? 1'b1 : 1'b0;
                            carryout_o  =   1'b0;
                        end
                        6'b100010   :   // SUB
                        begin    
                            F_o         =   A_i - B_i;
                            overflow_o  =   ((A_i[31] == 1'b0 && B_i[31] == 1'b1 && F_o[31] == 1'b1) || (A_i[31] == 1'b1 && B_i[31] == 1'b0 && F_o[31] == 1'b0)) ? 1'b1 : 1'b0;
                            zero_o      =   (A_i == B_i) ? 1'b1 : 1'b0;
                            carryout_o  =   1'b0;
                        end
                        6'b100100   :   // AND
                        begin    
                            F_o         =   A_i & B_i;
                            overflow_o  =   1'b0;
                            zero_o      =   (F_o == 32'b0) ? 1'b1 : 1'b0;
                            carryout_o  =   1'b0;
                        end
                        6'b100101   :   // OR
                        begin    
                            F_o         =   A_i | B_i;
                            overflow_o  =   1'b0;
                            zero_o      =   (F_o == 32'b0) ? 1'b1 : 1'b0;
                            carryout_o  =   1'b0;
                        end
                        6'b100110   :   // XOR
                        begin    
                            F_o         =   A_i ^ B_i;
                            overflow_o  =   1'b0;
                            zero_o      =   (F_o == 32'b0) ? 1'b1 : 1'b0;
                            carryout_o  =   1'b0;
                        end
                    endcase
                end

                6'b001000: begin    // I型ADDI运算
                    F_o         =   A_i + u_imm_i;
                    overflow_o  =   (A_i[31] == s_imm_i[31]) && (!A_i[31] == F_o[31]) ? 1'b1 : 1'b0;
                    zero_o      =   (F_o == 31'b0) ? 1'b1 : 1'b0;
                    address_o   =   32'b0;
                end

                6'b100011,
                6'b101011: begin    // sw, lw
                    F_o         =   B_i             ;
                    overflow_o  =   overflow_o      ;
                    zero_o      =   zero_o          ;
                    carryout_o  =   carryout_o      ;
                    address_o   =   A_i + u_imm_i   ;
                end

                6'b000100: begin    // beq
                    F_o         =   F_o             ;
                    overflow_o  =   overflow_o      ;
                    zero_o      =   zero_o          ;
                    carryout_o  =   carryout_o      ;
                    address_o   =   pc_i + 32'd4 + ((s_imm_i << 2) | (s_imm_i[31:30]))  ;
                end

                6'b000010: begin    // j
                    F_o         =   F_o             ;
                    overflow_o  =   overflow_o      ;
                    zero_o      =   zero_o          ;
                    carryout_o  =   carryout_o      ;
                    address_o   =   addr_i          ;
                end
                
                default: begin      // default
                    F_o         =   F_o         ;
                    overflow_o  =   overflow_o  ;
                    zero_o      =   zero_o      ;
                    carryout_o  =   carryout_o  ;
                    address_o   =   address_o   ;
                end
            endcase
        end
        else begin
            F_o         =  32'b0;
            overflow_o  =  1'b0 ;
            zero_o      =  1'b0 ;
            carryout_o  =  1'b0 ;
            address_o   =  32'b0;
        end
    end
            
    // pcwr_en 写pc使能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pcwr_en_o   =   1'b0;
        end
        else if (!stall_i[3]) begin
            if (op_i == 6'b000100) begin    // 条件跳转
                pcwr_en_o   =   ((A_i == B_i) ? 1'b1 : 1'b0);
            end
            else begin  // 非条件跳转
                pcwr_en_o   =   pcwr_en_i;
            end
        end
        else begin
            pcwr_en_o   =   1'b0;
        end
    end

    // rw / rw_en / mem_wea 暂存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rw_o        <=  1'b0    ;
            rw_src_o    <=  `RW_NONE;
            mem_wea_o   <=  1'b0    ;
        end
        else if (!stall_i[3]) begin
            rw_o        <=  rw_i        ;
            rw_src_o    <=  rw_src_i    ;
            mem_wea_o   <=  mem_wea_i   ;
        end
        else begin
            rw_o        <=  1'b0    ;
            rw_src_o    <=  `RW_NONE;
            mem_wea_o   <=  1'b0    ;
        end
    end

    
endmodule