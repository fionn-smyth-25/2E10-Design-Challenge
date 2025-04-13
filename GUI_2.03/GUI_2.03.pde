import processing.net.*;

// ---OUTGOING FEEDBACK---
// "Start\n" : buggy start command
// "STOP\n" : buggy stop command
// "LINE\n" : line follow mode command
// "OBJECT\n" : object follow mode command
//
// "HIGH\n" : buggy highest speed command
// "MID\n" : buggy mid speed command
// "LOW\n" : buggy low speed command
// "OFF\n" : buggy lowest speed command (slider less than quarter way down, so basically off)

// ---INCOMING FEEDBACK---
//"FORWARD" → Going Forward
//"LEFT" → Turning Left
//"RiGHT" → Turning Right
//"STOPPED" → Stopped (off track) or Stopped (object blocking path)
//
//Contains "Distance Traveled:" → Distance traveled by buggy in cm
//
//Contains "Buggy Speed:" → Buggy speed in cm/s
//
//Contains "Distance to Object:" → Distance to object in cm

// CLIENT SETUP
Client myClient;

// INCOMING DATA FROM ARDUINO
String data = "";
String prev_data = "";

// FONT
PFont f;

// BUGGY HANDLING
boolean BUGGY = false; // tracks buggy logic state, buggy initially off
String distance_travelled = "0";
String distance_to_object = "0 cm";
String buggy_speed = "0 cm/s";

// SPEED SLDER
int slider_x = 75; // x pos of slider
int slider_y = 110;  // y pos of slider
int slider_width = 250;  // Length of the slider track
int slider_height = 60;  // Height of the slider track
int slider_handle_x = slider_x + (slider_width / 2);  // Position of the draggable handle
int handle_size = 40;    // Size of the handle
boolean dragging = false; // Track if the handle is being dragged
color slider_handle_colour = color(255, 255, 255);
color slider_handle_dragging_colour = color(230, 230, 230);
float slider_speed = 0;
float prev_slider_speed = 0;

// BACKGROUND COLOUR
color baseColor = color(90, 90, 90);

// GENERAL BUTTON SIZE, COLOUR
int button_size = 93;
color start_button_colour = color(0, 255, 0);
color start_button_highlight = color(0, 204, 0);
color stop_button_colour = color(255, 0, 0);
color stop_button_highlight = color(204, 0, 0);

// DIRECTION ARROWS COLOURS
color active_direction_colour = color(0, 255, 0); // green
color stopped_direction_colour = color(204, 0, 0); // red

// BUGGY START/STOP BUTTON POS, VARIABLES
int start_stop_button_x = 125;
int start_stop_button_y = 530;
boolean buggy_start_button_fade = false; //updated to true if mouse hovering over buggy start button
boolean buggy_stop_button_fade = false; //updated to true if mouse hovering over buggy stop button

// MODE SELECTION BUTTON
boolean mode = true; // true = line follow mode
// false = object follow mode
int mode_selection_button_x = 387;
int mode_selection_button_y = 560;
boolean mode_selection_start_button_fade = false; //updated to true if mouse hovering over mode selection start button
boolean mode_selection_stop_button_fade = false; //updated to true if mouse hovering over mode selection stop button


