// $Id: $
// File name:   rx_eop.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx eop


module rx_eop
(
	input wire clk,
	input wire n_rst,
	input wire dplus_in_sync,
	input wire dminus_in_sync,
	output reg eop
);

	assign eop = !(dplus_in_sync || dminus_in_sync); 

endmodule