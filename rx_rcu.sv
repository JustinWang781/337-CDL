// $Id: $
// File name:   rx_rcu.sv
// Created:     4/26/2022
// Author:      Joseph Kawiecki
// Lab Section: 337-08
// Version:     1.0  Initial Design Entry
// Description: usb rx rcu

module rx_rcu
(
	input	wire clk,
	input	wire n_rst,
	input	wire [6:0] buffer_occupancy,
	input 	wire eop,
	input 	wire d_edge,
	input 	wire shift_enable,
	input 	wire [7:0] rcv_data,
	input 	wire byte_received,

	output	reg  rx_transfer_active,
	output  reg  rx_error,
	output	reg  [3:0] rx_packet,				// Incorrect on the diagram (should be 4 bits)
	output	reg  rx_data_ready,
	output 	reg  [7:0] rx_packet_data,
	output  reg  flush,
	output  reg  store_rx_packet_data
);
	

	typedef enum bit [3:0] {IDLE 		= 4'd0,
							LOAD_SYNC	= 4'd1,
							CHECK_SYNC 	= 4'd2,
							READ_PID 	= 4'd3,
							SEND_PID	= 4'd4,
							DATA_REC	= 4'd5,
							DATA_SEND	= 4'd6,
							TOKEN_DATA1	= 4'd7,
							SEND_TOKEN1 = 4'd8,
							TOKEN_DATA2 = 4'd9,
							SEND_TOKEN2	= 4'd10,
							ERROR		= 4'd11,
							EOP			= 4'd12} stateType;

	stateType state;
	stateType nxt_state;

	
	typedef enum bit [3:0] {OUT 		= 4'b0001,
							IN			= 4'b1001,
							DATA0 		= 4'b0011,
							DATA1 		= 4'b1011,
							ACK			= 4'b0010,
							NAK			= 4'b1010,
							STALL		= 4'b1110} pidType;

	pidType pid;
	


	assign buff_full = (buffer_occupancy >> 6) & 1'b1;	//will go high when occupancy is of 64 or higher

	
	always_comb
	begin : PID_CODES
		case(rcv_data[3:0])				//Should this be LSB 4 bits or MSB 4 bits?
			OUT: 	pid = OUT;			//OUT	
			IN: 	pid = IN;			//IN	
			DATA0: 	pid = DATA0;		//DATA0
			DATA1: 	pid = DATA1;		//DATA1
			ACK: 	pid = ACK;			//ACK
			NAK: 	pid = NAK;			//NAK
			STALL: 	pid = STALL; 		//STALL
		endcase
	end
	

	always_comb
	begin : NXT_LOGIC
		nxt_state = state;
		case(state)
			IDLE:
				if (d_edge) begin
					nxt_state = LOAD_SYNC;
				end
				else begin
					nxt_state = IDLE;
				end
			LOAD_SYNC:
				if (byte_received) begin
					nxt_state = CHECK_SYNC;
				end
				else if(eop) begin
					nxt_state = ERROR;
				end
				else begin
					nxt_state = LOAD_SYNC;
				end
			CHECK_SYNC:		
				if (rcv_data == 8'b10000000) begin
					nxt_state = READ_PID;
				end
				else begin
					nxt_state = ERROR;
				end
			READ_PID:
				if (byte_received) begin				/**/
					nxt_state = SEND_PID;
				end
				else if(eop) begin
					nxt_state = ERROR;
				end
			SEND_PID:
				case(rcv_data[3:0])								// lower 4 bits
					OUT: 		nxt_state = TOKEN_DATA1;
					IN: 		nxt_state = TOKEN_DATA1;
					DATA0: 		nxt_state = DATA_REC;
					DATA1: 		nxt_state = DATA_REC;
					ACK: 		nxt_state = EOP;
					NAK: 		nxt_state = EOP;
					STALL: 		nxt_state = ERROR; 			//Stall goes to error state
					default: 	nxt_state = ERROR;
				endcase
			DATA_REC:
				if(byte_received) begin
					nxt_state = DATA_SEND;
				end
				else if(eop || buff_full) begin
					nxt_state = ERROR;
				end
				else begin
					nxt_state = DATA_REC;
				end
			DATA_SEND:
				if(eop) begin
					nxt_state = EOP;
				end
				else if(!buff_full) begin //may need to be buff_full == 63
					nxt_state = DATA_REC;
				end
				else if(!eop || buff_full) begin
					nxt_state = ERROR;
				end
				else begin
					nxt_state = DATA_REC;
				end
			TOKEN_DATA1:
				if(byte_received) begin
					nxt_state = SEND_TOKEN1;
				end
				else if(eop) begin
					nxt_state = ERROR;
				end
				else begin
					nxt_state = TOKEN_DATA1;
				end
			SEND_TOKEN1:
				if(eop) begin
					nxt_state = ERROR;
				end
				else begin
					nxt_state = TOKEN_DATA2;
				end
			TOKEN_DATA2:
				if(byte_received) begin
					nxt_state = SEND_TOKEN2;
				end
				else if(eop) begin
					nxt_state = ERROR;
				end
				else begin
					nxt_state = TOKEN_DATA2;
				end
			SEND_TOKEN2:
				if(eop) begin
					nxt_state = EOP;
				end
				else if(!eop) begin
					nxt_state = ERROR;
				end
				else begin						//Actually I don't think I should have this here
					nxt_state = SEND_TOKEN2;
				end
			ERROR:								/**/
				if(eop) begin
					nxt_state = EOP;
				end
				//else begin
				//	nxt_state = ERROR;
				//end
			EOP:
				if(d_edge) begin
					nxt_state = LOAD_SYNC;	
				end
				else begin
					nxt_state = EOP;
				end
		endcase				
	end

	always_ff @ (posedge clk, negedge n_rst)
	begin : REG_LOGIC
		if (1'b0 == n_rst) begin
			state <= IDLE;
		end
		else begin
			state <= nxt_state;
		end
	end

		

	always_comb
	begin : OUT_LOGIC

		rx_transfer_active	 	= 1'b0;
		rx_error				= 1'b0;
		flush					= 1'b0;
		rx_data_ready		 	= 1'b0;
		store_rx_packet_data 	= 1'b0;
		rx_packet_data			= '0;

		case(state)
			IDLE:
			begin
				rx_transfer_active	 	= 1'b0;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= '0;
			end
			LOAD_SYNC:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= '0;
			end
			CHECK_SYNC:		
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= '0;
			end
			READ_PID:	
			begin	
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= '0;
			end
			SEND_PID:								//need to talk to Justin about PID codes, thinking I should just have them assigned in an always comb block
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b1;
				rx_data_ready		 	= 1'b1;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= pid;
			end
			DATA_REC:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= pid;
			end
			DATA_SEND:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b1;
				rx_packet				= pid;
				rx_packet_data			= rcv_data;
			end
			TOKEN_DATA1:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
			end
			SEND_TOKEN1:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b1;
				store_rx_packet_data 	= 1'b0;
				rx_packet_data			= rcv_data;
			end
			TOKEN_DATA2:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
			end
			SEND_TOKEN2:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b0;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b1;
				store_rx_packet_data 	= 1'b0;
				rx_packet_data			= rcv_data;
			end	
			ERROR:
			begin
				rx_transfer_active	 	= 1'b1;
				rx_error				= 1'b1;
				flush					= 1'b0;
				rx_data_ready		 	= 1'b0;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= pid;
			end
			EOP:
			begin
				rx_transfer_active	 	= 1'b0;
				rx_error				= 1'b0;			// I have something else in the diagram, but I think this is correct?
				flush					= 1'b0;
				rx_data_ready		 	= 1'b1;
				store_rx_packet_data 	= 1'b0;
				rx_packet				= pid;
			end
		endcase
	end

endmodule