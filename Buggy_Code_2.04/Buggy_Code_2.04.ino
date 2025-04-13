#include <WiFiS3.h>
#include <PID_v1_bc.h>

//Network ID and Password
char ssid[] = "F";
char pass[] = "12345678";

//Starts the server on port 2444
WiFiServer server(2444);

// Motor PWM Pins
const int pwmpinL = 11;
const int pwmpinR = 10;

// Left motor forward and backward pins
const int fpinL = 8;
const int bpinL = 12;

// Right motor forward and backward pins
const int fpinR = 4;
const int bpinR = 9;

// Left and right IR Sensor pins
const int LEYE = 5;
const int REYE = 7;

// Left and right motor speeds
const double right_motor_speed = 80;                //90
const double left_motor_speed = right_motor_speed;  // * 1.1;  //105

// Echo and Trig pins for Ultrasonic Sensor
const int ECHO = A2;
const int TRIG = A0;

// Hall Sensor Pins
const int hall_left = 2;
const int hall_right = 3;

// Timeout for the Ultrasonic Sensor
const int TIMEOUT = 1000000;

//wheel encoder pulses
volatile int pulseCount = 0;
float wheelDiameter = 5.18;                         // Wheel diameter in cm
float wheelCircumference = 3.1416 * wheelDiameter;  // Circumference of wheel

//pid variables
double Setpoint = 45, Input, Output;
double Kp = 5, Ki = 0.5, Kd = 2;
//double Kp = 1.5, Ki = 0.2, Kd = 0.05;
//initialize pid
PID myPID(&Input, &Output, &Setpoint, Kp, Ki, Kd, REVERSE);

//iteration counter for loop
int count = 0;
//data variable for receiving data from client
String data;
//if the buggy is on or off
bool buggyStart = false;
//if the buggy is following an object
bool buggyfollow = false;
//buggy speed
double setSpeed = right_motor_speed;

void setup() {
  Serial.begin(9600);
  // WiFi Setup
  WiFi.begin(ssid, pass);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  server.begin();
  // Set pin modes
  pinMode(fpinL, OUTPUT);
  pinMode(bpinL, OUTPUT);
  pinMode(fpinR, OUTPUT);
  pinMode(bpinR, OUTPUT);
  pinMode(pwmpinL, OUTPUT);
  pinMode(pwmpinR, OUTPUT);
  pinMode(LEYE, INPUT);
  pinMode(REYE, INPUT);
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  pinMode(hall_left, INPUT_PULLUP);
  pinMode(hall_right, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(hall_left), countPulse, RISING);  // Interrupt on signal change
  attachInterrupt(digitalPinToInterrupt(hall_right), countPulse, RISING);
  myPID.SetMode(AUTOMATIC);
}

void loop() {
  WiFiClient client = server.available();
  //checks if client is connected
  if (client) {
    //checks if client is sending data
    if (client.available()) {
      data = client.readStringUntil('\n');
      if (data == "START") {
        buggyStart = true;
        Serial.println("STARTING");
      } else if (data == "STOP") {
        buggyStart = false;
        buggyfollow = false;
        stop();
        pulseCount = 0;
        Serial.println("STOPPING");
      } else if (data == "OBJECT") {
        //Setpoint = 45;
        buggyfollow = true;
        buggyStart = false;
        count = 0;
        Serial.println("FOLLOWING");
      } else if (data == "LINE") {
        buggyfollow = false;
        buggyStart = true;
        count = 0;
        Serial.println("NO LONGER FOLLOWING");
      } else if (data == "HIGH") {
        setSpeed = 105;
        //Setpoint = setSpeed;
      } else if (data == "MID") {
        setSpeed = right_motor_speed;
        //Setpoint = setSpeed;
      } else if (data == "LOW") {
        setSpeed = 70;
        //Setpoint = setSpeed;
      } else if (data == "OFF") {
        setSpeed = 0;
        //Setpoint = setSpeed;
      }
    } else {
      if (buggyStart) {
        line_follow(client);
        //US Sensors and Hall Sensors runs every 50th run of the loop function
        if (count == 150) {
          //gets the distance to the next object
          long d = distance_to_object();

          //stops if the distance is roughly less than 10cm, until object is cleared
          while (d < 30) {
            stop();
            delay(500);
            d = distance_to_object();
            client.write("STOPPED\n");
          }
          Input = setSpeed;
          myPID.Compute();
          setSpeed = constrain(Output, 50, 105);
          //reset  the count
          count = 0;
        } else if (count == 50) {
          travel_dist(client);
        }
        //increment count
        count++;
      }
      if (buggyfollow) {
        Input = (double)distance_to_object();

        if (count >= 50) {
          // Input = (double)distance_to_object();
          String dist = "Distance to Object: " + String(Input) + "\n";
          client.write(dist.c_str());
          count = 0;
        }

        myPID.Compute();
        Serial.println(Output);
        setSpeed = constrain(Output, 50, 105);

        line_follow(client);

        count++;
      }
    }
  }
}

void go_forward() {
  analogWrite(pwmpinL, setSpeed);
  analogWrite(pwmpinR, setSpeed);
  digitalWrite(fpinL, HIGH);
  digitalWrite(bpinL, LOW);
  digitalWrite(fpinR, HIGH);
  digitalWrite(bpinR, LOW);
}

void go_back() {
  digitalWrite(fpinL, LOW);
  digitalWrite(bpinL, HIGH);
  digitalWrite(fpinR, LOW);
  digitalWrite(bpinR, HIGH);
}

void stop() {
  digitalWrite(fpinL, LOW);
  digitalWrite(bpinL, LOW);
  digitalWrite(fpinR, LOW);
  digitalWrite(bpinR, LOW);
}

void turn_left() {
  analogWrite(pwmpinL, 0);
  analogWrite(pwmpinR, 90);  //90
}

void turn_right() {
  analogWrite(pwmpinR, 0);
  analogWrite(pwmpinL, 95);  //105 95
}

void line_follow(WiFiClient client) {

  bool cur_val_LEYE = digitalRead(LEYE);
  bool cur_val_REYE = digitalRead(REYE);

  if (cur_val_LEYE == HIGH && cur_val_REYE == HIGH) {
    go_forward();
    client.write("FORWARD\n");
  } else if (cur_val_LEYE == LOW && cur_val_REYE == HIGH) {
    turn_left();
    client.write("LEFT\n");
  } else if (cur_val_LEYE == HIGH && cur_val_REYE == LOW) {
    turn_right();
    client.write("RIGHT\n");
  } else {
    stop();
    client.write("STOPPED\n");
  }
}

long distance_to_object() {
  long duration;
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  duration = pulseIn(ECHO, HIGH, TIMEOUT);
  return (duration / 2) / 29.1;
}

void countPulse() {
  pulseCount++;  // Increment count each time a magnet passes
}

unsigned long t1 = 0;
unsigned long t2 = 0;
float s = 0;

void travel_dist(WiFiClient client) {
  t1 = millis();
  float revolutions = pulseCount / 6;
  float distanceTraveled = revolutions * wheelCircumference;
  if (t2 - t1 >= 1000) {
    t2 = millis();
    s = distanceTraveled - s;
    s = abs(s / 10);
    String cmps = "Buggy Speed: " + String(s) + "\n";
    client.write(cmps.c_str());
    s = distanceTraveled;
  }
  String msg = "Distance Traveled: " + String(distanceTraveled) + "\n";  // Convert float to string
  client.write(msg.c_str());                                             // Send string as char array
}