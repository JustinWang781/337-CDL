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
  integer i;
  integer idx;

  // Test case 'inputs' used for test stimulus
  reg [7:0] tb_test_data;
  reg [63:0][7:0] tb_test_data_array;

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

    tb_test_data_array                 = '0;
    tb_rx_packet_data                  = '0;

    
    tb_store_rx_packet_data            = 1'b0;
    tb_get_rx_data                     = 1'b0;
    tb_flush                           = 1'b0;
    tb_clear                           = 1'b0;
    tb_expected_buffer_occupancy       = '0;
    tb_expected_rx_data                = '0;
    idx                                = 0;

    //Set inputs to reset
    tb_n_rst          = 1'b1;
    
    // Get away from Time = 0
    #0.1; 

/*
    // Test case 0: Basic Power on Reset
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Power-on-Reset";
        
    // DUT Reset
    reset_dut();
    
    // Check outputs
    check_outputs();

    #(CLK_PERIOD * 2);
*/

/*
    // Test case 1: RX Testing 32
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "RX Testing 32";
        
    // DUT Reset
    reset_dut();

    for(i = 0; i < 32; i++) begin
      tb_test_data_array[i][7:0] = i;
    end

    // Storage
    for(i = 0; i < 32; i++) begin
      tb_store_rx_packet_data = 1'b1;
      tb_rx_packet_data = tb_test_data_array[i][7:0];

      @(posedge tb_clk);
      tb_expected_buffer_occupancy++;
      tb_expected_rx_data = '0; //Should be 0 as we are just loading the buffer currently (see waveform)
      @(negedge tb_clk);

      check_outputs();

      tb_store_rx_packet_data = 1'b0;
      tb_rx_packet_data = 1'b0;
    end

    // Retreival
    for(i = 0; i < 32; i++) begin
      tb_get_rx_data = 1'b1;
      //tb_rx_packet_data = tb_test_data_array[i][7:0];

      if(i == 0) begin
        #(0.2);
        tb_expected_buffer_occupancy = 32;
        tb_expected_rx_data = tb_test_data_array[0][7:0];
        check_outputs();
      end
      @(posedge tb_clk);
      tb_expected_buffer_occupancy--;
      tb_expected_rx_data = tb_test_data_array[i+1][7:0];
      @(negedge tb_clk);

      check_outputs();

      tb_get_rx_data = 1'b0;
    end

    #(CLK_PERIOD * 2);
*/

/*
    // Test case 2: RX Testing 32
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "RX Testing 64";
        
    // DUT Reset
    reset_dut();

    for(i = 0; i < 64; i++) begin
      tb_test_data_array[i][7:0] = i;
    end

    // Storage
    for(i = 0; i < 64; i++) begin
      tb_store_rx_packet_data = 1'b1;
      tb_rx_packet_data = tb_test_data_array[i][7:0];

      @(posedge tb_clk);
      tb_expected_buffer_occupancy++;
      tb_expected_rx_data = '0; //Should be 0 as we are just loading the buffer currently (see waveform)
      @(negedge tb_clk);

      check_outputs();

      tb_store_rx_packet_data = 1'b0;
      tb_rx_packet_data = 1'b0;
    end

    // Retreival
    for(i = 0; i < 63; i++) begin
      tb_get_rx_data = 1'b1;
      //tb_rx_packet_data = tb_test_data_array[i][7:0];

      if(i == 0) begin
        #(0.2);
        tb_expected_buffer_occupancy = 64;
        tb_expected_rx_data = tb_test_data_array[0][7:0];
        check_outputs();
      end
      @(posedge tb_clk);
      tb_expected_buffer_occupancy--;
      tb_expected_rx_data = tb_test_data_array[i+1][7:0]; //Should be 0 as we are just loading the buffer currently (see proper configuration in waveform //tb_test_data_array[i][7:0];
      @(negedge tb_clk);

      check_outputs();

      tb_get_rx_data = 1'b0;
    end

    #(CLK_PERIOD * 2);
*/


/*
    // Test case 3: RX Testing 64 Clear
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "RX Testing 64 Clear";
        
    // DUT Reset
    reset_dut();

    for(i = 0; i < 64; i++) begin
      tb_test_data_array[i][7:0] = i;
    end

    // Storage
    for(i = 0; i < 64; i++) begin
      tb_store_rx_packet_data = 1'b1;
      tb_rx_packet_data = tb_test_data_array[i][7:0];

      @(posedge tb_clk);
      tb_expected_buffer_occupancy++;
      tb_expected_rx_data = '0; //Should be 0 as we are just loading the buffer currently (see waveform)
      @(negedge tb_clk);

      check_outputs();

      tb_store_rx_packet_data = 1'b0;
      tb_rx_packet_data = 1'b0;
    end

    tb_clear = 1'b1;
    @(posedge tb_clk);
    tb_expected_buffer_occupancy = '0;
    tb_expected_rx_data = '0;
    @(negedge tb_clk);

    check_outputs();
    tb_clear = 1'b0;

    #(CLK_PERIOD * 2);
*/

    // Test case 4: RX Testing 64 Flush
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "RX Testing 64 Flush";
        
    // DUT Reset
    reset_dut();

    for(i = 0; i < 64; i++) begin
      tb_test_data_array[i][7:0] = i;
    end

    // Storage
    for(i = 0; i < 64; i++) begin
      tb_store_rx_packet_data = 1'b1;
      tb_rx_packet_data = tb_test_data_array[i][7:0];

      @(posedge tb_clk);
      tb_expected_buffer_occupancy++;
      tb_expected_rx_data = '0;
      @(negedge tb_clk);
      check_outputs();

      tb_store_rx_packet_data = 1'b0;
      tb_rx_packet_data = 1'b0;
    end

    tb_flush = 1'b1;
    @(posedge tb_clk);
    tb_expected_buffer_occupancy = '0;
    tb_expected_rx_data = '0;
    @(negedge tb_clk);

    check_outputs();
    tb_flush = 1'b0;

    #(CLK_PERIOD * 2);


  $stop;
  end

endmodule