void setup() {
  // INITIALIZE SCREEN SIZE AND COLOUR
  size(1000, 650);
  background(baseColor);

  // NETWORK SETUP
  myClient = new Client(this, "192.168.79.212", 2444);

  // FONT SETUP
  f = createFont("Impact", 48);
  textFont(f);

  // BUGGY BOX DRAWING
  fill(40, 40, 40);
  rect(400, 25, 575, 400, 20); //grey square

  // BUGGY BODY DRAWING
  fill(50, 50, 200);
  rect(587, 140, 200, 275);

  // BUGGY WHEELS
  fill(0, 0, 0);
  rect(787, 165, 25, 100); //front right
  rect(562, 165, 25, 100); //front left

  // BUGGY IR SENSORS
  rect( 720, 125, 20, 15); //front right
  rect(637, 125, 20, 15); //front left

  // BUGGY BREADBOARD
  fill(230, 200, 70);
  rect(612, 150, 150, 100);

  // RED DIRECTION ARROWS
  fill(230, 200, 70);
  drawArrow(685, 110, 50, 270, stopped_direction_colour); // forward arrow
  drawArrow(540, 210, 50, 180, stopped_direction_colour); // left arrow
  drawArrow(830, 210, 50, 0, stopped_direction_colour); // right arrow

  // OBJECT DISTANCE READING BOX
  fill(40, 40, 40);
  rect(575, 450, 400, 75, 20);

  // DISTANCE TRAVELLED DISPLAY BOX
  fill(40, 40, 40);
  rect(575, 550, 400, 75, 20);

  // MODE SELECTION BUTTON BOX
  fill(40, 40, 40);
  rect(250, 450, 275, 175, 20);
  fill(255, 255, 255);
  textSize(30);
  text("Object Follow Mode:", 260, 500);

  // BUGGY START/STOP BUTTON BOX
  fill(40, 40, 40);
  rect(25, 450, 200, 175, 20);

  // REFERENCE SPEED CHOICE BOX
  fill(40, 40, 40);
  rect(25, 25, 350, 187, 20);
  fill(255, 255, 255);
  textSize(30);
  text("Buggy Speed Selection:", 60, 63);

  // REFERENCE SPEED DISPLAY BOX
  fill(40, 40, 40);
  rect(25, 237, 350, 187, 20);

  ellipseMode(CENTER);
}

//
// MAIN LOOP
//

void draw() {
  if (BUGGY) { // if BUGGY=true (buggy on), let it move
    // CHECK WHICH MODE BUGGY IN
    if (mode) // enter line follow mode
      lineFollow();
    else // enter object follow mode
    objectFollow();
  } else //else keep checking if BUGGY logic changed
  starting_up();
}

//
// BUGGY OFF
//

void starting_up() { //checks if BUGGY logic state changed from false to true by button click
  // RESET AFTER MOUSE CLICK
  buggy_stop_button_fade = false;

  // COVER UP MODE SELECTION BUTTON
  stroke(40, 40, 40); //outline background colour
  fill(40, 40, 40); //fill background colour
  ellipse(mode_selection_button_x, mode_selection_button_y, button_size, button_size); //button

  // COVER UP DISTANCE TO OBJECT
  fill(40, 40, 40);
  stroke(40, 40, 40);
  rect(575, 450, 400, 75, 20);
  
  // DRAW RED DIRECTION ARROWS
  fill(230, 200, 70);
  drawArrow(685, 110, 50, 270, stopped_direction_colour); // forward arrow
  drawArrow(540, 210, 50, 180, stopped_direction_colour); // left arrow
  drawArrow(830, 210, 50, 0, stopped_direction_colour); // right arrow
  
  // WRITE STOPPED ON BREADBOARD
  fill(230, 200, 70);
  rect(612, 150, 150, 100); // cover last stopped
  fill(204, 0, 0);
  textSize(30);
  text("Stopped", 635, 210); // write stopped
  
  // COVER UP BUGGY SPEED SLIDER
  stroke(40, 40, 40);
  fill(40, 40, 40);
  rect(60, 70, 300, 100);
  stroke(0);

  // REPORT DISTANCE TRAVELLED AS 0 cm
  stroke(40, 40, 40);
  fill(40, 40, 40);
  rect(575, 550, 400, 75, 20); // cover last distance
  fill(255, 255, 255);
  textSize(30);
  text("Distance Traveled: 0 cm", 600, 600); //report next distance

  // REPORT BUGGY SPEED AS 0 cm/s
  fill(40, 40, 40);
  stroke(40, 40, 40); //outline background colour
  rect(25, 237, 350, 187, 20);
  fill(255, 255, 255);
  textSize(30);
  text("Buggy Speed: 0 cm/s", 70, 340); //report next speed

  // CHECK IF MOUSE HOVERING OVER BUGGY START BUTTON
  buggy_start_button_fade = mouseHover(mouseX, mouseY, start_stop_button_x, start_stop_button_y);

  // DRAW BUGGY START BUTTON AS FADED OR NON FADED
  if (buggy_start_button_fade)
    fill(start_button_highlight);
  else
    fill(start_button_colour);
  stroke(0); //outline black
  ellipse(start_stop_button_x, start_stop_button_y, button_size, button_size); //button
  fill(0);
  textSize(20);
  text("START", start_stop_button_x - 25, start_stop_button_y + 5);
}

//
// BUGGY ON (MODE FUNCTIONS)
//

void lineFollow() {
  // RESET AFTER MOUSE CLICK
  buggy_start_button_fade = false;
  mode_selection_stop_button_fade = false;

  // CHECK IF MOUSE HOVERING OVER BUTTONS
  buggy_stop_button_fade = mouseHover(mouseX, mouseY, start_stop_button_x, start_stop_button_y);
  mode_selection_start_button_fade = mouseHover(mouseX, mouseY, mode_selection_button_x, mode_selection_button_y);

  // DRAW BUGGY STOP BUTTON AS FADED OR NON FADED
  if (buggy_stop_button_fade)
    fill(stop_button_highlight);
  else
    fill(stop_button_colour);
  stroke(0); //outline black
  ellipse(start_stop_button_x, start_stop_button_y, button_size, button_size); //button
  fill(0);
  textSize(20);
  text("STOP", start_stop_button_x - 25, start_stop_button_y + 5);

  // DRAW MODE SELECTION START BUTTON AS FADED OR NON FADED
  if (mode_selection_start_button_fade)
    fill(start_button_highlight);
  else
    fill(start_button_colour);
  stroke(0); //outline black
  ellipse(mode_selection_button_x, mode_selection_button_y, button_size, button_size); //button
  fill(0);
  textSize(20);
  text("START", mode_selection_button_x - 25, mode_selection_button_y + 5);

  // Draw slider track
  stroke(0);
  line(slider_x, slider_y, slider_x + slider_width, slider_y);

  // Draw slider handle
  if (dragging)
    fill(slider_handle_dragging_colour);  // Darker color when dragging
  else
    fill(slider_handle_colour);
  ellipse(slider_handle_x, slider_y, handle_size, handle_size);

  // MAP HANDLE POS TO SPEED VALUE (0 TO 100)
  slider_speed = map(slider_handle_x, slider_x, slider_x + slider_width, 0, 100);
  //println(slider_speed); //debug

  // SEND SELECTED SPEED BY SLIDER
  if (slider_speed != prev_slider_speed) {
    if (slider_speed > 75 ) 
      myClient.write("HIGH\n");
    else if (slider_speed <= 75 && slider_speed >= 50)
      myClient.write("MID\n");
    else if (slider_speed < 50 && slider_speed >= 25)
      myClient.write("LOW\n");
    else if (slider_speed < 25)
      myClient.write("OFF\n");
      
      prev_slider_speed = slider_speed;
  }

  // COVER UP DISTANCE TO OBJECT
  fill(40, 40, 40);
  stroke(40, 40, 40);
  rect(575, 450, 400, 75, 20);

  // READ DATA FROM SERVER
  if (myClient.available() > 0) {
    String newData = myClient.readStringUntil('\n');
    if (newData != null) {
      newData = newData.trim();
      data = newData;
    }
  }

  // BUGGY DIRECTION
  if (data.contains("RIGHT")) { // FORWARD
    drawArrow(685, 110, 50, 270, active_direction_colour); // green forward arrow
    drawArrow(540, 210, 50, 180, stopped_direction_colour); // red left arrow
    drawArrow(830, 210, 50, 0, stopped_direction_colour); // red right arrow
    fill(230, 200, 70);
    rect(612, 150, 150, 100); // cover stopped
  } else if (data.contains("LEFT")) { // LEFT
    drawArrow(685, 110, 50, 270, active_direction_colour); // green forward arrow
    drawArrow(540, 210, 50, 180, active_direction_colour); // green left arrow
    drawArrow(830, 210, 50, 0, stopped_direction_colour); // red right arrow
    fill(230, 200, 70);
    rect(612, 150, 150, 100); // cover stopped
  } else if (data.contains("FORWARD")) { // RIGHT
    drawArrow(685, 110, 50, 270, active_direction_colour); // green forward arrow
    drawArrow(540, 210, 50, 180, stopped_direction_colour); // red left arrow
    drawArrow(830, 210, 50, 0, active_direction_colour); // green right arrow
    fill(230, 200, 70);
    rect(612, 150, 150, 100); // cover stopped
  } else if (data.contains("STOPPED")) { // STOPPED, OFF TRACK
    drawArrow(685, 110, 50, 270, stopped_direction_colour); // red forward arrow
    drawArrow(540, 210, 50, 180, stopped_direction_colour); // red left arrow
    drawArrow(830, 210, 50, 0, stopped_direction_colour); // red right arrow
    fill(204, 0, 0);
    textSize(25);
    text("Stopped", 645, 190); // write stopped
    text("for Object", 635, 220); // for object
  }
  
  // Distance Traveled
  if (data.contains("Distance Traveled:")) {
    stroke(40, 40, 40);
    fill(40, 40, 40);
    rect(575, 550, 400, 75, 20); // cover last distance
    fill(255, 255, 255);
    textSize(30);
    text(data, 600, 600); //report next distance
  }
  
  // BUGGY SPEED
  if (data.contains("Buggy Speed:")) {
    fill(40, 40, 40);
    stroke(40, 40, 40); //outline background colour
    rect(25, 237, 350, 187, 20);
    fill(255, 255, 255);
    textSize(30);
    text(data + "cm/s", 65, 340); //report next speed
  }
}

