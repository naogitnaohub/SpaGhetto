import oscP5.*;
import netP5.*;

// ============================================================================
// GLOBAL NETWORKING CONTEXT
// ============================================================================
OscP5 oscP5;            // Listens for incoming messages from JUCE
NetAddress juceAddress; // Stores destination ip/port to send data back to JUCE

final int PORT_IN  = 9001; // Port where JUCE sends data
final int PORT_OUT = 9002; // Port where JUCE listens for data
final String IP_LOCAL = "127.0.0.1";

// ============================================================================
// Initialization of Audio Data controls
// ============================================================================
float valDryWet = 0.5;
float valDrive  = 0.2;
float valCutoff = 0.7;
float valVolume = 0.8;

int waveSelectorIndex = 0;
float incomingWaveSample = 0.0;

// Storage array to draw the waveform 
float[] scopeBuffer = new float[150];

// ============================================================================
// CORE 
// ============================================================================
void setup() {
  size(850, 450);
  
  // Initialize bidirectional network links
  initNetworkOSC();
  
  // Zero out the oscilloscope tracking data buffer memory
  for (int i = 0; i < scopeBuffer.length; i++) {
    scopeBuffer[i] = 0.0;
  }
}

void draw() {
  background(15, 18, 25);
  
  // 1. Draw the interactive parameters on screen
  drawFaderModule(50,  "Dry / Wet", valDryWet, color(0, 160, 255));
  drawFaderModule(140, "Drive",     valDrive,  color(255, 130, 0));
  drawFaderModule(230, "Cutoff",    valCutoff, color(180, 50, 255));
  drawFaderModule(320, "Volume",    valVolume, color(0, 220, 120));
  
  // 2. Draw the visual wave type index block tracker
  drawWaveIndexModule(420, 100, 70, 200);

  // 3. Render the dynamic screen and live oscilloscope engine
  drawOscilloscopeModule(520, 100, 280, 200);
  
  // 4. Advance sample tracking arrays
  updateOscilloscopeHistory();
}

// ============================================================================
// NETWORK SETUP AND INITIALIZATION 
// ============================================================================
void initNetworkOSC() {
  // Start the server to listen on inbound port channel mapping
  oscP5 = new OscP5(this, PORT_IN);
  
  // Define destination socket mapping properties
  juceAddress = new NetAddress(IP_LOCAL, PORT_OUT);
}

// ============================================================================
// IN OSC ROUTING HANDLER (JUCE -> Processing)
// ============================================================================
void oscEvent(OscMessage msg) {
  String pattern = msg.addrPattern();
  
  // Verify safety bounds before trying to parse the float index payload
  if (msg.arguments().length == 0) return;

  if (pattern.equals("/juce/drywet")) {
    valDryWet = msg.get(0).floatValue();
  } 
  else if (pattern.equals("/juce/drive")) {
    valDrive = msg.get(0).floatValue();
  } 
  else if (pattern.equals("/juce/cutoff")) {
    valCutoff = msg.get(0).floatValue();
  } 
  else if (pattern.equals("/juce/volume")) {
    valVolume = msg.get(0).floatValue();
  } 
  else if (pattern.equals("/juce/selector")) {
    waveSelectorIndex = int(msg.get(0).floatValue());
  } 
  else if (pattern.equals("/juce/waveform")) {
    incomingWaveSample = msg.get(0).floatValue();
  }
}

// ============================================================================
// OUT OSC MESSAGING HANDLER (Processing -> JUCE)
// ============================================================================
void transmitParameterToJuce(String addressPattern, float parameterValue) {
  OscMessage messagePacket = new OscMessage(addressPattern);
  messagePacket.add(parameterValue);
  
  // Dispatch bundle safely over port socket configuration link
  oscP5.send(messagePacket, juceAddress);
}

// ============================================================================
// MOUSE INTERACTION AND DRAG 
// ============================================================================
void mouseDragged() {
  // Bound check mouse to only process if clicking inside the vertical fader bounds
  if (mouseY >= 100 && mouseY <= 300) {
    float normalizedValue = map(mouseY, 300, 100, 0.0, 1.0);
    normalizedValue = constrain(normalizedValue, 0.0, 1.0);

    // Filter which column container was selected based on mouse horizontal alignment
    if (mouseX >= 50 && mouseX <= 95) {
      valDryWet = normalizedValue;
      transmitParameterToJuce("/processing/drywet", valDryWet);
    } 
    else if (mouseX >= 140 && mouseX <= 185) {
      valDrive = normalizedValue;
      transmitParameterToJuce("/processing/drive", valDrive);
    } 
    else if (mouseX >= 230 && mouseX <= 275) {
      valCutoff = normalizedValue;
      transmitParameterToJuce("/processing/cutoff", valCutoff);
    } 
    else if (mouseX >= 320 && mouseX <= 365) {
      valVolume = normalizedValue;
      transmitParameterToJuce("/processing/volume", valVolume);
    }
  }
}

// ============================================================================
// RENDERING FUNCTIONS
// ============================================================================
void drawFaderModule(int x, String label, float value, color fillCol) {
  noStroke();
  fill(30, 35, 45);
  rect(x, 100, 45, 200, 4); // Track bounding frame path
  
  fill(fillCol);
  rect(x, 300, 45, -value * 200); // Dynamic variable adjustment height filling
  
  fill(255);
  textSize(12);
  text(label + "\n" + nf(value, 1, 2), x, 325);
}

void drawWaveIndexModule(int x, int y, int w, int h) {
  noStroke();
  fill(35, 40, 50);
  rect(x, y, w, h, 4);
  
  fill(220, 50, 80);
  rect(x, y + h, w, -(waveSelectorIndex / 3.0f) * h); 
  
  fill(255);
  text("Wave Index\n      [" + waveSelectorIndex + "]", x + 2, y + h + 25);
}

void drawOscilloscopeModule(int x, int y, int w, int h) {
  // Apply visual background hue mapping depending on selected wave index setting
  if (waveSelectorIndex == 0)      fill(0, 120, 255, 25);   // Blue glow: Sine
  else if (waveSelectorIndex == 1) fill(255, 40, 40, 25);   // Red glow: Square
  else if (waveSelectorIndex == 2) fill(255, 200, 0, 25);   // Gold glow: Saw
  else                             fill(0, 255, 140, 25);   // Emerald glow: Triangle
  
  noStroke();
  rect(x, y, w, h, 6); // Screen mask backdrop boundary frame

  // Render vector geometry line connection vertex mapping string sequence array
  stroke(255);
  strokeWeight(2.5);
  noFill();
  beginShape();
  for (int i = 0; i < scopeBuffer.length; i++) {
    float drawX = map(i, 0, scopeBuffer.length, x, x + w);
    float drawY = (y + h/2) + (scopeBuffer[i] * (h/2.5));
    vertex(drawX, drawY);
  }
  endShape();
}

void updateOscilloscopeHistory() {
  // Shift register cells over one slot index to create left scroll effect
  for (int i = 0; i < scopeBuffer.length - 1; i++) {
    scopeBuffer[i] = scopeBuffer[i+1];
  }
  scopeBuffer[scopeBuffer.length - 1] = incomingWaveSample;
}
