#include <EEPROM.h>
#include <SPI.h>
#include <WiFiNINA.h>
#include <ArduinoHttpClient.h>
#include <Servo.h>
#include "wifi_setup.h"

#define SERVO_PIN 9
#define SERVO_START 120
#define SERVO_END 90
#define ONE_SECOND 1000L
#define ONE_MINUTE ONE_SECOND * 60L
#define RESET_DELAY 500

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

unsigned long lastConnectionTime = 0;

const unsigned long postingInterval = 10L * 1000L;

HttpClient client = HttpClient(wifi, server, 80);

void attachWifi() {
  while (WL_CONNECTED != WiFi.status()) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);

    WiFi.begin(ssid, pass);

    delay(8L * ONE_SECOND);
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

  servo.attach(SERVO_PIN);

  servo.write(SERVO_START);

  lastHash = readEString(STORAGE_ADDRESS);

  attachWifi();
}

void loop() {
  Serial.print("Current hash: ");
  Serial.println(lastHash);
  
  httpRequest();

  if (HTTP_OK != httpStatus) {
    digitalWrite(LED_BUILTIN, HIGH);

    Serial.print("Error: ");
    Serial.println(httpStatus);

    delay(ONE_MINUTE * 5L);

    attachWifi();
  } else {
    digitalWrite(LED_BUILTIN, LOW);
  }

  delay(ONE_MINUTE * 3L);
}

void hitGong() {
  servo.write(SERVO_END);
  delay(RESET_DELAY);
  servo.write(SERVO_START);
}

void httpRequest() {
  client.get("/");

  httpStatus = client.responseStatusCode();
  String response = client.responseBody();

  client.get("/?returnedStatus=" + httpStatus + "&previousHash=" + lastHash + "&nextHash=" + response + "&different=" + (lastHash != response));

  if (HTTP_OK == httpStatus && lastHash != response) {
    writeEString(STORAGE_ADDRESS, response);
    lastHash = response;
    hitGong();
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
