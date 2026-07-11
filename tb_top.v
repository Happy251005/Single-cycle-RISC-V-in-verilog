`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;
    integer errors;

    top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    // Per-cycle trace (handy for debugging, harmless for CI)
    always @(posedge clk) begin
        if (!rst) begin
            $display(
                "PC=%0d instr=%h | rs1=%0d rs2=%0d | ALU=%0d | WB=%0d",
                dut.pc_out,
                dut.instr,
                dut.rs1_data,
                dut.rs2_data,
                dut.ALU_result,
                dut.write_data
            );
        end
    end

    task check_reg(input [8*4-1:0] name, input integer idx, input signed [31:0] expected);
        reg signed [31:0] actual;
        begin
            actual = dut.RF.Registers[idx];
            if (actual !== expected) begin
                $display("FAIL: %s (x%0d) = %0d (expected %0d)", name, idx, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %s (x%0d) = %0d", name, idx, actual);
            end
        end
    endtask

    task check_mem(input [8*4-1:0] name, input integer idx, input signed [31:0] expected);
        reg signed [31:0] actual;
        begin
            actual = dut.DM.data_memory[idx];
            if (actual !== expected) begin
                $display("FAIL: %s (mem[%0d]) = %0d (expected %0d)", name, idx, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %s (mem[%0d]) = %0d", name, idx, actual);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        errors = 0;

        #20;
        rst = 0;

        // Program has 15 distinct fetch addresses to execute (one instruction
        // is skipped by the taken branch). One posedge commits one instruction,
        // so 15 cycles is exactly enough -- no extra cycles spent executing
        // uninitialized/NOP instructions past the end of the program.
        repeat (15) @(posedge clk);

        // Let the final cycle's non-blocking register/memory writes settle
        // before reading them -- otherwise the very last write can be read
        // one delta-cycle too early and looks like a false failure.
        #1;

        $display("");
        $display("---- FINAL REGISTER / MEMORY CHECK ----");
        check_reg("x1",  1,  10);
        check_reg("x2",  2,  20);
        check_reg("x3",  3,  30);
        check_reg("x4",  4,  30);
        check_reg("x5",  5,  99);
        check_reg("x6",  6,  -1);
        check_reg("x7",  7,  -10);
        check_reg("x8",  8,  0);
        check_reg("x9",  9,  30);
        check_reg("x10", 10, 5);
        check_reg("x11", 11, 111);
        check_reg("x12", 12, 222);
        check_mem("m0",  0,  30);

        $display("");
        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: %0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule