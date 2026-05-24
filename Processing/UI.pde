// Disegno della scena 3D e dell'interfaccia 2D.

void render3D() {
  cam.update();
  view3D.beginDraw();
  view3D.background(BG);
  cam.apply(view3D);
  view3D.ambientLight(60, 60, 55);
  view3D.directionalLight(220, 220, 200, 0.5, -0.85, -0.35);
  terrain.render(view3D);
  orbit.render(view3D, terrain, phase);
  view3D.endDraw();
}

void drawViewport() {
  noStroke(); fill(SURFACE);
  rect(viewX - 4, viewY - 4, viewW + 8, viewH + 8);
  image(view3D, viewX, viewY);
}

void drawSidePanel() {
  float x   = viewX + viewW + PAD;
  float gap = 14, scopeH = 150, mapH = 240;
  float fy  = PAD;
  float fh  = (height - fy - PAD - scopeH - mapH - 2*gap);

  noStroke(); fill(SURFACE);
  rect(x, fy, SIDE_W, fh);
  for (HorizontalFader f : faders) f.render();

  float sy = fy + fh + gap;
  noStroke(); fill(SURFACE);
  rect(x, sy, SIDE_W, scopeH);
  scope.render(x + 18, sy + 18, SIDE_W - 36, scopeH - 36, terrain, orbit, phase);

  float my = sy + scopeH + gap;
  noStroke(); fill(SURFACE);
  rect(x, my, SIDE_W, mapH);
  minimap.render(terrain, orbit);
}
