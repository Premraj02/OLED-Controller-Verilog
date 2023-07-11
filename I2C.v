module I2C(
input clk,                     //clock input
input start,                   //start signal
input DCn,                     //1 -> Data/ 0 -> Command
input [7:0]Data,               //8-bit Data
output reg busy=0,             //I2C busy
output reg scl=1,              //Serial clock
output reg sda=1);             //Serial data

parameter IDEL  = 0;
parameter START = 1;
parameter ADDR  = 2;
parameter CBYTE = 3;
parameter DATA  = 4;
parameter STOP  = 5;
parameter T_WAIT=10;        //=wait_time*clk_frequency  =5us*12MHz 4

reg DCn_r=0;
reg [2:0]state=0;
reg [3:0]i=0;
reg [3:0]step=0;
reg [12:0]delay=0;
reg [7:0]slave= 8'b01111000;   //slave address
reg [7:0]cbyte= 8'b10000000;   //Control byte for command
reg [7:0]dbyte= 8'b01000000;   //Control byte for data
reg [7:0]data=  0;

always @(posedge clk)
begin

if(delay != 0)                 //if delay is not zero, wait for clock cycles specified by delay
begin
 delay<= delay-1;
end else begin                 //if delay is zero, proceed
 case(state)
 IDEL:begin
 	scl<=1;
 	sda<=1;
 	if(start) 
 	begin                  //when start signal is recieved,
 	   DCn_r<=DCn;         //fetch data or command?
 	   data<=Data;         //detch data/command to transmit
 	   busy<=1;            //update busy flag
 	   state<= START;      //start transmission
 	   step<=0;            //sub state = 0    
 	end
      end
      
 START:begin                   //start signal. 
 	case(step)
 	0:begin
 	    sda<=0;            //SDA goes low
 	    delay<=T_WAIT;     //wait for T_WAIT cycles
 	    step<=step+1;      
 	  end
 	1:begin
 	    scl<=0;            //SCL goes low
 	    delay<=T_WAIT;     //Wait for T_WAIT cycles
 	    step<=step+1;
 	  end
 	2:begin
 	    state<=ADDR;       //Start sending address
 	    step<=0;
 	  end
 	endcase
       end

 ADDR:begin
 	case(step)
 	0:begin
 	  if(i<8)              //check if all bits are transmitted
 	  begin
 	      scl<=0;          //SCL goes low
 	      step<=1;
 	  end else if(i==8)    //ACK bit
 	  begin
 	      scl<=0;
 	      sda<=0;
 	      delay<=T_WAIT;
 	      i<=i+1;
 	      step<=2;
 	  end
 	  end
 	1:begin
 	      sda<=slave[7-i];  //transmit address bit
 	      delay<=T_WAIT;
 	      i<=i+1;
 	      step<=2;
 	  end
 	2:begin
 	    if(i<9)
 	    begin
 	      scl<=1;           //SCL goes high
 	      delay<=T_WAIT;    //Delay
 	      step<=0;
 	    end else begin
 	      scl<=1;
 	      delay<=T_WAIT;
 	      step<=3;
 	    end
 	  end
 	3:begin
 	      scl<=0;           //SCL goes low
 	      sda<=0;
 	      delay<=T_WAIT;    //Delay
 	      step<=4;
 	  end
 	4:begin
 	      step<=0;
 	      i<=0;
 	      state<=CBYTE;     //transmit control byte
 	  end
 	endcase
      end
      
 CBYTE:begin
 	case(step)
 	0:begin
 	  if(i<8)
 	  begin
 	      scl<=0;
 	      step<=1;
 	  end else if(i==8)
 	  begin
 	      scl<=0;
 	      sda<=0;
 	      delay<=T_WAIT;
 	      i<=i+1;
 	      step<=2;
 	  end
 	  end
 	1:begin
 	      if(DCn_r)
 	      begin
 	      	sda<=dbyte[7-i];
 	      end else begin
 	      	sda<=cbyte[7-i];
 	      end
 	      delay<=T_WAIT;
 	      i<=i+1;
 	      step<=2;
 	  end
 	2:begin
 	    if(i<9)
 	    begin
 	      scl<=1;
 	      delay<=T_WAIT;
 	      step<=0;
 	    end else begin
 	      scl<=1;
 	      delay<=T_WAIT;
 	      step<=3;
 	    end
 	  end
 	3:begin
 	      scl<=0;
 	      sda<=0;
 	      delay<=T_WAIT;
 	      step<=4;
 	  end
 	4:begin
 	      step<=0;
 	      i<=0;
 	      state<=DATA;
 	  end
 	
 	endcase
      end
      
 DATA:begin
 	case(step)
 	0:begin
 	  if(i<8)
 	  begin
 	      scl<=0;
 	      step<=1;
 	  end else if(i==8)
 	  begin
 	      scl<=0;
 	      sda<=0;
 	      delay<=T_WAIT;
 	      i<=i+1;
 	      step<=2;
 	  end
 	  end
 	1:begin
 	      sda<=data[7-i];
 	      delay<=T_WAIT;
 	      i<=i+1;
 	      step<=2;
 	  end
 	2:begin
 	    if(i<9)
 	    begin
 	      scl<=1;
 	      delay<=T_WAIT;
 	      step<=0;
 	    end else begin
 	      scl<=1;
 	      delay<=T_WAIT;
 	      step<=3;
 	    end
 	  end
 	3:begin
 	      scl<=0;
 	      sda<=0;
 	      delay<=T_WAIT;
 	      step<=4;
 	  end
 	4:begin
 	      step<=0;
 	      i<=0;
 	      state<=STOP;
 	  end
 	
 	endcase
      end   
 STOP:begin
 	case(step)
 	0:begin
 	    scl<=1;         //SCL goes high
 	    sda<=0;         //SDA goes low
 	    delay<=T_WAIT;     //Wait
 	    step<=step+1;
 	  end
 	1:begin
 	    state<=IDEL;   //IDLE, SDA goes high
 	    busy<=0;       //Update busy flag
 	    step<=0; 
 	  end
 	endcase
       end    

 endcase
end
end


endmodule
