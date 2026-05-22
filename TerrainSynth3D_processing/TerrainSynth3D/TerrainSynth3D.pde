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
float PAD = 18, SIDE_W = 460;
float viewX, viewY, viewW, viewH;

// --- mondo ---
PGraphics    view3D;
Terrain3D    terrain;
Orbit3D      orbit;
CameraRig    cam;
Oscilloscope scope;
Minimap      minimap;
HorizontalFader fScale, fRadius, fSpeed;
HorizontalFader[] faders;
PFont font;

// --- network ---
OscNetworkManager net; // Global instance for the network tab

// --- stato ---
float phase = 0;
int   lastTime = 0;

void settings() {
  java.awt.Rectangle b = java.awt.GraphicsEnvironment
      .getLocalGraphicsEnvironment().getMaximumWindowBounds();
  size(b.width, b.height, P2D);
}

void setup() {
  surface.setLocation(0, 0);
  surface.setTitle("Terrain Synth 3D");
  font = createFont("Consolas", 32, true);

  viewX = PAD; viewY = PAD;
  viewW = width - SIDE_W - 3*PAD;
  viewH = height - 2*PAD;
  view3D = createGraphics((int)viewW, (int)viewH, P3D);

  terrain = new Terrain3D();
  orbit   = new Orbit3D();
  cam     = new CameraRig();
  scope   = new Oscilloscope(256);

  // 3 fader + scope + minimap (niente più header)
  float px = viewX + viewW + PAD;
  float gap = 14, scopeH = 150, mapH = 240;
  float fy = PAD;
  float fh = (height - fy - PAD - scopeH - mapH - 2*gap) / 3.0;

  fScale  = new HorizontalFader(px, fy + fh*0, SIDE_W, fh, "SCALE",  0.3, 5.0);
  fRadius = new HorizontalFader(px, fy + fh*1, SIDE_W, fh, "RADIUS", 0.2, 6.0);
  fSpeed = new HorizontalFader(px, fy + fh*2, SIDE_W, fh, "SPEED", 0.1, 4.0);
  faders  = new HorizontalFader[] { fScale, fRadius, fSpeed };
  fScale.setValue(1.5); fRadius.setValue(2.0); fSpeed.setValue(1.0);

  float my = fy + 3*fh + gap + scopeH + gap;
  minimap = new Minimap(px, my, SIDE_W, mapH);

  // Initialize independent connection links right before clock time capture
  net = new OscNetworkManager(this);

  lastTime = millis();
}

void draw() {
  int now = millis();
  float dt = (now - lastTime) / 1000.0;
  lastTime = now;

  terrain.setA(fScale.getValue());
  orbit.setRadius(fRadius.getValue());
  phase = (phase + TWO_PI * fSpeed.getValue() * dt) % TWO_PI;

  background(BG);
  render3D();
  drawViewport();
  drawSidePanel();
}

// Global router forwards network packets directly to your manager tab
void oscEvent(OscMessage msg) {
  if (net != null) net.parseIncoming(msg);
}
