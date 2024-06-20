module ALU (
    input               clk         ,
    input               rst_n       ,
    input   wire[5:0]	stall_i     ,   // �����־λ
    input   wire[31:0]  pc_i        ,   // pc

    // ������IR
    input   wire [31:0] addr_i      ,   // ��ַ��չ
    input   wire [5:0]  op_i        ,   // ������
    input   wire [4:0]  shamt_i     ,   // shamt
    input   wire [5:0]  func_i      ,   // func
    input   wire [15:0] imm_i       ,   // ������
    input   wire [31:0] s_imm_i     ,   // �������з���λ��չ
    input   wire [31:0] u_imm_i     ,   // �������޷���λ��չ

    input   wire [1:0]  rw_src_i    ,  // �Ĵ���д����ѡ��
    input   wire [4:0]  rw_i        ,   // ������rw, д�ؼĴ�����ַ
    input   wire        mem_wea_i   ,   // �ڴ�дʹ��
    input   wire        pcwr_en_i   ,   // дpcʹ��

    // ���������
    input   wire [31:0] A_i         ,   // ������A
    input   wire [31:0] B_i         ,   // ������B

    // �Ĵ洫��
    output  reg  [1:0]  rw_src_o    ,   // �Ĵ���д����ѡ��
    output  reg  [4:0]  rw_o        ,   // ������rw, д�ؼĴ�����ַ
    output  reg         mem_wea_o   ,   // �ڴ�дʹ��
    output  reg         pcwr_en_o   ,   // дpcʹ��

    // ALU������
    output  reg  [31:0] address_o   ,   // ת�ƻ�ô�ָ��ĵ�ַ
    output  reg  [31:0] F_o         ,   // ALU���
    output  reg         overflow_o  ,   // �����־λ
    output  reg         zero_o      ,   // ���־λ
    output  reg         carryout_o      // ��λ
);

    // ����
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
                6'b000000: begin    // R������
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

                6'b001000: begin    // I��ADDI����
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
            
    // pcwr_en дpcʹ��
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pcwr_en_o   =   1'b0;
        end
        else if (!stall_i[3]) begin
            if (op_i == 6'b000100) begin    // ������ת
                pcwr_en_o   =   ((A_i == B_i) ? 1'b1 : 1'b0);
            end
            else begin  // ��������ת
                pcwr_en_o   =   pcwr_en_i;
            end
        end
        else begin
            pcwr_en_o   =   1'b0;
        end
    end

    // rw / rw_en / mem_wea �ݴ�
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