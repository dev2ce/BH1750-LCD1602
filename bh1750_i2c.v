module bh1750_i2c(
	i_clk,
	i_rst,
	io_sda,
	io_scl,
	o_data,
	o_tick_done,
);

	input 				i_clk;
	input					i_rst;
	inout 				io_sda;
	inout					io_scl;
	output	[15:0] 	o_data;
	output				o_tick_done;
	
	
	//STATE MACHINE
	parameter			s_power_down		= 0;
	parameter			s_power_on			= 1;
	parameter			s_reg_reset			= 2;
	parameter			s_command			= 3;
	parameter			s_measure			= 4;
	parameter			s_read_data			= 5;
	parameter			s_idle				= 6;
	
	// OPCODE
	parameter			p_POWER_DOWN		= 8'b0000_0000;
	parameter			p_POWER_ON			= 8'b0000_0001;
	parameter			p_RESET				= 8'b0000_0111;
	parameter			p_ONE_TIME_H		= 8'b0010_0000;
	
	// DELAY
	parameter			t_200ms		= 10000000;
	parameter			t_1s			= 50000000;
	
	// REGISTER
	reg	[2:0]			r_state				= s_power_down;
	reg	[31:0]		r_clk_count			= 0;
	reg	[7:0]			r_opcode				= p_POWER_DOWN;
	reg					r_RW					= 0;
	reg					r_start				= 0;
	reg					r_tick_done			= 0;
	
	wire					w_busy;
	wire					w_tick_done;
	wire	[15:0]		w_data;
	
	i2c U0(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_RW(r_RW),
		.i_start(r_start),
		.i_opcode(r_opcode),
		.io_sda(io_sda),
		.io_scl(io_scl),
		.o_data(w_data),
		.o_tick_done(w_tick_done),
		.o_busy(w_busy)
	);
	
	assign o_data = w_data;
	assign o_tick_done = r_tick_done;
		
	always @(posedge i_clk)
		begin
			if(i_rst == 0)
				begin
					r_state <= s_power_down;
					r_opcode <= p_POWER_DOWN;
					r_clk_count <= 0;
					r_tick_done <= 0;
				end
			else
				begin
					case(r_state)
						s_power_down:
							begin
								r_opcode <= p_POWER_DOWN;
								r_RW <= 0;
								if(w_busy == 0)
									r_start <= 1;
								else if(w_busy == 1)
									r_start <= 0;	
								
								if(w_tick_done == 1)
									r_state <= s_power_on;
								else
									r_state <= s_power_down;
							end
								
						s_power_on:
							begin
								r_opcode <= p_POWER_ON;
								r_RW <= 0;
								if(w_busy == 0)
									r_start <= 1;
								else if(w_busy == 1)
									r_start <= 0;	
								
								if(w_tick_done == 1)
									r_state <= s_reg_reset;
								else
									r_state <= s_power_on;
							end
							
						s_reg_reset:
							begin
								r_opcode <= p_RESET;
								r_RW <= 0;
								if(w_busy == 0)
									r_start <= 1;
								else if(w_busy == 1)
									r_start <= 0;	
								
								if(w_tick_done == 1)
									r_state <= s_command;
								else
									r_state <= s_reg_reset;
							end
							
						s_command:
							begin
								r_opcode <= p_ONE_TIME_H;
								r_RW <= 0;
								if(w_busy == 0)
									r_start <= 1;
								else if(w_busy == 1)
									r_start <= 0;	
								
								if(w_tick_done == 1)
									r_state <= s_measure;
								else
									r_state <= s_command;
							end
						
						s_measure:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == t_200ms - 1)
									begin
										r_state <= s_read_data;
										r_clk_count <= 0;
									end
								else
									r_state <= s_measure;
							end
							
						s_read_data:
							begin
								r_RW <= 1;
								if(w_busy == 0)
									r_start <= 1;
								else if(w_busy == 1)
									r_start <= 0;	
					
								if(w_tick_done == 1)
									begin
										r_state <= s_idle;
										r_tick_done <= 1;
									end
								else
									r_state <= s_read_data;
							end
							
						s_idle:
							begin
								r_clk_count <= r_clk_count + 1;
								r_start <= 0;
								if(r_clk_count == t_1s - 1)
									begin
										r_tick_done <= 0;
										r_state <= s_power_down;
										r_clk_count <= 0;
									end
								else
									r_state <= s_idle;
							end
							
					endcase
				end
		end
	
endmodule