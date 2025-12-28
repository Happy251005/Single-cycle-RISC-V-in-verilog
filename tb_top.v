`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;

    top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;

        #100;

        $display("---- FINAL REGISTER CHECK ----");
        $display("x3 = %0d", dut.RF.Registers[3]);
        $display("x4 = %0d", dut.RF.Registers[4]);
        $display("x5 = %0d", dut.RF.Registers[5]);

        $finish;
    end

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

endmodule
