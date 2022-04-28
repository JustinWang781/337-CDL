// $Id: $
// File name:   rx_edge_detect.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx dual edge detector


// Should this be a dual edge detector???

module rx_edge_detect
(
	input clk,
	input n_rst,
	input dplus_in_sync,
	output reg d_edge
);
	reg data;

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if(1'b0 == n_rst) begin
			data <= 1'd1;
		end
		else begin
			data <= dplus_in_sync;
		end
	end

	assign d_edge = (data & ~dplus_in_sync) | (~data & dplus_in_sync);

endmodule