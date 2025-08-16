`timescale 1ns / 1ps

module UART_Transmitter(
//Input from system
clk, 
resetn, 
//Input from baudrate generator
bclk, 
//Input from APB interface
datain, 
parity_en, 
parity_type,
write_en, 
tx_en, 
tx_thr_val,
//Output
txd, 
tx_bclk_en,
tx_thr
    );
//Input
input clk;
input bclk;
input resetn;
input [7:0] datain;
input wire parity_en;
input wire parity_type;
input wire write_en;
input wire tx_en;
input wire [1:0] tx_thr_val;

//Ouput
output wire txd;
output tx_bclk_en;
output wire tx_thr;

//Parameter

parameter FIFOLENGHT = 16;
parameter FIFOWIDTH = 7;
parameter IDLE = 2'b00;
parameter LOADING = 2'b01;
parameter START_TX = 2'b10 ;
parameter WAIT_TX = 2'b11 ;

//Set up reg and signal for uart
reg txd_reg;
reg [1:0] state;
reg [4:0] counter;
reg [3:0] index;
reg [1:0] state_next;
reg [4:0] counter_next;
reg [3:0] index_next;
reg [3:0] datalenght;
reg [8:0] data_temp;
wire start_tx;

//BCLKs per bit
parameter bclk_length = 16;

//Setup fifo_tx

reg [4:0] write_pt;
reg [4:0] read_pt;
reg [4:0] length;
reg [FIFOWIDTH : 0] fifo_mem [15:0];
reg [FIFOWIDTH:0] rdata;
wire read_en;
reg [1:0] fifo_state;

//FIFO emty
assign fifo_empty = (write_pt[4:0] == read_pt[4:0])? 1: 0;

//FIFO full	
assign fifo_full = ({~write_pt[4], write_pt[3:0]} == read_pt[4:0])? 1:0;


//Reset, write and read
always@(posedge clk or negedge resetn) 
	begin
	if(~resetn) 
		begin
		write_pt <= 0;
		read_pt <= 0;
		length <= 0;
		end
	else if(write_en == 1 & fifo_full == 0 & tx_en) 
			begin
			fifo_mem[write_pt] <= datain;
			write_pt <= write_pt + 1;
			length <= length + 1;
			end
	else if(read_en == 1 & fifo_empty == 0) 
			begin
			rdata <= fifo_mem[read_pt];
			read_pt <= read_pt + 1;
			length <= length - 1;
			end
	end
	
//Setting threshold
reg threshold;
always@(*) begin
	case (tx_thr_val)
		00: threshold = (length < 16);
		01: threshold = (length < 14);
		10: threshold = (length < 12);
		11: threshold = (length < 8);
		default: threshold = (length <= 8);
	endcase
end

assign tx_thr = threshold;
	
//Loading or wait fifo
always@(posedge clk or negedge resetn) begin	
	if(~resetn) 
		fifo_state  <= IDLE;
	else 
		case(fifo_state) 
			IDLE: begin
				if(tx_en & ~fifo_empty)
					fifo_state <= LOADING;
				end
			LOADING: begin
				if(tx_en) 
					fifo_state <= START_TX;
					end
			START_TX: begin
				if(state == DATA_STATE)
					fifo_state <= WAIT_TX;
				end
			WAIT_TX: begin
				if(state == IDLE_STATE)
					fifo_state <= IDLE;
			end
			default: fifo_state <= IDLE;
		endcase
	end
assign read_en = (fifo_state == LOADING)? 1 : 0;
assign start_tx = (fifo_state == START_TX)?1:0;

//Setup uart_tx
parameter IDLE_STATE  = 2'b00;
parameter START_STATE = 2'b01;
parameter DATA_STATE  = 2'b10;
parameter STOP_STATE  = 2'b11;

reg tx_done;

always@(posedge clk or negedge resetn) begin
	if(~resetn) begin
		state <=  IDLE_STATE;
		counter <= 0;
		index <= 0;
		datalenght <= 7;
		data_temp <= 9'bxxxxxxxxx;
		end
	else begin
		state <= state_next;
		counter <= counter_next;
		index <= index_next;
		data_temp[7:0] <= rdata;
		if(parity_en) begin
			datalenght <= 8;
			if(parity_type)
				data_temp[8] <= ~(^data_temp[7:0]);
			else 
				data_temp[8] <= (^data_temp[7:0]);
			end
		else begin
			datalenght <= 7;
			data_temp[8] <= 0;
			end
		end
	end

always@(*) begin
	state_next = state;
	counter_next = counter;
	index_next = index;
	tx_done = 0;
	case (state)
		IDLE_STATE: begin
			tx_done = 1;
			txd_reg = 1;
			if(start_tx) begin
				state_next = START_STATE;
				counter_next = 0;
				end

			end
		START_STATE: begin
			if(bclk)
				if(counter == bclk_length) begin
					state_next = DATA_STATE;
					counter_next = 0;
					end
				else begin
					counter_next = counter_next + 5'b1;
					txd_reg = 0;
					end

			end
		DATA_STATE: begin
			txd_reg = data_temp[index];
			if(bclk) begin	
				if(counter == bclk_length - 1) begin
					counter_next = 0;
					if(index == datalenght) 
						state_next = STOP_STATE;
					else begin
						index_next = index_next + 4'b1;
						state_next = DATA_STATE;
						end
					end
				else
					counter_next = counter_next + 5'b1;
				end

			end
		STOP_STATE: begin
			txd_reg = 1;
			if(bclk) begin
				if(counter == bclk_length - 1) begin
					counter_next = 0;
					index_next = 0;
					state_next = IDLE_STATE;
					txd_reg = 1;			
					end
				else
					counter_next = counter_next + 5'b1;
				end

			end
		default: state_next = IDLE_STATE;
	endcase
	end

assign tx_busy = (state == IDLE)? 0:1;
assign txd = txd_reg;
assign tx_bclk_en = tx_busy;

endmodule
