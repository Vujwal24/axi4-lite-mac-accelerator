// AXI4-Lite Slave
// Implements a simple memory-mapped register file.
// Supports one read or write transaction at a time using an FSM.

module axi4_lite_slave #(
    parameter ADDRESS = 32,
    parameter DATA_WIDTH = 32,
    parameter MAC = 8
)(
    input                           ACLK,
    input                           ARESETN,

    // Read address channel
    input      [ADDRESS-1:0]        S_ARADDR,
    input                           S_ARVALID,
    input                           S_RREADY,

    // Write address channel
    input      [ADDRESS-1:0]        S_AWADDR,
    input                           S_AWVALID,

    // Write data channel
    input      [DATA_WIDTH-1:0]     S_WDATA,
    input      [3:0]                S_WSTRB,
    input                           S_WVALID,

    // Write response channel
    input                           S_BREADY,

    // Read response channel outputs
    output logic                    S_ARREADY,
    output logic [DATA_WIDTH-1:0]   S_RDATA,
    output logic [1:0]              S_RRESP,
    output logic                    S_RVALID,

    // Write channel ready signals
    output logic                    S_AWREADY,
    output logic                    S_WREADY,

    // Write response outputs
    output logic [1:0]              S_BRESP,
    output logic                    S_BVALID
);

    // Number of memory-mapped registers
    localparam REG_COUNT = 32;

    // Register file storage
    logic [DATA_WIDTH-1:0] regfile [0:REG_COUNT-1];

    // Latched read address
    logic [ADDRESS-1:0]    rd_addr_q;
    
    // MAC Unit Inputs and Outputs
    logic                       mac_start;
    logic                       mac_clear;
    logic [MAC - 1 :0]          mac_a;
    logic [MAC - 1 :0]          mac_b;
    logic [DATA_WIDTH - 1 :0]   mac_acc;
    logic                       mac_done;

    // Slave FSM states
    typedef enum logic [2:0] {
        SL_IDLE,         // No active transaction
        SL_WRITE,        // Write address + data
        SL_WRITE_RESP,   // Write response phase
        SL_READ_ADDR,    // Read address capture
        SL_READ_DATA     // Read data phase
    } slv_state_t;

    slv_state_t state_q, state_d;
    
    // MAC Unit Initialization
    mac_unit mac_inst (
        .clk   (ACLK),
        .rst_n (ARESETN),
        .start (mac_start),
        .clear (mac_clear),
        .a     (mac_a),
        .b     (mac_b),
        .acc   (mac_acc),
        .done  (mac_done)
    );


    // Read channel control
    assign S_ARREADY = (state_q == SL_READ_ADDR);
    assign S_RVALID  = (state_q == SL_READ_DATA);
    assign S_RDATA   = (state_q == SL_READ_DATA) ? regfile[rd_addr_q] : '0;
    assign S_RRESP   = 2'b00;

    // Write channel control
    assign S_AWREADY = (state_q == SL_WRITE);
    assign S_WREADY  = (state_q == SL_WRITE);

    // Write response channel
    assign S_BVALID  = (state_q == SL_WRITE_RESP);
    assign S_BRESP   = 2'b00;
    
    // MAC trigger always block
    logic start_d;

    always_ff @(posedge ACLK) begin
        if (!ARESETN)
            start_d <= 1'b0;
        else
            start_d <= regfile[0][0];
    end

    assign mac_start = regfile[0][0] & ~start_d;
    assign mac_clear = regfile[0][1];
    
    assign mac_a = regfile[1][7:0];
    assign mac_b = regfile[2][7:0];

    
    // Register file write and read-address capture
    integer j;
    always_ff @(posedge ACLK) begin
        if (!ARESETN) begin
            // Clear all registers on reset
            for (j = 0; j < REG_COUNT; j = j + 1)
                regfile[j] <= '0;
        end else begin
            // Perform write during write state
            if (state_q == SL_WRITE)
                regfile[S_AWADDR] <= S_WDATA;
            // Latch read address
            else if (state_q == SL_READ_ADDR)
                rd_addr_q <= S_ARADDR;
            // Write MAC results back to registers
            if (mac_done) begin
                regfile[3]    <= mac_acc;
                regfile[4][0] <= 1'b1;
            end
            // Clearing status of completion when CTRL is written
            if (state_q == SL_WRITE && S_AWADDR == 0)
                regfile[4][0] <= 1'b0;
            // Auto clear START bit after it triggers MAC
            if (mac_start)
                regfile[0][0] <= 1'b0;
        end
    end

    // FSM state register
    always_ff @(posedge ACLK) begin
        if (!ARESETN)
            state_q <= SL_IDLE;
        else
            state_q <= state_d;
    end

    // FSM next-state logic
    always_comb begin
        state_d = state_q;
        case (state_q)
            SL_IDLE:
                if (S_AWVALID)       state_d = SL_WRITE;
                else if (S_ARVALID)  state_d = SL_READ_ADDR;

            SL_READ_ADDR:
                if (S_ARVALID && S_ARREADY)
                    state_d = SL_READ_DATA;

            SL_READ_DATA:
                if (S_RVALID && S_RREADY)
                    state_d = SL_IDLE;

            SL_WRITE:
                if (S_AWVALID && S_WVALID)
                    state_d = SL_WRITE_RESP;

            SL_WRITE_RESP:
                if (S_BVALID && S_BREADY)
                    state_d = SL_IDLE;

            default:
                state_d = SL_IDLE;
        endcase
    end

endmodule
