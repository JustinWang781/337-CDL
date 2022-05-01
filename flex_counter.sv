// $Id: $
// File name:   flex_counter.sv
// Created:     2/2/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: Flexible Counter Desgin

module flex_counter
#(
	parameter NUM_CNT_BITS = 4
)
(
	input clk,
	input n_rst,
	input clear,
	input count_enable,
	input [NUM_CNT_BITS-1:0] rollover_val,
	output reg [NUM_CNT_BITS-1:0] count_out,
	output reg rollover_flag
);
	
	reg [NUM_CNT_BITS-1:0] nxt_count;
	reg nxt_flag;

	
	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if(1'b0 == n_rst) begin
			count_out <= '0;
			rollover_flag <= 1'b0;
		end
		else begin //if(count_enable) begin
			count_out <= nxt_count;
			rollover_flag <= nxt_flag;
		end
	end

	always_comb	
	begin : NXT_COUNT
		nxt_count = count_out;
		nxt_flag = rollover_flag;

		if(count_enable) begin

			if(count_out == rollover_val-1) begin
				nxt_flag = 1'b1;
			end
			else begin
				nxt_flag = 1'b0;
			end

			if(rollover_flag) begin
				nxt_count = 0;
			end
			else if(clear) begin
				nxt_count = 0;
			end
			else begin
				nxt_count = count_out + 1;
			end

		end
	end
	
endmodule

