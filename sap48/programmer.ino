/*
 * Program memory can be both read and programmed
 * When erased, bits of the 8748H and 8749H Program Memory are in the logic "0" state.
 * Information on Verify of EPROM/ROM contents was found in Intel-8048-Manual page 2-17
 * and in Grokking the MCS-48 system page 22
 * NMOS chips need 25V, while HMOS chips only 21V
 */

#define PULSE_WIDTH 50

/*
 * set pin mode (INPUT, OUTPUT,..)
 */
void set_data_bus_direction(uint8_t pin_direction) {
  // switch pins to input/output mode
  pinMode(DB0, pin_direction);
  pinMode(DB1, pin_direction);
  pinMode(DB2, pin_direction);
  pinMode(DB3, pin_direction);
  pinMode(DB4, pin_direction);
  pinMode(DB5, pin_direction);
  pinMode(DB6, pin_direction);
  pinMode(DB7, pin_direction);
}

byte read_bus() {
  return
    digitalRead(DB0) * 1 +
    digitalRead(DB1) * 2 +
    digitalRead(DB2) * 4 +
    digitalRead(DB3) * 8 +
    digitalRead(DB4) * 16 +
    digitalRead(DB5) * 32 +
    digitalRead(DB6) * 64 +
    digitalRead(DB7) * 128;
}

/*
 * output the address to DB0..DB7, P20,P21,P22
 */
void output_data(byte data) {
  digitalWrite(DB0, bitRead(data, 0));
  digitalWrite(DB1, bitRead(data, 1));
  digitalWrite(DB2, bitRead(data, 2));
  digitalWrite(DB3, bitRead(data, 3));
  digitalWrite(DB4, bitRead(data, 4));
  digitalWrite(DB5, bitRead(data, 5));
  digitalWrite(DB6, bitRead(data, 6));
  digitalWrite(DB7, bitRead(data, 7));
}

/*
 * output the data to DB0..DB7
 */
void output_address(int address) {
  output_data(address);
  digitalWrite(P20, bitRead(address, 8));
  digitalWrite(P21, bitRead(address, 9));
  digitalWrite(P22, bitRead(address, 10));
}

/*
 * print error info
 */
void print_error(byte a_byte, int address) {
  Serial.print(F("\rERROR ---> address = "));
  Serial.print(address, HEX);
  Serial.print(F(" buffer byte = "));
  Serial.println(data_prog[address], HEX);
  Serial.print(F(" verified byte = "));
  Serial.println(a_byte, HEX);
}

/*
 * read/verify memory
 */
bool read_8748(bool to_buffer) {
  bool erased = true;
  digitalWrite(PROG_H, LOW);    // PROG floating
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(RESET, LOW);     // 0V
  digitalWrite(TEST0, LOW);     // address can be latched (and bus driven) only when programm mode active
  digitalWrite(EA_H, LOW);      // EA = 5V
  delayMicroseconds(100);       // 8748 needs at least 4 clock cycles (~20 uS) to process each change

  int max_chip_address = prog_size_8748*chip_type;
  //int high_address = max_chip_address; //highest_address < max_chip_address ? highest_address : max_chip_address;

  digitalWrite(EA_H, HIGH);     // EA = 21V for 874x HMOS (12V for 804x ROM, 25V for 8748 NMOS EPROM)

  for (int i=0; i<max_chip_address; i++) {
    byte one_byte = read_byte(i);
    if (to_buffer) { // read mode
      data_prog[i] = one_byte;
      if (data_prog[i] != 0) {
        erased = false;
      }
    } else { //verify mode
      if (data_prog[i] != one_byte) {
        Serial.print(F("Verify failed at address"));
        Serial.println(i, 16);
        break;
      }
    }
  }

  // Programmer should be at conditions of step 1 when 8748 is removed from socket.
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(TEST0, HIGH);    // 5V
  digitalWrite(EA_H, LOW);      // EA = 5V
  digitalWrite(PROG_H, LOW);    // PROG floating
  digitalWrite(RESET, LOW);     // 0V
  Serial.println(F("EPROM read successfully."));
  hex_file_loaded = true;

  return erased;
}

