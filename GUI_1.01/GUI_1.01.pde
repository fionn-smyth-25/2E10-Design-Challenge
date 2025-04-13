import processing.net.*;

Client myClient;
String data = "";
String prev_data = "";
PFont f;
boolean buggyStart = false;
String distance = "0";

int circleX, circleY;
int circleSize = 93;
color circleColor, baseColor;
color circleHighlight;
boolean circleOver = false;

int stopX, stopY;
int stopSize = 93;
color stopColor, stopHighlight;
boolean stopOver = false;

int count;

void setup() {
  size(700, 700);
  background(0);

  // Network setup
  myClient = new Client(this, "192.168.160.212", 2444);
  myClient.write("I am a new client\n");

  // Font setup
  f = createFont("Impact", 48);
  textFont(f);

  // Button colors
  circleColor = color(0, 255, 0);
  circleHighlight = color(0, 204, 0);

  stopColor = color(255, 0, 0);
  stopHighlight = color(204, 0, 0);

  baseColor = color(102);

  // Button positions
  circleX = width / 2;
  circleY = height / 2 - 100;  // Move start button higher

  stopX = width / 2;
  stopY = height / 2 + 100;  // Stop button lower

  ellipseMode(CENTER);
}

void draw() {
  background(baseColor);

  if (buggyStart) {
    update_position();
  } else {
    starting_up();
  }
}

void starting_up() {
  update(mouseX, mouseY);

  // Draw Start Button
  if (circleOver) {
    fill(circleHighlight);
  } else {
    fill(circleColor);
  }
  stroke(0);
  ellipse(circleX, circleY, circleSize, circleSize);
  fill(0);
  textSize(20);
  text("START", circleX - 25, circleY + 5);
}

void update(int x, int y) {
  circleOver = overCircle(circleX, circleY, circleSize);
  stopOver = overCircle(stopX, stopY, stopSize);
}

void mousePressed() {
  if (circleOver) {  // Start button clicked
    buggyStart = true;
    myClient.write("1\n");
  }

  if (stopOver) {  // Stop button clicked
    buggyStart = false;
    distance = "0";
    myClient.write("4\n");  // Send stop command
  }
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  return sqrt(sq(disX) + sq(disY)) < diameter / 2;
}

void drawArrow(int cx, int cy, int len, float angle) {
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0, 0, len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}

void update_position() {
  update(mouseX, mouseY);

  // Draw Stop Button
  if (stopOver) {
    fill(stopHighlight);
  } else {
    fill(stopColor);
  }
  stroke(0);
  ellipse(stopX, stopY, stopSize, stopSize);
  fill(0);
  textSize(20);
  text("STOP", stopX - 20, stopY + 5);

  // Read Data from Server
  if (myClient.available() > 0) {
    String newData = myClient.readStringUntil('\n');
    if (newData != null) {
      newData = newData.trim();
      data = newData;
    }
    count++;
  }

  if (data != prev_data) {
    fill(255);
    textSize(25);
    strokeWeight(2);
    println(data);
    text("Distance Travelled: " + distance + "cm", 150, 150);

    if (data.equals("1")) {
      stroke(255, 0, 0);
      drawArrow(350, 350, 150, -90);
      text("Going Forward", 150, 100);
    } else if (data.equals("2")) {
      stroke(255, 0, 0);
      drawArrow(350, 350, 150, -180);
      text("Going Left", 150, 100);
    } else if (data.equals("3")) {
      stroke(255, 0, 0);
      drawArrow(350, 350, 150, 0);
      text("Going Right", 150, 100);
    } else if (data.equals("4")) {
      text("Stopped: Off track", 150, 100);
    } else if (data.equals("5")) {
      text("Stopped: Object blocking path", 150, 100);
    } else {
      distance = data;
    }
  }

  if (count == 30) {
    prev_data = data;
  }
}
