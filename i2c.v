module i2c
	(	
		i_clk,
		i_rst,
		i_RW,
		i_start,
		i_opcode,
		io_sda,
		io_scl,
		o_data,
		o_tick_done,
		o_busy
	);
	
	
	// INPUT & OUTPUT
	input					i_clk;
	input					i_rst;
	input					i_RW;
	input					i_start;
	input		[7:0]		i_opcode;
	inout					io_sda;	
	inout					io_scl;	
	output	[15:0]	o_data;
	output				o_tick_done;
	output				o_busy;
		
	//STATES
	parameter			s_ready				= 0;
	parameter 			s_start 				= 1;
	parameter			s_address			= 2;
	parameter			s_slave_ack1		= 3;
	parameter			s_opcode				= 4;
	parameter			s_slave_ack2		= 5;
	parameter			s_master_ack		= 6;
	parameter			s_master_nack		= 7;
	parameter			s_read_h_byte		= 8;
	parameter			s_read_l_byte		= 9;
	parameter			s_stop				= 10;
	parameter			s_idle				= 11;
	
	//PARAMETER 
	parameter			p_devider			= 500;
	parameter			p_ADDRESS			= 7'b010_0011;
	parameter			p_WRITE				= 1'b0;
	parameter			p_READ				= 1'b1;

	
	//REGISTER
	reg	[3:0]			r_state				= s_idle;
	reg 	[8:0]			r_clk_count			= 0;
	reg					r_sda					= 1;
	reg					r_scl					= 1;
	reg					r_sda_en				= 1;
	reg					r_scl_en				= 1;
	reg					r_tick_done			= 0;
	reg 					r_RW					= 0;
	reg	[2:0]			r_bit_index			= 7;
	reg 	[7:0]			r_address_buf		= 0;
	reg	[7:0]			r_opcode_buf		= 0;
	reg	[15:0]		r_data_buf			= 0;
	reg					r_ack_flag			= 0;
	reg					r_start 				= 0;
	reg					r_busy 				= 0;
	
	assign io_sda = r_sda_en ? r_sda : 1'bz;			//EN = 1 => MASTER'S CONTROLING ; EN = 0 => SLAVE'S CONTROLING
	assign io_scl = r_scl_en ? r_scl : 1'bz;
	assign o_data = r_data_buf;
	assign o_tick_done = r_tick_done;
	assign o_busy = r_busy;
	
	always @(posedge i_clk)
		begin
			if(i_rst == 0)
				begin
					r_tick_done <= 0;
					r_clk_count	<= 0;
					r_address_buf <= 0;
					r_opcode_buf <= 0;
					r_data_buf <= 0;
					r_start <= 0;
					r_busy <= 0;
					r_state <= s_idle;
				end
			else
				begin
					case(r_state)
						
						s_ready:
							begin
								r_clk_count <= 0;
								r_tick_done <= 0;
								r_RW <= i_RW;
								r_scl	<= 1;
								r_sda <= 1;
								r_sda_en <= 1;
								r_scl_en <= 1;
								r_state <= s_start;
								r_busy <= 1;
								if(r_RW)
									r_address_buf <= {p_ADDRESS, p_READ};
								else
									begin
										r_address_buf <= {p_ADDRESS, p_WRITE};
										r_opcode_buf <= i_opcode;
									end
							end
							
						s_start:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == 0)
									r_sda <= 0;
								else if(r_clk_count == p_devider/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider/2 - 1)
									begin
										r_clk_count <= 0;
										r_state <= s_address;
									end
							end
							
						s_address:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == 0)
									r_sda <= r_address_buf[r_bit_index];
								else if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider*4/5 - 1)
									r_sda <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										r_clk_count <= 0;
										if(r_bit_index > 0)
											begin
												r_bit_index <= r_bit_index - 1;
												r_state <= s_address;
											end
										else
											begin
												r_bit_index <= 7;
												r_sda_en <= 0;
												r_state <= s_slave_ack1;
											end
									end
							end
							
						s_slave_ack1:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										if(r_ack_flag)
											begin
												r_ack_flag <= 0;
												r_clk_count <= 0;
												if(r_address_buf[0] == 0)
													begin
														r_state <= s_opcode;
														r_sda_en <= 1;
													end
												else
													begin
														r_state <= s_read_h_byte;
														r_sda_en <= 0;
													end
											end
										else
											begin
												r_clk_count <= p_devider*3/4;
												r_state <= s_slave_ack1;
											end
									end
								else if(r_clk_count > p_devider/4 - 1)
									begin
										if(io_sda == 0)
											r_ack_flag <= 1;
										else
											r_ack_flag <= r_ack_flag;
									end							
							end
							
						s_opcode:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == 0)
									r_sda <= r_opcode_buf[r_bit_index];
								else if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider*4/5 - 1)
									r_sda <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										r_clk_count <= 0;
										if(r_bit_index > 0)
											begin
												r_bit_index <= r_bit_index - 1;
												r_state <= s_opcode;
											end
										else
											begin
												r_bit_index <= 7;
												r_sda_en <= 0;
												r_state <= s_slave_ack2;
											end
									end
							end
							
						s_slave_ack2:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										if(r_ack_flag)
											begin
												r_ack_flag <= 0;
												r_clk_count <= 0;
												r_sda_en <= 1;
												r_state <= s_stop;
											end
										else
											begin
												r_clk_count <= p_devider*3/4;
												r_state <= s_slave_ack2;
											end
									end
								else if(r_clk_count > p_devider/4 - 1)
									begin
										if(io_sda == 0)
											r_ack_flag <= 1;
										else
											r_ack_flag <= r_ack_flag;
									end							
							end
							
						s_read_h_byte:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider/2 - 1)
									r_data_buf[r_bit_index + 8] <= io_sda;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										r_clk_count <= 0;
										if(r_bit_index > 0)
											begin
												r_bit_index <= r_bit_index - 1;
												r_state <= s_read_h_byte;
											end
										else
											begin
												r_bit_index <= 7;
												r_sda_en <= 1;
												r_state <= s_master_ack;
											end
									end
							end
							
						s_master_ack:
							begin	
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == 0)
									r_sda <= 0;
								else if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										r_clk_count <= 0;
										r_sda_en <= 0;
										r_state <= s_read_l_byte;
									end
							end
						
						s_read_l_byte:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider/2 - 1)
									r_data_buf[r_bit_index] <= io_sda;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										r_clk_count <= 0;
										if(r_bit_index > 0)
											begin
												r_bit_index <= r_bit_index - 1;
												r_state <= s_read_l_byte;
											end
										else
											begin
												r_bit_index <= 7;
												r_sda_en <= 1;
												r_state <= s_master_nack;
											end
									end
							end
							
						s_master_nack:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == 0)
									r_sda <= 1;
								else if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								else if(r_clk_count == p_devider*3/4 - 1)
									r_scl <= 0;
								else if(r_clk_count == p_devider - 1)
									begin
										r_clk_count <= 0;
										r_sda_en <= 1;
										r_state <= s_stop;
									end
							end
							
						s_stop:
							begin
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count == 0)
									r_sda <= 0;
								if(r_clk_count == p_devider/4 - 1)
									r_scl <= 1;
								if(r_clk_count == p_devider/2 - 1)
									begin
										r_sda <= 1;
										r_tick_done <= 1;
										r_clk_count <= 0;
										r_state <= s_idle;
									end
							end
							
						s_idle:
							begin
								r_tick_done <= 0;
								r_busy <= 0;
								r_start <= i_start;
								r_clk_count <= r_clk_count + 1;
								if(r_clk_count < p_devider - 1)
									r_state <= s_idle;
								else
									begin
										if(r_start)
											r_state <= s_ready;
										else
											r_state <= s_idle;
									end	
							end
					endcase
				end
		end
endmodule