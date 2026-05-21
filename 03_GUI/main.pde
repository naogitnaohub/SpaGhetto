// Grid Layout 
float panelW, panelH;
float pad = 50; // margin btw the pannels

// Classs modules
WaveDrawer waveTable;
SynthSimulator synth;
AudioEffectsProcessor fx;
AudioAnalyzer analyzer;
FaderBank controls;

void setup() {
  size(2800, 1500, P2D);
  surface.setLocation(width/10, height/10);
  
  // -----------GRID----------------------
  panelW = (width - (pad * 3)) / 2;
  panelH = (height - (pad * 3)) / 2;
  
  // Coordinates mapping
  float xCol1 = pad;  
  float yRow1 = pad;
  
 //------------WAVETABLE INITIALIZATION----------------
  waveTable = new WaveDrawer(xCol1+pad, yRow1 + 3*panelH/4, 3*panelW/4, 400, 50, PI/4);
  waveTable.setGlobalAlpha(80); 
  waveTable.setWaveStrokeWeight(2.0); 
  waveTable.setWaveParameters(80, 4); 
  
  // ------------FFT & SIGNAL INITIALIZATION---------------------
  synth = new SynthSimulator(512, 44100);
  fx = new AudioEffectsProcessor(44100);
  
  analyzer = new AudioAnalyzer(44100);
  analyzer.setTextSize(20);
  analyzer.setWaveColor(color(150, 250, 220));     
  analyzer.setSpectrumColor(color(255, 100, 0));
  

}

void draw() {
  background(60, 120, 120); 
  // fish eye (inside the radar XY fader)
  analyzer.renderFishEye(width/4, 3*height/4, 500, fx.getDrive());
  
  //----------- WAVETABLE RENDERING------------
  waveTable.render();
  waveTable.renderSlider(width/4, height/2, width/2-2*pad);
  
  // ----------- SIGNAL COMPUTATION & FFT -------------
  synth.update();
  float[] audioBuffer = synth.getAudioBuffer();
  fx.process(audioBuffer);
  analyzer.analyze(audioBuffer);
  
  analyzer.renderFFT(pad * 2 + panelW+20, 2*pad, panelW-30, 700, fx.getFilterCutoff()); 
  
  // ----------OSCILLOSCOPE RENDERING ----------------------
  analyzer.renderWaveform(3*width/4, 3*height/4, width/2-2*pad, height/2-4*pad);
  
  // --------- FX GENERATOR GUI PANEL --------------------------
  fx.drawControlPanel(width/4, 3*height/4, panelW, height/2-2*pad); 
  
  
}

void mouseDragged() {
  waveTable.checkSliderInteraction(mouseX, mouseY);
  fx.checkMouseInteraction(mouseX, mouseY);
  if (controls != null) controls.checkMouseDragged(mouseX, mouseY); 
}

void mousePressed() {
  waveTable.checkSliderInteraction(mouseX, mouseY);
  fx.checkMouseInteraction(mouseX, mouseY);
  if (controls != null) controls.checkMousePressed(mouseX, mouseY); 
}

void mouseReleased() { 
  if (controls != null) controls.releaseInteraction(); 
}
