// $Id: $
// File name:   tb_usb_rx.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 008
// Version:     1.0  Initial Design Entry
// Description: usb rx TB

`timescale 1ns / 10ps

module tb_data_buffer();

  // Define parameters
  parameter CLK_PERIOD        = 10;           //100 MHz clk
  parameter DATA_PERIOD       = (8 * CLK_PERIOD);

  
  //  DUT inputs
  reg       tb_clk;
  reg       tb_n_rst;
  reg [7:0] tb_rx_packet_data;
  reg       tb_flush;
  reg       tb_store_rx_packet_data;
  reg       tb_get_rx_data;
  reg       tb_clear;
  
  // DUT outputs
  wire [7:0] tb_rx_data;
  wire [6:0] tb_buffer_occupancy;
  
  // Test bench debug signals
  // Overall test case number for reference
  integer tb_test_num;
  string  tb_test_case;
  reg     tb_check;

  // Test case 'inputs' used for test stimulus
  reg [7:0] tb_test_data;

  // Test case expected output values for the test case
  reg [7:0] tb_expected_rx_data;
  reg [6:0] tb_expected_buffer_occupancy;


  // DUT portmap
  data_buffer DUT
  (
    .clk(tb_clk),
    .n_rst(tb_n_rst),
    .rx_packet_data(tb_rx_packet_data),
    .flush(tb_flush),
    .store_rx_packet_data(tb_store_rx_packet_data),
    .get_rx_data(tb_get_rx_data),
    .clear(tb_clear),

    .rx_data(tb_rx_data),
    .buffer_occupancy(tb_buffer_occupancy)
  );


  task reset_dut;
  begin
    // Activate the design's reset (does not need to be synchronize with clock)
    tb_n_rst = 1'b0;
    
    // Wait for a couple clock cycles
    @(posedge tb_clk);
    @(posedge tb_clk);
    
    // Release the reset
    @(negedge tb_clk);
    tb_n_rst = 1'b1;
    
    // Wait for a while before activating the design
    @(posedge tb_clk);
    @(posedge tb_clk);
  end
  endtask
  
  
  task check_outputs;
  begin
    
    tb_check = 1'b1;
        
    // Buff Occupancy
    assert(tb_expected_buffer_occupancy == tb_buffer_occupancy)
      $info("Test case %0d: buffer occupancy correct", tb_test_num);
    else
      $error("Test case %0d: buffer occupancy incorrect", tb_test_num);
      
    // RX Data
    assert(tb_expected_rx_data == tb_rx_data)
      $info("Test case %0d: rx data correct", tb_test_num);
    else
      $error("Test case %0d: rx data incorrect", tb_test_num);
 
    #(0.1);
    tb_check = 1'b0;
  end
  endtask

  
  always
  begin : CLK_GEN
    tb_clk = 1'b0;
    #(CLK_PERIOD / 2);
    tb_clk = 1'b1;
    #(CLK_PERIOD / 2);
  end

  // Actual test bench process
  initial
  begin
    // Initialize all test bench signals
    tb_test_num                        = -1;
    tb_test_case                       = "TB Init";
    tb_check                           = 1'b0;

    tb_rx_packet_data                  = '0;

    
    tb_store_rx_packet_data            = 1'b0;
    tb_get_rx_data                     = 1'b0;
    tb_flush                           = 1'b0;
    tb_clear                           = 1'b0;
    tb_expected_buffer_occupancy       = '0;
    tb_expected_rx_data                = '0;

    //Set inputs to reset
    tb_n_rst          = 1'b1;
    
    // Get away from Time = 0
    #0.1; 
  


    // Test case 0: Basic Power on Reset
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Power-on-Reset";
        
    // DUT Reset
    reset_dut();
    
    // Check outputs
    check_outputs();

    #(CLK_PERIOD * 2);


  

  $stop;
  end

endmodule
