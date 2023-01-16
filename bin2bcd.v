module bin2bcd
(	
	i_start,
	i_binary,
	o_bcd,
);

input					i_start;
input 	[15:0] 	i_binary;
output 	[19:0] 	o_bcd;

reg 		[19:0] 	r_bcd = 20'b0;

integer i;

// double-dabble algorithm
always @(posedge i_start)
	begin
		r_bcd = 20'b0;
		for(i = 0; i < 16; i = i+1)
		begin
			r_bcd = {r_bcd[18:0], i_binary[15-i]};
			if(i < 15 && r_bcd[3:0] > 4)
				r_bcd[3:0] = r_bcd[3:0] + 3;
			if(i < 15 && r_bcd[7:4] > 4)
				r_bcd[7:4] = r_bcd[7:4] + 3;
			if(i < 15 && r_bcd[11:8] > 4)
				r_bcd[11:8] = r_bcd[11:8] + 3;	
			if(i < 15 && r_bcd[15:12] > 4)
				r_bcd[15:12] = r_bcd[15:12] + 3;
			if(i < 15 && r_bcd[19:16] > 4)
				r_bcd[19:16] = r_bcd[19:16] + 3;
		end
	end

assign o_bcd = r_bcd;

endmodule