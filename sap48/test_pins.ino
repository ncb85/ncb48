
void test_submenu() {
  Serial.println(F("REMOVE the chip before proceeding"));
  Serial.println(F("Check there is no MICROCONTROLLER in programming socket!!"));
  Serial.println(F("Press D for data pin test or V programming voltages test"));
  do {
    byte_received = get_char();
  } while((byte_received != 'D') && (byte_received != 'V'));
  if ((byte_received == 'D')) {
    test_data_pins();
  } else {
    test_voltages();
  }
  // put pins back into floating mode
  set_data_bus_direction(INPUT);
}

void test_data_pins() {
  Serial.println(F("Press 0..9 or A for data pins D0..D7,P20,P21 or P22 function test"));
  do {
    byte_received = get_char();
  } while(!((byte_received >= '0') && (byte_received <= '9'))
       && !(byte_received == 'A'));
  if (byte_received == 'A') {
    byte_received = 'a'; //convert do lower case
  }
  if (byte_received == 'a') { // P22
    byte_received = 10;
  } else {
    byte_received -= '0'; // binary
  }
  test_data_pin(byte_received);
}

void test_data_pin(int pin_number) {
  byte val = LOW;
  Serial.print(F("Measure voltage on pin: "));
  print_pin_name(pin_number);
  Serial.println(F("It will go HIGH and LOW 5 times"));
  // set data pins to output
  set_data_bus_direction(OUTPUT);
  for (int i=0; i<11; i++) {
    val = i%2 ? HIGH : LOW;
    switch(pin_number) {
      case 0:
        digitalWrite(DB0, val);
        break;
      case 1:
        digitalWrite(DB1, val);
        break;
      case 2:
        digitalWrite(DB2, val);
        break;
      case 3:
        digitalWrite(DB3, val);
        break;
      case 4:
        digitalWrite(DB4, val);
        break;
      case 5:
        digitalWrite(DB5, val);
        break;
      case 6:
        digitalWrite(DB6, val);
        break;
      case 7:
        digitalWrite(DB7, val);
        break;
      case 8:
        digitalWrite(P20, val);
        break;
      case 9:
        digitalWrite(P21, val);    
        break;
      case 10:
        digitalWrite(P22, val);    
        break;
    }
    delay(600);
  }
  Serial.println(F("end of pin test"));
}

void test_voltages() {
  Serial.println(F("PROG must be 18V"));
  Serial.println(F("EA must be 5V"));
  Serial.println(F("VDD must be 5V"));
  Serial.println(F("Check the PROG LED is on."));
  digitalWrite(EA_H, LOW);      // EA = 5V
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(PROG_H, HIGH);    // PROG 18V

  Serial.println(F("Press Y to continue to EA pin test\n"));
  do {
    byte_received = get_char();
  } while(byte_received != 'Y');
        
  Serial.println(F("PROG must be floating"));
  Serial.println(F("EA must be 18V"));
  Serial.println(F("VDD must be 5V"));
  digitalWrite(EA_H, HIGH);      // EA = 18V
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(PROG_H, LOW);    // PROG floating

  Serial.println(F("Press Y to continue to VDD pin test\n"));
  do {
    byte_received = get_char();
  } while(byte_received != 'Y');
  
  Serial.println(F("PROG must  be floating"));
  Serial.println(F("EA must be 5V"));
  Serial.println(F("VDD must be 21V"));
  digitalWrite(EA_H, LOW);      // EA = 5V
  digitalWrite(VDD_H, HIGH);     // VDD = 21V
  digitalWrite(PROG_H, LOW);    // PROG floating

  Serial.println(F("Press Y to end test and return to menu\n"));
  do {
    byte_received = get_char();
  } while(byte_received != 'Y');
  
  // set pins EA, PROGA and VDD low again
  digitalWrite(EA_H, LOW);      // EA = 5V
  digitalWrite(VDD_H, LOW);     // VDD = 5V
  digitalWrite(PROG_H, LOW);    // PROG floating
  Serial.println(F("It is safe to plug the MICROCONTROLLER into socket now."));
}

void print_pin_name(int pin_number) {
  switch (pin_number) {
    case 0:
      Serial.println(F("D0 - pin 12"));
      break;
    case 1:
      Serial.println(F("D1 - pin 13"));
      break;
    case 2:
      Serial.println(F("D2 - pin 14"));
      break;
    case 3:
      Serial.println(F("D3 - pin 15"));
      break;
    case 4:
      Serial.println(F("D4 - pin 16"));
      break;
    case 5:
      Serial.println(F("D5 - pin 17"));
      break;
    case 6:
      Serial.println(F("D6 - pin 18"));
      break;
    case 7:
      Serial.println(F("D7 - pin 19"));
      break;
    case 8:
      Serial.println(F("P2.0 - pin 21"));
      break;
    case 9:
      Serial.println(F("P2.1 - pin 22"));
      break;
    case 10:
      Serial.println(F("P2.2 - pin 23"));
      break;
    default:
      break;
  }
}

