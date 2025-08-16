`timescale 1ns / 1ps

module UART_Receiver(
clk, 
bclk, 
resetn, 
rxd, 
read_en, 
rx_en, 
parity_en,
parity_type,
rx_thr_val,
data_out, 
rx_bclk_en,
rx_fre,
rx_pe,
rx_ov,
rx_thr

    ); 
//Input
input clk;
input resetn;
input bclk;
input rxd;
input read_en;
input rx_en;
input parity_en;
input parity_type;
input [1:0] rx_thr_val;
//Output
output [9:0] data_out;
output wire rx_bclk_en;
output wire rx_fre;
output wire rx_pe;
output wire rx_ov;
output wire rx_thr;


//Set up UART_RX

parameter IDLE_STATE  = 2'b00;
parameter START_STATE = 2'b01;
parameter DATA_STATE  = 2'b10;
parameter STOP_STATE  = 2'b11;

reg [1:0] state;
reg [4:0] counter;
reg [3:0] index;
reg [1:0] state_next;
reg [4:0] counter_next;
reg [3:0] index_next;


reg rx_ov_reg;
reg rx_done;
reg [9:0] data_temp;
reg write_en;
reg [3:0] LENGTHDATA;

parameter FIFOLENGHT = 16;
parameter FIFOWIDTH = 9;

reg [4:0] write_pt;
reg [4:0] read_pt;
reg [4:0] length;
reg [FIFOWIDTH : 0] fifo_mem [15:0];
reg [FIFOWIDTH:0] rdata;	


wire check_parity;
wire data_pe;
wire data_fre;

//Set lenghtdata
always@(posedge clk or negedge resetn) begin
	if(~resetn)
		LENGTHDATA = 4'd7;
	else
		if(parity_en)
			LENGTHDATA = 4'd8;
		else
			LENGTHDATA = 4'd7;
end


//FIFO emty
assign fifo_empty = (write_pt == read_pt)? 1: 0;

//FIFO full	
assign fifo_full = ({~write_pt[4], write_pt[3:0]} == read_pt[4:0])? 1:0;


		
	
//Reset signal
always@(posedge clk or negedge resetn) 
	begin
	if(~resetn) 
		begin
		write_pt <= 0;
		read_pt <= 0;
		length <= 0;
		rdata <= 10'd0;
		end
	else if(write_en == 1) 
			begin
			fifo_mem[write_pt] <= {data_pe, data_fre, data_temp[7:0]};
			write_pt <= write_pt + 1;
			length <= length + 1;
			end
	else if(read_en == 1) 
			begin
			rdata <= fifo_mem[read_pt];
			read_pt <= read_pt + 1;
			length <= length - 1;
			end
	end

assign data_out[7:0]  = rdata[7:0];
assign rx_fre = rdata[8];
assign rx_pe = rdata[9];
	
//Set threshold 
reg threshold;
always@(posedge clk or negedge resetn) begin
		case(rx_thr_val)
		00: threshold <= (length >= 16);
		01: threshold <= (length >= 8);
		10: threshold <= (length >= 4);
		11: threshold <= (length >= 2);
		default: threshold  <= (length >= 2);
		endcase
end
assign rx_thr = threshold;

reg [1:0] fifo_state;
parameter IDLE = 2'b00;
parameter WAITING = 2'b01;
always@(posedge clk or negedge resetn) begin
	if(~resetn) begin
		fifo_state <= IDLE;
		rx_ov_reg <= 0;
		end
	else
		case (fifo_state)
			IDLE: begin
				rx_ov_reg <= 0;
				write_en <= 0;
				if(rx_en & state != IDLE)
					fifo_state <= WAITING;
				end
			WAITING: begin
				write_en <= 0;
				if(state == IDLE) begin
					if(~fifo_full)
						write_en <= 1;
					else
						rx_ov_reg <= 1;
					fifo_state <= IDLE;
					end
				end
			default: fifo_state <= IDLE;
		endcase
	end
assign rx_ov = rx_ov_reg;

//Set state for FSM
always@(posedge clk or negedge resetn) begin
	if(resetn == 0) begin
		state <= IDLE_STATE;
		counter <= 0;
		index <= 0;
		end
	else begin
		state <= state_next;
		counter <= counter_next;
		index <= index_next;
		end
	end
	
//FSM	
always@(*) begin		
	rx_done = 0;
	counter_next = counter;
	index_next = index;
	state_next = state;
	case(state)
		IDLE_STATE:  
			if(~rxd & rx_en) begin
				state_next = START_STATE;
				counter_next = 0;
				index_next = 0;
				end
			else 
				state_next = IDLE_STATE;
		START_STATE: begin
			if(bclk) begin
				if(counter == 8) begin
					if(rxd) 
					 state_next = IDLE_STATE;
					else begin
						counter_next =0;
						state_next = DATA_STATE;
						end
					end
				else begin
					counter_next = counter_next + 4'b1;
					state_next = START_STATE;
					end
				end
			else
				state_next = START_STATE;
			end

		DATA_STATE: begin
			if(bclk == 1) begin
				if(counter == 15) begin
					counter_next = 0;
					data_temp[index] = rxd;
					if(index == LENGTHDATA) begin
						state_next = STOP_STATE;
						index_next  = index_next + 4'b1;
						counter_next = 0;
						end
					else 
						index_next  = index_next + 4'b1;
					end
				else
					counter_next = counter_next + 4'b1;
				end
			else
				state_next = DATA_STATE;
			end
		STOP_STATE: 
			if(bclk == 1) begin
				if(counter == 15) begin
						data_temp[index] = rxd;
						if(rxd)
							state_next = IDLE_STATE;
						else
							counter_next = counter_next + 4'b1;
					end
				else if(counter == 23) 
					state_next = IDLE_STATE;
				else begin
					counter_next = counter_next + 4'b1;
					end
				end
			else 
				state_next = STOP_STATE;
		default: state_next = IDLE_STATE;
	endcase
end
//Set busy rx signal
assign rx_busy = (state == IDLE_STATE)? 0 : 1;	
assign rx_bclk_en = rx_busy;
//Calculate parity
assign check_parity = (parity_type ==1) ?  ~(^data_temp[7:0]) : (^data_temp[7:0]);
//Set parity error
assign data_pe = (parity_en & ~rx_busy)? ~(check_parity == data_temp[8]) : 0;

//Set frame error
assign data_fre = parity_en ? (~data_temp[9]) : (~data_temp[8]);
		
		
		

endmodule
