// $Id: $
// File name:   rx_decoder.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx decoder

module rx_decoder
(
    input wire clk,
    input wire n_rst,
	
    input wire dplus_in_sync,
    input wire eop,
	input wire shift_enable,

    output reg d_orig
);
	logic d_orig_1;
	logic nxt_d_orig_1;

	logic d_orig_2;
	logic nxt_d_orig_2;

	always_comb
	begin : NXT_Logic
		nxt_d_orig_1 = d_orig_1;
		nxt_d_orig_2 = d_orig_2;

		//if(!eop) begin

			if(shift_enable) begin
				nxt_d_orig_1 = dplus_in_sync;
				nxt_d_orig_2 = d_orig_1;
				/*
				if(d_orig == dplus_in_sync) begin
					nxt_d_orig = 1;
				end
				else begin
					nxt_d_orig = 0;
				end
				*/
			end

		//end
	end

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if((1'b0 == n_rst) || eop) begin
			d_orig_1 <= 1'b1;
			d_orig_2 <= 1'b0;
		end
		else begin
			d_orig_1 <= nxt_d_orig_1;
			d_orig_2 <= nxt_d_orig_2;
		end
	end

	assign d_orig = !(nxt_d_orig_1 ^ nxt_d_orig_2);

endmodule