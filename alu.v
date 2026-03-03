`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Team 7, EE533 sp2026
// Description: Lane-wise operations on packed 4x16-bit lanes.
//      opcodes:
//          0000: AND
//          0001: OR
//          0010: SUM   (4 x 16-bit additions)
//          0011: SUB   (4 x 16-bit subtractions)
//          0100: XNOR
//          0101: CMP   (per-lane, signed)
//          0110: SHIFT (left by bottom 4bit in b lane amount)
//          0111: MOV   (b passed through)
//
// Create Date:    03/02/2026
// Design Name:    gpu_design (ee533_lab7)
// Module Name:    alu
// Project Name:   gpu_design
// Target Devices: XC2VP50
//////////////////////////////////////////////////////////////////////////////////

module alu(
    input  [63:0] a,
    input  [63:0] b,
    input  [3:0]  opcode,
    output reg [63:0] result
);

    always @(*) begin
        result = 64'b0; // default value is 0s
        case (opcode)
            4'b0000: begin  //AND
                result = a & b;
            end

            4'b0001: begin  // OR
                result = a | b;
            end

            4'b0010: begin
                // SUM: 4 independent 16-bit additions (no cross-lane carry)
                result[15:0]   = a[15:0]   + b[15:0];
                result[31:16]  = a[31:16]  + b[31:16];
                result[47:32]  = a[47:32]  + b[47:32];
                result[63:48]  = a[63:48]  + b[63:48];
            end

            4'b0011: begin
                // SUB: 4 independent 16-bit subtractions (no cross-lane borrow)
                result[15:0]   = a[15:0]   - b[15:0];
                result[31:16]  = a[31:16]  - b[31:16];
                result[47:32]  = a[47:32]  - b[47:32];
                result[63:48]  = a[63:48]  - b[63:48];
            end

            4'b0100: begin  // XNOR
                result = ~(a ^ b);
            end

            4'b0110: begin
                // SHIFT left by low 4 bits of the corresponding b lane
                result[15:0]   = a[15:0]   << b[3:0];
                result[31:16]  = a[31:16]  << b[19:16];
                result[47:32]  = a[47:32]  << b[35:32];
                result[63:48]  = a[63:48]  << b[51:48];
            end

            4'b0101: begin  // CMP signed
                result[15:0]   = ($signed(a[15:0])  < $signed(b[15:0]))  ? 16'hFFFF : 16'h0000;
                result[31:16]  = ($signed(a[31:16]) < $signed(b[31:16])) ? 16'hFFFF : 16'h0000;
                result[47:32]  = ($signed(a[47:32]) < $signed(b[47:32])) ? 16'hFFFF : 16'h0000;
                result[63:48]  = ($signed(a[63:48]) < $signed(b[63:48])) ? 16'hFFFF : 16'h0000;
            end

            4'b0111: begin  // MOV
                result = b;
            end
        endcase
    end

endmodule
