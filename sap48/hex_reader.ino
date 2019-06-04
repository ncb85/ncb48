/**
 *   Intel HEX file reader
 */
#define HEX_RECORD 0
#define EOF_RECORD 1

unsigned long highest_address;

/*
 * convert two hex characters into a byte
 */
byte hex_conv (char *pstr) {
  if (!isxdigit (pstr [0]) || !isxdigit (pstr [1])) {
    Serial.println (F("Invalid hex digits"));
    Serial.flush();
    return -1;
  }

  byte b = *pstr++ - '0';
  if (b > 9) { // A-F
    b -= 7;
  }
  // high-order nybble
  b <<= 4;

  byte b1 = *pstr++ - '0';
  if (b1 > 9) {
    b1 -= 7;
  }
  b |= b1; // low order nybble

  return b;
}

char *get_two_digits() {
  for (int i=0; i<2; i++) {
    byte_received = get_char();
    hexbuff[i] = byte_received;
  }
  hexbuff[2] = '\0';
  return hexbuff;
}

/*
 * returns false if error
 */
bool read_line() {
  unsigned int line_length, highest_line_address, rec_type, checksum, filechksum, address;
  int wrong_count = 0;
  // line start
  while ((byte_received = get_char())!= ':') { //skip newlines
    wrong_count++;
    if (wrong_count > 5) {
     Serial.print(F("Record does not start with colon!"));
     Serial.flush();
     return false;
    }
  }
  // length
  line_length = hex_conv(get_two_digits());
  checksum = line_length;
  // address
  address = hex_conv(get_two_digits());
  checksum += address;
  address *= 256;
  address += hex_conv(get_two_digits());
  checksum += address%256;
  highest_line_address = address+line_length-1;
  rec_type = hex_conv(get_two_digits());
  // highest address
  if ((rec_type != EOF_RECORD) && (highest_address < highest_line_address)) {
    highest_address = highest_line_address;
  }
  // record type
  if (rec_type != HEX_RECORD && rec_type != EOF_RECORD) {
     return false;
  }
  // check chip address range
  int max_chip_address = prog_size_8748*chip_type;
  if (highest_address > max_chip_address) {
      Serial.print(F("Record max address is beyond chip program size!"));
      Serial.print(highest_address);
      Serial.flush();
      return false;
  }
  // data
  for (int i=0; i<line_length; i++) {
    data_prog[address+i] = hex_conv(get_two_digits());
    checksum += data_prog[address+i];
  }

  // sumcheck
  if (line_length > 0 && rec_type == HEX_RECORD) {
    filechksum = hex_conv(get_two_digits());
    if (checksum > 256) {
      checksum = checksum % 256;
    }
    checksum = 256 - checksum;
    checksum = checksum % 256;
    if (checksum == filechksum) {
      Serial.print(".");
    } else {
      Serial.print(F("Bad checksum! "));
      Serial.print(checksum);
      Serial.print(F(","));
      Serial.print(filechksum);
      Serial.flush();
      return false;
    }
  } else {
    while((byte_received = get_char()) == 'F'); //skip last bytes of file
    hex_file_loaded = true;
  }
  return true;
}

bool load_hex() {
  if (!check_chip_type()) {
    return;
  }
  int lineNumber = 0;
  highest_address = 0;
  hex_file_loaded = false;
  Serial.println(F("Waiting for HEX file"));
  Serial.flush();
  while (!hex_file_loaded) {
    if (!read_line()) {
      Serial.print(F(" - line number: "));
      Serial.println(lineNumber);
      Serial.flush();
      break;
    }
    lineNumber++;
  }
  Serial.println(F("\r\nHex file loaded"));
  Serial.print(F("Highest address: "));
  Serial.println(highest_address);
  Serial.flush();
}
