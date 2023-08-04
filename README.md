# OLED-Controller-Verilog

## Table of contents:
- [Introduction](#introduction)
- [Circuit](#circuit)
- [Waveforms](#waveforms)
- [Steps to run](#steps-to-run)
    - [Ubuntu](#ubuntu)
    - [Windows](#windows)
- [Output](#output)
- [Tech stack](#tech-stack)
    - [UPduino v3.0](#upduino-v30)
    - [I2C](#i2c)
    - [Jupyter notebook](#jupyter-notebook)
- [Future work](#future-work)

## Introduction:
In this project, I have designed a Verilog driver for OLED display. Current version of this project uses SSD1306 0.96 inch OLED display. Currently I am using upduino 3.0 FPGA board to run this code. The Upduino 3.0 board houses Lattice UltraPlus ICE40UP5K FPGA. (To use this driver with other FPGA boards, Connect the `clk` pin to FPGA clock and change the BRAM IPs accordingly.)


## Circuit:

![Circuit](https://github.com/Premraj02/OLED-Controller-Verilog/assets/84727176/4186b27d-e540-4e5a-b6b0-2ef537701dbf)

- OLED Gnd -> Any ground pin on FPGA
- OLED 5V  -> 5V pin on FPGA
- OLED SCL -> IO pin 28
- OLED SDA -> IO pin 38

## Waveforms:
- I2C: T_WAIT is the parameter that decides number clock division factor for SCL. T_WAIT is also used to decide start hold time and stop settle time. To change the FPS, change value of T_WAIT.

![Waveform1](https://github.com/Premraj02/OLED-Controller-Verilog/assets/84727176/7a5850e7-7aa4-4db0-b546-0493bd09e658)

- OLED: T is the parameter which decides number of clock cycles between two data/ command transmissions.

![Waveform2](https://github.com/Premraj02/OLED-Controller-Verilog/assets/84727176/ec62517b-ac02-4520-9078-4be2b759c6a6)

## Steps to run:
### Ubuntu:
- Setup necessary packages and drivers using [this](https://daveho.github.io/2021/02/07/upduino3-getting-started-on-linux.html ) tutorial.
- Open the OLED.ipynb file in jupyter notebook.
- Run the cell intended for Ubuntu.
- Enter the name of image file (for example OLED.png).
- Enter the threshold value for converting image in binary format.
- Enter Y to program the FPGA automatically or N if you want to program it manually.
- To program the FPGA manually, open the terminal and execute the following commands:
```sh
apio verify
apio build
apio upload
```
- OLED screen should display the image.

### Windows:
- Setup necessary packages and drivers using [this](https://daveho.github.io/2021/02/07/upduino3-getting-started-on-linux.html ) tutorial.
- Open the OLED.ipynb file in jupyter notebook.
- Run the cell intended for Windows.
- Enter the name of image file. For example OLED.png
- Enter the threshold value for converting image in binary format.
- Copy the memory configuration.
- Paste the memory configuration in OLED.v file after `Replace this part` comment.
- To program the FPGA, open the terminal and execute the following commands: 
```sh
apio verify
apio build
apio upload
```
- OLED screen should display the image.

## Output:

![Demo](https://github.com/Premraj02/OLED-Controller-Verilog/assets/84727176/da93e691-9bf0-4845-9d9e-f0fe206498ba)

## Tech stack:
### [UPduino v3.0](https://github.com/tinyvision-ai-inc/UPduino-v3.0)
The UPduino v3.0 is a small, low cost FPGA board. The board features an on-board FPGA programmer, flash and LED with all FPGA pins brought out to easy to use 0.1" header pins for fast prototyping. It is an open source FPGA board and supports apio toolchain. 

### [I2C](https://en.wikipedia.org/wiki/I%C2%B2C):
For this project, I have implemented the I2C module from scratch. This implementation of I2C uses bit banging method to boost the speed of conventional I2C communication. Here we also ignore the acknowledgement bit to make the communication even faster. With these optimisations, this driver can operate the OLED screen upto 140 FPS*. 

>*I have tested several OLED screens and among them only few could display in 140 FPS. FPS can be adjusted by varying the delay time parameter in I2C module. Refer to [I2C waveform](#waveforms) for more details.
### [Jupyter notebook](https://jupyter.org/):
The jupyter notebook file reads the given image. It then resizes it to fit the OLED display and converts it into a binary image using the threshold value. After this, the jupyter file modifies the OLED.v file so that the BRAM modules are initialized with given image data.
In next step, if user choose to program the FPGA automatically, the program is verified, synthesized and the FPGA is programmed.

## Future work:

 - [ ]  Implement Run Lengtg Encoding (RLE) to store the image in compressed format.
 - [ ]  Add support for gif and video files.
 - [ ]  Solve file handling issue in windows.

