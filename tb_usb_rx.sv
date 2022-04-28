// $Id: $
// File name:   tb_usb_rx.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 008
// Version:     1.0  Initial Design Entry
// Description: usb rx TB

`timescale 1ns / 10ps

module tb_usb_rx();

  // Define parameters
  parameter CLK_PERIOD        = 10;           //100 MHz clk
  parameter DATA_PERIOD       = (8 * CLK_PERIOD);
  
  //  DUT inputs
  reg tb_clk;
  reg tb_n_rst;
  reg tb_dplus_in;
  reg tb_dminus_in;
  reg [6:0] buffer_occupancy;
  
  // DUT outputs
  wire tb_rx_transfer_active;
  wire tb_rx_error;
  wire [3:0] tb_rx_packet;
  wire tb_rx_data_ready;
  wire [7:0] tb_rx_packet_data;
  wire tb_flush;
  wire tb_store_rx_packet_data;
  
  // Test bench debug signals
  // Overall test case number for reference
  integer tb_test_num;
  string  tb_test_case;
  reg     tb_check;

  // Test case 'inputs' used for test stimulus
  reg [7:0] tb_test_data;

  // Test case expected output values for the test case
  reg       tb_expected_rx_transfer_active;
  reg       tb_expected_rx_error;
  reg [3:0] tb_expected_rx_packet;
  reg       tb_expected_rx_data_ready;
  reg [7:0] tb_expected_rx_packet_data;
  reg       tb_expected_flush;
  reg       tb_expected_store_rx_packet_data;


  // DUT portmap
  usb_rx DUT
  (
    .clk(tb_clk),
    .n_rst(tb_n_rst),
    .dplus_in(tb_dplus_in),
    .dminus_in(tb_dminus_in),
    .buffer_occupancy(buffer_occupancy),

    .rx_transfer_active(tb_rx_transfer_active),
    .rx_error(tb_rx_error),
    .rx_packet(tb_rx_packet),
    .rx_data_ready(tb_rx_data_ready),
    .rx_packet_data(tb_rx_packet_data),
    .flush(tb_flush),
    .store_rx_packet_data(tb_store_rx_packet_data)
  );
  

  task sync_send;
    integer i;
  begin
    @(negedge tb_clk);

    tb_dplus_in = 1'b0;
    tb_dminus_in = 1'b1;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b1;
    tb_dminus_in = 1'b0;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b0;
    tb_dminus_in = 1'b1;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b1;
    tb_dminus_in = 1'b0;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b0;
    tb_dminus_in = 1'b1;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b1;
    tb_dminus_in = 1'b0;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b0;
    tb_dminus_in = 1'b1;
    #(DATA_PERIOD);

    tb_dplus_in = 1'b0;
    tb_dminus_in = 1'b1;
    #(DATA_PERIOD);

  end
  endtask



  // Send encoded data into RX module
  task send_encode;
    input logic [7:0] data;
    integer i;
  begin

    for(i = 0; i < 8; i++) 
    begin
      tb_dplus_in = data[i];
      tb_dminus_in = ~data[i];
      #(DATA_PERIOD);
    end
  end
  endtask

  task send_eop;
  begin
    @(negedge tb_clk);

    tb_dplus_in = 1'b0;
    tb_dminus_in = 1'b0;
    #(DATA_PERIOD * 2);

    tb_dplus_in = 1'b1;
    tb_dminus_in = 1'b0;
    #(DATA_PERIOD);

  end
  endtask  


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
        
    // RX Transfer Active
    assert(tb_expected_rx_transfer_active == tb_rx_transfer_active)
      $info("Test case %0d: RX Transfer correctly active", tb_test_num);
    else
      $error("Test case %0d: RX Transfer not correctly active", tb_test_num);
      
    // RX Error
    assert(tb_expected_rx_error == tb_rx_error)
      $info("Test case %0d: DUT correctly shows no RX error", tb_test_num);
    else
      $error("Test case %0d: DUT incorrectly shows a RX error", tb_test_num);
    
    // RX Packet
    assert(tb_expected_rx_packet == tb_rx_packet)
      $info("Test case %0d: DUT correctly shows proper RX packet", tb_test_num);
    else
      $error("Test case %0d: DUT did not correctly show proper RX packet", tb_test_num);
      
    // RX Data Ready
    assert(tb_expected_rx_data_ready == tb_rx_data_ready)
      $info("Test case %0d: DUT correctly shows proper RX data ready", tb_test_num);
    else
      $error("Test case %0d: DUT did not correctly show RX data ready", tb_test_num);

    // RX Packet Data
    assert(tb_expected_rx_packet_data == tb_rx_packet_data)
      $info("Test case %0d: DUT correctly shows proper RX packet data", tb_test_num);
    else
      $error("Test case %0d: DUT did not correctly show RX packet data", tb_test_num);

    // Flush
    assert(tb_expected_flush == tb_flush)
      $info("Test case %0d: DUT correctly shows proper flush", tb_test_num);
    else
      $error("Test case %0d: DUT did not correctly show flush", tb_test_num);
    
    // Store RX Packet Data
    assert(tb_expected_store_rx_packet_data == tb_store_rx_packet_data)
      $info("Test case %0d: DUT correctly store RX Packet Data", tb_test_num);
    else
      $error("Test case %0d: DUT did not correctly store RX Packet Data", tb_test_num);
  
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
    tb_test_data                       = '0;
    tb_check                           = 1'b0;

    tb_expected_rx_transfer_active     = 1'b0;
    tb_expected_rx_error               = 1'b0;
    tb_expected_rx_packet              = '0;
    tb_expected_rx_data_ready          = 1'b0;
    tb_expected_rx_packet_data         = '0;
    tb_expected_flush                  = 1'b0;
    tb_expected_store_rx_packet_data   = 1'b0;

    //Set inputs to reset
    tb_n_rst          = 1'b1;
    tb_dplus_in       = 1'b1;
    tb_dminus_in      = 1'b0;
    buffer_occupancy  = '0;
    
    // Get away from Time = 0
    #0.1; 
  

/*
    // Test case 0: Basic Power on Reset
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Power-on-Reset";
    
    // Expected outputs
    tb_expected_rx_transfer_active     = 1'b0;
    tb_expected_rx_error               = 1'b0;
    tb_expected_rx_packet              = '0;
    tb_expected_rx_data_ready          = 1'b0;
    tb_expected_rx_packet_data         = '0;
    tb_expected_flush                  = 1'b0;
    tb_expected_store_rx_packet_data   = 1'b0;
    
    // DUT Reset
    reset_dut();
    
    // Check outputs
    check_outputs();

    #(CLK_PERIOD * 2);
*/


/*
    // Test case 1: PID OUT Check
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID OUT Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b00001010;
    tb_expected_rx_packet   = 4'b0001;

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '0;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();    //Checking too late

    #(DATA_PERIOD * 2);
*/

/*
    // Test case 2: PID IN Check (Works based on wave)
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID IN Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b01110010;
    tb_expected_rx_packet   = 4'b1001;      //IN

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '0;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();

    #(DATA_PERIOD * 2);
*/

/*
    // Test case 3: PID DATA0 Check (good on wave)
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID DATA0 Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b00010100;
    tb_expected_rx_packet   = 4'b0011;      //DATA0

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '1;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();

    #(DATA_PERIOD * 2);
*/

/*
    // Test case 4: PID DATA1 Check (good on wave)
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID DATA1 Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b01101100;
    tb_expected_rx_packet   = 4'b1011;      //DATA1

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '1;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();

    #(DATA_PERIOD * 2);
*/

/*
    // Test case 5: PID ACK Check (good in wave)
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID ACK Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b00011011;
    tb_expected_rx_packet   = 4'b0010;      //ACK

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '0;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();

    #(DATA_PERIOD * 2);
*/

/*
    // Test case 6: PID NAK Check (good in wave)
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID NAK Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b01100011;
    tb_expected_rx_packet   = 4'b1010;;      //NAK

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '0;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();

    #(DATA_PERIOD * 2);
*/

/*
    // Test case 7: PID STALL Check (good in wave)
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "PID STALL Check";

    // DUT Reset
    reset_dut;

    tb_test_data            = 8'b01011111;
    tb_expected_rx_packet   = 4'b1110;      //STALL

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    tb_expected_rx_packet_data = '0;
    tb_expected_rx_transfer_active = 1'b1;
    
    send_eop();
    
    // Check outputs
    check_outputs();

    #(DATA_PERIOD * 2);
*/


    // Test case 8: Send data Check
    @(negedge tb_clk);
    tb_test_num++;
    tb_test_case = "Send data Check";

    // DUT Reset
    reset_dut;

    //Sync + PID
    sync_send();
    tb_expected_rx_transfer_active = 1'b1;

    tb_test_data            = 8'b00010100;      //DATA0
    send_encode(tb_test_data);
    tb_expected_rx_packet   = 4'b0011;   

    //First 2 data sends
    tb_test_data            = 8'b01011111;      //STALL Decoded = 00011110
    send_encode(tb_test_data);

    tb_test_data            = 8'b01100011;      //NAK Decoded = 01011010
    send_encode(tb_test_data);

    //Eval Send
    tb_test_data            = 8'b00011011;      //ACK Decoded = 11010010
    tb_expected_store_rx_packet_data = 1'b0;
    send_encode(tb_test_data);
    tb_expected_rx_packet_data = 8'b11010010;
    tb_expected_store_rx_packet_data = 1'b1;
    check_outputs();

    send_eop();
    tb_expected_rx_transfer_active = 1'b0;

    #(DATA_PERIOD * 2); 



/*
    // Test case 2: Normal packet, max faster data rate
    // Synchronize to falling edge of clock to prevent timing shifts from prior test case(s)
    @(negedge tb_clk);
    tb_test_num += 1;
    tb_test_case = "Max Fast Data-Rate, Normal Packet";
    
    // Setup packet info for debugging/verificaton signals
    tb_test_data       = 8'b11010101;
    tb_test_stop_bit   = 1'b1;
    tb_test_bit_period = WORST_FAST_DATA_PERIOD;
    tb_test_data_read  = 1'b1;
    
    // Define expected ouputs for this test case
    // For a good packet RX Data value should match data sent
    tb_expected_rx_data       = tb_test_data;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;
    // Not intentionally creating an overrun condition -> overrun should be 0
    tb_expected_overrun       = 1'b0;
    
    // DUT Reset
    reset_dut;
    
    // Send packet
    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);
    
    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
    
    // Check outputs
    check_outputs(tb_test_data_read);
  
    // Append additonal test cases here (such as overrun case)




    // Test case 3: Normal packet, slowest data rate
    // Synchronize to falling edge of clock to prevent timing shifts from prior test case(s)
    @(negedge tb_clk);
    tb_test_num += 1;
    tb_test_case = "Slowest Data-Rate, Normal Packet";
    
    // Setup packet info for debugging/verificaton signals
    tb_test_data       = 8'b11010101;
    tb_test_stop_bit   = 1'b1;
    tb_test_bit_period = WORST_SLOW_DATA_PERIOD;
    tb_test_data_read  = 1'b1;
    
    // Define expected ouputs for this test case
    // For a good packet RX Data value should match data sent
    tb_expected_rx_data       = tb_test_data;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;
    // Not intentionally creating an overrun condition -> overrun should be 0
    tb_expected_overrun       = 1'b0;
    
    // DUT Reset
    reset_dut;
    
    // Send packet
    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);
    
    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
    
    // Check outputs
    check_outputs(tb_test_data_read);


    // Test case 4: Overrun Error
    // Synchronize to falling edge of clock to prevent timing shifts from prior test case(s)
    @(negedge tb_clk);
    tb_test_num += 1;
    tb_test_case = "Overrun Error";
    
    // Setup packet info for debugging/verificaton signals
    tb_test_data       = 8'b11010101;
    tb_test_stop_bit   = 1'b1;
    tb_test_bit_period = NORM_DATA_PERIOD;
    tb_test_data_read  = 1'b1;

    // DUT Reset
    reset_dut;

    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);

    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);

    tb_test_data      = 8'b10010001;
    tb_test_stop_bit   = 1'b1;
    tb_test_bit_period = NORM_DATA_PERIOD;
    tb_test_data_read  = 1'b0;

    // Send packet
    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);

    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
  
    // Define expected ouputs for this test case
    // For a good packet RX Data value should match data sent
    tb_expected_rx_data       = tb_test_data;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;
    // Not intentionally creating an overrun condition -> overrun should be 0
    tb_expected_overrun       = 1'b1;

    // Check outputs
    check_outputs(tb_test_data_read);


    // Test case 5: Framing Error
    // Synchronize to falling edge of clock to prevent timing shifts from prior test case(s)
    //@(negedge tb_clk);
    tb_test_num += 1;
    tb_test_case = "Framing Error";
    
    // Setup packet info for debugging/verificaton signals
    tb_test_data       = 8'b11010101;
    tb_test_stop_bit   = 1'b1;
    tb_test_bit_period = NORM_DATA_PERIOD;
    tb_test_data_read  = 1'b1;

    // Define expected ouputs for this test case
    // For a good packet RX Data value should match data sent
    tb_expected_rx_data       = tb_test_data;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;
    // Not intentionally creating an overrun condition -> overrun should be 0
    tb_expected_overrun       = 1'b0;

    // DUT Reset
    reset_dut;

    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);
    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
    check_outputs(tb_test_data_read);
    tb_serial_in = 1'b1;


    tb_test_stop_bit   = 1'b0;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;

    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);
    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
    check_outputs(tb_test_data_read);
    tb_serial_in = 1'b1;


    tb_test_stop_bit   = 1'b1;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;

    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);
    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
    check_outputs(tb_test_data_read);
    tb_serial_in = 1'b1;


    tb_test_stop_bit   = 1'b0;
    // Valid stop bit ('1') -> Valid data -> Active data ready output
    tb_expected_data_ready    = tb_test_stop_bit; 
    // Framing error if and only if bad stop_bit ('0') was sent
    tb_expected_framing_error = ~tb_test_stop_bit;

    send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period);
    // Wait for 2 data periods to allow DUT to finish processing the packet
    #(tb_test_bit_period * 2);
    check_outputs(tb_test_data_read);
    tb_serial_in = 1'b1;
*/
  

  $stop;
  end

endmodule
