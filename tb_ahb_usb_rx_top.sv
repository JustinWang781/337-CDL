
`timescale 1ns / 10ps

module tb_ahb_usb_rx_top();

// Timing related constants
localparam CLK_PERIOD = 10;
localparam DATA_PERIOD = (8*CLK_PERIOD);
localparam BUS_DELAY  = 800ps; // Based on FF propagation delay

// Sizing related constants
localparam DATA_WIDTH      = 4;
localparam ADDR_WIDTH      = 4;
localparam DATA_WIDTH_BITS = DATA_WIDTH * 8;
localparam DATA_MAX_BIT    = DATA_WIDTH_BITS - 1;
localparam ADDR_MAX_BIT    = ADDR_WIDTH - 1;

// Define our address mapping scheme via constants
localparam ADDR_STATUS      = 4'd0;
localparam ADDR_STATUS_BUSY = 4'd0;
localparam ADDR_STATUS_ERR  = 4'd1;
localparam ADDR_RESULT      = 4'd2;
localparam ADDR_SAMPLE      = 4'd4;
localparam ADDR_COEF_START  = 4'd6;  // F0
localparam ADDR_COEF_SET    = 4'd14; // Coeff Set Confirmation

// AHB-Lite-Slave reset value constants
// Student TODO: Update these based on the reset values for your config registers
localparam RESET_COEFF  = '0;
localparam RESET_SAMPLE = '0;

  reg [15:0][7:0] tb_test_data_array;
  logic [7:0] data;
  integer i;
//*****************************************************************************
// Declare TB Signals (Bus Model Controls)
//*****************************************************************************
// Testing setup signals
logic                      tb_enqueue_transaction;
logic                      tb_transaction_write;
logic                      tb_transaction_fake;
logic [3:0]     tb_transaction_addr;
logic [31:0]     tb_transaction_data;
logic                      tb_transaction_error;
logic [2:0]                tb_transaction_size;
// Testing control signal(s)
logic    tb_enable_transactions;
integer  tb_current_transaction_num;
logic    tb_current_transaction_error;
logic    tb_model_reset;
string   tb_test_case;
integer  tb_test_case_num;
logic [31:0] tb_test_data;
string                 tb_check_tag;
logic                  tb_mismatch;
logic                  tb_check;

//*****************************************************************************
// General System signals
//*****************************************************************************
logic tb_clk;
logic tb_n_rst;
logic tb_dplus_in;
logic tb_dminus_in;
logic tb_d_mode;

//*****************************************************************************
// AHB-Lite-Slave side signals
//*****************************************************************************
logic                  tb_hsel;
logic [1:0]            tb_htrans;
logic [ADDR_MAX_BIT:0] tb_haddr;
logic [2:0]            tb_hsize;
logic                  tb_hwrite;
logic [31:0] tb_hwdata;
logic [31:0] tb_hrdata;
logic                  tb_hresp;
logic                  tb_hready;

//added signals for CDL
logic [3:0] tb_rx_packet;
logic tb_rx_data_ready;
logic tb_rx_transfer_active;
logic tb_rx_error;
logic [6:0] tb_buffer_occupancy;
logic [7:0] tb_rx_data;
logic tb_get_rx_data;
logic tb_clear;

logic tb_expected_hready;
logic tb_expected_get_rx_data;
logic tb_expected_clear;


//*****************************************************************************
// Clock Generation Block
//*****************************************************************************
// Clock generation block
always begin
  // Start with clock low to avoid false rising edge events at t=0
  tb_clk = 1'b0;
  // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
  tb_clk = 1'b1;
  // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
end

//*****************************************************************************
// Bus Model Instance
//*****************************************************************************
ahb_lite_bus #(.DATA_WIDTH(4)) BFM (.clk(tb_clk),
                  // Testing setup signals
                  .enqueue_transaction(tb_enqueue_transaction),
                  .transaction_write(tb_transaction_write),
                  .transaction_fake(tb_transaction_fake),
                  .transaction_addr(tb_transaction_addr),
                  .transaction_data(tb_transaction_data),
                  .transaction_error(tb_transaction_error),
                  .transaction_size(tb_transaction_size),
                  // Testing controls
                  .model_reset(tb_model_reset),
                  .enable_transactions(tb_enable_transactions),
                  .current_transaction_num(tb_current_transaction_num),
                  .current_transaction_error(tb_current_transaction_error),
                  // AHB-Lite-Slave Side
                  .hsel(tb_hsel),
                  .htrans(tb_htrans),
                  .haddr(tb_haddr),
                  .hsize(tb_hsize),
                  .hwrite(tb_hwrite),
                  .hwdata(tb_hwdata),
                  .hrdata(tb_hrdata),
                  .hresp(tb_hresp));


//*****************************************************************************
// DUT Instance
//*****************************************************************************

ahb_usb_rx_top DUT (.clk(tb_clk), .n_rst(tb_n_rst),
                    .hsel(tb_hsel),
                    .htrans(tb_htrans),
                    .haddr(tb_haddr),
                    .hsize(tb_hsize[1:0]),
                    .hwrite(tb_hwrite),
                    .hwdata(tb_hwdata),
                    .hrdata(tb_hrdata),
                    .hresp(tb_hresp),
                    .hready(tb_hready),
                    .dplus_in(tb_dplus_in),
                    .dminus_in(tb_dminus_in),
                    .d_mode(tb_d_mode)
                   );
                    

//*****************************************************************************
// DUT Related TB Tasks
//*****************************************************************************
// Task for standard DUT reset procedure
task reset_dut;
begin
  // Activate the reset
  tb_n_rst = 1'b0;

  // Maintain the reset for more than one cycle
  @(posedge tb_clk);
  @(posedge tb_clk);

  // Wait until safely away from rising edge of the clock before releasing
  @(negedge tb_clk);
  tb_n_rst = 1'b1;

  // Leave out of reset for a couple cycles before allowing other stimulus
  // Wait for negative clock edges, 
  // since inputs to DUT should normally be applied away from rising clock edges
  @(negedge tb_clk);
  @(negedge tb_clk);
end
endtask

// Task to cleanly and consistently check DUT output values
task check_outputs;
  input string check_tag;
begin
  tb_mismatch = 1'b0;
  tb_check    = 1'b1;
  if(tb_expected_hready == tb_hready) begin // Check passed
    $info("Correct 'hready' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("  INCORRECT 'hready' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_get_rx_data == tb_get_rx_data) begin // Check passed
    $info("Correct 'get_rx_data' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("  INCORRECT 'get_rx_data' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_clear == tb_clear) begin // Check passed
    $info("Correct 'clear' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("  INCORRECT 'clear' output %s during %s test case", check_tag, tb_test_case);
  end

  // Wait some small amount of time so check pulse timing is visible on waves
  #(0.1);
  tb_check =1'b0;
end
endtask
  
  
  
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

 

//*****************************************************************************
// Bus Model Usage Related TB Tasks
//*****************************************************************************
// Task to pulse the reset for the bus model
task reset_model;
begin
  tb_model_reset = 1'b1;
  #(0.1);
  tb_model_reset = 1'b0;
end
endtask

// Task to enqueue a new transaction
task enqueue_transaction;
  input logic for_dut;
  input logic write_mode;
  input logic [ADDR_MAX_BIT:0] address;
  input logic [DATA_MAX_BIT:0] data;
  input logic expected_error;
  input logic [1:0] size;
begin
  // Make sure enqueue flag is low (will need a 0->1 pulse later)
  tb_enqueue_transaction = 1'b0;
  #0.1ns;

  // Setup info about transaction
  tb_transaction_fake  = ~for_dut;
  tb_transaction_write = write_mode;
  tb_transaction_addr  = address;
  tb_transaction_data  = data;
  tb_transaction_error = expected_error;
  tb_transaction_size  = {1'b0,size};

  // Pulse the enqueue flag
  tb_enqueue_transaction = 1'b1;
  #0.1ns;
  tb_enqueue_transaction = 1'b0;
end
endtask

// Task to wait for multiple transactions to happen
task execute_transactions;
  input integer num_transactions;
  integer wait_var;
begin
  // Activate the bus model
  tb_enable_transactions = 1'b1;
  @(posedge tb_clk);

  while(tb_hready == 1'b0) begin
    #0.1ns;
  end
  // Process the transactions (all but last one overlap 1 out of 2 cycles
  for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
    @(posedge tb_clk);
  end

  // Run out the last one (currently in data phase)
  @(posedge tb_clk);

  // Turn off the bus model
  @(negedge tb_clk);
  tb_enable_transactions = 1'b0;
end
endtask


// Task to clear/initialize all FIR-side inputs
task init_expected_outs;
begin
  tb_expected_hready = 1'b1;
  tb_expected_get_rx_data = 1'b0;
  tb_expected_clear = 1'b0;
end
endtask

//*****************************************************************************
//*****************************************************************************
// Main TB Process
//*****************************************************************************
//*****************************************************************************
initial begin
  // Initialize Test Case Navigation Signals
  tb_test_case       = "Initilization";
  tb_test_case_num   = -1;
  tb_test_data       = '0;
  tb_check_tag       = "N/A";
  tb_check           = 1'b0;
  tb_mismatch        = 1'b0;
  // Initialize all of the directly controled DUT inputs
  tb_n_rst          = 1'b1;
  // Initialize all of the bus model control inputs
  tb_model_reset          = 1'b0;
  tb_enable_transactions  = 1'b0;
  tb_enqueue_transaction  = 1'b0;
  tb_transaction_write    = 1'b0;
  tb_transaction_fake     = 1'b0;
  tb_transaction_addr     = '0;
  tb_transaction_data     = '0;
  tb_transaction_error    = 1'b0;
  tb_transaction_size     = 3'd0;

  //Set inputs to reset
  tb_n_rst          = 1'b1;
  tb_dplus_in       = 1'b1;
  tb_dminus_in      = 1'b0;

  // Wait some time before starting first test case
  #(0.1);

  // Clear the bus model
  reset_model();

  //*****************************************************************************
  // Power-on-Reset Test Case
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Power-on-Reset";
  tb_test_case_num = tb_test_case_num + 1;
  
  // Setup FIR Filter provided signals with 'active' values for reset check

  // Reset the DUT
  reset_dut();

  // Check outputs for reset state

  // Give some visual spacing between check and next test case start
  #(CLK_PERIOD * 3);

// Test case 1: PID OUT Check
    @(negedge tb_clk);
    tb_test_case_num++;
    tb_test_case = "PID OUT Check";

    // DUT Reset
    reset_dut();

    tb_test_data            = 8'b00001010;
    //tb_expected_rx_packet   = 4'b0001;

    sync_send();
    send_encode(tb_test_data);

    //send addr???
    //tb_expected_rx_packet_data = '0;
    //tb_expected_rx_transfer_active = 1'b1;
    
  enqueue_transaction(1'b1, 1'b0, (4), 32'h00000104, 1'b0, 2'd1);
  execute_transactions(1);
    send_eop();
    
    // Check outputs

    #(DATA_PERIOD * 2);

// Test case 2: PID IN Check (Works based on wave)
    @(negedge tb_clk);
    tb_test_case_num++;
    tb_test_case = "PID IN Check";
    // DUT Reset
    reset_dut;
    tb_test_data            = 8'b01110010;
    sync_send();
    send_encode(tb_test_data);
    //send addr???
    
  enqueue_transaction(1'b1, 1'b0, (4), 32'h00000102, 1'b0, 2'd1);
  execute_transactions(1);
    send_eop();
    
    // Check outputs
    #(DATA_PERIOD * 2);



    // Test case 3: Send data Check
    @(negedge tb_clk);
    tb_test_case_num++;
    tb_test_case = "Send data Check";

    // DUT Reset
    reset_dut();

    //Sync + PID
    sync_send();

    tb_test_data            = 8'b00010100;      //DATA0
    send_encode(tb_test_data);

    //First 2 data sends
    tb_test_data            = 8'b01011111;      //STALL Decoded = 00011110
    send_encode(tb_test_data);

    tb_test_data            = 8'b01100011;      //NAK Decoded = 01011010
    send_encode(tb_test_data);

    //Eval Send
    tb_test_data            = 8'b00011011;      //ACK Decoded = 11010010
    send_encode(tb_test_data);
    send_eop();

    #(DATA_PERIOD * 2); 

    enqueue_transaction(1'b1, 1'b0, (0), 32'b0, 1'b0, 2'd1);
    enqueue_transaction(1'b1, 1'b0, (0), 32'b0, 1'b0, 2'd1);
    enqueue_transaction(1'b1, 1'b0, (0), 32'h0000001e, 1'b0, 2'd1);
    enqueue_transaction(1'b1, 1'b0, (0), 32'h00005a1e, 1'b0, 2'd1);
    execute_transactions(4);
    #(CLK_PERIOD * 10);

    // Test case 4: Invaid Sync (works on wave)
    @(negedge tb_clk);
    tb_test_case_num++;
    tb_test_case = "Invalid Sync";

    // DUT Reset
    reset_dut();


    //Invalid Sync
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

    tb_dplus_in = 1'b1;
    tb_dminus_in = 1'b0;
    #(DATA_PERIOD);

    enqueue_transaction(1'b1, 1'b0, (6), 32'h00000001, 1'b0, 2'd1);
    execute_transactions(1);

    #(DATA_PERIOD * 2); 


    // Test case 5: Premature EOP (works on wave)
    @(negedge tb_clk);
    tb_test_case_num++;
    tb_test_case = "Premature EOP";
    // DUT Reset
    reset_dut();
    //Sync + PID
    sync_send();
    send_encode(8'b00010100);                //DATA0 Encode
    tb_test_data            = 8'b10010110;
    send_encode(tb_test_data);
    
    data = tb_test_data;
    for(i = 0; i < 6; i++) 
    begin
      tb_dplus_in = data[i];
      tb_dminus_in = ~data[i];
      #(DATA_PERIOD);
    end

    send_eop();
  enqueue_transaction(1'b1, 1'b0, (6), 32'h00000001, 1'b0, 2'd1);
  execute_transactions(1);
 
    #(DATA_PERIOD * 2);


    // Test case 6: Larger data Check with flush
    @(negedge tb_clk);
    tb_test_case_num++;
    tb_test_case = "Larger data check with flush";
    // DUT Reset
    reset_dut();
    //Sync + PID
    sync_send();
    tb_test_data            = 8'b00010100;      //DATA0
    send_encode(tb_test_data);
    tb_test_data_array = { {8'h32}, {8'h40}, {8'he3}, {8'h59}, {8'ha8}, {8'hb4}, {8'hc7}, {8'hd5}, {8'he9}, {8'h45}, {8'hf6}, {8'hcc} };
  //tb_test_data_array_decoded = { {8'ha9}, {8'h3e}, {8'hda}, {8'h15}, {8'h06}, {8'h22}, {8'hb7}, {8'h81}, {8'hc4}, {8'h31}, {8'he4}, {8'hab} };
    for(integer i = 0; i < 12; i++) begin
      send_encode(tb_test_data_array[i][7:0]);
    end
    
    send_eop();
    #(DATA_PERIOD * 2);

    enqueue_transaction(1'b1, 1'b0, (2), 32'b0, 1'b0, 2'd2);
    enqueue_transaction(1'b1, 1'b0, (2), 32'b0, 1'b0, 2'd2);
    enqueue_transaction(1'b1, 1'b0, (2), 32'h000000ab, 1'b0, 2'd2);
    enqueue_transaction(1'b1, 1'b0, (2), 32'h0000e4ab, 1'b0, 2'd2);
    enqueue_transaction(1'b1, 1'b0, (2), 32'h0031e4ab, 1'b0, 2'd2);
    enqueue_transaction(1'b1, 1'b0, (2), 32'hc431e4ab, 1'b0, 2'd2);
    execute_transactions(6);
    #(CLK_PERIOD * 8);

    enqueue_transaction(1'b1, 1'b1, (13), 32'h1, 1'b0, 2'd0);
    execute_transactions(1);
    #(CLK_PERIOD * 2);
    enqueue_transaction(1'b1, 1'b0, (8), 32'h0, 1'b0, 2'd0);
    execute_transactions(1);
    #(CLK_PERIOD * 8);


// Test case 7: Write to read only address
    tb_test_case_num++;
    tb_test_case = "Write to read only address";
    // DUT Reset
    reset_dut();

    enqueue_transaction(1'b1, 1'b1, (8), 32'hff, 1'b1, 2'd0);
    execute_transactions(1);
    #(CLK_PERIOD * 2);

  $stop;
end

endmodule
