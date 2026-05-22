// =====================================================
//  TERRAIN SYNTH 3D — pure visualization (no audio, no libs)
//  Processing 3.5+ / 4.x, P3D renderer.
// =====================================================

// ---------- palette ----------
final color BG          = #0c0b0a;
final color SURFACE     = #161310;
final color SURFACE_2   = #1d1915;
final color LINE        = #2a2620;
final color LINE_STRONG = #3a342c;
final color TEXT     = #b8f5c8;   // verde-crema chiaro
final color TEXT_DIM = #6a9a78;   // verde desaturato
final color TEXT_FAINT  = #534c41;
final color ACCENT      = #4ade80;   // glow green
final color ACCENT_SOFT = #1f8a4d;   // green più scuro

final float PAD = 18;
final float SIDE_W = 460;

// ---------- instances ----------
PGraphics    view3D;
Terrain3D    terrain;
Orbit3D      orbit;
CameraRig    cam;
Oscilloscope scope;

HorizontalFader fScale, fRadius, fSpeed;
HorizontalFader[] faders;

PFont fontMono, fontMonoBig;

// orbit phase, advanced by time
float phase = 0;

// camera drag state
boolean dragInView = false;
float lastMx = 0, lastMy = 0;
float downX = 0, downY = 0;
int   downTime = 0;
boolean autoBtnHover = false;
int   lastFrameTime = 0;

// viewport rect
float viewX, viewY, viewW, viewH;

float[] autoBtnRect = new float[4];

void settings() {
  size(1920, 1080, P2D);
  smooth(4);
}

void setup() {
  surface.setLocation(60, 40);
  surface.setTitle("Terrain Synth 3D");

  fontMono    = createFont("Menlo", 11, true);
  fontMonoBig = createFont("Menlo", 14, true);

  // layout
  viewX = PAD; viewY = PAD;
  viewW = width - SIDE_W - 3 * PAD;
  viewH = height - 2 * PAD;
  view3D = createGraphics((int)viewW, (int)viewH, P3D);

  // 3D
  terrain = new Terrain3D();
  orbit   = new Orbit3D();
  cam     = new CameraRig();
  scope   = new Oscilloscope(256);

  // faders — only 3 now: SCALE (terrain), RADIUS (orbit), SPEED (rotation Hz)
  float panelX   = viewX + viewW + PAD;
  float panelW   = SIDE_W;
  float headerH  = 92;
  float scopeH   = 150;
  float readoutH = 110;
  float gap      = 14;
  float fy       = PAD + headerH + gap;
  float availH   = height - 2*PAD - headerH - scopeH - readoutH - 3*gap;
  float secH     = availH / 3.0;

  fScale  = new HorizontalFader(panelX, fy + secH*0, panelW, secH, "SCALE",  0.3, 5.0, "linear", "%.2f");
  fRadius = new HorizontalFader(panelX, fy + secH*1, panelW, secH, "RADIUS", 0.2, 6.0, "linear", "%.2f");
  fSpeed  = new HorizontalFader(panelX, fy + secH*2, panelW, secH, "SPEED",  0.1, 6.0, "log",    "%.2f Hz");

  faders = new HorizontalFader[] { fScale, fRadius, fSpeed };
  fScale.setValue(1.5);
  fRadius.setValue(2.0);
  fSpeed.setValue(1.0);

  lastFrameTime = millis();
}

void draw() {
  int now = millis();
  float dt = (now - lastFrameTime) / 1000.0;
  lastFrameTime = now;

  // push params
  terrain.setA(fScale.getValue());
  orbit.setRadius(fRadius.getValue());

  // advance traveller phase
  phase = (phase + TWO_PI * fSpeed.getValue() * dt) % TWO_PI;

  background(BG);
  drawAppBackground();

  // ---------- 3D viewport ----------
  cam.update(dt);

  view3D.beginDraw();
  view3D.background(BG);
  view3D.smooth(4);
  cam.apply(view3D);

  view3D.ambientLight(50, 47, 42);
  view3D.directionalLight(225, 215, 200,  0.55, -0.85, -0.35);
view3D.directionalLight(50, 180, 100, -0.55, -0.15, 0.65);
  view3D.lightSpecular(120, 120, 120);
  view3D.specular(40);
  view3D.shininess(6);

  terrain.render(view3D);
  orbit.renderOrbit(view3D, terrain);
  orbit.renderTraveller(view3D, terrain, phase, 0);

  view3D.endDraw();

  drawCard(viewX - 4, viewY - 4, viewW + 8, viewH + 8);
  image(view3D, viewX, viewY);
  drawMapHUD();

  drawSidePanel();
}

