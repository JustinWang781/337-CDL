module ahb_lite_slave
(
  input clk, n_rst,
  input hsel, 
  input [3:0] haddr,
  input [1:0] htrans, hsize,
  input hwrite,
  input [31:0] hwdata,
  output [31:0] hrdata, 
  output hresp, hready,
  input [3:0] rx_packet,
  input rx_data_ready, rx_transfer_active, rx_error,
  output d_mode,
  input [6:0] buffer_occupancy,
  input [7:0] rx_data,
  output get_rx_data, clear
);

  logic [7:0] data [9:0];
  logic [31:0] next_hrdata_reg;
  logic [31:0] hrdata_reg;
  logic [15:0] error;
  logic [15:0] status;
  logic [7:0] buffer_occupancy_8;

  logic [4:0] next_write_sel;
  logic [4:0] write_sel;

  logic hresp_reg;
  assign hresp = hresp_reg;

  logic hready_reg;
  assign hready = hready_reg;

  logic get_rx_data_reg;
  assign get_rx_data = get_rx_data_reg;

  assign hrdata = hrdata_reg;

  assign d_mode = 1'b1;



//writable data registers
  reg [7:0] next_data_buffer_reg_0;
  reg [7:0] data_buffer_reg_0;

  reg [7:0] next_data_buffer_reg_1;
  reg [7:0] data_buffer_reg_1;

  reg [7:0] next_data_buffer_reg_2;
  reg [7:0] data_buffer_reg_2;

  reg [7:0] next_data_buffer_reg_3;
  reg [7:0] data_buffer_reg_3;

  reg [7:0] next_flush_buffer_control_reg;
  reg [7:0] flush_buffer_control_reg;

  assign clear = flush_buffer_control_reg[0];

