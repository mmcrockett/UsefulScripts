#include <EEPROM.h>
#include <SPI.h>
#include <WiFiNINA.h>
#include <ArduinoHttpClient.h>
#include <Servo.h>
#include "wifi_setup.h"

#define SERVO_PIN 9
#define SERVO_START 135
#define SERVO_END 45
#define ONE_SECOND 1000L
#define ONE_MINUTE ONE_SECOND * 60L
#define RESET_DELAY 500L
#define RESET_DELAY_L RESET_DELAY * 4L

#define MAX_HASH_SIZE 64

#define STORAGE_ADDRESS 0
//#define SERIAL_CONNECTED true

char ssid[] = SECRET_SSID_W;
char pass[] = SECRET_PASS_W;

#define HTTP_OK 200

int httpStatus = HTTP_OK;

WiFiClient wifi;
Servo servo;

char server[] = "mikeduino.com";
String lastHash;

HttpClient client = HttpClient(wifi, server, 80);

void attachWifi() {
  while (WL_CONNECTED != WiFi.status()) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);

    WiFi.begin(ssid, pass);

    delay(ONE_SECOND * 30L);
  }

  printWifiStatus();
}

void setup() {
  #ifdef SERIAL_CONNECTED
  Serial.begin(9600);

  while (!Serial) {
  }
  #endif

  pinMode(LED_BUILTIN, OUTPUT);

  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    while (true);
  }

  lastHash = readEString(STORAGE_ADDRESS);

  attachWifi();

  hitGong();

  delay(ONE_MINUTE);
}

void loop() {
  Serial.print("Current hash: ");
  Serial.println(lastHash);
  
  httpRequest();

  if (HTTP_OK != httpStatus) {
    digitalWrite(LED_BUILTIN, HIGH);

    WiFi.end();

    Serial.print("Error: ");
    Serial.println(httpStatus);

    delay(ONE_MINUTE);

    attachWifi();
  } else {
    digitalWrite(LED_BUILTIN, LOW);
  }

  delay(ONE_MINUTE * 3L);
}

void hitGong() {
  servo.attach(SERVO_PIN);
  servo.write(SERVO_START);
  delay(RESET_DELAY_L);
  servo.write(SERVO_END);
  delay(RESET_DELAY);
  servo.write(SERVO_START);
  delay(RESET_DELAY_L);

  servo.detach();
}

void httpRequest() {
  client.get("/");

  httpStatus = client.responseStatusCode();
  String response = client.responseBody();

  if (HTTP_OK == httpStatus) {
    String data = "/?returnedStatus=";
    data.concat(httpStatus);
    data.concat("&previousHash=");
    data.concat(lastHash);
    data.concat("&nextHash=");
    data.concat(response);
    data.concat("&different=");
    data.concat(lastHash != response);

    client.get(data);

    if (lastHash != response) {
      writeEString(STORAGE_ADDRESS, response);
      lastHash = response;

      delay(ONE_SECOND * 5L);

      hitGong();
    }
  }
}

void writeEString(char loc,String data)
{
  int dSize = data.length();
  int i = 0;
  
  for(i = 0; i < dSize; ++i) {
    EEPROM.write(loc + i, data[i]);
  }
  
  EEPROM.write(loc + dSize,'\0');
}

String readEString(char loc)
{
  int i;
  char data[MAX_HASH_SIZE + 1];
  int len = 0;
  unsigned char k;
  
  k = EEPROM.read(loc);
  
  while(k != '\0' && len < MAX_HASH_SIZE) {    
    k = EEPROM.read(loc + len);
    data[len] = k;
    len++;
  }
  
  data[len]='\0';
  
  return String(data);
}

void printWifiStatus() {
  Serial.print("SSID: ");

  Serial.println(WiFi.SSID());
  
  IPAddress ip = WiFi.localIP();

  Serial.print("IP Address: ");
  Serial.println(ip);

  long rssi = WiFi.RSSI();
  
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");
}
