// $Id: $
// File name:   rx_timer.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx timer

module rx_timer 
(
    input wire clk,
    input wire n_rst,
    input wire rx_transfer_active,
    input wire d_edge,

    output reg shift_enable,
    output reg byte_received
);

    reg [3:0] clk_count;
	reg [3:0] bit_count;
	reg [3:0] nxt_clk_count;
    reg shift_strobe;

	//Flex Counter 1
 	flex_counter
 	I (
		.clk(clk),
		.n_rst(n_rst), 
		.clear(d_edge),
		.count_enable(rx_transfer_active | d_edge),
		.rollover_val(clk_count),
		.count_out(),
		.rollover_flag(shift_enable)
	);

	//Flex Counter 2
 	flex_counter
 	II (
		.clk(clk),
		.n_rst(n_rst), 
		.clear(!rx_transfer_active),
		.count_enable(shift_strobe | byte_received),
		.rollover_val(bit_count),
		.count_out(),
		.rollover_flag(byte_received)
	);


	always_comb
	begin
		bit_count = 4'd8;
		nxt_clk_count = clk_count;

		if(d_edge) begin
			nxt_clk_count = 4'd3;
		end
		else if(shift_enable) begin
			nxt_clk_count = 4'd7;
		end
	end
	

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if(1'b0 == n_rst) begin
			clk_count <= 4'd8;
		end
		else begin
			clk_count <= nxt_clk_count;
		end
	end

	assign shift_strobe = (!rx_transfer_active) | (shift_enable);

endmodule