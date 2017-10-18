/* 
(C) OOMusou 2008 http://oomusou.cnblogs.com

Filename    : DE2_70.v
Compiler    : Quartus II 8.0
Description : Demo how to write color pattern generator
Release     : 11/16/2008 1.0
*/
`include "Keyboard.v"
`include "LCD.v"
module VGA (
  //////////////////////// Clock Input ////////////////////////
  input          iCLK_28,           // 28.63636 MHz
  input          iCLK_50,           // 50 MHz
  input          iCLK_50_2,         // 50 MHz
  input          iCLK_50_3,         // 50 MHz
  input          iCLK_50_4,         // 50 MHz
  input          iEXT_CLOCK,        // External Clock
  //////////////////////// Push Button ////////////////////////
  input  [3:0]   iKEY,              // Pushbutton[3:0]
  //////////////////////// DPDT Switch ////////////////////////
  input  [17:0]  iSW,               // Toggle Switch[17:0]
  //////////////////////// 7-SEG Dispaly ////////////////////////
  output [6:0]   oHEX0_D,           // Seven Segment Digit 0
  output [6:0]   oHEX1_D,           // Seven Segment Digit 1
  output [6:0]   oHEX2_D,           // Seven Segment Digit 2
  output [6:0]   oHEX3_D,           // Seven Segment Digit 3
  output [6:0]   oHEX4_D,           // Seven Segment Digit 4
  output [6:0]   oHEX5_D,           // Seven Segment Digit 5
  output [6:0]   oHEX6_D,           // Seven Segment Digit 6
  output [6:0]   oHEX7_D,           // Seven Segment Digit 7
  //////////////////////////// LED ////////////////////////////
  output [8:0]   oLEDG,             // LED Green[8:0]
  output [17:0]  oLEDR,             // LED Red[17:0]
  //////////////////////////LCD///////////////////////////////
  inout   [7:0]  LCD_D,             // LCD Data bus 8 bits
  output         oLCD_ON,           // LCD Power ON/OFF
  output         oLCD_BLON,         // LCD Back Light ON/OFF
  output         oLCD_RW,           // LCD Read/Write Select, 0 = Write, 1 = Read
  output         oLCD_EN,           // LCD Enable
  output         oLCD_RS,           // LCD Command/Data Select, 0 = Command, 1 = Data
  inout          PS2_KBDAT,         // PS2 Keyboard Data
  inout          PS2_KBCLK,         // PS2 Keyboard Clock
  inout          PS2_MSDAT,         // PS2 Mouse Data
  inout          PS2_MSCLK,         // PS2 Mouse Clock
  //////////////////////// VGA ////////////////////////////
  output         oVGA_CLOCK,        // VGA Clock
  output         oVGA_HS,           // VGA H_SYNC
  output         oVGA_VS,           // VGA V_SYNC
  output         oVGA_BLANK_N,      // VGA BLANK
  output         oVGA_SYNC_N,       // VGA SYNC
  output  [7:0]  oVGA_R,            // VGA Red[9:0]
  output  [7:0]  oVGA_G,            // VGA Green[9:0]
  output  [7:0]  oVGA_B,            // VGA Blue[9:0]
  output  [20:0] change,
  output [1:0]ostate
  );
// Horizontal Parameter
parameter H_FRONT = 16;
parameter H_SYNC  = 96;
parameter H_BACK  = 48;
parameter H_ACT   = 640;
parameter H_BLANK = H_FRONT + H_SYNC + H_BACK;
parameter H_TOTAL = H_FRONT + H_SYNC + H_BACK + H_ACT;

// Vertical Parameter
parameter V_FRONT = 11;
parameter V_SYNC  = 2;
parameter V_BACK  = 32;
parameter V_ACT   = 480;
parameter V_BLANK = V_FRONT + V_SYNC + V_BACK;
parameter V_TOTAL = V_FRONT + V_SYNC + V_BACK + V_ACT;

