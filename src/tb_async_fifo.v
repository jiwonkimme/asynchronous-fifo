module tb;
	
	reg        	CLK_W, CLK_R;
	reg			rstn;
	
	reg        	write_en, read_en;
	reg [15:0] 	din;	

	wire       	full, empty;
	wire [15:0] dout;	
	
	integer i,j;
	
	initial begin
		CLK_W	= 0;
		forever #4 CLK_W = ~CLK_W;
	end
	
	initial begin
		CLK_R	= 0;		
		forever #5 CLK_R = ~CLK_R;
	end
	
	fifo #(
		.DEPTH(8), .WIDTH(16)
	) ufifo (
		.CLK_W(CLK_W),			.CLK_R(CLK_R),		.rstn(rstn),
		.write_en(write_en),	.read_en(read_en),	.din(din),			
		.full(full),			.empty(empty),		.dout(dout)
  	);
	
	initial begin
		
	end

	initial begin
		rstn = 1;
		write_en <= 0;
		#10 rstn = 0;
		#20 rstn = 1;
		for (i=0; i<15; i=i+1) begin
			write_en <= 1;
			din  <= i*2;
			@(posedge CLK_W);
		end
		write_en <= 0;
		@(posedge CLK_W);
		@(posedge CLK_W);
		@(posedge CLK_W);
	end
	
	initial begin
		read_en <= 0;
		#120
		for (j=0; j<10; j=j+1) begin
			read_en <= 1;
			@(posedge CLK_R);
			read_en <= 0;
			@(posedge CLK_R);
		end
		read_en <= 0;		
		#50
		$finish;
	end

	
endmodule