module mac_unit (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic        clear,

    input  logic [7:0]  a,
    input  logic [7:0]  b,

    output logic [31:0] acc,
    output logic        done
);

    logic [15:0] mult_res;

    assign mult_res = a * b;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            acc  <= 32'd0;
            done <= 1'b0;
        end
        else begin
            done <= 1'b0;

            if (clear) begin
                acc <= 32'd0;
            end
            else if (start) begin
                acc  <= acc + mult_res;
                done <= 1'b1;
            end
        end
    end

endmodule

