module lcd16x2
	(
		i_clk,
		i_rst,
		i_byte0,
		i_byte1,
		i_byte2,
		i_byte3,
		i_byte4,
		i_tick,
		o_lcd_rs,
		o_lcd_en,
		o_lcd_data_bus
	);
	
	// INPUT & OUTPUT DECLARATION
	input						i_clk;
	input 					i_rst;
	input						i_tick;
	input			[7:0]		i_byte0;
	input			[7:0]		i_byte1;
	input			[7:0]		i_byte2;
	input			[7:0]		i_byte3;
	input			[7:0]		i_byte4;
	output 					o_lcd_rs;
	output 					o_lcd_en;
	output 		[7:0] 	o_lcd_data_bus;
	
	
	// DEFINE STATE MACHINE'S STATES //
	parameter 				s_power_on 						= 0;
	parameter				s_function_set_1				= 1;
	parameter				s_function_set_2				= 2;
	parameter				s_function_set_3				= 3;
	parameter				s_function_set_4				= 4;
	parameter				s_display_off					= 5;
	parameter				s_display_clear_1				= 6;
	parameter				s_entry_mode_set				= 7;
	parameter				s_display_on					= 8;
	parameter				s_display_clear_2				= 9;
	parameter				s_address_set					= 10;
	parameter				s_write_data_line_1			= 11;
	parameter				s_write_data_line_2			= 12;
	parameter				s_idle							= 13;
	
	// DEFINE TIMING CONSTANTS
	// CLOCK FREQUENCY = 50MHZ => CLOCK PERIOD = 20NS
	parameter				p_delay_2us						= 100;
	parameter				p_delay_60us					= 3000;
	parameter				p_delay_200us					= 10000;
	parameter				p_delay_5ms						= 250000;
	parameter				p_delay_2ms						= 100000;
	parameter				p_delay_1s						= 50000000;
	
	// DEFINE INITIAL INSTRUCTIONS
	parameter 				p_init							= 8'b00110000;		// send 3 times for initilization
	parameter				p_function_set					= 8'b00111000; 	// 8 bits, 2 lines, 5x7 dots
	parameter				p_display_off					= 8'b00001000;		// turn off display
	parameter				p_display_on					= 8'b00001111;		// turn on display
	parameter				p_clear							= 8'b00000001;		// clear display
	parameter				p_entry							= 8'b00000110;		// normal entry, cursor increments, no shift
	parameter				p_address_line_1				= 8'b10000000;		// first cursor, line 1, address = 8h80
	
	// DEFINE SOME CHARACTERS
	parameter				p_H 								= 8'b01001000;
	
	
	// REGISTER, CLK COUNT, ETC
	integer 					r_clk_count						= 0;
	reg				[3:0]	r_state							= 0;
	reg 				[7:0] r_data_bus						= 0;
	reg						r_lcd_en							= 0;
	reg						r_lcd_rs							= 0;
	reg				[3:0]	r_pointer						= 0;
	reg 				[7:0]	r_buffer_line_1	[0:15]		;  				// LIGHT_INTENSITY_
	reg 				[7:0]	r_buffer_line_2	[0:15]		;					// DO_AM:_
	
	always @(posedge i_clk) 
		begin
			r_buffer_line_1[0] <= 8'b0100_1100;			// 'L'
			r_buffer_line_1[1] <= 8'b0100_1001;			// 'I'
			r_buffer_line_1[2] <= 8'b0100_0111;			// 'G'
			r_buffer_line_1[3] <= 8'b0100_1000;			// 'H'
			r_buffer_line_1[4] <= 8'b0101_0100;			// 'T'
			r_buffer_line_1[5] <= 8'b0010_0000;			// '_'
			r_buffer_line_1[6] <= 8'b0100_1001;			// 'I'
			r_buffer_line_1[7] <= 8'b0100_1110;			// 'N'
			r_buffer_line_1[8] <= 8'b0101_0100;			// 'T'
			r_buffer_line_1[9] <= 8'b0100_0101;			// 'E'
			r_buffer_line_1[10] <= 8'b0100_1110;		// 'N'
			r_buffer_line_1[11] <= 8'b0101_0011;		// 'S'
			r_buffer_line_1[12] <= 8'b0100_1001;		// 'I'
			r_buffer_line_1[13] <= 8'b0101_0100;		// 'T'
			r_buffer_line_1[14] <= 8'b0101_1001;		// 'Y'
			r_buffer_line_1[15] <= 8'b0010_0000;		// '_'
			
			r_buffer_line_2[0] <= i_byte4;				// byte4
			r_buffer_line_2[1] <= i_byte3;				// byte3
			r_buffer_line_2[2] <= i_byte2;				// byte2
			r_buffer_line_2[3] <= i_byte1;				// byte1
			r_buffer_line_2[4] <= i_byte0;				// byte0
			r_buffer_line_2[5] <= 8'b0010_0000;			// '_'
			r_buffer_line_2[6] <= 8'b0110_1100;			// 'l'
			r_buffer_line_2[7] <= 8'b0111_1000;			// 'x'
			r_buffer_line_2[8] <= 8'b0010_0000;			// '_'
			r_buffer_line_2[9] <= 8'b0010_0000;			// '_'
			r_buffer_line_2[10] <= 8'b0010_0000;		// '_'
			r_buffer_line_2[11] <= 8'b0010_0000;		// '_'
			r_buffer_line_2[12] <= 8'b0010_0000;		// '_'
			r_buffer_line_2[13] <= 8'b0010_0000;		// '_'
			r_buffer_line_2[14] <= 8'b0010_0000;		// '_'
			r_buffer_line_2[15] <= 8'b0010_0000;		// '_'
		end
		
	always @(posedge i_clk or negedge i_rst)
		begin
			if(i_rst == 0)
				begin
					r_lcd_en <= 0;
					r_lcd_rs <= 0;
					r_data_bus <= 8'b0;
					r_clk_count <= 0;
					r_state <= s_power_on;
				end
			else 
				begin
					case(r_state)
						
						// POWER ON: WAIT FOR 20MS
						// START INITIALIZING LCD
						s_power_on: 
							begin
								r_lcd_rs <= 0;
								r_lcd_en <= 0;
								r_data_bus <= 8'b0;
								if(r_clk_count < p_delay_1s)
									begin
										r_clk_count <= r_clk_count + 1;
										r_state <= s_power_on;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_function_set_1;
									end
							end
						
						// FUNCTION SET 1ST TIME, WAIT AT LEAST 4.1MS, 8 BITS 2 LINES MODE
						s_function_set_1:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_init;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_1;
									end
								else if (r_clk_count < p_delay_5ms)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_1;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_function_set_2;
									end
							end
						
						// FUNCTION SET 2ND TIME, WAIT AT LEAST 100US
						s_function_set_2:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_init;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_2;
									end
								else if (r_clk_count < p_delay_200us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_2;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_function_set_3;
									end
							end
						
						// FUNCTION SET 3RD TIME
						s_function_set_3:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_init;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_3;
									end
								else if (r_clk_count < p_delay_200us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_3;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_function_set_4;
									end
							end
						
						//FUNCTION SET LAST TIME
						s_function_set_4:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_function_set;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_4;
									end
								else if (r_clk_count < p_delay_200us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_function_set_4;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_display_off;
									end
							end
						
						// TURN OFF ALL DISPLAY, EXCUTION TIME = 37US
						s_display_off:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_display_off;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_off;
									end
								else if (r_clk_count < p_delay_60us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_off;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_display_clear_1;
									end
							end
						
						// CLEAR DISPLAY, EXECUTION TIME = 1.52MS
						s_display_clear_1:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_clear;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_clear_1;
									end
								else if (r_clk_count < p_delay_2ms)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_clear_1;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_entry_mode_set;
									end
							end
						
						// ENTRY MODE NORMAL, EXCUTION TIME = 37US
						s_entry_mode_set:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_entry;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_entry_mode_set;
									end
								else if (r_clk_count < p_delay_60us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_entry_mode_set;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_display_on;
									end
							end
						
						// END OF INITIALIZATION
						// DISPLAY ON, EXECUTION TIME = 37US 
						s_display_on:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_display_on;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_on;
									end
								else if (r_clk_count < p_delay_60us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_on;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_display_clear_2;
									end
							end
						
						// CLEAR DISPLAY, READY TO DISPLAY, EXECUTION TIME = 1.52MS
						s_display_clear_2:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= p_clear;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_clear_2;
									end
								else if (r_clk_count < p_delay_2ms)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_display_clear_2;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_write_data_line_1;
									end
							end
						
						//	WRITE 16 H CHARACTERS
						s_write_data_line_1:
							begin
								r_lcd_rs <= 1;
								r_data_bus <= r_buffer_line_1[r_pointer];
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_write_data_line_1;
									end
								else if (r_clk_count < p_delay_60us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_write_data_line_1;
									end
								else
									begin
										r_clk_count <= 0;
										if(r_pointer < 15)
											begin
												r_pointer <= r_pointer + 1;
												r_state <= s_write_data_line_1;
											end
										else
											begin
												r_pointer <= 0;
												r_state <= s_address_set;
											end											
									end
							end
						
						s_address_set:
							begin
								r_lcd_rs <= 0;
								r_data_bus <= 8'b1100_0000;
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_address_set;
									end
								else if (r_clk_count < p_delay_2ms)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_address_set;
									end
								else
									begin
										r_clk_count <= 0;
										r_state <= s_write_data_line_2;
									end
							end
							
						s_write_data_line_2:
							begin
								r_lcd_rs <= 1;
								r_data_bus <= r_buffer_line_2[r_pointer];
								if(r_clk_count < p_delay_2us)
									begin
										r_lcd_en <= 1;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_write_data_line_2;
									end
								else if (r_clk_count < p_delay_60us)
									begin
										r_lcd_en <= 0;
										r_clk_count <= r_clk_count + 1;
										r_state <= s_write_data_line_2;
									end
								else
									begin
										r_clk_count <= 0;
										if(r_pointer < 15)
											begin
												r_pointer <= r_pointer + 1;
												r_state <= s_write_data_line_2;
											end
										else
											begin
												r_state <= s_idle;
												r_pointer <= 0;
											end
									end
							end
						// STAY HERE
						s_idle:
							begin
								if(i_tick == 1)
									r_state <= s_address_set;
								else
									r_state <= s_idle;
							end
					endcase	
				end
		end
	
	assign o_lcd_data_bus = r_data_bus;
	assign o_lcd_en = r_lcd_en;
	assign o_lcd_rs = r_lcd_rs;
endmodule