wire CLK_25;
wire CLK_move;
wire CLK_to_DAC;
wire RST_N;
wire left_one;
wire right_one;
wire left_two;
wire right_two;
PLL pll0 (
  .inclk0(iCLK_50),
  .c0(CLK_25)
);
PLL #(500000)pll(
  .inclk0(iCLK_50),
  .c0(CLK_move)
);
LCD lcdout(iCLK_50,RST_N,{oLCD_EN,oLCD_RS,oLCD_RW,LCD_D},ostate);
// Select DAC clock
assign CLK_to_DAC = CLK_25;
assign oVGA_SYNC_N  = 1'b0;        // This pin is unused.
assign oVGA_BLANK_N = ~((H_Cont<H_BLANK)||(V_Cont<V_BLANK));
assign oVGA_CLOCK   = ~CLK_to_DAC; // Invert internal clock to output clock
assign RST_N     = iSW[1];      // Set reset signal is KEY[0]
assign right_B = iKEY[0];
assign left_B  = iKEY[1];
assign right_A = iKEY[2]; 
assign left_A  = iKEY[3]; 
assign oLCD_ON = 1'b1;
assign oLCD_BLON = 1'b0;
reg [10:0] H_Cont;
reg [10:0] V_Cont;
reg [7:0]  vga_r;
reg [7:0]  vga_g;
reg [7:0]  vga_b;
reg        vga_hs;
reg        vga_vs;
reg [10:0] X;
reg [10:0] Y;
reg [6:0]scoreA;
reg [6:0]scoreB;
reg [1:0]state;
integer originalX=320;
integer originalY=240;
integer boardAposition=320;
integer boardBposition=320;
reg directX,directY;
reg [35:0]counter;
integer countbooard=0;
reg [7:0] dateR,dateG,dateB;
reg [7:0] boardA_R,boardA_G,boardA_B;
reg [7:0] boardB_R,boardB_G,boardB_B;
reg [5:0]sizeA,sizeB;
reg [4:0]speed;
assign ostate = state;
assign oVGA_R = vga_r;
assign oVGA_G = vga_g;
assign oVGA_B = vga_b;
assign oVGA_HS = vga_hs;
assign oVGA_VS = vga_vs;
SegOUT SEG0(10,oHEX0_D);
SegOUT SEG1(10,oHEX1_D);
SegOUT SEG2(10,oHEX2_D);
SegOUT SEG3(10,oHEX3_D);
SegOUT SEG4(scoreA%10,oHEX4_D);
SegOUT SEG5(scoreA%100/10,oHEX5_D);
SegOUT SEG6(scoreB%10,oHEX6_D);
SegOUT SEG7(scoreB%100/10,oHEX7_D);
// Horizontal Generator: Refer to the pixel clock
always@(posedge CLK_to_DAC, negedge RST_N) begin
  if(!RST_N) begin
    H_Cont <= 0;
    vga_hs <= 1;
    X      <= 0;
  end 
  else begin
    if (H_Cont < H_TOTAL)
      H_Cont    <=    H_Cont+1'b1;
    else
      H_Cont    <=    0;
    // Horizontal Sync
    if(H_Cont == H_FRONT-1) // Front porch end
      vga_hs <= 1'b0; 
    if(H_Cont == H_FRONT + H_SYNC -1) // Sync pulse end
      vga_hs <= 1'b1;
    // Current X
    if(H_Cont >= H_BLANK)
      X <= H_Cont-H_BLANK;
    else
      X <= 0;
  end
end

// Vertical Generator: Refer to the horizontal sync
always@(posedge oVGA_HS, negedge RST_N) begin
  if(!RST_N) begin
    V_Cont <= 0;
    vga_vs <= 1;
    Y      <= 0;
  end
  else begin
    if (V_Cont<V_TOTAL)
      V_Cont <= V_Cont + 1'b1;
    else
      V_Cont    <= 0;
    // Vertical Sync
    if (V_Cont == V_FRONT-1) // Front porch end
      vga_vs <= 1'b0;
    if (V_Cont == V_FRONT + V_SYNC-1) // Sync pulse end
      vga_vs <= 1'b1;
    // Current Y
    if (V_Cont >= V_BLANK)
      Y <= V_Cont-V_BLANK;
    else
      Y <= 0;
  end
end
// Pattern Generator
always@(posedge CLK_to_DAC, negedge RST_N) begin
  if(!RST_N) begin
    vga_r <= 0;
    vga_g <= 0;
    vga_b <= 0;
  end
  else 
  begin
	{vga_r,vga_g,vga_b} <=(Y>=(originalY-4)&&Y<=(originalY+4)&&X>=(originalX-4)&&(X<=(originalX+4)))?{dateR,dateG,dateB}:
								(Y<480&&Y>=476&&((boardAposition+sizeA)>=X)&&((boardAposition-sizeA)<=X))?{boardA_R,boardA_G,boardA_B}:
								(Y<4&&Y>=0&&((boardBposition+sizeB)>=X)&&((boardBposition-sizeB)<=X))?{boardB_R,boardB_G,boardB_B}:
								24'hFFFFFF;
  end
end
always@(negedge iCLK_50 or negedge RST_N)
begin
if(~RST_N)
	begin
	counter=0;
	originalX=320;
	originalY=240;
	directX=0;
	directY=0;
	scoreA=0;
	scoreB=0;
	state=0;
	end