// =================== UI ===================

void drawAppBackground() {
  noStroke();
  fill(24, 22, 19);
  rect(0, 0, width, 60);
  fill(20, 18, 16);
  rect(0, height - 60, width, 60);
}

void drawCard(float x, float y, float w, float h) {
  noStroke();
  fill(SURFACE);
  rect(x, y, w, h, 6);
  noFill();
  stroke(LINE);
  strokeWeight(1);
  rect(x + 0.5, y + 0.5, w - 1, h - 1, 6);
}

void drawMapHUD() {
  textFont(fontMono); textSize(16);
  String formula = "f(x,y) = sin( ( x sin x - y sin y log(x^2+1) ) / a )";
  pill(viewX + 14, viewY + 14, formula, TEXT_DIM, false);

  String autoTxt = cam.autoRotate ? "CAM . AUTO" : "CAM . MANUAL";
  float aw = textWidth(autoTxt) + 18;
  pill(viewX + viewW - 14 - aw, viewY + 14, autoTxt,
       cam.autoRotate ? ACCENT : TEXT_DIM, autoBtnHover);
  autoBtnRect[0] = viewX + viewW - 14 - aw;
  autoBtnRect[1] = viewY + 14;
  autoBtnRect[2] = aw;
  autoBtnRect[3] = 22;

  if (frameCount < 300) {
    String hint = "CLICK to place orbit  .  DRAG to rotate  .  SCROLL to zoom";
    float fade = 1.0 - constrain((frameCount - 240) / 60.0, 0, 1);
    float hw = textWidth(hint) + 24;
    float hx = viewX + viewW * 0.5 - hw * 0.5;
    float hy = viewY + viewH - 36;
    noStroke();
    fill(12, 11, 10, 200 * fade);
    rect(hx, hy, hw, 22, 3);
    noFill(); stroke(LINE, 255 * fade); rect(hx + 0.5, hy + 0.5, hw - 1, 21, 3);
    fill(TEXT_DIM, 255 * fade);
    textAlign(CENTER, CENTER);
    text(hint, hx + hw/2, hy + 11);
  }

  drawAxes(viewX + 16, viewY + viewH - 76);
}

void pill(float x, float y, String s, color textColor, boolean hover) {
  float pw = textWidth(s) + 18;
  noStroke();
  fill(12, 11, 10, 200);
  rect(x, y, pw, 22, 3);
  noFill();
  stroke(hover ? ACCENT_SOFT : LINE);
  strokeWeight(1);
  rect(x + 0.5, y + 0.5, pw - 1, 21, 3);
  fill(textColor);
  textAlign(LEFT, CENTER);
  text(s, x + 9, y + 11);
}

void drawAxes(float x, float y) {
  pushStyle();
  stroke(ACCENT_SOFT);
  strokeWeight(1);
  line(x + 10, y + 50, x + 50, y + 50);  // X
  line(x + 10, y + 50, x + 10, y + 10);  // Y
  stroke(ACCENT_SOFT, 150);
  line(x + 10, y + 50, x + 32, y + 32);  // Z
  textFont(fontMono); textSize(9);
  fill(TEXT_DIM);
  textAlign(LEFT, CENTER);
  text("X", x + 52, y + 50);
  text("Y", x + 4,  y + 8);
  text("Z", x + 34, y + 30);
  popStyle();
}

void drawSidePanel() {
  float x  = viewX + viewW + PAD;
  float w  = SIDE_W;
  float gap = 14;
  float hh  = 92;
  float scopeH = 150;
  float readoutH = 110;

  // header
  drawCard(x, PAD, w, hh);
  drawHeader(x, PAD, w, hh);

  // faders container
  float fy = PAD + hh + gap;
  float fh = height - 2*PAD - hh - scopeH - readoutH - 3*gap;
  drawCard(x, fy, w, fh);
  for (HorizontalFader f : faders) f.render();

  // waveform card (signal along orbit, one period)
  float sy = fy + fh + gap;
  drawCard(x, sy, w, scopeH);
  textFont(fontMono); textSize(10);
  fill(TEXT_DIM);
  textAlign(LEFT, TOP);
  text("ORBIT WAVEFORM", x + 18, sy + 14);
  textAlign(RIGHT, TOP);
  fill(TEXT_FAINT);
  text("1 PERIOD", x + w - 18, sy + 14);
  scope.render(x + 18, sy + 36, w - 36, scopeH - 50, terrain, orbit, phase);

  // readout
  float ry = sy + scopeH + gap;
  drawCard(x, ry, w, readoutH);
  drawReadout(x, ry, w, readoutH);
}

