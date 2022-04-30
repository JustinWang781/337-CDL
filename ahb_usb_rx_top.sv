module ahb_usb_rx_top
(
  input clk, n_rst,
  input hsel,
  input [3:0] haddr,
  input [1:0] htrans, hsize, 
  input hwrite,
  input [31:0] hwdata,
  output [31:0] hrdata,
  output hresp, hready,
  input dplus_in, dminus_in,
  output d_mode
);

  logic [3:0] rx_packet;
  logic rx_data_ready;
  logic rx_transfer_active;
  logic rx_error;
  logic flush;
  logic [6:0] buffer_occupancy;
  logic [7:0] rx_data;
  logic get_rx_data;
  logic clear;
  logic store_rx_packet_data;
  logic [7:0] rx_packet_data;

  ahb_lite_slave ahb(.clk(clk), .n_rst(n_rst), .hsel(hsel), .haddr(haddr), .htrans(htrans), .hsize(hsize),
                     .hwrite(hwrite), .hwdata(hwdata), .hrdata(hrdata), .hresp(hresp), .hready(hready), 
                     .rx_packet(rx_packet), .rx_data_ready(rx_data_ready), .rx_transfer_active(rx_transfer_active),
                     .rx_error(rx_error), .d_mode(d_mode), .buffer_occupancy(buffer_occupancy), .rx_data(rx_data),
                     .get_rx_data(get_rx_data), .clear(clear));

  data_buffer buff(.clk(clk), .n_rst(n_rst), .rx_packet_data(rx_packet_data), .store_rx_packet_data(store_rx_packet_data),
                   .flush(flush), .get_rx_data(get_rx_data), .clear(clear), .rx_data(rx_data), .buffer_occupancy(buffer_occupancy));

  usb_rx rx(.clk(clk), .n_rst(n_rst), .dplus_in(dplus_in), .dminus_in(dminus_in), .buffer_occupancy(buffer_occupancy),
         .rx_transfer_active(rx_transfer_active), .rx_error(rx_error), .rx_packet(rx_packet), .rx_data_ready(rx_data_ready),
         .rx_packet_data(rx_packet_data), .flush(flush), .store_rx_packet_data(store_rx_packet_data));

endmodule
