class WaveDrawer {
  // Layout parameters
  private float xPos, yPos;
  private float wWidth, wDepth, angle;
  private int totalLines;
  
  // Wave Parameters
  private float currentAmp = 100.0;
  private float currentFreq = 5.0;
  
  // Style and Interaction variables
  private float globalAlpha = 255; // transparency
  private float waveStrokeWeight = 3.0; // line wieght
  private int highlightedIdx = 0; // highlighted waveform initial position
  
  // Graphics cache to not redraw background waves everytime
  private PGraphics bgCache;
  private boolean isCacheValid = false;
  
  // Waveforms array
  private final String[] waveOrder = {"SINE", "TRIANGLE", "SAWTOOTH", "SQUARE"};

  WaveDrawer(float x, float y, float w, float d, int lines, float a) {
    this.xPos = x;
    this.yPos = y;
    this.wWidth = w;
    this.wDepth = d;
    this.totalLines = max(2, lines); 
    this.angle = a;
  }

  // --- PUBLIC ---
  
  // Updates frequency and amplitude
  // Automatically clears background cache if values change
  void setWaveParameters(float amp, float freq) {
    if (this.currentAmp != amp || this.currentFreq != freq) {
      this.currentAmp = amp;
      this.currentFreq = max(0.1, freq); // security if 0 or negative frequency
      invalidateCache();
    }
  }

  void setGlobalAlpha(float alpha) {
    this.globalAlpha = constrain(alpha, 0, 255);
    invalidateCache();
  }

  void setWaveStrokeWeight(float weight) {
    this.waveStrokeWeight = max(0.5, weight);
    invalidateCache();
  }
  
  void setHighlightedIndex(int idx) {
    this.highlightedIdx = constrain(idx, 0, totalLines - 1);
  }
  
  private void invalidateCache() {
    isCacheValid = false;
  }

  // --- CORE RENDERING ---
  
  void cacheBackgroundWaves() {
    if (bgCache == null) {
      bgCache = createGraphics(width, height, P2D);
    }
    
    bgCache.beginDraw();
    bgCache.clear(); 
    bgCache.pushMatrix();
    bgCache.translate(xPos, yPos);
    bgCache.scale(1, -1); // to have y go positive UP
    
   
    
    for (int i = 0; i < totalLines; i++) {
      drawMorphedWaveToCache(i);
    }
    
    bgCache.popMatrix();
    bgCache.endDraw();
    isCacheValid = true;
  }

  void render() {
    // If frequency or style changed, rebuild background cache once
    if (!isCacheValid) {
      cacheBackgroundWaves(); 
    }
    
    // Draw cached static background
    image(bgCache, 0, 0);
    
    // Draw real-time waveform highlight
    pushMatrix();
    translate(xPos, yPos);
    scale(1, -1);
    drawMorphedWaveToScreen(highlightedIdx); 
    popMatrix();
    
    // Draw controls
    
  }

  // --- RENDERING TARGET VARIATIONS ---

  private void drawMorphedWaveToCache(int zIdx) {
    float z0 = (zIdx * wDepth) / (totalLines - 1);
    bgCache.pushMatrix();
    bgCache.translate(z0 * cos(angle), z0 * sin(angle));
    
    bgCache.stroke(0, globalAlpha);
    bgCache.strokeWeight(waveStrokeWeight);
    
    drawWaveGeometry(bgCache, zIdx);
    bgCache.popMatrix();
  }

  private void drawMorphedWaveToScreen(int zIdx) {
    float z0 = (zIdx * wDepth) / (totalLines - 1);
    pushMatrix();
    translate(z0 * cos(angle), z0 * sin(angle));
    
    stroke(255, 230, 0); 
    strokeWeight(waveStrokeWeight + 1.5); 
    
    drawWaveGeometry(null, zIdx);
    pushMatrix(); 
    popMatrix();
    popMatrix();
  }