void drawHeader(float x, float y, float w, float h) {
  float mx = x + 36, my = y + h * 0.5;
  noFill();
  stroke(ACCENT);
  strokeWeight(1);
  rectMode(CENTER);
  rect(mx, my, 32, 32, 3);
  line(mx - 13, my, mx + 13, my);
  line(mx, my - 13, mx, my + 13);
  rectMode(CORNER);
  noStroke();
  fill(ACCENT);
  ellipse(mx + 10, my - 10, 6, 6);

  textFont(fontMonoBig);
  fill(TEXT);
  textAlign(LEFT, BASELINE);
  text("TERRAIN VIEWER", mx + 32, my - 2);
  textFont(fontMono); textSize(10);
  fill(TEXT_FAINT);
  text("v3 . 3D FIELD VISUALIZER", mx + 32, my + 16);
}

void drawReadout(float x, float y, float w, float h) {
  float colW = w / 2.0;
  float py = y + 16;
  readoutCell(x + 18,        py,       "ORBIT CENTER",
              signed(orbit.cx) + ", " + signed(orbit.cz), TEXT);
  readoutCell(x + 18 + colW, py,       "PHASE",
              nf(phase, 0, 2) + " rad", ACCENT);
  readoutCell(x + 18,        py + 44,  "SCALE  a",
              nf(terrain.getA(), 0, 2), TEXT);
  readoutCell(x + 18 + colW, py + 44,  "RADIUS",
              nf(orbit.r, 0, 2), TEXT);
}
void readoutCell(float x, float y, String label, String val, color c) {
  textFont(fontMono); textSize(9);
  fill(TEXT_FAINT);
  textAlign(LEFT, TOP);
  text(label, x, y);
  textFont(fontMonoBig);
  fill(c);
  text(val, x, y + 16);
}
String signed(float v) { return (v >= 0 ? "+" : "-") + nf(abs(v), 0, 2); }

// =================== input ===================
boolean overViewport(float mx, float my) {
  return mx >= viewX && mx <= viewX + viewW && my >= viewY && my <= viewY + viewH;
}
boolean overAutoBtn(float mx, float my) {
  return mx >= autoBtnRect[0] && mx <= autoBtnRect[0] + autoBtnRect[2]
      && my >= autoBtnRect[1] && my <= autoBtnRect[1] + autoBtnRect[3];
}

void mouseMoved() {
  autoBtnHover = overAutoBtn(mouseX, mouseY);
}

void mousePressed() {
  downX = mouseX; downY = mouseY; downTime = millis();
  if (overViewport(mouseX, mouseY)) {
    dragInView = true;
    lastMx = mouseX; lastMy = mouseY;
    return;
  }
  if (overAutoBtn(mouseX, mouseY)) {
    cam.autoRotate = !cam.autoRotate;
    return;
  }
  for (HorizontalFader f : faders) f.checkMousePressed(mouseX, mouseY);
}

void mouseDragged() {
  if (dragInView) {
    float dx = mouseX - lastMx;
    float dy = mouseY - lastMy;
    if (abs(dx) + abs(dy) > 1) {
      cam.mouseDrag(dx, dy);
    }
    lastMx = mouseX; lastMy = mouseY;
    return;
  }
  for (HorizontalFader f : faders) f.checkMouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  if (dragInView) {
    float ddx = mouseX - downX, ddy = mouseY - downY;
    int   dt  = millis() - downTime;
    if (dt < 350 && (ddx*ddx + ddy*ddy) < 25) {
      PVector hit = cam.pickPlane(mouseX - viewX, mouseY - viewY, viewW, viewH);
      if (hit != null) {
        float margin = orbit.r;
        float bx = constrain(hit.x, -8 + margin, 8 - margin);
        float bz = constrain(hit.z, -8 + margin, 8 - margin);
        orbit.setPosition(bx, bz);
      }
    }
    dragInView = false;
  }
  for (HorizontalFader f : faders) f.release();

  // double-click reset
  for (HorizontalFader f : faders) {
    if (f.over(mouseX, mouseY) && (millis() - f.lastClick) < 350) f.reset();
    if (f.over(mouseX, mouseY)) f.lastClick = millis();
  }
}

void mouseWheel(MouseEvent e) {
  if (overViewport(mouseX, mouseY)) cam.mouseWheel(e.getCount());
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    cam.azimuth = PI * 0.25;
    cam.elevation = PI * 0.22;
    cam.distance = 19;
    cam.autoRotate = true;
  }
}
