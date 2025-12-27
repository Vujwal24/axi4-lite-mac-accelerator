// AXI4-Lite Master
// This master issues single read or write transactions based on external triggers.
// Internally, a small FSM sequences through AXI address, data, and response phases.

module axi4_lite_master #(
    parameter ADDRESS = 32,
    parameter DATA_WIDTH = 32
)(
    // Global clock and active-low reset
    input                           ACLK,
    input                           ARESETN,

    // External trigger signals
    input                           START_READ,
    input                           START_WRITE,

    // Address and write data from system / testbench
    input      [ADDRESS-1:0]        address,
    input      [DATA_WIDTH-1:0]     W_data,

    // Read channel inputs from slave
    input                           M_ARREADY,
    input      [DATA_WIDTH-1:0]     M_RDATA,
    input      [1:0]                M_RRESP,
    input                           M_RVALID,

    // Write channel inputs from slave
    input                           M_AWREADY,
    input                           M_WREADY,

    // Write response inputs from slave
    input      [1:0]                M_BRESP,
    input                           M_BVALID,

    // Read address channel outputs
    output logic [ADDRESS-1:0]      M_ARADDR,
    output logic                    M_ARVALID,
    output logic                    M_RREADY,

    // Write address channel outputs
    output logic [ADDRESS-1:0]      M_AWADDR,
    output logic                    M_AWVALID,

    // Write data channel outputs
    output logic [DATA_WIDTH-1:0]   M_WDATA,
    output logic [3:0]              M_WSTRB,
    output logic                    M_WVALID,

    // Write response channel output
    output logic                    M_BREADY
);

    // FSM states representing AXI transaction phases
    typedef enum logic [2:0] {
        ST_IDLE,        // No transaction in progress
        ST_WR_PHASE,   // Write address + data phase
        ST_WR_RESP,    // Waiting for write response
        ST_RD_ADDR,    // Read address phase
        ST_RD_DATA     // Read data phase
    } mst_state_t;

    mst_state_t state_q, state_d;

    logic rd_req_d, wr_req_d;

    // Read address channel driving
    assign M_ARADDR  = (state_q == ST_RD_ADDR) ? address : '0;
    assign M_ARVALID = (state_q == ST_RD_ADDR);

    // Master is ready to accept read data once address is issued
    assign M_RREADY  = (state_q == ST_RD_DATA || state_q == ST_RD_ADDR);

    // Write address channel driving
    assign M_AWADDR  = (state_q == ST_WR_PHASE) ? address : '0;
    assign M_AWVALID = (state_q == ST_WR_PHASE);

    // Write data channel driving
    assign M_WDATA   = (state_q == ST_WR_PHASE) ? W_data : '0;
    assign M_WVALID  = (state_q == ST_WR_PHASE);

    // Full-word write strobe during write phase
    assign M_WSTRB   = (state_q == ST_WR_PHASE) ? 4'b1111 : 4'b0000;

    // Master is ready for write response during write phases
    assign M_BREADY  = (state_q == ST_WR_PHASE || state_q == ST_WR_RESP);

    // FSM state register
    always_ff @(posedge ACLK) begin
        if (!ARESETN)
            state_q <= ST_IDLE;
        else
            state_q <= state_d;
    end

    // Capture trigger signals
    always_ff @(posedge ACLK) begin
        if (!ARESETN) begin
            rd_req_d <= 1'b0;
            wr_req_d <= 1'b0;
        end else begin
            rd_req_d <= START_READ;
            wr_req_d <= START_WRITE;
        end
    end

    // FSM next-state logic
    always_comb begin
        state_d = state_q;
        case (state_q)
            ST_IDLE:
                if (wr_req_d)       state_d = ST_WR_PHASE;
                else if (rd_req_d)  state_d = ST_RD_ADDR;

            ST_RD_ADDR:
                if (M_ARVALID && M_ARREADY)
                    state_d = ST_RD_DATA;

            ST_RD_DATA:
                if (M_RVALID && M_RREADY)
                    state_d = ST_IDLE;

            ST_WR_PHASE:
                if (M_AWREADY && M_WREADY)
                    state_d = ST_WR_RESP;

            ST_WR_RESP:
                if (M_BVALID && M_BREADY)
                    state_d = ST_IDLE;

            default:
                state_d = ST_IDLE;
        endcase
    end

endmodule


