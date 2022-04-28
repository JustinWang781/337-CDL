// $Id: $
// File name:   flex_stp_sr.sv
// Created:     2/9/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: Flexible and Scalable Serial-to-Parallel Shift Register Design

module flex_stp_sr
#(
	parameter NUM_BITS = 8,
	parameter SHIFT_MSB = 1'b0
)
(
	input clk,
	input n_rst,
	input shift_enable,
	input serial_in,
	output reg [NUM_BITS-1:0] parallel_out
);

	reg [NUM_BITS-1:0] nxt_par;

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if (1'b0 == n_rst) begin
			parallel_out <= '0;		//Careful (usually is a 1 but in this case I am making it a 0)
		end
		else begin
			parallel_out <= nxt_par;
		end
	end
	
	always_comb
	begin : NXT_PAR
		nxt_par = parallel_out;
		if (!shift_enable) begin
			nxt_par = parallel_out;
		end
		else begin
			if (SHIFT_MSB) begin
				nxt_par = {parallel_out[NUM_BITS-2:0], serial_in}; //Shift MSB case
			end
			else begin
				nxt_par = {serial_in, parallel_out[NUM_BITS-1:1]}; //Shift LSB case
			end
		end
	end

endmodule
 
