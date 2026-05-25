// =====================================================
//  TERRAIN SYNTH 3D
//  Funzione: f(x,z) = sin( ( z·sin z − x·sin x · log(z²+1) ) / a )
// =====================================================

// --- colori ---
final color BG      = #0c0b0a;
final color SURFACE = #161310;
final color ACCENT  = #4ade80;
final color AMBER   = #d946ef;

// --- layout ---
float PAD = 18, SIDE_W;
float viewX, viewY, viewW, viewH;

// --- mondo ---
PGraphics    view3D;
Terrain3D    terrain;
Orbit3D      orbit;
CameraRig    cam;
Oscilloscope scope;
Minimap      minimap;
HorizontalFader fScale, fRadius, fSpeed, fWaveTerrain;
HorizontalFader[] faders;
PFont font;

// --- network ---
OscNetworkManager net; // Global instance for the network tab

// --- stato ---
float phase = 0;
int   lastTime = 0;

void settings() {
  // displayWidth/Height = dimensione reale dello schermo
  // -60 lascia spazio alla taskbar
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
  net     = new OscNetworkManager(this);   // <-- qui

  layout();
  lastTime = millis();
}

void layout() {
  PAD    = max(12, width * 0.012);
  SIDE_W = constrain(width * 0.28, 380, 600);

  viewX = PAD; viewY = PAD;
  viewW = width - SIDE_W - 3*PAD;
  viewH = height - 2*PAD;
  view3D = createGraphics((int)viewW, (int)viewH, P3D);

  float px = viewX + viewW + PAD;
  float gap = 14;
  float fy = PAD;
  
  // --- RESPONSIVE HEIGHT ALLOCATION ---
  // Subtract paddings and spacing gaps from total screen height
  float totalAvailableH = height - (2 * PAD) - (3 * gap);
  
  float scopeH = totalAvailableH * 0.25; // Oscilloscope gets 25% of the space
  float mapH   = totalAvailableH * 0.25; // Minimap gets 40% of the space
  float fadersTotalH = totalAvailableH * 0.5; // Faders share the remaining 35%
  float fh     = fadersTotalH / 4.0;    // Divided equally among 4 fader rows

  // Preserve existing slider values if already initialized
  float sV = fScale  != null ? fScale.getValue()  : 1.5;
  float rV = fRadius != null ? fRadius.getValue() : 2.0;
  float pV = fSpeed  != null ? fSpeed.getValue()  : 1.0;
  float wV = fWaveTerrain != null ? fWaveTerrain.getIntValue() : 1.0;

  fScale  = new HorizontalFader(px, fy + fh*0, SIDE_W, fh, "SCALE",  0.3, 5.0);
  fRadius = new HorizontalFader(px, fy + fh*1, SIDE_W, fh, "RADIUS", 0.2, 6.0);
  fSpeed  = new HorizontalFader(px, fy + fh*2, SIDE_W, fh, "SPEED",  0.1, 4.0);
  fWaveTerrain = new HorizontalFader(px, fy + fh*3, SIDE_W, fh, "WAVE TERRAIN FUNCTION", 1.0, 4.0);
  
  faders  = new HorizontalFader[] { fScale, fRadius, fSpeed, fWaveTerrain };
  fScale.setValue(sV); fRadius.setValue(rV); fSpeed.setValue(pV); fWaveTerrain.setIntValue(wV);

  // Position coordinates calculated dynamically
  float sy = fy + (fh * 4) + gap;
  float my = sy + scopeH + gap; 
  
  if (minimap == null) {
    minimap = new Minimap(px, my, SIDE_W, mapH);
  } else {
    minimap.updatePosition(px, my, SIDE_W, mapH); // Push updates to the map container
  }

  lastW = width; lastH = height;
  lastTime = millis();
}


void draw() {
  // ricalcola layout se la finestra è stata ridimensionata
  if (width != lastW || height != lastH) layout();

  int now = millis();
  float dt = (now - lastTime) / 1000.0;
  lastTime = now;

  terrain.setA(fScale.getValue());
  orbit.setRadius(fRadius.getValue());
  phase = (phase + TWO_PI * fSpeed.getValue() * dt) % TWO_PI;
  
  int currentWave = fWaveTerrain.getIntValue(); 
  terrain.setWaveNumber(currentWave);

  background(BG);
  render3D();
  drawViewport();
  drawSidePanel();
}

// Global router forwards network packets directly to your manager tab
void oscEvent(OscMessage msg) {
  if (net != null) net.parseIncoming(msg);
}
