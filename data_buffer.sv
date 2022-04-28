// $Id: $
// File name:   data_buffer.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: data buffer

module data_buffer
(
	input	wire clk,
	input	wire n_rst,
	input	wire [7:0] rx_packet_data,
	input   wire store_rx_packet_data,
	input	wire flush,
	input	wire get_rx_data,
	input 	wire clear,

	output	reg  [7:0] rx_data,
	output	reg  [6:0] buffer_occupancy
);
	logic [7:0][63:0] regs;
	logic [7:0][63:0] nxt_reg;

	logic [7:0] read_ptr;
	logic [7:0] nxt_read_ptr;
	logic [7:0] write_ptr;
	logic [7:0] nxt_write_ptr;


	always_comb
	begin : NXT_LOGIC
		nxt_reg = regs;
		nxt_read_ptr = read_ptr;
		nxt_write_ptr = write_ptr;

		if(flush || clear) begin
			nxt_reg = '0;
			nxt_read_ptr = '0;
			nxt_write_ptr = '0;
		end
		else if(store_rx_packet_data) begin
			if(buffer_occupancy == 63) begin
				nxt_reg = '0;
				nxt_read_ptr = '0;
				nxt_write_ptr = '0;
			end
			nxt_reg[nxt_write_ptr] = rx_packet_data;
			nxt_write_ptr++;
		end
		else if(get_rx_data) begin
			nxt_read_ptr++;
		end
	end

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if (1'b0 == n_rst) begin
			regs <= '0;
			read_ptr <= '0;
			write_ptr <= '0;
		end
		else begin
			regs <= nxt_reg;
			read_ptr <= nxt_read_ptr;
			write_ptr <= nxt_write_ptr;
		end
	end

	always_comb
	begin : OUT_LOGIC
		if(get_rx_data) begin
			rx_data = regs[read_ptr];
		end
	end

	assign buffer_occupancy = (write_ptr - read_ptr);

endmodule