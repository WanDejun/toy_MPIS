module controller (
    input               clk     ,
    input               rst_n   ,

    output reg [5:0]    stall_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stall_o     <=  6'b111110;
        else 
            stall_o     <=  {stall_o[4:0], stall_o[5]};
    end
    
endmodule