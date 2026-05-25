// =====================================================
//  TERRAIN SYNTH 3D
//  Funzione: f(x,z) = sin( ( z·sin z − x·sin x · log(z²+1) ) / a )
// =====================================================

float lastLow = -1, lastMid = -1, lastHigh = -1;
float lastLMX = -1, lastMHX = -1;
float lastFb = -1, lastDel = -1;
int lastType = -1;

// --- colori ---
final color BG      = #0c0b0a;
final color SURFACE = #161310;
final color ACCENT  = #4ade80;
final color AMBER   = #d946ef;

// --- layout ---
float PAD = 18, SIDE_W;
float viewX, viewY, viewW, viewH;
float leftX, rightX; // Tracks the starting X position of both panels

// --- mondo ---
PGraphics    view3D;
Terrain3D    terrain;
Orbit3D      orbit;
CameraRig    cam;
Oscilloscope scope;
Minimap      minimap;

// --- Left Panel Controls (Now 8 Faders - REVERB Removed) ---
HorizontalFader fMidDrive, fHighDrive, fLowDrive, fFeedback, fDelay, fType, fLMX, fMHX;

// --- Right Panel Controls (3 Faders) ---
HorizontalFader fScale, fRadius, fWaveTerrain;

// Global array groups for interface distribution loops
HorizontalFader[] leftFaders;
HorizontalFader[] rightFaders;
PFont font;

// --- network ---
OscNetworkManager net; // Global instance for the network tab

// --- stato ---
float phase = 0;
int   lastTime = 0;

void settings() {
  size(2500, 1500, P2D);
}

int lastW = -1, lastH = -1;

void setup() {
  surface.setLocation(0, 0);
  surface.setTitle("Terrain Synth 3D");
  font = createFont("Consolas", 32, true);

  terrain = new Terrain3D();
  orbit   = new Orbit3D();
  cam     = new CameraRig();
  scope   = new Oscilloscope(256);
  net     = new OscNetworkManager(this);   

  layout();
  lastTime = millis();
}

