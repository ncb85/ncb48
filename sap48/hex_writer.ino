/*
 * Intel HEX file writer
 */


char *bin_to_hex(unsigned int value, int digits) {
  int i,j,k;
  char p;
  hexbuff[0] = '\0'; // terminate string
  if (value > 65536 || value < 0 || digits > 4 || digits < 1) {
    return hexbuff;
  }
  // convert to hex
  for (i=0; i<digits; i++) {
    p = value % 16;
    if (p > 9) {
      p += 65-10; // 'A'
    } else {
      p += 48; // '0'
    }
    hexbuff[i] = (char)p;
    value /= 16;
  }
  hexbuff[i] = '\0'; // terminate string
  // reverse string
  for(j=0, k=i-1; j<k; j++, k--) {
    p = hexbuff[k];
    hexbuff[k] = hexbuff[j];
    hexbuff[j] = p;
  }
  
  return hexbuff;
}

void send_hex() {
  int line_length, checksum;
  int max_chip_address = prog_size_8748*chip_type;
  int high_address = max_chip_address; //highest_address < max_chip_address ? highest_address : max_chip_address;
  if (!check_chip_type()) {
    return;
  }
  for (int i=0; i<high_address;) {
    line_length = (i < (high_address-16)) ? 16 : high_address-i; // or less on last line
    checksum = line_length;
    Serial.print(F(":")); // line start
    Serial.print(bin_to_hex(line_length, 2)); // data length
    Serial.print(bin_to_hex(i, 4)); // address
    checksum += i/256;
    checksum += i%256;
    Serial.print(F("00")); // record type
    for (int j=0; j<line_length; j++) {
      Serial.print(bin_to_hex(data_prog[i+j], 2));
      checksum += data_prog[i+j];
    }
    Serial.println(bin_to_hex(256-(checksum%256), 2));
    i += line_length;
    Serial.flush();
  }
  Serial.println(F(":00000001FF")); // end of file
  Serial.flush();
}

