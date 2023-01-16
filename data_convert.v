module data_convert(
		i_clk,
		i_start,
		i_data_in,
		o_byte0,
		o_byte1,
		o_byte2,
		o_byte3,
		o_byte4
	);
	
	input 				i_start;
	input					i_clk;
	input		[15:0]	i_data_in;
	output	[7:0]		o_byte0;
	output	[7:0]		o_byte1;
	output	[7:0]		o_byte2;
	output	[7:0]		o_byte3;
	output	[7:0]		o_byte4;
	
	parameter			p_NUM0 = 8'b0011_0000;		//0
	parameter			p_NUM1 = 8'b0011_0001;		//1
	parameter			p_NUM2 = 8'b0011_0010;		//2
	parameter			p_NUM3 = 8'b0011_0011;		//3
	parameter			p_NUM4 = 8'b0011_0100;
	parameter			p_NUM5 = 8'b0011_0101;
	parameter			p_NUM6 = 8'b0011_0110;
	parameter			p_NUM7 = 8'b0011_0111;
	parameter			p_NUM8 = 8'b0011_1000;
	parameter			p_NUM9 = 8'b0011_1001;
	parameter			p_ERROR = 8'b0011_1111;  	//? 
	
	reg		[7:0]		r_byte0 = 8'b0;
	reg		[7:0]		r_byte1 = 8'b0;
	reg		[7:0]		r_byte2 = 8'b0;
	reg		[7:0]		r_byte3 = 8'b0;
	reg		[7:0]		r_byte4 = 8'b0;
		
	wire 		[19:0]	w_bcd;
	
	bin2bcd U0(
		.i_start(i_start),
		.i_binary(i_data_in),
		.o_bcd(w_bcd)
	);
	
	assign o_byte0 = r_byte0;
	assign o_byte1 = r_byte1;
	assign o_byte2 = r_byte2;
	assign o_byte3 = r_byte3;
	assign o_byte4 = r_byte4;
	 
	always @(posedge i_clk)
		begin
			case(w_bcd[3:0])
				4'b0000:
					r_byte0 <= p_NUM0;
				4'b0001:
					r_byte0 <= p_NUM1;
				4'b0010:
					r_byte0 <= p_NUM2;
				4'b0011:
					r_byte0 <= p_NUM3;
				4'b0100:
					r_byte0 <= p_NUM4;
				4'b0101:
					r_byte0 <= p_NUM5;
				4'b0110:
					r_byte0 <= p_NUM6;
				4'b0111:
					r_byte0 <= p_NUM7;
				4'b1000:
					r_byte0 <= p_NUM8;
				4'b1001:
					r_byte0 <= p_NUM9;
				default:
					r_byte0 <= p_ERROR;
			endcase
			
			case(w_bcd[7:4])
				4'b0000:
					r_byte1 <= p_NUM0;
				4'b0001:
					r_byte1 <= p_NUM1;
				4'b0010:
					r_byte1 <= p_NUM2;
				4'b0011:
					r_byte1 <= p_NUM3;
				4'b0100:
					r_byte1 <= p_NUM4;
				4'b0101:
					r_byte1 <= p_NUM5;
				4'b0110:
					r_byte1 <= p_NUM6;
				4'b0111:
					r_byte1 <= p_NUM7;
				4'b1000:
					r_byte1 <= p_NUM8;
				4'b1001:
					r_byte1 <= p_NUM9;
				default:
					r_byte0 <= p_ERROR;
			endcase
			
			case(w_bcd[11:8])
				4'b0000:
					r_byte2 <= p_NUM0;
				4'b0001:
					r_byte2 <= p_NUM1;
				4'b0010:
					r_byte2 <= p_NUM2;
				4'b0011:
					r_byte2 <= p_NUM3;
				4'b0100:
					r_byte2 <= p_NUM4;
				4'b0101:
					r_byte2 <= p_NUM5;
				4'b0110:
					r_byte2 <= p_NUM6;
				4'b0111:
					r_byte2 <= p_NUM7;
				4'b1000:
					r_byte2 <= p_NUM8;
				4'b1001:
					r_byte2 <= p_NUM9;
				default:
					r_byte0 <= p_ERROR;
			endcase
			
			case(w_bcd[15:12])
				4'b0000:
					r_byte3 <= p_NUM0;
				4'b0001:
					r_byte3 <= p_NUM1;
				4'b0010:
					r_byte3 <= p_NUM2;
				4'b0011:
					r_byte3 <= p_NUM3;
				4'b0100:
					r_byte3 <= p_NUM4;
				4'b0101:
					r_byte3 <= p_NUM5;
				4'b0110:
					r_byte3 <= p_NUM6;
				4'b0111:
					r_byte3 <= p_NUM7;
				4'b1000:
					r_byte3 <= p_NUM8;
				4'b1001:
					r_byte3 <= p_NUM9;
				default:
					r_byte0 <= p_ERROR;
			endcase
			
			case(w_bcd[19:16])
				4'b0000:
					r_byte4 <= p_NUM0;
				4'b0001:
					r_byte4 <= p_NUM1;
				4'b0010:
					r_byte4 <= p_NUM2;
				4'b0011:
					r_byte4 <= p_NUM3;
				4'b0100:
					r_byte4 <= p_NUM4;
				4'b0101:
					r_byte4 <= p_NUM5;
				4'b0110:
					r_byte4 <= p_NUM6;
				4'b0111:
					r_byte4 <= p_NUM7;
				4'b1000:
					r_byte4 <= p_NUM8;
				4'b1001:
					r_byte4 <= p_NUM9;
				default:
					r_byte0 <= p_ERROR;
			endcase
		end
endmodule