/*
 * read byte from address
 * param address
 */
byte read_byte(int address) {
  // Returns the EPROM byte at location "address".
  byte result;

  // make sure EA is high and PROG is floating (they should be anyway)
  /*digitalWrite(EA_H, HIGH);
  digitalWrite(PROG_H, LOW);
  delay(1);*/

  if (address > 0) {
      // put the address on the bus
      output_address(address);
      delayMicroseconds(100);

      // latch address in 8748
      digitalWrite(RESET, HIGH);
      delay(1);
  }

  // switch pins to input mode
  set_data_bus_direction(INPUT);

  // have 8748 put data on bus
  digitalWrite(TEST0, HIGH);
  delay(1);

  // read the data
  result = read_bus();

  // turn off read mode
  digitalWrite(RESET, LOW);
  digitalWrite(TEST0, LOW);
  delay(1);

  // put pins back into output mode
  set_data_bus_direction(OUTPUT);

  return result;
}

//--------------------------------------------------------------------------------------
void program_8748() {
  byte programmed_byte;
  bool error_flag = false;
  int max_chip_address = prog_size_8748*chip_type;
  Serial.print(F("programming ..."));

  // Steps are from datasheet programming instructions.  Steps 1 and 2 already done in setup().
  // Step 1: VDD=5V, oscillator operating, RESET=0V, TEST0=5V, EA=5V, BUS and PROG floating
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(RESET, LOW);     // 0V
  digitalWrite(TEST0, HIGH);    // 5V
  digitalWrite(EA_H, LOW);      // EA = 5V
  digitalWrite(PROG_H, LOW);    // PROG floating

  // Step 2: insert 8748/8749 in programming socket

  // Step 3: TEST0 = 0V (select program mode).
  digitalWrite(TEST0, LOW);
  delay(1);          // 8748 needs at least 4 clock cycles (~20 uS) to process each change

  // Step 4: EA = 18V (activate program mode),
  digitalWrite(EA_H, HIGH);
  delay(1);

  for (int i = 0; i < max_chip_address; i++) {
    if (data_prog[i] == 0) {                  // skip zero bytes
      continue;
    }
    // Step 5 (repeats from here for all program bytes): Address applied to BUS and P20-1.
    set_data_bus_direction(OUTPUT);

    output_address(i);
    delay(1);

    // Step 6: RESET = 5V (latch address).
    digitalWrite(RESET, HIGH);
    delay(1);

    // Step 7: Data applied to BUS.
    output_data(data_prog[i]);
    delay(1);

    // Step 8: VDD = 21V (programming power).
    digitalWrite(VDD_H, HIGH);
    // datasheet says no delay needed here.

    // Step 9: PROG = float followed by one 50 to 60 ms pulse to 18V.
    digitalWrite(PROG_H, HIGH);
    delay(PULSE_WIDTH);
    digitalWrite(PROG_H, LOW);
    // datasheet says no delay needed here.

    // Step 10: VDD = 5V.
    digitalWrite(VDD_H, LOW);
    delayMicroseconds(100);

    // Step 11: TEST0 = 5V (verify mode).
    digitalWrite(TEST0, HIGH);
    delay(1);

    // Step 12: Read and verify data on BUS.
    programmed_byte = read_byte(i);
    if (programmed_byte != data_prog[i]) {
      error_flag = true;
      print_error(programmed_byte, i);
      break;    // abort programming
    }

    // Step 13: TEST0 = 0V.
    digitalWrite(TEST0, LOW);
    delayMicroseconds(100);

    // Step 14:  RESET = OV and repeat from step 5.
    digitalWrite(RESET, LOW);
    delay(1);
  }

  // Step 15: Programmer should be at conditions of step 1 when 8748 is removed from socket.
  digitalWrite(TEST0, HIGH);    // 5V
  digitalWrite(RESET, LOW);     // 0V
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(PROG_H, LOW);
  digitalWrite(EA_H, LOW);      // EA = 5V

  if (error_flag) {
    Serial.println(F("Exited with ERROR!"));
  } else {
    Serial.println(F("EPROM programmed successfully."));
  }
}
