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

defparam Mem2.INIT_F =256'hfffffffffffffffffffffffffffffffffffffdfffffafffffff9fbe4e4c4ccc2;
defparam Mem2.INIT_E =256'hc1cfcfcfdfdfdfffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem2.INIT_D =256'hf7f3f3fff3fffffffffffffffffffffffeeefffdfffffffffffffffefeeee6fc;
defparam Mem2.INIT_C =256'hfcfcfcfcfffffffffffffffffffefffffeffffffffffffffffffffffffffffff;
defparam Mem2.INIT_B =256'hffffe3ccc0c0c0c0c1c0e0e0e0e0e0c0e028680090909000d030e001e323ab0b;
defparam Mem2.INIT_A =256'h1f8ad6c2c1f7f7fffffffffffffffffffffffffffffbfbfffffffffffffffefc;
defparam Mem2.INIT_9 =256'hf8f0e0e3c4c0c0e0e8e0f0f0e0f0e020e0c0e0e0808090808000000000000000;
defparam Mem2.INIT_8 =256'h00000000000080800080c0c0c080008080c0c0c1c1e0e0e0c1e1e1e7e7f7f7ff;
defparam Mem2.INIT_7 =256'hffffffffbf7fffffffffffffff7f3f1f0700000000000000000000008084c6c2;
defparam Mem2.INIT_6 =256'hf040000081098dcfe3fbffffffffffffffffffffffffffffffcefecae8f0e021;
defparam Mem2.INIT_5 =256'h6021c1c080000303010301000003020000020000000000000000000000000000;
defparam Mem2.INIT_4 =256'h0000000000000000000000002167e6ffffffff8f1fbfffffffffffffffffffff;
defparam Mem2.INIT_3 =256'hffffffffffffffffffffffffffffffffff3f1f0f0f0301000000030707070703;
defparam Mem2.INIT_2 =256'h0f1f7ffffffffffffffffffffffffffffffffffffffffffffe32012160c0c040;
defparam Mem2.INIT_1 =256'hf150787830f0b8383a2110000044c28202011f3f3f7c78000400000301010000;
defparam Mem2.INIT_0 =256'h000000000001437fffdfffefdf9fffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_F =256'hffffffffffffffffffffffffffffffffffffffffffffffff3f3fbfff9f7fe7ff;
defparam Mem1.INIT_E =256'hff78f0f8f8f8f8e8fcfcfeffffffffffffffffffffffffbf3f3ffbffff7f7fff;
defparam Mem1.INIT_D =256'hfdfbfeff7ffffffffffe7e3f3f3f7f3f7fffffffffff3f073b3f7fffff7f7f9a;
defparam Mem1.INIT_C =256'h9c47effffcfcfffffbfffffbffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_B =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_A =256'h1f07030102080001000080808080c1cfffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_9 =256'h3f28e0e0faf9faf2ff7f7fffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_8 =256'h3fbfff7f3f7fbffefcfcf8b8bc9ed8dcfffffffffffffffffffffffffffffbff;
defparam Mem1.INIT_7 =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_6 =256'hffffffe00000000101030f3f7f7fffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_5 =256'hffff0fe30707979fffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_4 =256'hffffffff9f030707070f0f07070101010187fffffffffffffffefeffffffffff;
defparam Mem1.INIT_3 =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_2 =256'hffffcf030f3fffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_1 =256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
defparam Mem1.INIT_0 =256'hffffffffffffffffffffffffffffff7fffffffffffffffdfbfffffffffffffff;
//------------------------------------------------------------------------------------------
endmodule