else
	begin
	if(~iSW[0])
		begin
		if(state==0)
		begin
			if(counter==(speed*50000))
			begin
				if(directX&&directY) //左上角移動
					begin
					originalX=originalX-2;
					originalY=originalY-1;
					end
				else if(~directX&&directY) //右上角移動
					begin
					originalX=originalX+2;
					originalY=originalY-1;
					end
				else if(directX&&~directY) //左下角移動
					begin
					originalX=originalX-2;
					originalY=originalY+1;
					end
				else if(~directX&&~directY) //右下角移動
					begin
					originalX=originalX+2;
					originalY=originalY+1;
					end
				if(originalX==4)directX=0;		//向右反彈
				else if(originalX==636)directX=1;	//向左反彈
				if(originalY==6)	
					begin
					if(((boardBposition+sizeB+2)>=originalX)&&((boardBposition-sizeB-2)<=originalX))
						begin		//玩家B的板子反彈判斷
						directY=0;
						end
					else	//若玩家B未接到球則重新設定方塊位置增加玩家A的分數
						begin
						directY=1;
						originalX=320;
						originalY=240;
						scoreA=scoreA+15;
						if(scoreA==90)state=1;
						end	
					end
				else if(originalY==474)
					begin
					if(((boardAposition+sizeA+2)>=originalX)&&((boardAposition-sizeA-2)<=originalX))
						begin		//玩家A的板子反彈判斷
						directY=1;
						end
					else		//若玩家A未接到球則重新設定方塊位置增加玩家B的分數
						begin
						directY=0;
						originalX=320;
						originalY=240;
						scoreB=scoreB+15;
						if(scoreB==90)state=2;
						end
					end 
				counter=0;
				end
			else counter=counter+1;
			end
		else 
			begin
			state=3;
			end
		end
	end
end
always@(negedge iCLK_50)
begin
	if(state==0)
	begin
		if(countbooard==500000)
			begin
			if(~left_A)boardAposition<=boardAposition-2;
			if(~right_A)boardAposition<=boardAposition+2;
			if(~left_B)boardBposition<=boardBposition-2;
			if(~right_B)boardBposition<=boardBposition+2;
			countbooard=0;
			end
		else 
			begin
			countbooard=countbooard+1;
			if(boardAposition<sizeA)boardAposition<=sizeA;
			if(boardAposition>(640-sizeA))boardAposition<=640-sizeA;
			if(boardBposition>(640-sizeB))boardBposition<=640-sizeB;
			if(boardBposition<sizeB)boardBposition<=sizeB;
			end
	end
end
always@(posedge iCLK_50) //方塊的顏色
begin
	if(iSW[15])dateR=8'hFF;
	else dateR=8'h0;
	if(iSW[16])dateG=8'hFF;
	else dateG=8'h0;
	if(iSW[17])dateB=8'hFF;
	else dateB=8'h0;
 end
always@(posedge iCLK_50)//玩家A板子的顏色
begin
	if(iSW[12])boardB_R=8'hFF;
	else boardB_R=8'h0;
	if(iSW[13])boardB_G=8'hFF;
	else boardB_G=8'h0;
	if(iSW[14])boardB_B=8'hFF;
	else boardB_B=8'h0;
 end
always@(posedge iCLK_50) //玩家B的顏色
begin
	if(iSW[9])boardA_R=8'hFF;
	else boardA_R=8'h0;
	if(iSW[10])boardA_G=8'hFF;
	else boardA_G=8'h0;
	if(iSW[11])boardA_B=8'hFF;
	else boardA_B=8'h0;
 end
always@(posedge iCLK_50) //球的速度
begin
	case({iSW[8],iSW[7],iSW[6]})
	0:speed=20;
	1:speed=18;
	2:speed=16;
	3:speed=15;
	4:speed=14;
	5:speed=13;
	6:speed=12;
	7:speed=10;
	default:;
	endcase
 end
 always@(posedge iCLK_50) //玩家B板子大小
begin
	case({iSW[5],iSW[4]})
	0:sizeB=30;
	1:sizeB=25;
	2:sizeB=20;
	3:sizeB=15;
	default:;
	endcase
 end
 always@(posedge iCLK_50) //玩家A板子大小
begin
	case({iSW[3],iSW[2]})
	0:sizeA=30;
	1:sizeA=25;
	2:sizeA=20;
	3:sizeA=15;
	default:;
	endcase
 end
endmodule

module PLL(inclk0,c0);
input inclk0;
output reg c0;
parameter target=1;
reg [30:0]count;
always@(posedge inclk0)
begin
	if(count==target)count=0;
	else count=count+1;
	if(count<=target/2)
		begin
		c0=0;
		end
	else 
		begin
		c0=1;
		end
end 
endmodule

module SegOUT(in,out);
input [3:0]in;
output reg [6:0]out;
always@(in)
begin
	case(in)
	0:out=~7'b0111111;
	1:out=~7'b0000110;
	2:out=~7'b1011011;
	3:out=~7'b1001111;
	4:out=~7'b1100110;
	5:out=~7'b1101101;
	6:out=~7'b1111100;
	7:out=~7'b0000111;
	8:out=~7'b1111111;
	9:out=~7'b1100111;
	default out=~7'b0000000;
	endcase
end
endmodule
