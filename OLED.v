module OLED(
output SCL,         //OLED serial Clock
output SDA,         //OLED serial Data
output FPS         //Output to measure FPS
);

parameter T=5;     //Delay betweeen two instructions

//--------------I2C interface-----------------------
wire Busy;
wire Clk;              
reg Start=0;
reg DCn=0;
reg [7:0]DATA=0;

reg [15:0]d=0;
reg [12:0]delay=0;
reg [7:0] addr=0;
reg [6:0]col=0;
reg [5:0]step=0;
reg [2:0]page=0;
reg bank=0;
reg mem=0;
reg fps=0;

wire [15:0] dout1;
wire [15:0] dout2;


//----------Module instantiation-----------------------------------------------------------
SB_HFOSC inthosc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(Clk));   //50MHz clock
I2C Mod(.clk(Clk),.start(Start),.DCn(DCn),.Data(DATA),.busy(Busy),.scl(SCL),.sda(SDA));   //I2C Master
SB_RAM40_4K Mem1(.WDATA(16'd0),.MASK(16'd0),.WADDR(11'd0),.WE(1'b1),.WCLKE(1'b0),.WCLK(1'b0),.RDATA(dout1),.RADDR({3'b0,addr}),.RE(1'b1),.RCLKE(1'b1),.RCLK(Clk));
SB_RAM40_4K Mem2(.WDATA(16'd0),.MASK(16'd0),.WADDR(11'd0),.WE(1'b1),.WCLKE(1'b0),.WCLK(1'b0),.RDATA(dout2),.RADDR({3'b0,addr}),.RE(1'b1),.RCLKE(1'b1),.RCLK(Clk));
//------------------------------------------------------------------------------------------

always @(negedge Clk)
begin
  if(mem)                //choose memory module
     begin
        d=dout2;         //Mem2
     end
  else
     begin
        d=dout1;         //Mem1
     end
end

always @(posedge Clk)
begin
  if(delay!=0)
     begin
        delay<=delay-1;             //Handle delay
     end 
  else 
     begin
        if(Busy)
           begin
              Start<=0;              //If I2C bus is busy, add delay of T cycles 
              delay<=T;              //Delay between two instructions
           end 
        else
           begin
              case(step)
              0:begin
          	   DATA<=8'hAF;      //set display on
          	   DCn<=0;
	           Start<=1;
         	   step<=step+1;
	           delay<=T;
        	end
      	      1:begin
          	   DATA<=8'hA6;      //set normal mode
	           DCn<=0;
         	   Start<=1;
	           step<=step+1;
         	   delay<=T;
	        end
      	      2:begin
          	   DATA<=8'h20;      //set addressing mode
  	           DCn<=0;
         	   Start<=1;
	           step<=step+1;
        	   delay<=T;
 	        end
      	      3:begin
         	   DATA<=8'h02;      //set addressing mode to page
	           DCn<=0;
         	   Start<=1;
	           step<=step+1;
	           delay<=T;
 	        end
      	      4:begin
	           DATA<=8'h8D;      //charge pump setting
         	   DCn<=0;
	           Start<=1;
         	   step<=step+1;
	           delay<=T;
        	end
      	      5:begin
	           DATA<=8'h14;      //charge pump on
         	   DCn<=0;
	           Start<=1;
         	   step<=step+1;
	           delay<=T;
	        end
      	      6:begin
        	   DATA<=8'h00;      //set column address lower nibble to 0
	           DCn<=0;
         	   Start<=1;
	           step<=step+1;
	           delay<=T;
        	end
      	      7:begin
	           DATA<=8'h10;      //set column address higher nibble to 0
         	   DCn<=0;
	           Start<=1;
         	   step<=step+1;
 	           delay<=T;
        	end
      	      8:begin
	           DATA<=8'hB0+page; //set page number
	           DCn<=0;
	           Start<=1;
	           step<=9;
 	           delay<=T;
        	end
      	      9:begin
   	           if(bank==0)
          	      begin
 	                 DATA<=d[7:0];      //send data from lower bank
            	         bank<=1;
  	             end
          	   else
 	              begin	
            	         DATA<=d[15:8];      //send data from upper bank
   	                 addr<=addr+1;       //increment address
	                 if(addr==8'b11111111)
		            begin
		               mem=mem+1;    //After reading Mem1, read Mem2
		               addr<=0;      //Reset address
		            end
	                 bank<=0;
 	              end
          	   DCn<=1;
          	   Start<=1;
          	   delay<=T;
          	   col<=col+1;                //Increment column address
          	   if(col==127)
          	      begin
	                 page<=page+1;        //After 128 columns, change page
	                 if(page==7)
   	                    begin
            	               fps<=1;
 		            end 
 		         else 
 		            begin
		               fps<=0;
		            end
	                step<=8;             //Send page address
          	      end
      	        end
              endcase
           end
     end
end

assign FPS=fps;
assign CLK=Clk;

//------------Replace this part------------------------------------------------------------

defparam Mem2.INIT_F =256'hfffffffffffffffffffffffffffffffffffdfdfdfcfafcf7fdf8f9e4e0c4c0c0;
defparam Mem2.INIT_E =256'hc0c3c7cbc9c1c1e1c0c0e0c0e0c0c080808080e0c0e7efffffffffffffffffff;
defparam Mem2.INIT_D =256'hf7f3f3e7f3f7ffffffffffffefefffefeeeeedfdfdffffffeffffffefee6e6f0;
defparam Mem2.INIT_C =256'hf4fcfcfcfffffffffffffffffffefefffeffffffffffffffffffffffffffffff;
defparam Mem2.INIT_B =256'hffffe0c8c0c0c0c0c0c0c0e0e0e0c0c08000200000800000c030000161230301;
defparam Mem2.INIT_A =256'h1d0880c2c1e1f7ffff1f1701010107070f0f1f1f33fbf3fbfffffffffffffefc;
defparam Mem2.INIT_9 =256'hf8f0e0c3c4c0c0c0e0e0e0f0e0f0a02060c0e0e0800080808000000000000000;
defparam Mem2.INIT_8 =256'h00000000000000000000c0808080008080c0c0c1c1e0e0c0c0c1e1a5e7f3f7ff;
defparam Mem2.INIT_7 =256'hffffffff3f7f7fffffffffff7f3f3f0f0700000000000000000000008084c0c0;
defparam Mem2.INIT_6 =256'h90000000010005c7e3fbffffffffffffffffffffffffffffffce1682e8f06001;
defparam Mem2.INIT_5 =256'h400040c000000003010100000003020000000000000000000000000000000000;
defparam Mem2.INIT_4 =256'h0000000000000000000000000143e2feffffff8f1f3fffffffffffffffffffff;
defparam Mem2.INIT_3 =256'hffffffffffffffffffffffffffffffffff3f1f0f030101000000030707070703;
defparam Mem2.INIT_2 =256'h0d1f7ffffffffffffffffffffffffffffffffffffffffffcf830002000c0c040;
defparam Mem2.INIT_1 =256'hf050707030703010100100000000c00200010101000000000000000000000000;
defparam Mem2.INIT_0 =256'h000000000000417f3f1fe7efdf1fffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_F =256'hffffffffff7fffffffffffffffffffffffffffffffffff7f3f3f9f9f9f1fc7ff;
defparam Mem1.INIT_E =256'hfb78f0b0f0b080e8fcfcfeffffffffffffffffffffff7f170301010103030111;
defparam Mem1.INIT_D =256'h00000000000000000080603010131f3f3fffffffff7f1f070b3f7fffff3f3d0a;
defparam Mem1.INIT_C =256'h0c078ffefcfcdff3fbfffffbfffffffffffbffffffffffffffffffffffffffff;
defparam Mem1.INIT_B =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffff7fffffff;
defparam Mem1.INIT_A =256'h1f0703010000000000000000808080c7ffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_9 =256'h3f000000000000000c0133fffcf8ffdffeffffffffffffffffffffffffffff7f;
defparam Mem1.INIT_8 =256'h3f9fff2f2f6f2ffcecbcf098bc8e80dcefdfffffeffffffdffffdffffffffbbf;
defparam Mem1.INIT_7 =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_6 =256'hffffff800000000101030f1f7f7fffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_5 =256'hff3f0f030707070f3fffffff3fffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_4 =256'hffffffff1f03070707070707030101010183ffffffff7ffffffcfeffffffffff;
defparam Mem1.INIT_3 =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_2 =256'hffff4703093fffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_1 =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_0 =256'hffffffffffffffffffffffffffffff7f7fffffffffffff9f3f7fffffffffffff;
//------------------------------------------------------------------------------------------
endmodule
