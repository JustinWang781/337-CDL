// $Id: $
// File name:   usb_rx.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx total

module usb_rx
(
	input	wire clk,
	input	wire n_rst,
	input 	wire dplus_in,
	input 	wire dminus_in,
	input	wire [6:0] buffer_occupancy,

	output	reg  rx_transfer_active,
	output  reg  rx_error,
	output	reg  [3:0] rx_packet,				// Incorrect on the diagram (should be 4 bits)
	output	reg  rx_data_ready,
	output 	reg  [7:0] rx_packet_data,
	output  reg  flush,
	output  reg  store_rx_packet_data
);

	wire dplus_in_sync;
	wire dminus_in_sync;

	wire eop;

	wire shift_enable;
	wire d_orig;

	wire d_edge;

	wire [7:0] rcv_data;
	wire byte_received;


	rx_sync_high I ( .clk(clk), .n_rst(n_rst), .dplus_in(dplus_in), .dplus_in_sync(dplus_in_sync) );
	rx_sync_low II ( .clk(clk), .n_rst(n_rst), .dminus_in(dminus_in), .dminus_in_sync(dminus_in_sync) );

	rx_eop III ( .clk(clk), .n_rst(n_rst), .dplus_in_sync(dplus_in_sync), .dminus_in_sync(dminus_in_sync), .eop(eop) );

	rx_decoder IV ( .clk(clk), .n_rst(n_rst), .dplus_in_sync(dplus_in_sync), .eop(eop), .shift_enable(shift_enable), .d_orig(d_orig) );

	rx_edge_detect V ( .clk(clk), .n_rst(n_rst), .dplus_in_sync(dplus_in_sync), .d_edge(d_edge) );

	rx_timer VI ( .clk(clk), .n_rst(n_rst), .rx_transfer_active(rx_transfer_active), .d_edge(d_edge), .shift_enable(shift_enable), .byte_received(byte_received) );

	rx_sr VII ( .clk(clk), .n_rst(n_rst), .shift_enable(shift_enable), .d_orig(d_orig), .rcv_data(rcv_data) );


	rx_rcu VIII ( .clk(clk), .n_rst(n_rst), .buffer_occupancy(buffer_occupancy), .eop(eop), .d_edge(d_edge), .shift_enable(shift_enable), .rcv_data(rcv_data),
				  .byte_received(byte_received), .rx_transfer_active(rx_transfer_active), .rx_error(rx_error), .rx_packet(rx_packet), .rx_data_ready(rx_data_ready),
				  .rx_packet_data(rx_packet_data), .flush(flush), .store_rx_packet_data(store_rx_packet_data) );
				  	

endmodule