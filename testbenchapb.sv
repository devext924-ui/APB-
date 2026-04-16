`timescale 1ns/1ps

module tb;

    reg PCLK;
    reg PRESETn;

    wire PSEL, PENABLE, PWRITE;
    wire [31:0] PADDR, PWDATA, PRDATA;
    wire PREADY;

    // Clock
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    // Reset
    initial begin
        PRESETn = 0;
        #20 PRESETn = 1;
    end

    // Master
    apb_master master (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY)
    );

    // Slave
    apb_slave slave (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR()
    );

    // Monitor
    initial begin
        $monitor("Time=%0t PWRITE=%b PADDR=%h PWDATA=%h PRDATA=%h",
                  $time, PWRITE, PADDR, PWDATA, PRDATA);
        #200 $finish;
    end

endmodule