void objectFollow() {
  // RESET AFTER MOUSE CLICK
  buggy_start_button_fade = false;
  mode_selection_start_button_fade = false;

  // CHECK IF MOUSE HOVERING OVER BUTTONS
  buggy_stop_button_fade = mouseHover(mouseX, mouseY, start_stop_button_x, start_stop_button_y);
  mode_selection_stop_button_fade = mouseHover(mouseX, mouseY, mode_selection_button_x, mode_selection_button_y);

  // DRAW BUGGY STOP BUTTON AS FADED OR NON FADED
  if (buggy_stop_button_fade)
    fill(stop_button_highlight);
  else
    fill(stop_button_colour);
  stroke(0); //outline black
  ellipse(start_stop_button_x, start_stop_button_y, button_size, button_size); //button
  fill(0);
  textSize(20);
  text("STOP", start_stop_button_x - 25, start_stop_button_y + 5);

  // DRAW MODE SELECTION STOP BUTTON AS FADED OR NON FADED
  if (mode_selection_stop_button_fade)
    fill(stop_button_highlight);
  else
    fill(stop_button_colour);
  stroke(0); //outline black
  ellipse(mode_selection_button_x, mode_selection_button_y, button_size, button_size); //button
  fill(0);
  textSize(20);
  text("STOP", start_stop_button_x - 25, start_stop_button_y + 5);

  // COVER UP BUGGY SPEED SLIDER
  stroke(40, 40, 40);
  fill(40, 40, 40);
  rect(60, 70, 300, 100);
  stroke(0);

  // READ DATA FROM SERVER
  if (myClient.available() > 0) {
    String newData = myClient.readStringUntil('\n');
    if (newData != null) {
      newData = newData.trim();
      data = newData;
    }
  }

  // BUGGY DIRECTION
  if (data.contains("RIGHT")) { // FORWARD
    drawArrow(685, 110, 50, 270, active_direction_colour); // green forward arrow
    drawArrow(540, 210, 50, 180, stopped_direction_colour); // red left arrow
    drawArrow(830, 210, 50, 0, stopped_direction_colour); // red right arrow
    fill(230, 200, 70);
    rect(612, 150, 150, 100); // cover stopped
  } else if (data.contains("LEFT")) { // LEFT
    drawArrow(685, 110, 50, 270, active_direction_colour); // green forward arrow
    drawArrow(540, 210, 50, 180, active_direction_colour); // green left arrow
    drawArrow(830, 210, 50, 0, stopped_direction_colour); // red right arrow
    fill(230, 200, 70);
    rect(612, 150, 150, 100); // cover stopped
  } else if (data.contains("FORWARD")) { // RIGHT
    drawArrow(685, 110, 50, 270, active_direction_colour); // green forward arrow
    drawArrow(540, 210, 50, 180, stopped_direction_colour); // red left arrow
    drawArrow(830, 210, 50, 0, active_direction_colour); // green right arrow
    fill(230, 200, 70);
    rect(612, 150, 150, 100); // cover stopped
  } else if (data.contains("STOPPED")) { // STOPPED, OFF TRACK
    drawArrow(685, 110, 50, 270, stopped_direction_colour); // red forward arrow
    drawArrow(540, 210, 50, 180, stopped_direction_colour); // red left arrow
    drawArrow(830, 210, 50, 0, stopped_direction_colour); // red right arrow
    fill(204, 0, 0);
    textSize(25);
    text("Stopped", 645, 190); // write stopped
    text("for Object", 635, 220); // for object
  }

  // Distance Traveled
  if (data.contains("Distance Traveled:")) {
    stroke(40, 40, 40);
    fill(40, 40, 40);
    rect(575, 550, 400, 75, 20); // cover last distance
    fill(255, 255, 255);
    textSize(30);
    text(data + " cm", 600, 600); //report next distance
  }

  // BUGGY SPEED
  if (data.contains("Buggy Speed:")) {
    fill(40, 40, 40);
    stroke(40, 40, 40); //outline background colour
    rect(25, 237, 350, 187, 20);
    fill(255, 255, 255);
    textSize(30);
    text(data + " cm/s", 65, 340); //report next speed
  }

  // DISTANCE TO AN OBJECT
  if (data.contains("Distance to Object:")) {
    fill(40, 40, 40);
    strokeWeight(0);
    rect(575, 450, 400, 75, 20); //cover last distance
    fill(255, 255, 255);
    textSize(30);
    strokeWeight(2);
    text(data + " cm", 600, 500); //print next distance
  }
}


