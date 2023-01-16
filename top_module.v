module top_module(
	i_clk,
	i_rst,
	io_sda,
	io_scl,
	o_lcd_rs,
	o_lcd_en,
	o_lcd_data_bus
	);
	
	input 			i_clk;
	input				i_rst;
	inout				io_sda;
	inout				io_scl;
	output			o_lcd_rs;
	output			o_lcd_en;
	output 	[7:0]	o_lcd_data_bus;

	bh1750_i2c U0(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.io_sda(io_sda),
		.io_scl(io_scl),
		.o_data(w_bh1750_data),
		.o_tick_done(w_bh1750_tick_done),
	);
	
	data_convert U1(
		.i_clk(i_clk),
		.i_start(w_bh1750_tick_done),
		.i_data_in(w_bh1750_data),
		.o_byte0(w_byte0),
		.o_byte1(w_byte1),
		.o_byte2(w_byte2),
		.o_byte3(w_byte3),
		.o_byte4(w_byte4)
	);
	
	lcd16x2 U2(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_byte0(w_byte0),
		.i_byte1(w_byte1),
		.i_byte2(w_byte2),
		.i_byte3(w_byte3),
		.i_byte4(w_byte4),
		.i_tick(w_bh1750_tick_done),
		.o_lcd_rs(o_lcd_rs),
		.o_lcd_en(o_lcd_en),
		.o_lcd_data_bus(o_lcd_data_bus)
	);
	
	wire 	[15:0]		w_bh1750_data;
	wire 					w_bh1750_tick_done;
	wire	[7:0]			w_byte0;
	wire	[7:0]			w_byte1;
	wire	[7:0]			w_byte2;
	wire	[7:0]			w_byte3;
	wire	[7:0]			w_byte4;
endmodule