// =====================================================
//  TERRAIN SYNTH 3D

// =====================================================

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

// --- Left Panel Controls (Now 6 Faders) ---
HorizontalFader fMidDrive, fHighDrive, fFeedback, fDelay, fType, fReverb;

// --- Right Panel Controls (Now 3 Faders) ---
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
  size(displayWidth, displayHeight - 60, P2D);
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
  
  // UPDATED COUNTS: Left has 6 faders, Right has 3 faders now!
  float fhLeft  = fadersTotalH / 6.0;    
  float fhRight = fadersTotalH / 3.0;    

  // --- BACKUP VALUES ---
  float sV   = fScale      != null ? fScale.getValue()       : 1.5;
  float rV   = fRadius     != null ? fRadius.getValue()      : 2.0;
  float pV   = fReverb     != null ? fReverb.getValue()      : 1.0;
  float wV   = fWaveTerrain!= null ? fWaveTerrain.getIntValue() : 1.0;
  float midV = fMidDrive   != null ? fMidDrive.getValue()    : 0.2;
  float higV = fHighDrive  != null ? fHighDrive.getValue()   : 0.1;
  float feeV = fFeedback   != null ? fFeedback.getValue()    : 0.3;
  float delV = fDelay      != null ? fDelay.getValue()       : 250.0;
  float typV = fType       != null ? fType.getIntValue()     : 1.0;

  // --- INITIALIZE LEFT FADERS (All on leftX, divided by fhLeft) ---
  fMidDrive  = new HorizontalFader(leftX, fy + fhLeft*0, SIDE_W, fhLeft, "MID DRIVE", 0.0, 1.0);
  fHighDrive = new HorizontalFader(leftX, fy + fhLeft*1, SIDE_W, fhLeft, "HIGH DRIVE", 0.0, 1.0);
  fFeedback  = new HorizontalFader(leftX, fy + fhLeft*2, SIDE_W, fhLeft, "FEEDBACK", 0.0, 1.0);
  fDelay     = new HorizontalFader(leftX, fy + fhLeft*3, SIDE_W, fhLeft, "DELAY (ms)", 0.0, 1000.0);
  fType      = new HorizontalFader(leftX, fy + fhLeft*4, SIDE_W, fhLeft, "TYPE SELECTOR", 1.0, 4.0);
  fReverb    = new HorizontalFader(leftX, fy + fhLeft*5, SIDE_W, fhLeft, "REVERB",  0.1, 4.0); // Moved to leftX

  // --- INITIALIZE RIGHT FADERS (All on rightX, divided by fhRight) ---
  fScale       = new HorizontalFader(rightX, fy + fhRight*0, SIDE_W, fhRight, "SCALE",  0.3, 5.0);
  fRadius      = new HorizontalFader(rightX, fy + fhRight*1, SIDE_W, fhRight, "RADIUS", 0.2, 6.0);
  fWaveTerrain = new HorizontalFader(rightX, fy + fhRight*2, SIDE_W, fhRight, "WAVE TERRAIN FUNCTION", 1.0, 4.0);
  
    // --- DEFINE BOTH ARRAYS CORRECTLY ---
  leftFaders  = new HorizontalFader[] { fMidDrive, fHighDrive, fFeedback, fDelay, fType, fReverb };
  rightFaders = new HorizontalFader[] { fScale, fRadius, fWaveTerrain };
  
  // --- NEW COLOR ASSIGNMENT FOR LEFT PANEL ---
 
  color leftSideColor = color(240, 136, 80); 
  for (HorizontalFader f : leftFaders) {
    f.setAccentColor(leftSideColor);
    
  }

  
  // Restore values
  fScale.setValue(sV); fRadius.setValue(rV); fReverb.setValue(pV); fWaveTerrain.setIntValue(wV);
  fMidDrive.setValue(midV); fHighDrive.setValue(higV); fFeedback.setValue(feeV); fDelay.setValue(delV); fType.setIntValue(typV);

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

  background(BG);
  render3D();
  drawViewport();
  drawSidePanel();
}

void oscEvent(OscMessage msg) {
  if (net != null) net.parseIncoming(msg);
}
