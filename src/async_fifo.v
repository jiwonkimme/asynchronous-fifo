module fifo #(
	parameter	DEPTH=8,
	parameter	WIDTH=16,
  	parameter	PADDR=$clog2(DEPTH)
)(
	input           	CLK_W,
	input           	CLK_R,
	input           	rstn,
	input           	write_en,
	input           	read_en,	
	input [WIDTH-1:0] 	din,
	output          	full,
	output          	empty,
	output [WIDTH-1:0] 	dout
);

//Wire and reg Setting
	parameter PTR_WIDTH = PADDR + 1;

	reg [PTR_WIDTH-1:0] wptr, rptr;
    wire [PTR_WIDTH-1:0] wptr_next, rptr_next;
    wire [PTR_WIDTH-1:0] wptr_gray, rptr_gray;
    wire full_flag, empty_flag;
    wire write_valid, read_valid;
    reg [PTR_WIDTH-1:0] rptr_gray_sync1, rptr_gray_final;
    reg [PTR_WIDTH-1:0] wptr_gray_sync1, wptr_gray_final;
//RAM FIFO Buffer 
	reg [WIDTH-1:0] ram [DEPTH-1:0];
	reg [WIDTH-1:0] rdata;

// CLK_W Domain
//RAM (WRITE) Write Based Setting
	always @(posedge CLK_W) begin
		if (write_valid) begin
			ram[wptr[PADDR-1:0]] <= din;
		end 
	end

// Write Pointer (binary) 
	always @(posedge CLK_W or negedge rstn) begin
		if (!rstn) begin
			wptr <= 0;
		end else if (write_valid) begin
			wptr <= wptr_next;
		end 
	end

// Binary -> Gray Code : gray_value = (counter >> 1) ^ counter;
	assign wptr_gray = (wptr >> 1) ^ wptr;
	assign wptr_next = wptr + 1;

// R -> W Synchronizer (2-FF) (pipeline)
	always @(posedge CLK_W or negedge rstn) begin
		if (!rstn) begin
			rptr_gray_sync1 <= 0;
			rptr_gray_final <= 0;
		end else begin
			rptr_gray_sync1 <= rptr_gray;
			rptr_gray_final <= rptr_gray_sync1;
		end
	end
// Full Calculation -> Synchronizer value(e.g. comparison between wptr <-> rptr_gray_final)
	assign full_flag = (wptr_gray[PADDR]     != rptr_gray_final[PADDR]) &&
                       (wptr_gray[PADDR-1] != rptr_gray_final[PADDR-1]) &&
                       (wptr_gray[PADDR-2:0] == rptr_gray_final[PADDR-2:0]);
	assign write_valid = write_en && !full_flag;
	assign full = full_flag;

// CLK_R Domain  
//RAM (READ) Read Based Setting
	always @(posedge CLK_R or negedge rstn) begin
		if (!rstn) begin
			rdata <= 0;
		end else if (read_valid) begin
			rdata <= ram[rptr_next[PADDR-1:0]];
		end else if (!empty_flag) begin
			rdata <= ram[rptr[PADDR-1:0]];
		end
	end

// Read Pointer (binary)  
	always @(posedge CLK_R or negedge rstn) begin
		if (!rstn) begin
			rptr <= 0;
		end else if (read_valid) begin
			rptr <= rptr_next;
		end 
	end  

// Binary -> Gray Code
	assign rptr_gray = (rptr >> 1) ^ rptr;
	assign rptr_next = rptr + 1;

// W -> R Synchronizer (2-FF)
	always @(posedge CLK_R or negedge rstn) begin
		if (!rstn) begin
			wptr_gray_sync1 <= 0;
			wptr_gray_final <= 0;
		end else begin
			wptr_gray_sync1 <= wptr_gray;
			wptr_gray_final <= wptr_gray_sync1;
		end
	end

// Empry Calculation
	assign empty_flag = (wptr_gray_final == rptr_gray);  
	assign read_valid = read_en && !empty_flag;
	assign empty = empty_flag;
	
// RAM Read Assignment
	assign dout = rdata;

endmodule