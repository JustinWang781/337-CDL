// $Id: $
// File name:   rx_sync_low.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: Reset to Logic Low Synchronizer

module rx_sync_low
(
	input clk,
	input n_rst,
	input dminus_in,
	output reg dminus_in_sync
);
	reg data;

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if(1'b0 == n_rst) begin
			data <= 1'd0;
			dminus_in_sync <= 1'd0;
		end
		else begin
			data <= dminus_in;
			dminus_in_sync <= data;
		end
	end

endmodule