void layout() {
  PAD    = max(12, width * 0.012);
  SIDE_W = constrain(width * 0.24, 320, 500); 

  // --- DUAL PANEL VIEWPORT POSITIONING ---
  leftX  = PAD;
  viewX  = leftX + SIDE_W + PAD;
  viewW  = width - (SIDE_W * 2) - (4 * PAD); 
  viewH  = height - 2*PAD;
  rightX = viewX + viewW + PAD;
  
  view3D = createGraphics((int)viewW, (int)viewH, P3D);

  float gap = 14;
  float fy = PAD;
  
  // --- RESPONSIVE HEIGHT ALLOCATION ---
  float totalAvailableH = height - (2 * PAD) - (3 * gap);
  
  float scopeH       = totalAvailableH * 0.25; 
  float mapH         = totalAvailableH * 0.25; 
  float fadersTotalH = totalAvailableH * 0.5; 
  
  // --- SPACING MATH CONSTRAINTS ---
  float faderSpacingGap = 18.0; // Change this number to tweak spacing size in pixels
  
  // Subtract the total gaps (7 gaps between 8 faders) from the allocated panel area
  float leftFadersDrawH = fadersTotalH - (faderSpacingGap * 7);
  float fhLeft  = leftFadersDrawH / 8.0;    
  float fhRight = fadersTotalH / 3.0;    

  // --- BACKUP VALUES ---
  float sV   = fScale      != null ? fScale.getValue()       : 1.5;
  float rV   = fRadius     != null ? fRadius.getValue()      : 2.0;
  float wV   = fWaveTerrain!= null ? fWaveTerrain.getIntValue() : 1.0;
  float midV = fMidDrive   != null ? fMidDrive.getValue()    : 1.;
  float higV = fHighDrive  != null ? fHighDrive.getValue()   : 1.;
  float lowV = fLowDrive   != null ? fLowDrive.getValue()    : 1.; 
  float feeV = fFeedback   != null ? fFeedback.getValue()    : 0.;
  float delV = fDelay      != null ? fDelay.getValue()       : 1.;
  float typV = fType       != null ? fType.getIntValue()     : 0.;
  float lmxV = fLMX        != null ? fLMX.getValue()         : 20.; 
  float mhxV = fMHX        != null ? fMHX.getValue()         : 1000.0; 

  // --- INITIALIZE LEFT FADERS (With spacing step offset added to 'fy') ---
  fMidDrive  = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*0, SIDE_W, fhLeft, "MID DRIVE", 1.0, 250.0);
  fHighDrive = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*1, SIDE_W, fhLeft, "HIGH DRIVE", 1.0, 250.0);
  fLowDrive  = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*2, SIDE_W, fhLeft, "LOW DRIVE", 1.0, 250.0);
  fFeedback  = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*3, SIDE_W, fhLeft, "FEEDBACK", 0.0, 150.0);
  fDelay     = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*4, SIDE_W, fhLeft, "DELAY (ms)", 1.0, 250.0);
  fType      = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*5, SIDE_W, fhLeft, "TYPE SELECTOR", 0.0, 2.0); 
  fLMX       = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*6, SIDE_W, fhLeft, "LOW MIDDLE XOVER", 20.0, 1000.0);
  fMHX       = new HorizontalFader(leftX, fy + (fhLeft + faderSpacingGap)*7, SIDE_W, fhLeft, "HIGH MIDDLE XOVER", 1000.0, 20000.0);

  // --- INITIALIZE RIGHT FADERS ---
  fScale       = new HorizontalFader(rightX, fy + fhRight*0, SIDE_W, fhRight, "SCALE",  0.3, 5.0);
  fRadius      = new HorizontalFader(rightX, fy + fhRight*1, SIDE_W, fhRight, "RADIUS", 0.2, 6.0);
  fWaveTerrain = new HorizontalFader(rightX, fy + fhRight*2, SIDE_W, fhRight, "WAVE TERRAIN FUNCTION", 1.0, 4.0);
  
  leftFaders  = new HorizontalFader[] { fMidDrive, fHighDrive, fLowDrive, fFeedback, fDelay, fType, fLMX, fMHX };
  rightFaders = new HorizontalFader[] { fScale, fRadius, fWaveTerrain };
  
  color leftSideColor = color(240, 136, 80); 
  for (HorizontalFader f : leftFaders) {
    f.setAccentColor(leftSideColor);
  }

  fScale.setValue(sV); fRadius.setValue(rV); fWaveTerrain.setIntValue(wV);
  fMidDrive.setValue(midV); fHighDrive.setValue(higV); fLowDrive.setValue(lowV);
  fFeedback.setValue(feeV); fDelay.setValue(delV); fType.setIntValue(typV);
  fLMX.setValue(lmxV); fMHX.setValue(mhxV);

  // Position coordinates calculated dynamically
  float sy = fy + fadersTotalH + gap;
  float my = sy + scopeH + gap; 
  
  if (minimap == null) {
    minimap = new Minimap(rightX, my, SIDE_W, mapH);
  } else {
    minimap.updatePosition(rightX, my, SIDE_W, mapH); 
  }

  lastW = width; lastH = height;
  lastTime = millis();
}

void draw() {
  if (width != lastW || height != lastH) layout();

  int now = millis();
  float dt = (now - lastTime) / 1000.0;
  lastTime = now;

  terrain.setA(fScale.getValue());
  orbit.setRadius(fRadius.getValue());
  phase = (phase + TWO_PI * 0.5 * dt) % TWO_PI;
  
  int currentWave = fWaveTerrain.getIntValue(); 
  terrain.setWaveNumber(currentWave);
  
  checkAndSendOSC();

  background(BG);
  render3D();
  drawViewport();
  drawSidePanel();
}

void oscEvent(OscMessage msg) {
  if (net != null) net.parseIncoming(msg);
}

void checkAndSendOSC() {
  if (net == null) return;
  
  float vLow = fLowDrive.getValue();
  if (vLow != lastLow) { net.transmit("/fader/lowDrive", vLow); lastLow = vLow; }

  float vMid = fMidDrive.getValue();
  if (vMid != lastMid) { net.transmit("/fader/midDrive", vMid); lastMid = vMid; }

  float vHigh = fHighDrive.getValue();
  if (vHigh != lastHigh) { net.transmit("/fader/highDrive", vHigh); lastHigh = vHigh; }

  float vLMX = fLMX.getValue();
  if (vLMX != lastLMX) { net.transmit("/fader/lowMidFreq", vLMX); lastLMX = vLMX; }

  float vMHX = fMHX.getValue();
  if (vMHX != lastMHX) { net.transmit("/fader/midHighFreq", vMHX); lastMHX = vMHX; }

  float vFb = fFeedback.getValue();
  if (vFb != lastFb) { net.transmit("/fader/feedback", vFb); lastFb = vFb; }

  float vDel = fDelay.getValue();
  if (vDel != lastDel) { net.transmit("/fader/delay", vDel); lastDel = vDel; }

  int vType = fType.getIntValue();
  if (vType != lastType) { net.transmit("/fader/type", (float)vType); lastType = vType; }
}
