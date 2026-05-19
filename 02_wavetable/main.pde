// Grid Layout 
float panelW, panelH;
float pad = 20; // margin btw the pannels

// Modular System Interfaces
WaveDrawer waveTable;
// FFTVisualizer fftVisualizer;  // coming soon
// LiveOscilloscope liveWave;   // 
// ControlPanel sliders;        // 

void setup() {
  size(2800, 1500, P2D);
  surface.setLocation(width/10, height/10);
  
  // Separate grid in 2x2 same size panels
  panelW = (width - (pad * 3)) / 2;
  panelH = (height - (pad * 3)) / 2;
  
  // Coordinates mapping
  float xCol1 = pad;
  //float xCol2 = pad * 2 + panelW;
  
  float yRow1 = pad;
  //float yRow2 = pad * 2 + panelH;
  
  // Initliaze the waveTable
  // WaveDrawer(xPos, yPos, totalWidth, totalDepth, totalLines, projectionAngle)
  waveTable = new WaveDrawer(xCol1+pad, yRow1 + 3*panelH/4, 3*panelW/4, 400, 50, PI/4);
  waveTable.setGlobalAlpha(80); // lines transparency
  waveTable.setWaveStrokeWeight(2.0); // lines weight
  waveTable.setWaveParameters(80, 4); // (amp, freq)
  
  /* 
  // future modules
  fftVisualizer = new FFTVisualizer(xCol2, yRow1, panelW, panelH); // cadran 1
  liveWave      = new LiveOscilloscope(xCol1, yRow2, panelW, panelH); // cadran 3
  sliders       = new ControlPanel(xCol2, yRow2, panelW, panelH);    // cadran 4
  */
}

void draw() {
  background(60, 120, 120); 
  
  // draw blueprints of layout panels
  drawDebugGrid(); 
  
  // Wavetable rendering
  waveTable.render();
  
  /*
  fftVisualizer.render();
  liveWave.render();
  sliders.render();
  */
}

// to help with modules position
void drawDebugGrid() {
  noFill();
  stroke(255, 100); 
  strokeWeight(1);
  
  // Draw 4 panels
  rect(pad, pad, panelW, panelH);                         // cadran 2 - wavetable
  rect(pad * 2 + panelW, pad, panelW, panelH);             // cadran 1
  rect(pad, pad * 2 + panelH, panelW, panelH);             // cadran 3
  rect(pad * 2 + panelW, pad * 2 + panelH, panelW, panelH); //cadran 4
}


void mouseDragged() {
  waveTable.checkSliderInteraction(mouseX, mouseY);
}

void mousePressed() {
  waveTable.checkSliderInteraction(mouseX, mouseY);
}