  // --- MORPHING FUNCTION ---
  private void drawWaveGeometry(PGraphics target, int zIdx) {
    float normZ = (float) zIdx / (totalLines - 1);
    
    int numSegments = waveOrder.length - 1;
    float segmentLength = 1.0 / numSegments;
    
    int segment = constrain(floor(normZ / segmentLength), 0, numSegments - 1);
    float t = (normZ - (segment * segmentLength)) / segmentLength;
    t = constrain(t, 0.0, 1.0);
    
    float prevX = 0;
    float prevY = 0; 
    
    for (int i = 1; i < wWidth; ++i) {
      float theta = TWO_PI * currentFreq * i / wWidth;
      
      float y1 = getWaveValue(waveOrder[segment], theta);
      float y2 = getWaveValue(waveOrder[segment + 1], theta);
      
      float y = currentAmp * lerp(y1, y2, t);
      
      if (target != null) {
        target.line(prevX, prevY, i, y);
      } else {
        line(prevX, prevY, i, y);
      }
      prevX = i;
      prevY = y;
    }
  }

  private float getWaveValue(String type, float theta) {
    switch (type) {
      case "SINE":     return drawSine(theta);
      case "SQUARE":   return drawSquare(theta);
      case "TRIANGLE": return drawTriangle(theta);
      case "SAWTOOTH": return drawSawtooth(theta);
      default:         return 0;
    }
  }

  // --- OSCILLATOR FUNCTIONS ---
  private float drawSine(float theta) { return sin(theta); }
  private float drawTriangle(float theta) { return (2.0 / PI) * asin(sin(theta)); }
  private float drawSawtooth(float theta) { return 2.0 * ((theta / TWO_PI + 0.5) - floor(theta / TWO_PI + 0.5)) - 1.0; }
  private float drawSquare(float theta) { return (cos(theta) >= 0) ? 1.0 : -1.0; }

  // --- DRAW REFERENCE FRAME --- not used for now
  /*
  private void drawRefFrame(PGraphics pg, int w, int length){
    pg.strokeWeight(w);
    pg.stroke(255, 0, 0, globalAlpha); pg.line(0, 0, length, 0); 
    pg.stroke(0, 255, 0, globalAlpha); pg.line(0, 0, 0, length); 
    pg.stroke(0, 0, 255, globalAlpha);                           
    pg.line(0, 0, -length * cos(angle) / 1.5, -length * sin(angle) / 1.5);
  }
  */

  // --- INJECTIONS STORAGE FOR LAYOUT POSITION TRACKING ---
  private float currentSliderX, currentSliderY, currentSliderW;

  // --- INDEPENDENT INTERACTIVE UI COMPONENT (CENTER ANCHORED H-AXIS) ---
  void renderSlider(float x, float y, float w) {
    // Save position values locally to transform mouse coordinates accurately later
    this.currentSliderX = x;
    this.currentSliderY = y;
    this.currentSliderW = w;
    
    pushStyle();
    
    // 1. Draw Background Track Line (Centered on X and Y)
    stroke(30, 80, 80);
    strokeWeight(6);
    line(x - (w / 2.0f), y, x + (w / 2.0f), y);
    
    // 2. Map highlighted index to handle positions smoothly
    float handleX = map(highlightedIdx, 0, totalLines - 1, x - (w / 2.0f), x + (w / 2.0f));
    
    // 3. Draw Handle Slider Knob
    fill(255, 230, 0);
    noStroke();
    ellipse(handleX, y, 20, 20);
    
    // 4. Draw Header text descriptions
    fill(255);
    textSize(30);
    textAlign(CENTER, BOTTOM);
    text("z - waveform" + highlightedIdx, x, y - 15);
    
    popStyle();
  }

  // --- RESPONSIVE USER INTERACTION ENGINE ---
  void checkSliderInteraction(float mx, float my) {
    // Calculates absolute left and right tracking limits using stored values
    float startX = currentSliderX - (currentSliderW / 2.0f);
    float endX   = currentSliderX + (currentSliderW / 2.0f);
    
    // Hit-box boundaries tracking detection checks with built-in padding tolerances
    if (mx >= startX - 10 && mx <= endX + 10 && my >= currentSliderY - 20 && my <= currentSliderY + 20) {
      // Maps mouse click percentage directly back to a rounded line index step array slot
      float rawNorm = (mx - startX) / currentSliderW;
      setHighlightedIndex(round(rawNorm * (totalLines - 1)));
    }
  }

}
