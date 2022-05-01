// $Id: $
// File name:   rx_sr.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx shift register

module rx_sr
(
	input	wire clk,
	input	wire n_rst,
	input	wire shift_enable,
	input	wire d_orig,
	output	logic [7:0] rcv_data
);

  	flex_stp_sr#(
    	.NUM_BITS(8),
		.SHIFT_MSB(1'b0)
  	) 
  	CORE(
		.clk(clk),
    	.n_rst(n_rst),
    	.serial_in(d_orig),
    	.shift_enable(shift_enable),
    	.parallel_out(rcv_data)
  	);

endmodule