/*-----------------------------------------------------------------------
								 \\\|///
							   \\  - -  //
								(  @ @  )
+-----------------------------oOOo-(_)-oOOo-----------------------------+
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo (Thereturnofbingo).
In the event of publication, the following notice is applicable:
Copyright (C) 2012-20xx CrazyBingo Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		CrazyBingo
Technology blogs 	: 		www.crazyfpga.com
Email Address 		: 		crazyfpga@vip.qq.com
Filename			:		Sensor_Image_Crop.v
Date				:		2017-06-19
Description			:		Zoom X & Y for Sensor image output.
Modification History	:
Date			By			Version			Change Description
=========================================================================
17/06/19		CrazyBingo	1.0				Original
17/08/19		CrazyBingo	1.1				Modify for X & Y zoom
24/04/18		Codex		1.2				Add runtime crop configuration
-------------------------------------------------------------------------
|                                     Oooo								|
+------------------------------oooO--(   )-----------------------------+
                              (   )   ) /
                               \ (   (_/
                                \_)
----------------------------------------------------------------------*/ 

`timescale 1ns / 1ns
module Sensor_Image_XYCrop
#(
	parameter 	PIXEL_DATA_WIDTH 	= 8,
	parameter	H_COUNTER_WIDTH		= 12,
	parameter	V_COUNTER_WIDTH		= 12
)
(
	//globel clock
	input				clk,				//image pixel clock
	input				rst_n,				//system reset
	
	// runtime configuration (sampled every clock, latch to internal regs)
	input	[H_COUNTER_WIDTH-1:0]	h_crop_start_i,
	input	[H_COUNTER_WIDTH-1:0]	h_crop_end_i,		// exclusive end position
	input	[V_COUNTER_WIDTH-1:0]	v_source_total_i,
	input	[V_COUNTER_WIDTH-1:0]	v_crop_size_i,
	
	//CMOS Sensor interface
	input								image_in_vsync,		//H : Data Valid; L : Frame Sync(Set it by register)
	input								image_in_href,		//H : Data vaild, L : Line Sync
	input								image_in_de,		//H : Data Enable, L : Line Sync
	input		[PIXEL_DATA_WIDTH-1:0]	image_in_data,		//8 bits cmos data input
	
	output								image_out_vsync,	//H : Data Valid; L : Frame Sync(Set it by register)
	output								image_out_href,		//H : Data vaild, L : Line Sync
	output								image_out_de,		//H : Data Enable, L : Line Sync
	output		[PIXEL_DATA_WIDTH-1:0]	image_out_data		//8 bits cmos data input	
);

//-----------------------------------
//Register input signals for alignment
reg							image_in_href_r;
reg 						image_in_de_r; 
reg							image_in_vsync_r;
reg	[PIXEL_DATA_WIDTH-1:0]	image_in_data_r;

reg	[H_COUNTER_WIDTH-1:0]	h_crop_start;
reg	[H_COUNTER_WIDTH-1:0]	h_crop_end;
reg	[V_COUNTER_WIDTH-1:0]	v_crop_top;
reg	[V_COUNTER_WIDTH-1:0]	v_crop_bottom;

wire	[V_COUNTER_WIDTH-1:0]	v_half_gap = (v_source_total_i > v_crop_size_i) ? ((v_source_total_i - v_crop_size_i) >> 1) : {V_COUNTER_WIDTH{1'b0}};
wire	[V_COUNTER_WIDTH-1:0]	v_bottom_candidate = v_half_gap + v_crop_size_i;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		image_in_vsync_r <= 0;
		image_in_href_r <= 0;
		image_in_data_r <= 0;
		image_in_de_r <= 0; 
		h_crop_start <= {H_COUNTER_WIDTH{1'b0}};
		h_crop_end <= {H_COUNTER_WIDTH{1'b0}};
		v_crop_top <= {V_COUNTER_WIDTH{1'b0}};
		v_crop_bottom <= {V_COUNTER_WIDTH{1'b0}};
		end
	else
		begin
		image_in_vsync_r <= image_in_vsync;
		image_in_href_r <= image_in_href;
		image_in_data_r <= image_in_data;
		image_in_de_r <= image_in_de; 
		h_crop_start <= h_crop_start_i;
		h_crop_end <= h_crop_end_i;
		v_crop_top <= v_half_gap;
		v_crop_bottom <= (v_bottom_candidate > v_source_total_i) ? v_source_total_i : v_bottom_candidate;
		end
end
wire	image_in_href_negedge = (image_in_href_r & ~image_in_href) ? 1'b1 : 1'b0;

	
//-----------------------------------
//Image Ysize Crop
reg	[V_COUNTER_WIDTH-1:0] image_ypos;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		image_ypos <= 0;
	else if(image_in_vsync == 1'b1)
		begin
		if(image_in_href_negedge == 1'b1)
			image_ypos <= image_ypos + 1'b1;
		else
			image_ypos <= image_ypos;
		end
	else
		image_ypos <= 0;
end
assign	image_out_vsync = image_in_vsync_r;

						   
						   
//-----------------------------------
//Image Hsize Crop
reg	[H_COUNTER_WIDTH-1:0] image_xpos;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		image_xpos <= 0;
	else if(image_in_href == 1'b1)
		image_xpos <= image_xpos + image_in_de;
	else
		image_xpos <= 0;
end

wire 			w_image_out_href = (image_in_href == 1'b1) &&
								   (image_ypos >= v_crop_top) && 
								   (image_ypos <  v_crop_bottom) &&
								   (image_xpos >= h_crop_start )&& 
								   (image_xpos <  h_crop_end);
                                   
reg 			image_out_href_r = 0; 
always @(posedge clk) begin	
	image_out_href_r <= w_image_out_href; 
end
assign image_out_href = image_out_href_r; 

assign 	image_out_de = image_out_href_r && image_in_de_r; 

assign	image_out_data = image_in_data_r;				   


endmodule
