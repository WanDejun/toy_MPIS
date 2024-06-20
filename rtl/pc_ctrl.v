module pc_ctrl (
    input               clk,
    input               rst_n,
    input       [5:0]   stall_i,

    input       [31:0]  address_i,
    input               pcwr_en_i,

    output  reg [31:0]  pc_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_o    <=  32'd0;
        else if (!stall_i[5]) begin
            if (!pcwr_en_i) // ·Ç×ªÒÆÖ¸Áî
                pc_o    <=  pc_o + 32'd4;
            else 
                pc_o    <=  address_i;
        end
    end
    
endmodule