`timescale 1ns/1ps

module axi4_lite_tb;

    parameter int DATA_WIDTH = 32;
    parameter int ADDRESS    = 32;

    logic                   clk;
    logic                   rst_n;
    logic                   rd_trig;
    logic                   wr_trig;
    logic [ADDRESS-1:0]     addr;
    logic [DATA_WIDTH-1:0]  wdata;

    axi4_lite_top dut (
        .ACLK     (clk),
        .ARESETN  (rst_n),
        .read_s   (rd_trig),
        .write_s  (wr_trig),
        .address  (addr),
        .W_data   (wdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk     = 0;
        rst_n   = 0;
        rd_trig = 0;
        wr_trig = 0;
        addr    = 0;
        wdata   = 0;

        #20;
        rst_n = 1;

        // Clear MAC accumulator before starting operations
        write_op(0, 32'b10);
        write_op(0, 32'b00);

        // MAC run #1: A=5, B=6 → ACC should become 30
        write_op(1, 5);
        write_op(2, 6);
        write_op(0, 32'b1);

        read_op(3);

        // MAC run #2: A=3, B=4 → ACC should accumulate to 42
        write_op(1, 3);
        write_op(2, 4);
        write_op(0, 32'b1);

        read_op(3);

        // MAC run #3: A=2, B=10 → ACC should accumulate to 62
        write_op(1, 2);
        write_op(2, 10);
        write_op(0, 32'b1);

        read_op(3);

        // Write and read registers not connected to the MAC
        write_op(6,  32'hAAAA_AAAA);
        write_op(7,  32'h5555_5555);
        write_op(10, 32'h1234_5678);

        read_op(6);
        read_op(7);
        read_op(10);

        #100;
        $finish;
    end

    task automatic write_op(input logic [ADDRESS-1:0] a,
                            input logic [DATA_WIDTH-1:0] d);
        begin
            addr    = a;
            wdata   = d;
            wr_trig = 1'b1;
            #10;
            wr_trig = 1'b0;
            #80;
        end
    endtask

    task automatic read_op(input logic [ADDRESS-1:0] a);
        begin
            addr    = a;
            rd_trig = 1'b1;
            #10;
            rd_trig = 1'b0;
            #80;
        end
    endtask

endmodule
