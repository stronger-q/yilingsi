`timescale 1ns / 1ps

module AlphaLevelAdjust
(
	input  wire [7:0] pixel_in,
	input  wire [7:0] alpha_in,
	output wire [7:0] pixel_out
);

	wire [7:0] alpha_clamped = (alpha_in > 8'd100) ? 8'd100 : alpha_in;
	wire        use_dark_path = (alpha_clamped <= 8'd50);
	wire [7:0]  alpha_dark    = alpha_clamped;
	wire [7:0]  alpha_light   = (alpha_clamped > 8'd50) ? (alpha_clamped - 8'd50) : 8'd0;

	// Darken towards black
	wire [15:0] mult_dark    = pixel_in * alpha_dark;
	wire [31:0] scaled_dark  = mult_dark * 16'd1311;
	wire [15:0] div_dark     = scaled_dark[31:16];
	wire [7:0]  pixel_dark   = (div_dark[15:8] != 8'd0) ? 8'd255 : div_dark[7:0];

	// Brighten towards white
	wire [7:0]  delta        = 8'd255 - pixel_in;
	wire [15:0] mult_light   = delta * alpha_light;
	wire [31:0] scaled_light = mult_light * 16'd1311;
	wire [15:0] div_light    = scaled_light[31:16];
	wire [15:0] sum_light    = {8'd0, pixel_in} + div_light;
	wire [7:0]  pixel_light  = (sum_light[15:8] != 8'd0) ? 8'd255 : sum_light[7:0];

	assign pixel_out = use_dark_path ? pixel_dark : pixel_light;

endmodule
