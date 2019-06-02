/*
 * simple menu system over serial port
 */
 #define TYPEUNDEF -1
 #define TYPE48 1
 #define TYPE49 2

bool check_chip_seated() {
  Serial.println(F("Do you see BOTH ALE LEDs lit on?"));
  do {
    byte_received = get_char();
  } while((byte_received != 'Y') && (byte_received != 'y') &&
          (byte_received != 'N') && (byte_received != 'n'));
  return byte_received == 'Y' || byte_received == 'y';
}

bool menu_program() {
  if (chip_type == -1) {
    Serial.println(F("Chip type not set"));
    return false;
  }
  if (hex_file_loaded == false) {
    Serial.println(F("Hex file not loaded"));
    return false;
  }
  program_8748();
  return true;
}

void set_chip_type() {
  Serial.println(F("Press 1 for 8748 with 1kB EPROM or 2 for 8749 with 2kB EPROM"));
  do {
    byte_received = get_char();
  } while((byte_received != (char)(TYPE48+'0')) && (byte_received != (char)(TYPE49+'0')));

  if (byte_received == '1') {
    chip_type = TYPE48;
  } else {
    chip_type = TYPE49;
  }
  Serial.print(F("Chip type set to "));
  Serial.println(chip_type == TYPE48 ? F("8748") : F("8749"));
}


void menu_setup() {
  print_menu();
}

char get_char() {
  while (!Serial.available() > 0) {
    ;
  }
  int byte_in = Serial.read();
  char p =char(byte_in);
  if (isLowerCase(p)) {
    p = toupper(p);
  }
  return p;
}

 void print_menu() {
  Serial.println(F("\n\nINTEL 8748/8749 programmer V1.0.0"));
  Serial.println(F("Press: C to set chip type"));
  Serial.println(F("       T to jump to test pins and voltages submenu"));
  Serial.println(F("       L to load HEX file from PC to data buffer"));
  Serial.println(F("       H to send data buffer as HEX file to PC"));
  Serial.println(F("       P to program data buffer to chip"));
  Serial.println(F("       R to read chip code memory to data buffer"));
  Serial.println(F("       V to verify chip memory for match with data buffer"));
 }

void menu_loop() {
  last_byte_received = byte_received;
  byte_received = get_char();
  /*Serial.print(F("byte_received:"));
  Serial.print((byte)byte_received);
  Serial.print(F(", last byte_received:"));
  Serial.println((byte)last_byte_received);*/
  bool valid_choice = true;
  if(byte_received == 'C') {
    set_chip_type();
  } else if(byte_received == 'P') {
    menu_program();
  } else if(byte_received == 'T') {
    test_submenu();
  } else if(byte_received == 'H') {
    send_hex();
  } else if(byte_received == 'L') {
    load_hex();
  } else if(byte_received == 'R') {
    menu_read();
  } else if(byte_received == 'V') {
    menu_verify();
  } else {
    valid_choice = false;
  }
  if (valid_choice) {
      print_menu();
      last_byte_received = 10; // mark menu as printed
  }
}

