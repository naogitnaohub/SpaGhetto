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
  float gap = 14;
  float fy  = PAD;
  
  float totalAvailableH = height - (2 * PAD) - (3 * gap);
  float scopeH       = totalAvailableH * 0.25; 
  float mapH         = totalAvailableH * 0.25; 
  float fadersTotalH = totalAvailableH * 0.50;

  // ==========================================
  //  RENDER LEFT SIDE PANEL (Faders Only)
  // ==========================================
  noStroke(); fill(SURFACE);
  rect(leftX, fy, SIDE_W, fadersTotalH); 
  
  for (HorizontalFader f : leftFaders) f.render();

  // ==========================================
  //  RENDER RIGHT SIDE PANEL (Faders + Graphs)
  // ==========================================
  noStroke(); fill(SURFACE);
  rect(rightX, fy, SIDE_W, fadersTotalH); 
  
  for (HorizontalFader f : rightFaders) f.render();

  // Draw Oscilloscope Box
  float sy = fy + fadersTotalH + gap;
  noStroke(); fill(SURFACE);
  rect(rightX, sy, SIDE_W, scopeH);
  scope.render(rightX + 18, sy + 18, SIDE_W - 36, scopeH - 36, terrain, orbit, phase);

  // Draw Minimap Box
  float my = sy + scopeH + gap;
  noStroke(); fill(SURFACE);
  rect(rightX, my, SIDE_W, mapH);
  
  minimap.updatePosition(rightX, my, SIDE_W, mapH);
  minimap.render(terrain, orbit);
}
