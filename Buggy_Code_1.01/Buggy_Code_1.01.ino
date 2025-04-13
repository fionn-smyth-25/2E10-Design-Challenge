//Motor PWM Pins
const int pwmpinL = 11;
const int pwmpinR = 10;

//Left motor foward and backwards pins
const int fpinL = 8;
const int bpinL = 12;

//Right motor foward and backwards pins
const int fpinR = 4;
const int bpinR = 9;

//Left and right IR Sensor pins
const int LEYE = 5;
const int REYE = 7;

//Left and right motor speeds, left is faster to prevent drifting
const int right_motor_speed = 135; 
const int left_motor_speed = 150; 

//Echo and Trig pins for the US Sensor
const int ECHO = A2;
const int TRIG = A0;

//Timeout for the US Sensor 
const int TIMEOUT = 1000000;

void setup() {
  //Initialize serial port and all pins
  Serial.begin(9600);
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
}

//count for the US sensor 
int count = 0;

void loop() {
  //Calls line following function
  line_follow();

  //US Sensor runs every 100th run of the loop function 
  if (count >= 100) {
    //gets the distance to the next object
    long d = distance_to_object();

    //stops if the distance is roughly less than 10cm, until object is cleared 
    while (d < 30) {
      stop();
      delay(500);
      d = distance_to_object();
    }

    //reset  the count
    count = 0;
  }

  //increment count
  count++;
}

void go_forward() {
  analogWrite(pwmpinL, left_motor_speed);
  analogWrite(pwmpinR, right_motor_speed);
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
  analogWrite(pwmpinR, 90);

  analogWrite(pwmpinL, left_motor_speed);
  analogWrite(pwmpinR, right_motor_speed);
}

void turn_right() {
  analogWrite(pwmpinR, 0);
  analogWrite(pwmpinL, 110);
  analogWrite(pwmpinR, right_motor_speed);
  analogWrite(pwmpinL, left_motor_speed);
}

void line_follow() 
{
  bool cur_val_LEYE = digitalRead(LEYE);
  bool cur_val_REYE = digitalRead(REYE);
  if (cur_val_LEYE == HIGH && cur_val_REYE == HIGH) {
    go_forward();
  }
  else if (cur_val_LEYE == LOW && cur_val_REYE == HIGH) {
    turn_left();
  }
  else if (cur_val_LEYE == HIGH && cur_val_REYE == LOW) {
    turn_right();
  }
  else {
    stop();
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
  return (duration/2) / 29.1;
}
