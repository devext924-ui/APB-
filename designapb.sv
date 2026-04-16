// ================= SLAVE =================
module apb_slave (
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,
    output wire PSLVERR
);

    reg [31:0] DATA;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            DATA <= 0;
        else if (PSEL && PENABLE && PWRITE)
            DATA <= PWDATA;
    end

    always @(*) begin
        if (PSEL && PENABLE && !PWRITE)
            PRDATA = DATA;
        else
            PRDATA = 0;
    end

endmodule


// ================= MASTER =================
module apb_master (
    input wire PCLK,
    input wire PRESETn,

    output reg PSEL,
    output reg PENABLE,
    output reg PWRITE,
    output reg [31:0] PADDR,
    output reg [31:0] PWDATA,

    input wire [31:0] PRDATA,
    input wire PREADY
);

    reg [2:0] state;

    localparam IDLE=0, SETUP=1, ACCESS=2, DONE=3;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state<=IDLE; PSEL<=0; PENABLE<=0; PWRITE<=0;
        end else begin
            case(state)

            IDLE: begin
                PSEL<=1; PENABLE<=0;
                PWRITE<=1; PADDR<=0; PWDATA<=32'd10;
                state<=SETUP;
            end

            SETUP: begin
                PENABLE<=1;
                state<=ACCESS;
            end

            ACCESS: begin
    if(PREADY) begin
        if (PWRITE == 1) begin
            // switch to read
            PWRITE <= 0;
            PENABLE<= 0;
            state <= SETUP;
        end else begin
            // DONE after read
            state <= DONE;
        end
    end
end

DONE: begin
    PSEL <= 0;
    PENABLE <= 0;
end

            endcase
        end
    end

endmodule
