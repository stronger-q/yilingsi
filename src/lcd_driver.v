/*-----------------------------------------------------------------------
								 \\\|///
							   \\  - -  //
								(  @ @  )
+-----------------------------oOOo-(_)-oOOo-----------------------------+
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo (Thereturnofbingo).
In the event of publication, the following notice is applicable:
Copyright (C) 2013-20xx CrazyBingo Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		CrazyBingo
Technology blogs 	: 		www.crazyfpga.com
Email Address 		: 		crazyfpga@vip.qq.com
Filename			:		lcd_driver.v
Date				:		2012-02-18
Description			:		LCD/VGA driver.
Modification History	:
Date			By			Version			Change Description
=========================================================================
12/02/18		CrazyBingo	1.0				Original
12/03/19		CrazyBingo	1.1				Modification
12/03/21		CrazyBingo	1.2				Modification
12/05/13		CrazyBingo	1.3				Modification
13/11/07		CrazyBingo	2.1				Modification
17/04/02		CrazyBingo	3.0				Modify for 12bit width logic
-------------------------------------------------------------------------
|                                     Oooo							|
+------------------------------oooO--(   )-----------------------------+
                              (   )   ) /
                               \ (   (_/
                                \_)
----------------------------------------------------------------------*/   

`timescale 1ns/1ps

`include "lcd_para.v"

module lcd_driver #(
	//	Setting up default timing
	parameter 	H_FRONT	= `H_FRONT,
			H_SYNC 	= `H_SYNC,
			H_BACK 	= `H_BACK,
			H_DISP	= `H_DISP,
			H_TOTAL	= `H_TOTAL,
						
			V_FRONT	= `V_FRONT,
			V_SYNC 	= `V_SYNC,
			V_BACK 	= `V_BACK,
			V_DISP 	= `V_DISP,
			V_TOTAL	= `V_TOTAL,
			
			DATA_WIDTH 	= 48
)(  	
	//global clock
	input					clk,			//system clock
	input					rst_n,     		//sync reset
	
	//lcd interface
	output				lcd_dclk,   	//lcd pixel clock
	output				lcd_blank,		//lcd blank
	output				lcd_sync,		//lcd sync
	output reg			lcd_hs,	    	//lcd horizontal sync
	output reg			lcd_vs,	    	//lcd vertical sync
	output reg			lcd_en,			//lcd display enable
	output	[DATA_WIDTH-1:0]	lcd_rgb,		//lcd display data

	//user interface
	output reg			lcd_request,	//lcd data request
	output reg	[11:0]	lcd_xpos,		//lcd horizontal coordinate
	output reg	[11:0]	lcd_ypos,		//lcd vertical coordinate
	input 	[DATA_WIDTH-1:0]	lcd_data,		//lcd data

	// dynamic placement configuration
	input	[11:0]		cfg_active_width,
	input	[11:0]		cfg_active_height,
	input	[11:0]		cfg_fill_h_range,
	input	[11:0]		cfg_fill_v_range
);	 

/*******************************************
		SYNC--BACK--DISP--FRONT
*******************************************/
//------------------------------------------
//h_sync counter & generator
reg [13:0] hcnt; 
always @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)
		hcnt <= 12'd0;
	else
		begin
        if(hcnt < H_TOTAL - 1'b1)		//line over			
            hcnt <= hcnt + 1'b1;
        else
            hcnt <= 12'd0;
        
        lcd_hs <= (hcnt <= H_SYNC - 1'b1) ? 1'b0 : 1'b1;
		end
end 


//------------------------------------------
//v_sync counter & generator
reg [11:0] vcnt;
always@(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		vcnt <= 12'b0;
	else if(hcnt == H_TOTAL - 1'b1)		//line over
		begin
		if(vcnt < V_TOTAL - 1'b1)		//frame over
			vcnt <= vcnt + 1'b1;
		else
			vcnt <= 12'd0;
            
        lcd_vs <= (vcnt <= V_SYNC - 1'b1) ? 1'b0 : 1'b1;
		end
end


//------------------------------------------
//LCELL	LCELL(.in(clk),.out(lcd_dclk));
assign	lcd_dclk = ~clk;
assign	lcd_blank = lcd_hs & lcd_vs;		
assign	lcd_sync = 1'b0;


//-----------------------------------------
reg     [DATA_WIDTH-1:0]  r_lcd_rgb = 0; 
always@(posedge clk) begin
	lcd_en		<=	(hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISP) &&
						(vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISP) 
						? 1'b1 : 1'b0;
   // r_lcd_rgb 	<= 	lcd_data;
	if (lcd_request) begin
			r_lcd_rgb 	<= 	lcd_data;
	end
		else begin
			r_lcd_rgb <= 0;
		end
end 
assign lcd_rgb = lcd_en ? r_lcd_rgb : 0; 

//------------------------------------------
//ahead x clock
localparam	H_AHEAD = 	12'd1; 		//	Set to 1T ahead. Data shall be put into ISP module directly. 

// //	Standard FIFO Request Port
//  always@(posedge clk) begin
// 	lcd_request	<=	(hcnt >= H_SYNC + H_BACK - H_AHEAD && hcnt < H_SYNC + H_BACK + H_DISP - H_AHEAD) &&
// 						 (vcnt >= V_SYNC + V_BACK && vcnt < V_SYNC + V_BACK + V_DISP) 
// 						 ? 1'b1 : 1'b0;

                         
// // lcd xpos & ypos
// 	lcd_xpos	<= 	lcd_request ? (hcnt - (H_SYNC + H_BACK - H_AHEAD)) : 11'd0;
// 	lcd_ypos	<= 	lcd_request ? (vcnt - (V_SYNC + V_BACK)) : 12'd0;
// end
//	Standard FIFO Request Port
wire [11:0] w_active_width  = (cfg_active_width  == 12'd0) ? 12'd1 : cfg_active_width;
wire [11:0] w_active_height = (cfg_active_height == 12'd0) ? 12'd1 : cfg_active_height;
wire [11:0] w_fill_h_range  = cfg_fill_h_range;
wire [11:0] w_fill_v_range  = cfg_fill_v_range;

wire [11:0] w_h_base = (H_SYNC + H_BACK > H_AHEAD) ? (H_SYNC + H_BACK - H_AHEAD) : 12'd0;
wire [11:0] w_v_base = V_SYNC + V_BACK;
wire [11:0] w_h_start = w_h_base + w_fill_h_range;
wire [11:0] w_h_end   = w_h_start + w_active_width;
wire [11:0] w_v_start = w_v_base + w_fill_v_range;
wire [11:0] w_v_end   = w_v_start + w_active_height;

 always@(posedge clk) begin
	lcd_request	<=	(hcnt >= w_h_start && hcnt < w_h_end) &&
						 (vcnt >= w_v_start && vcnt < w_v_end) 
						 ? 1'b1 : 1'b0;

                         
// lcd xpos & ypos
	lcd_xpos	<= 	lcd_request ? (hcnt - w_h_start) : 11'd0;
	lcd_ypos	<= 	lcd_request ? (vcnt - w_v_start) : 12'd0;
end


endmodule