//
// MOUSE FUNCTIONS
//

void mousePressed() {
  // BUGGY START/STOP BUTTON
  if (buggy_start_button_fade) {  // Buggy start button clicked
    BUGGY = true;
    myClient.write("START\n"); // Send buggy start command
  }
  if (buggy_stop_button_fade) {  // Buggy stop button clicked
    BUGGY = false;
    distance_travelled = "0"; // zero distance
    myClient.write("STOP\n");  // Send buggy stop command
  }

  // MODE SELECTION BUTTON
  if (mode_selection_start_button_fade && BUGGY) { // Mode selection start button clicked and buggy on
    mode = false;
    myClient.write("OBJECT\n"); // Send line follow mode selection command
  }
  if (mode_selection_stop_button_fade && BUGGY) { // Mode selection stop button clicked and buggy on
    mode = true;
    myClient.write("LINE\n"); // Send object follow mode selection command
  }

  // SPEED SLIDER
  if (dist(mouseX, mouseY, slider_handle_x, slider_y) < handle_size / 2)
    dragging = true;
}
void mouseDragged() {
  if (dragging)
    slider_handle_x = constrain(mouseX, slider_x, slider_x + slider_width); // Move handle within slider limits
}

void mouseReleased() {
  dragging = false;  // Stop dragging when mouse is released
}

boolean mouseHover (int mouse_x, int mouse_y, int button_x, int button_y) { //returns true if mouse hovering over pos (button_x, button_y), given mouse_x = mouseX and  mouse_y = mouseY
  float disX = button_x - mouse_x;
  float disY = button_y - mouse_y;
  return sqrt(sq(disX) + sq(disY)) < button_size / 2;
}


//
// SHAPE DRAWING FUNCTIONS
//

void drawArrow(int cx, int cy, int len, float angle, color arrow_colour) {
  stroke(arrow_colour);
  strokeWeight(9); // Thicker outline for visibility
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0, 0, len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();

  //RESET STROKE AND WEIGHT
  stroke(0);
  strokeWeight(1);
}
