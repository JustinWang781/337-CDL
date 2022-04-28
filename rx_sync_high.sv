// $Id: $
// File name:   rx_sync_high.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: Reset to Logic High Synchronizer

module rx_sync_high
(
	input clk,
	input n_rst,
	input dplus_in,
	output reg dplus_in_sync
);
	reg data;

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if(1'b0 == n_rst) begin
			data <= 1'd1;
			dplus_in_sync <= 1'd1;
		end
		else begin
			data <= dplus_in;
			dplus_in_sync <= data;
		end
	end

endmodule