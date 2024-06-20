module IF (
    input               clk,
    input               rst_n,
    input       [5:0]   stall_i,

    input       [31:0]  addr_i,
    input       [31:0]  pc_i,
    output wire [31:0]  if_addr_o
);

assign if_addr_o = (!stall_i[0]) ? pc_i : ((!stall_i[4]) ? addr_i : 32'b0);

endmodule