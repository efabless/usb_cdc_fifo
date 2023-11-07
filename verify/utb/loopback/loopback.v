module loopback
  (
   input  clk, // 192MHz Clock
   input  rstn,
   output led, // User LED ON=1, OFF=0
   inout  usb_p, // USB+
   inout  usb_n, // USB-
   output usb_pu  // USB 1.5kOhm Pullup EN
   );

   localparam BIT_SAMPLES = 'd4;
   localparam [6:0] DIVF = 12*BIT_SAMPLES-1;

   wire             clk_pll;
   wire             clk_48MHz;
   wire             clk_div2;
   wire             clk_div4;
   wire             clk_div8;
   wire             clk_div16;
   wire             lock;
   wire             dp_pu;
   wire             dp_rx;
   wire             dn_rx;
   wire             dp_tx;
   wire             dn_tx;
   wire             tx_en;
   wire [7:0]       out_data;
   wire             out_valid;
   wire             in_ready;
   wire [7:0]       in_data;
   wire             in_valid;
   wire             out_ready;
   wire [10:0]      frame;
   wire             configured;

   assign led = (configured) ? frame[9] : ~&frame[4:3];

   // if FEEDBACK_PATH = SIMPLE:
   // clk_freq = (ref_freq * (DIVF + 1)) / (2**DIVQ * (DIVR + 1));
   /*SB_PLL40_CORE #(.DIVR(4'd0),
                   .DIVF(DIVF),
                   .DIVQ(3'd2),
                   .FILTER_RANGE(3'b001),
                   .FEEDBACK_PATH("SIMPLE"),
                   .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
                   .FDA_FEEDBACK(4'b0000),
                   .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
                   .FDA_RELATIVE(4'b0000),
                   .SHIFTREG_DIV_MODE(2'b00),
                   .PLLOUT_SELECT("GENCLK"),
                   .ENABLE_ICEGATE(1'b0))
   u_pll (.REFERENCECLK(clk), // 16MHz
          .PLLOUTCORE(),
          .PLLOUTGLOBAL(clk_pll), // 192MHz
          .EXTFEEDBACK(1'b0),
          .DYNAMICDELAY(8'd0),
          .LOCK(lock),
          .BYPASS(1'b0),
          .RESETB(1'b1),
          .SDI(1'b0),
          .SDO(),
          .SCLK(1'b0),
          .LATCHINPUTVALUE(1'b1));*/
    
    /*clk_wiz_12_to_192MHz clk_wix_12_to_192 (.clk_out1(clk_pll),
                                            .reset(RSTB),
                                            .locked(lock),
                                            .clk_in1(clk));*/


   prescaler u_prescaler (.clk_i(clk),
                          //.rstn_i(lock),
                          .rstn_i(rstn),
                          .clk_div2_o(clk_div2),
                          .clk_div4_o(clk_div4),
                          .clk_div8_o(clk_div8),
                          .clk_div16_o(clk_div16));

    /*clk_wiz_12_to_48MHz clk_wix_12_to_48 (.clk_out1(clk_48MHz),
                                            .reset(RSTB),
                                            .locked(lock),
                                            .clk_in1(clk));*/
   usb_cdc #(.VENDORID(16'h1D50),
             .PRODUCTID(16'h6130),
             .IN_BULK_MAXPACKETSIZE('d8),
             .OUT_BULK_MAXPACKETSIZE('d8),
             .BIT_SAMPLES(BIT_SAMPLES),
             //.USE_APP_CLK(1),
             //.APP_CLK_RATIO(BIT_SAMPLES*12/192))  // BIT_SAMPLES * 12MHz / 192MHz
             .USE_APP_CLK(0))
   u_usb_cdc (.frame_o(frame),
              .configured_o(configured),
              //.app_clk_i(clk),
              .app_clk_i(1'b0),
              //.clk_i(clk_div4),
              .clk_i(clk),
              //.rstn_i(lock),
              .rstn_i(rstn),
              .out_ready_i(in_ready),
              .in_data_i(out_data),
              .in_valid_i(out_valid),
              .dp_rx_i(dp_rx),
              .dn_rx_i(dn_rx),
              .out_data_o(out_data),
              .out_valid_o(out_valid),
              .in_ready_o(in_ready),
              .dp_pu_o(dp_pu),
              .tx_en_o(tx_en),
              .dp_tx_o(dp_tx),
              .dn_tx_o(dn_tx));

   /*SB_IO #(.PIN_TYPE(6'b101001),
           .PULLUP(1'b0))
   u_usb_p (.PACKAGE_PIN(usb_p),
            .OUTPUT_ENABLE(tx_en),
            .D_OUT_0(dp_tx),
            .D_IN_0(dp_rx),
            .D_OUT_1(1'b0),
            .D_IN_1(),
            .CLOCK_ENABLE(1'b0),
            .LATCH_INPUT_VALUE(1'b0),
            .INPUT_CLK(1'b0),
            .OUTPUT_CLK(1'b0));*/
    io_buf #(
            .WIDTH(1)
    ) u_usb_p (
            .dio_buf(usb_p),
            .din_i(dp_tx),
            .dout_o(dp_rx),
            .in_not_out_i(~tx_en)
    );

   /*SB_IO #(.PIN_TYPE(6'b101001),
           .PULLUP(1'b0))
   u_usb_n (.PACKAGE_PIN(usb_n),
            .OUTPUT_ENABLE(tx_en),
            .D_OUT_0(dn_tx),
            .D_IN_0(dn_rx),
            .D_OUT_1(1'b0),
            .D_IN_1(),
            .CLOCK_ENABLE(1'b0),
            .LATCH_INPUT_VALUE(1'b0),
            .INPUT_CLK(1'b0),
            .OUTPUT_CLK(1'b0));*/
    io_buf #(
            .WIDTH(1)
    ) u_usb_n (
            .dio_buf(usb_n),
            .din_i(dn_tx),
            .dout_o(dn_rx),
            .in_not_out_i(~tx_en)
    );

   // drive usb_pu to 3.3V or to high impedance
   /*SB_IO #(.PIN_TYPE(6'b101001),
           .PULLUP(1'b0))
   u_usb_pu (.PACKAGE_PIN(usb_pu),
             .OUTPUT_ENABLE(dp_pu),
             .D_OUT_0(1'b1),
             .D_IN_0(),
             .D_OUT_1(1'b0),
             .D_IN_1(),
             .CLOCK_ENABLE(1'b0),
             .LATCH_INPUT_VALUE(1'b0),
             .INPUT_CLK(1'b0),
             .OUTPUT_CLK(1'b0));*/
    io_buf #(
            .WIDTH(1)
    ) u_usb_pu (
            .dio_buf(usb_pu),
            .din_i(1'b1),
            .dout_o(),
            .in_not_out_i(~dp_pu)
    );

endmodule

module io_buf #(parameter WIDTH=1) (
    inout  wire [WIDTH-1:0] dio_buf,
    input  wire [WIDTH-1:0] din_i,
    output wire [WIDTH-1:0] dout_o,
    input  wire [WIDTH-1:0] in_not_out_i         // high: input, low: output
);

//`ifdef USE_IO_BUF_BEH
    assign dout_o  = dio_buf;
    generate
        genvar i;
        for (i=0; i<WIDTH; i=i+1)
            assign dio_buf[i] = in_not_out_i[i] ? 1'bz : din_i[i];
    endgenerate
endmodule
