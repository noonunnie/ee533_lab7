`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Team 7, EE533 sp2026
// Description: program counter (increments by 4 because word addressed)
//      if reset is high, pc is reset to 0
//      if stall_cpu is high, pc does not increment
// 
// Create Date:    03/02/2026 
// Design Name: gpu_design (ee533_lab7)
// Module Name:    pc
// Project Name: gpu_design
// Target Devices: XC2VP50
// Description: 
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
module pc(
    input  clk,
    input  reset,
    input  stall_cpu,
    output [31:0] pc_out
);

    reg [31:0] pc_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= 32'b0;
        end else begin
            if (!stall_cpu) begin
                pc_reg <= pc_reg + 4;
            end
        end
    end

    assign pc_out = pc_reg;
endmodule
