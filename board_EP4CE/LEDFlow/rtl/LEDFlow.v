module LEDFlow (
	input 		 clk,
	input 		 rst_n,
	output [3:0] led_o
);

reg [23:0] count;

always @ (posedge clk or negedge rst_n) begin
	if(~rst_n)
		count <= 24'd0;
	else if(count == 24'd10_000_000)
		count <= 24'd0;
	else
		count <= count + 24'd1;
end


reg [ 3:0] led_r;

always @ (posedge clk or negedge rst_n) begin
	if(~rst_n)
		led_r <= 4'b0001;
	else if(count == 24'd0)
		led_r <= {led_r[2:0], led_r[3]};
	else
		led_r <= led_r;
end

assign led_o = led_r;

endmodule
