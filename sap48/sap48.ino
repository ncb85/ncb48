
/*
  Sketch for programming EPROM in Intel D8748H/D8749H microcontroller using an Arduino Mega

  Note the D8748H uses different programming voltages than the 8748.

  Inspired by a solution by SaabFAN on EEVblog forum for the 8742 and Ardunio Nano:
  https://www.eevblog.com/forum/microcontrollers/simple-programmer-for-vintage-intel-mcs-48-microcontroller/

  Reference: Intel D8748H datasheet http://www.alldatasheet.com/datasheet-pdf/pdf/80208/INTEL/D8748H.html

  Programming the D8748H version requires:
    VCC = 5 +/- 0.25    total supply current @ VCC = 100 mA max
    VDD_H = 21 +/- 1.0 @ 20 mA max
    VDD_L = VCC @ 15 mA max
    PROG_H = 18 +/- 0.5 @ 1 mA max
    PROG_L = float or 4.0 to VCC @ 1 mA max
    EA_H = 18 +/- 0.5 @ 1 mA max
    EA_L = VCC
    also, P10 & P11 must be tied to ground.

  In addition to these signals, the 8748 needs a crystal on pins 2&3, 5V on pin 40 and 0V on pin 20.
  The datasheet says there must be a floating state on PROG.

  Each byte is programmed then read back immediately for verification.  If there is not a match,
  programming stops with an error message.  To test the hardware is working, the "break" statement
  in Step 12 can be commented out and the Arduino will go through the full programming cycle
  without stopping.

  This code is in the public domain.  Use at your own risk, and have fun!

  Further development of code from
  http://www.eevblog.com/forum/repair/intel-8748-uc-programming-with-arduino/

  Using MEGA there is 8k of RAM available, which is enough to load data via Serial port
*/

// Pin assignments from Mega 2560 to the 8748/8749
int DB0 = 32;      //DB0-DB7 are 8748 pins 12-19
int DB1 = 34;
int DB2 = 36;
int DB3 = 38;
int DB4 = 40;
int DB5 = 42;
int DB6 = 44;
int DB7 = 46;
int P20 = 48;     //P20, P21 are 8748 pins 21, 22
int P21 = 50;
int P22 = 52;     //P22 is 8749 pin 23
int TEST0 = 28;   // 8748 pin 1
int RESET = 30;   // 8748 pin 4
int EA_H = 22;    // transistor switch for EA high  (8748 pin 7)
int VDD_H = 24;   // transistor switch for VDD high (8748 pin 26)
int PROG_H = 26;  // transistor switch for PROG high (8748 pin 25)

const int prog_size_8748 = 1024;
byte data_prog[2048];/* = {0x31,0x00,0x20,0x3E,0xFF,0xC3,0x42,0x06,0xE3,0xEF,0xBE,0xC3,0x68,0x00,0x3E,0x0D,
                        0xF5,0x3A,0x00,0x08,0xB7,0xC3,0x6C,0x06,0xCD,0x71,0x03,0xE5,0xC3,0x2D,0x03,0x57};*/

int chip_type = -1;
char byte_received, last_byte_received;
char hexbuff[5];
bool hex_file_loaded = false;

void setup() {
  Serial.begin(9600);     // Actions will be echoed to the monitor.  Make sure it is open.

  // Setup the Control-Pins
  pinMode(P20, OUTPUT);
  pinMode(P21, OUTPUT);
  pinMode(TEST0, OUTPUT);
  pinMode(RESET, OUTPUT);
  pinMode(EA_H, OUTPUT);
  pinMode(VDD_H, OUTPUT);
  pinMode(PROG_H, OUTPUT);
  //DB0-7 are bidirectional, so set their mode later.

  // Initial state from data sheet
  digitalWrite(TEST0, HIGH);    // 5V
  digitalWrite(RESET, LOW);     // 0V
  digitalWrite(EA_H, LOW);      // EA = 5V
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(PROG_H, LOW);    // PROG floating

  menu_setup();
}

void loop() {
  menu_loop();
}


