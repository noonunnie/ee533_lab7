`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Team 7, EE533 sp2026
// Description: decode instructions (first by type then using 4b opcode)
//      we can add a halt if we want but rn, gpu is always running
// Create Date:    03/02/2026
// Design Name:    gpu_design (ee533_lab7)
// Module Name:    decoder
// Project Name:   gpu_design
// Target Devices: XC2VP50
//////////////////////////////////////////////////////////////////////////////////

module decoder (
    input  [31:0] instr,
    input         tensor_busy,

    // decoded fields
    output [3:0]  rd,   // destination register
    output [3:0]  rs1,  // source register 1
    output [3:0]  rs2,  // source register 2
    output [13:0] imm,  // immediate value

    output [3:0]  alu_opcode,

    // enable bits
    output        regfile_we,
    output        alu_enable,
    output        mem_read,
    output        mem_write,

    output        tensor_start,
    output        stall_cpu     // we need this so we can stall cpu if tensor is busy
);

    // decode GPU ISA (type + 4 opcode)
    wire [5:0] opcode = instr[31:26];
    assign rd        = instr[25:22];
    assign rs1       = instr[21:18];
    assign rs2       = instr[17:14];
    assign imm       = instr[13:0];

    wire [1:0] type  = opcode[5:4];
    wire [3:0] op    = opcode[3:0];

    // control signals
    reg        regfile_we_r;
    reg        alu_enable_r;
    reg        mem_read_r;
    reg        mem_write_r;
    reg        tensor_start_r;
    reg        stall_cpu_r;
    reg [3:0]  alu_opcode_r;

    assign regfile_we   = regfile_we_r;
    assign alu_enable   = alu_enable_r;
    assign mem_read     = mem_read_r;   // memory read
    assign mem_write    = mem_write_r;   // memory write
    assign tensor_start = tensor_start_r;
    assign stall_cpu    = stall_cpu_r;
    assign alu_opcode   = alu_opcode_r;

    always @(*) begin
        // default to avoid latches (they are bad right?)
        regfile_we_r   = 1'b0;
        alu_enable_r   = 1'b0;
        mem_read_r     = 1'b0;
        mem_write_r    = 1'b0;
        tensor_start_r = 1'b0;
        stall_cpu_r    = 1'b0;
        alu_opcode_r   = 4'b0000;

        // if tensor busy, stall and exit
        if (tensor_busy) begin
            stall_cpu_r = 1'b1;
        end else begin // else decode instruction by type then 4b opcode
            case (type)
                // 00: ALU
                2'b00: begin
                    alu_enable_r = 1'b1;
                    alu_opcode_r = op;
                    regfile_we_r = 1'b1;    // writes to register file (rd)
                end
                // 01: MEMORY / CONTROL
                2'b01: begin
                    case (op)
                        4'b0000: begin // LD
                            mem_read_r   = 1'b1;
                            regfile_we_r = 1'b1;
                        end
                        4'b0001: begin // ST
                            mem_write_r  = 1'b1;
                            regfile_we_r = 1'b0;
                        end
                        default: begin
                            // NOP (avoid latches)
                        end
                    endcase
                end

                // 10: TENSOR (for RELU and BF16_MUL, alu en regfile we are set to 1)
                2'b10: begin
                    case (op)
                        4'b0000: begin // BF16_MUL
                            alu_enable_r = 1'b1;
                            alu_opcode_r = op;      // use op as ALU opcode for BF16_MUL
                            regfile_we_r = 1'b1;
                        end
                        4'b0001: begin // FMA
                            tensor_start_r = 1'b1;
                            stall_cpu_r    = 1'b1;  // stall (stops pc from incrementing while tensor is busy)
                        end
                        4'b0010: begin // RELU
                            alu_enable_r = 1'b1;
                            alu_opcode_r = op;      // use op as ALU opcode for RELU
                            regfile_we_r = 1'b1;
                        end
                        4'b0011: begin // TENSOR_DOT
                            tensor_start_r = 1'b1;
                            stall_cpu_r    = 1'b1;  // stall
                        end
                        default: begin
                            // NOP (avoid latches)
                        end
                    endcase
                end

                // 11: other
                2'b11: begin
                    case (op)
                        4'b0000: begin // CVTA (convert to accumulator)
                            alu_enable_r = 1'b1;
                            regfile_we_r = 1'b1;
                        end
                        default: begin
                            // NOP (avoid latches)
                        end
                    endcase
                end

                default: begin  // avoid latches
                    // NOP (avoid latches)
                end     
            endcase
        end
    end

endmodule
