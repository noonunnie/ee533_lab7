`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Team 7, EE533 sp2026
// Description: control unit and fetch-decode. generates opcode fields, control signals for pipeline.
//      Decoder provides 4-bit reg IDs so we use the low 2 bits as address for the regfile IP
//      Mem reads = synchronous. mem_load_pending for when not yet ready
//      Tensor
//          tensor_start_dec = decoder requests tensor op (one-cycle pulse)
//          tensor_go = pulse signal
//          tensor_busy = busy signal
//      CPU
//          1. tensor
//          2. memory
//          3. alu
//      ** DONT FORGET TO WIRE THE STALL
// Create Date:    03/02/2026 
// Design Name: gpu_design (ee533_lab7)
// Module Name:	control_unit
// Project Name: gpu_design
// Target Devices: XC2VP50
//
//////////////////////////////////////////////////////////////////////////////////
module control_unit (
    input  wire         clk,
    input  wire         reset,

    // inputs from decoder (combinational signals)
    input  wire [3:0]   rd,               // destination reg idx (4b from decoder)
    input  wire [3:0]   rs1,
    input  wire [3:0]   rs2,
    input  wire [13:0]  imm,
    input  wire [3:0]   alu_opcode,
    input  wire         regfile_we_dec,   // ALU or LD will write to rd
    input  wire         alu_enable_dec,
    input  wire         mem_read_dec,
    input  wire         mem_write_dec,
    input  wire         tensor_start_dec,
    input  wire         stall_cpu_dec,    // decoder asks CPU to stall (mainly from tensor_busy)

    // data sources
    input  wire [63:0]  alu_result,
    input  wire [63:0]  regfile_douta,    // regfile a read (rs1)
    input  wire [63:0]  regfile_doutb,    // regfile b read (rs2)
    input  wire [63:0]  mem_read_data,
    input  wire         tensor_done,
    input  wire [63:0]  tensor_result,

    // outputs to regfile (port A used for read/write; port B used as read)
    output reg  [1:0]   regfile_raddr_a,  // connect to reg_file.ADDRA (rs1[1:0])
    output reg  [1:0]   regfile_raddr_b,  // connect to reg_file.ADDRB (rs2[1:0])
    output reg  [1:0]   regfile_waddr,    // connect to reg_file.ADDRA (write address)
    output reg          regfile_we,       // connect to reg_file.WEA (write enable)
    output reg  [63:0]  regfile_wdata,    // connect to reg_file.DINA (write data)

    // outputs to memory
    output reg  [31:0]  mem_addr,
    output reg  [63:0]  mem_wdata,        // data to write fr regfile_doutb
    output reg          mem_we,

    // for tensor
    output reg          tensor_go,        // one-cycle pulse to start tensor
);

    // internal small state
    reg mem_load_pending;
    reg [1:0] pending_waddr;       // store destination reg for pending mem read
    reg tensor_busy_flag;

    // map 4b reg idx to 2b addr (low 2b)
    wire [1:0] rd_addr  = rd[1:0];
    wire [1:0] rs1_addr = rs1[1:0];
    wire [1:0] rs2_addr = rs2[1:0];

    // sequential logic: main sequencer, writeback, mem handling, tensor go/done
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regfile_raddr_a   <= 2'b00;
            regfile_raddr_b   <= 2'b00;
            regfile_waddr     <= 2'b00;
            regfile_we        <= 1'b0;
            regfile_wdata     <= 64'b0;

            mem_addr          <= 32'b0;
            mem_wdata         <= 64'b0;
            mem_we            <= 1'b0;
            mem_load_pending  <= 1'b0;
            pending_waddr     <= 2'b00;

            tensor_go         <= 1'b0;
            tensor_busy_flag  <= 1'b0;

        end else begin
            // default clears
            regfile_we        <= 1'b0;
            regfile_wdata     <= 64'b0;
            regfile_waddr     <= 2'b00;
            mem_we            <= 1'b0;
            tensor_go         <= 1'b0;

            // always drive read addresses from decoder's rs fields
            regfile_raddr_a   <= rs1_addr;
            regfile_raddr_b   <= rs2_addr;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Memory store (ST)
            if (mem_write_dec) begin
                // Issue store to memory immediately using regfile read values:
                mem_addr  <= regfile_douta[31:0];
                mem_wdata <= regfile_doutb;
                mem_we    <= 1'b1;
            end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Memory load (LD) - sync mem
            if (mem_read_dec) begin
                // start memory read: sample address, mark pending so that
                // next cycle we write mem_read_data into the destination reg
                mem_addr         <= regfile_douta[31:0];  // address in rs1
                mem_load_pending <= 1'b1;
                pending_waddr    <= rd_addr;
            end

            // if there is a pending mem read (issued prior cycle), commit it to regfile now
            if (mem_load_pending) begin
                regfile_we      <= 1'b1;
                regfile_waddr   <= pending_waddr;
                regfile_wdata   <= mem_read_data;
                mem_load_pending<= 1'b0;   // clear pending flag after writeback
            end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // ALU writeback (single-cycle result)
            if (alu_enable_dec && regfile_we_dec) begin
                regfile_we    <= 1'b1;
                regfile_waddr <= rd_addr;
                regfile_wdata <= alu_result;
            end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Tensor handshake
            if (tensor_start_dec && !tensor_busy_flag) begin
                tensor_go        <= 1'b1;
                tensor_busy_flag <= 1'b1;
            end

            // when tensor reports completion, write result to regfile immediately
            if (tensor_done) begin
                regfile_we      <= 1'b1;
                regfile_waddr   <= rd_addr;
                regfile_wdata   <= tensor_result;  // write tensor result to destination register (rd)
                tensor_busy_flag<= 1'b0;
            end
        end
    end

endmodule
