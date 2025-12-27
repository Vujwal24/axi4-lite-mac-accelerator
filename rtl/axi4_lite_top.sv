// AXI4-Lite Top Module
// This module connects the AXI4-Lite master and slave directly.
// This module only wires signals between master and slave and does not have any internal logic

module axi4_lite_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS    = 32
)(
    input                       ACLK,
    input                       ARESETN,
    input                       read_s,
    input                       write_s,
    input   [ADDRESS-1:0]       address,
    input   [DATA_WIDTH-1:0]    W_data
);

    // Read channel wiring
    logic ar_rdy_s;
    logic ar_vld_m;
    logic r_rdy_m;
    logic r_vld_s;

    // Write channel wiring
    logic aw_rdy_s;
    logic aw_vld_m;
    logic w_rdy_s;
    logic w_vld_m;
    logic b_rdy_m;
    logic b_vld_s;

    // Address, data, and response buses
    logic [ADDRESS-1:0]    ar_addr_m;
    logic [ADDRESS-1:0]    aw_addr_m;
    logic [DATA_WIDTH-1:0] w_data_m;
    logic [DATA_WIDTH-1:0] r_data_s;
    logic [3:0]            w_strb_m;
    logic [1:0]            r_resp_s;
    logic [1:0]            b_resp_s;

    axi4_lite_master master_inst (
        .ACLK        (ACLK),
        .ARESETN     (ARESETN),
        .START_READ  (read_s),
        .START_WRITE (write_s),
        .address     (address),
        .W_data      (W_data),

        .M_ARREADY   (ar_rdy_s),
        .M_RDATA     (r_data_s),
        .M_RRESP     (r_resp_s),
        .M_RVALID    (r_vld_s),

        .M_AWREADY   (aw_rdy_s),
        .M_WREADY    (w_rdy_s),

        .M_BRESP     (b_resp_s),
        .M_BVALID    (b_vld_s),

        .M_ARADDR    (ar_addr_m),
        .M_ARVALID   (ar_vld_m),
        .M_RREADY    (r_rdy_m),

        .M_AWADDR    (aw_addr_m),
        .M_AWVALID   (aw_vld_m),

        .M_WDATA     (w_data_m),
        .M_WSTRB     (w_strb_m),
        .M_WVALID    (w_vld_m),

        .M_BREADY    (b_rdy_m)
    );

    axi4_lite_slave slave_inst (
        .ACLK        (ACLK),
        .ARESETN     (ARESETN),

        .S_ARADDR    (ar_addr_m),
        .S_ARVALID   (ar_vld_m),
        .S_RREADY    (r_rdy_m),

        .S_AWADDR    (aw_addr_m),
        .S_AWVALID   (aw_vld_m),

        .S_WDATA     (w_data_m),
        .S_WSTRB     (w_strb_m),
        .S_WVALID    (w_vld_m),

        .S_BREADY    (b_rdy_m),

        .S_ARREADY   (ar_rdy_s),
        .S_RDATA     (r_data_s),
        .S_RRESP     (r_resp_s),
        .S_RVALID    (r_vld_s),

        .S_AWREADY   (aw_rdy_s),
        .S_WREADY    (w_rdy_s),

        .S_BRESP     (b_resp_s),
        .S_BVALID    (b_vld_s)
    );

endmodule


