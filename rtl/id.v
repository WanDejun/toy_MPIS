`include "define.v"

// ����,��IR��ɼĴ��������ALU����
module id (
    input               clk         ,
    input               rst_n       ,
    input   wire[5:0]	stall_i     ,   // �����־λ

    input   wire [31:0] IR_i        ,   // ָ��Ĵ���
    
    output  reg [31:0]  addr_o      ,   // ��ַ��չ

    output  reg [5:0]   op_o        ,   // ������
    output  reg [4:0]   shamt_o     ,   // shamt
    output  reg [5:0]   func_o      ,   // func
    output  reg [15:0]  imm_o       ,   // ������
    output  reg [31:0]  s_imm_o     ,   // �������з���λ��չ
    output  reg [31:0]  u_imm_o     ,   // �������޷���λ��չ

    output  reg [1:0]   rw_src_o     ,   // �Ĵ���дʹ��

    output  reg [4:0]   ra_o        ,   // ������ra
    output  reg [4:0]   rb_o        ,   // ������rb
    output  reg [4:0]   rw_o        ,   // ������rw, д�ؼĴ�����ַ

    output  reg         mem_wea_o   ,   // �ڴ�дʹ��
    output  reg         pcwr_en_o       // дpcʹ��
);

    wire    [4:0]  rs;  // rs
    wire    [4:0]  rt;  // rt
    wire    [4:0]  rd;  // rd

    wire    [5:0]  op;  // ������

    assign  rs      = IR_i[25:21];
    assign  rt      = IR_i[20:16];
    assign  rd      = IR_i[15:11];

    assign  op      = IR_i[31:26];


    // ��ַ��չ
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            addr_o  <= 32'b0;
        end
        else if (!stall_i[1]) begin
            addr_o  <= {4'b0000, IR_i[25:0], {2'b00}};
        end
        else begin
            addr_o  <= addr_o;
        end
    end

    // ����ALU�Ĳ�����
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            op_o    <= 6'b111111;
            shamt_o <= 5'b0     ;
            func_o  <= 6'b0     ;
            imm_o   <= 16'b0    ;
            s_imm_o <= 32'b0    ;
            u_imm_o <= 32'b0    ;
        end
        else if (!stall_i[1]) begin
            op_o    <= IR_i[31:26];
            shamt_o <= IR_i[10:6];
            func_o  <= IR_i[5:0];
            imm_o   <= IR_i[15:0];                      // ������
            s_imm_o <= {{16{IR_i[15]}}, IR_i[15:0]};    // �������з���λ��չ
            u_imm_o <= {{16{1'b0}},     IR_i[15:0]};    // �������޷���λ��չ
        end
        else begin
            op_o    <= op_o     ;
            shamt_o <= shamt_o  ;
            func_o  <= func_o   ;
            imm_o   <= imm_o    ;
            s_imm_o <= s_imm_o  ;
            u_imm_o <= u_imm_o  ;
        end
    end

    // ����Reg�ѵĲ�����
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            ra_o    <= 5'b0     ;
            rb_o    <= 5'b0     ;
            rw_o    <= 5'b0     ;
            rw_src_o<= `RW_NONE ;
        end
        else if (IR_i == 32'b0) begin
            ra_o    <= 5'b0     ;
            rb_o    <= 5'b0     ;
            rw_o    <= 5'b0     ;
            rw_src_o<= `RW_NONE ;
        end
        else if (!stall_i[1]) begin
            case (op)
                6'b000000: begin        // R������(ADD, SUB, AND, OR, XOR, SLT)
                    ra_o    <=  rs      ;
                    rb_o    <=  rt      ;
                    rw_o    <=  rd      ;
                    rw_src_o<=  `RW_ALU ;
                end

                6'b001000: begin        // I��ADDI����
                    ra_o    <=  rs      ;
                    rb_o    <=  5'b0    ;
                    rw_o    <=  rt      ;
                    rw_src_o<=  `RW_ALU ;
                end

                6'b100011: begin        // lw�ô�
                    ra_o    <=  rs      ;
                    rb_o    <=  5'b0    ;
                    rw_o    <=  rt      ;
                    rw_src_o<=  `RW_RAM ;
                end

                6'b101011: begin        // sw�ô�
                    ra_o    <=  rs      ;
                    rb_o    <=  rt      ;
                    rw_o    <=  5'b0    ;
                    rw_src_o<=  `RW_NONE;
                end

                6'b000100: begin  // beq�����ת��imm
                    ra_o    <=  rs      ;
                    rb_o    <=  rt      ;
                    rw_o    <=  5'b0    ;
                    rw_src_o<=  `RW_NONE;
                end
                6'b000010: begin // j��������ת
                    ra_o    <=  5'b0    ;
                    rb_o    <=  5'b0    ;
                    rw_o    <=  5'b0    ;
                    rw_src_o<=  `RW_NONE;
                end
                default: begin // Ĭ��
                    ra_o    <=  ra_o    ;
                    rb_o    <=  rb_o    ;
                    rw_o    <=  rw_o    ;
                    rw_src_o<=  `RW_NONE;
                end
            endcase
        end
        else begin
            ra_o    <= ra_o     ;
            rb_o    <= rb_o     ;
            rw_o    <= rw_o     ;
            rw_src_o<= rw_src_o ;
        end
    end

    // �����ڴ�Ĳ�����
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            mem_wea_o   <=  1'b0;
        end
        else begin
            if (op == 6'b101011) begin
                mem_wea_o   <=  1'b1;
            end
            else begin
                mem_wea_o   <=  1'b0;
            end
        end
    end

    // ����PC�Ĵ����Ĳ�����
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            pcwr_en_o   <=  1'b0;
        end
        else if (!stall_i[1]) begin
            if (op == 6'b000100 || op == 6'b000010) begin // beq, j
                pcwr_en_o   <=  1'b1;
            end
            else begin
                pcwr_en_o   <=  1'b0;
            end
        end
        else begin
            pcwr_en_o   <=  pcwr_en_o;
        end
    end

endmodule