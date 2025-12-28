module instr_mem(
    input  [31:0] addr,
    output [31:0] instr
);

    reg [31:0] memory [0:63];

    // Instruction according to current test
    initial begin
    // addi x1, x0, 10
    memory[0] = 32'b000000001010_00000_000_00001_0010011;

    // addi x2, x0, 20
    memory[1] = 32'b000000010100_00000_000_00010_0010011;

    // add x3, x1, x2
    memory[2] = 32'b0000000_00010_00001_000_00011_0110011;

    // sw x3, 0
    memory[3] = 32'b0000000_00011_00000_010_00000_0100011;

    // lw x4, 0
    memory[4] = 32'b000000000000_00000_010_00100_0000011;

    // beq x3, x4, +8 
    memory[5] = 32'b0000000_00100_00011_000_01000_1100011;

    // addi x5, x0, 1 
    memory[6] = 32'b000000000001_00000_000_00101_0010011;

    // addi x5, x0, 99
    memory[7] = 32'b000001100011_00000_000_00101_0010011;
end


    assign instr = memory[addr[31:2]];

endmodule