//read buffer signals
  logic [2:0] start_addr;
  logic [1:0] size;
  logic [2:0] enable;
  logic enable_0;
  logic enable_1;
  logic enable_2;
  logic enable_3;

  typedef enum logic [3:0] {IDLE, GET1_1, DELAY1, GET2_1, GET2_2, DELAY2, DUMMY,
                            GET4_1, GET4_2, GET4_3, GET4_4, DELAY3} state_type;
  state_type state;
  state_type next_state;

  always_ff @(posedge clk, negedge n_rst) begin
    if(!n_rst) begin
      state <= IDLE;
      hrdata_reg <= 32'b0; 
      data_buffer_reg_0 <= 8'b0;
      data_buffer_reg_1 <= 8'b0;
      data_buffer_reg_2 <= 8'b0;
      data_buffer_reg_3 <= 8'b0;
      flush_buffer_control_reg <= 8'b0;
      write_sel <= 5'b0;
    end
    else begin
      state <= next_state;
      hrdata_reg <= next_hrdata_reg;
      data_buffer_reg_0 <= next_data_buffer_reg_0;
      data_buffer_reg_1 <= next_data_buffer_reg_1;
      data_buffer_reg_2 <= next_data_buffer_reg_2;
      data_buffer_reg_3 <= next_data_buffer_reg_3;
      flush_buffer_control_reg <= next_flush_buffer_control_reg;
      write_sel <= next_write_sel;
    end
  end

  always_comb begin

    hresp_reg = 0;
    next_write_sel = 5'b0;

    if(hsel == 1'b1 && (htrans == 2'b10)) begin
      if(hwrite) begin
        case(haddr)
          4'd0: begin
            if(hsize == 0)
              next_write_sel = 5'b00001;
            else if(hsize == 1)
              next_write_sel = 5'b00011;
            else if(hsize == 2'd2)
              next_write_sel = 5'b01111;
            else
              hresp_reg = 1;
          end
          4'd1: begin
            if(hsize == 0)
              next_write_sel = 5'b00010;
            else if(hsize == 1)
              next_write_sel = 5'b00011;
            else if(hsize == 2'd2)
              next_write_sel = 5'b01111;
            else
              hresp_reg = 1;
          end
          4'd2: begin
            if(hsize == 0)
              next_write_sel = 5'b00100;
            else if(hsize == 1)
              next_write_sel = 5'b01100;
            else if(hsize == 2'd2)
              next_write_sel = 5'b01111;
            else
              hresp_reg = 1;
          end
          4'd3: begin
            if(hsize == 0)
              next_write_sel = 5'b01000;
            else if(hsize == 1)
              next_write_sel = 5'b01100;
            else if(hsize == 2'd2)
              next_write_sel = 5'b01111;
            else
              hresp_reg = 1;
          end
          4'd13: begin
            if(hsize == 0)
              next_write_sel = 5'b10000;
            else
              hresp_reg = 1;
          end
          default: hresp_reg = 1;
        endcase
      end
    end
    
    if(buffer_occupancy == 7'b0)
      next_flush_buffer_control_reg = 8'b0;
    else begin
      if(write_sel[4])
        next_flush_buffer_control_reg = hwdata[7:0];
      else
        next_flush_buffer_control_reg = flush_buffer_control_reg;
    end

    status = 16'b0;
    if(rx_data_ready) //New Data
      status[0] = 1'b1;
    if(rx_packet == 4'b0001) //OUT
      status[2] = 1'b1;
    if(rx_packet == 4'b1001) //IN
      status[1] = 1'b1;
    if(rx_packet == 4'b0010) //ACK
      status[3] = 1'b1;
    if(rx_packet == 4'b1010) //NACK
      status[4] = 1'b1;
    if(rx_transfer_active) //Receiving Packet
      status[8] = 1'b1;

    error = 16'b0;
    if(rx_error)
      error = 16'b1;

    buffer_occupancy_8 = {1'b0, buffer_occupancy};

    
    data[0] = data_buffer_reg_0; //addr 0
    data[1] = data_buffer_reg_1; //addr 1
    data[2] = data_buffer_reg_2; //addr 2
    data[3] = data_buffer_reg_3; //addr 3
    data[4] = status[7:0];
    data[5] = status[15:8];
    data[6] = error[7:0];
    data[7] = error[15:8];
    data[8] = buffer_occupancy_8;
    data[9] = flush_buffer_control_reg; //addr D

    case(haddr)
      4'd0: begin
        if(hsize == 0)
          next_hrdata_reg = {24'b0, data[0]};
        else if(hsize == 2'd1)
          next_hrdata_reg = {16'b0, data[1], data[0]};
        else
          next_hrdata_reg = {data[3], data[2], data[1], data[0]};
      end
      4'd1: begin
        if(hsize == 0)
          next_hrdata_reg = {16'b0, data[1], 8'b0};
        else if(hsize == 2'd1)
          next_hrdata_reg = {16'b0, data[1], data[0]};
        else
          next_hrdata_reg = {data[3], data[2], data[1], data[0]};
      end
      4'd2: begin
        if(hsize == 0)
          next_hrdata_reg = {8'b0, data[2], 16'b0};
        else if(hsize == 2'd1)
          next_hrdata_reg = {data[3], data[2], 16'b0};
        else
          next_hrdata_reg = {data[3], data[2], data[1], data[0]};
      end
      4'd3: begin
        if(hsize == 0)
          next_hrdata_reg = {data[3], 24'b0};
        else if(hsize == 2'd1)
          next_hrdata_reg = {data[3], data[2], 16'b0};
        else
          next_hrdata_reg = {data[3], data[2], data[1], data[0]};
      end
      4'd4: begin
        if(hsize == 0)
          next_hrdata_reg = {24'b0, data[4]};
        else if(hsize == 2'd1)
          next_hrdata_reg = {16'b0, data[5], data[4]};
        else
          hresp_reg = 1;
      end
      4'd5: begin
        if(hsize == 0)
          next_hrdata_reg = {16'b0, data[5], 8'b0};
        else if(hsize == 2'd1)
          next_hrdata_reg = {16'b0, data[5], data[4]};
        else
          hresp_reg = 1;
      end
      4'd6: begin
        if(hsize == 0)
          next_hrdata_reg = {24'b0, data[6]};
        else if(hsize == 2'd1)
          next_hrdata_reg = {16'b0, data[7], data[6]};
        else
          hresp_reg = 1;
      end
      4'd7: begin
        if(hsize == 0)
          next_hrdata_reg = {16'b0, data[7], 8'b0};
        else if(hsize == 2'd1)
          next_hrdata_reg = {16'b0, data[7], data[6]};
        else
          hresp_reg = 1;
      end
      4'd8: begin
        if(hsize == 0)
          next_hrdata_reg = {24'b0, data[8]};
        else
          hresp_reg = 1;
      end
      4'd13: begin
        if(hsize == 0 | hsize == 2'd1)
          next_hrdata_reg = {24'b0, data[9]};
        else
          hresp_reg = 1;
      end
      default: next_hrdata_reg = 32'b0;
    endcase

//Read Buffer Controller----------

    //comb block
    size = 2'd0;
    if(hsel & !hwrite & htrans == 2'b10) begin
      if(hsize == 0) begin
        if(haddr <= 4'd4) begin
          start_addr = haddr[2:0];
          size = 2'd1;
        end
      end
      else if(hsize == 2'b1) begin
        if(haddr == 4'd1 | haddr == 4'd0) begin
          start_addr = 3'd0;
          size = 2'd2;
        end
        else if(haddr == 4'd2 | haddr == 4'd3) begin
          start_addr = 3'd2;
          size = 2'd2;
        end
      end
      else if(hsize == 2'd2) begin
        if(haddr == 4'd1 | haddr == 4'd0 | haddr == 4'd2 | haddr == 4'd3) begin
          start_addr = 3'd0;
          size = 2'd3;
        end
      end
    end
    hready_reg = 1'b1;
    get_rx_data_reg = 1'b0;
    enable = 3'd4;
    next_state = state;

    case(state)
      DUMMY: next_state = IDLE;
      IDLE: begin
        if(size == 2'd1) begin
          hready_reg = 1'b0;
          next_state = GET1_1;
        end
        else if(size == 2'd2) begin
          hready_reg = 1'b0;
          next_state = GET2_1;
        end
        else if(size == 2'd3) begin
          hready_reg = 1'b0;
          next_state = GET4_1;
        end
        else
          next_state = IDLE;
      end
      GET1_1: begin
        next_state = DELAY1;
        get_rx_data_reg = 1'b1;
        enable = 3'd0;
        hready_reg = 1'b0;
      end
      DELAY1: begin
        next_state = DUMMY;
        hready_reg = 1'b0;
      end
      GET2_1: begin
        next_state = GET2_2;
        get_rx_data_reg = 1'b1;
        enable = 3'd0;
        hready_reg = 1'b0;
      end
      GET2_2: begin
        next_state = DELAY2;
        get_rx_data_reg = 1'b1;
        enable = 3'd1;
        hready_reg = 1'b0;
      end
      DELAY2: begin
        next_state = DUMMY;
        hready_reg = 1'b0;
      end
      GET4_1: begin
        next_state = GET4_2;
        get_rx_data_reg = 1'b1;
        enable = 3'd0;
        hready_reg = 1'b0;
      end
      GET4_2: begin
        next_state = GET4_3;
        get_rx_data_reg = 1'b1;
        enable = 3'd1;
        hready_reg = 1'b0;
      end
      GET4_3: begin
        next_state = GET4_4;
        get_rx_data_reg = 1'b1;
        enable = 3'd2;
        hready_reg = 1'b0;
      end
      GET4_4: begin
        next_state = DELAY3;
        get_rx_data_reg = 1'b1;
        enable = 3'd3;
        hready_reg = 1'b0;
      end
      DELAY3: begin
        next_state = DUMMY;
        hready_reg = 1'b0;
      end
    endcase


    //enable comb block

    enable_0 = 0;
    enable_1 = 0;
    enable_2 = 0;
    enable_3 = 0;
    if((enable + start_addr) == 3'd0)
      enable_0 = 1;
    else if((enable + start_addr) == 3'd1)
      enable_1 = 1;
    else if((enable + start_addr) == 3'd2)
      enable_2 = 1;
    else if((enable + start_addr) == 3'd3)
      enable_3 = 1;

    if(enable_0) 
      next_data_buffer_reg_0 = rx_data;
    else if(write_sel[0])
      next_data_buffer_reg_0 = hwdata[7:0];
    else
      next_data_buffer_reg_0 = data_buffer_reg_0;
      
    if(enable_1) 
      next_data_buffer_reg_1 = rx_data;
    else if(write_sel[1])
      next_data_buffer_reg_1 = hwdata[15:8];
    else
      next_data_buffer_reg_1 = data_buffer_reg_1;

    if(enable_2) 
      next_data_buffer_reg_2 = rx_data;
    else if(write_sel[2])
      next_data_buffer_reg_2 = hwdata[23:16];
    else
      next_data_buffer_reg_2 = data_buffer_reg_2;

    if(enable_3) 
      next_data_buffer_reg_3 = rx_data;
    else if(write_sel[3])
      next_data_buffer_reg_3 = hwdata[31:24];
    else
      next_data_buffer_reg_3 = data_buffer_reg_3;

  end

endmodule
