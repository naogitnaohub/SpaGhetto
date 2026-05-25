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
  float gap = 14;
  float fy  = PAD;
  
  // --- MATCH DYNAMIC LAYOUT MATH EXACTLY ---
  float totalAvailableH = height - (2 * PAD) - (3 * gap);
  
  float scopeH = totalAvailableH * 0.25; 
  float mapH   = totalAvailableH * 0.25; 
  float fadersTotalH = totalAvailableH * 0.5;
  float fh     = fadersTotalH / 4.0;

  // Draw the background block behind all faders
  noStroke(); fill(SURFACE);
  rect(x, fy, SIDE_W, fh * 4); 
  
  for (HorizontalFader f : faders) f.render();

  // Draw Oscilloscope Panel
  float sy = fy + (fh * 4) + gap;
  noStroke(); fill(SURFACE);
  rect(x, sy, SIDE_W, scopeH);
  scope.render(x + 18, sy + 18, SIDE_W - 36, scopeH - 36, terrain, orbit, phase);

  // Draw Minimap Panel
  float my = sy + scopeH + gap;
  noStroke(); fill(SURFACE);
  rect(x, my, SIDE_W, mapH);
  
  // Update internal dimensions to prevent offset selection bugs on resize
  minimap.updatePosition(x, my, SIDE_W, mapH);
  minimap.render(terrain, orbit);
}
