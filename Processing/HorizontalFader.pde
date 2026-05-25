class HorizontalFader {
  float x, y, w, h;
  String label;
  float minVal, maxVal;
  private float norm = 0.5;
  private boolean dragging = false;
  
  // Tracks the color of this specific fader (Defaults to neon green)
  color localAccent = #4ade80; 

  HorizontalFader(float x, float y, float w, float h,
                  String label, float minVal, float maxVal) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
    this.minVal = minVal; this.maxVal = maxVal;
  }

  void setAccentColor(color c) {
    this.localAccent = c;
  }

  void  setValue(float v) { norm = (v - minVal) / (maxVal - minVal); }
  float getValue()        { return minVal + norm * (maxVal - minVal); }
  
  void setIntValue(float v) { 
    float snappedValue = constrain(round(v), minVal, maxVal);
    norm = (snappedValue - minVal) / (maxVal - minVal); 
  }

  int getIntValue() { 
    return round(minVal + norm * (maxVal - minVal)); 
  }

  boolean over(float mx, float my) {
    return mx >= x && mx <= x+w && my >= y && my <= y+h;
  }

  void render() {
    pushStyle();
    float pad   = 22;
    float track = y + h * 0.5 + 6;
    float left  = x + pad, right = x + w - pad;
    
    float hx;
    String displayValue;
    
    if (label.equals("WAVE TERRAIN FUNCTION") || label.equals("TYPE SELECTOR")) {
      float snappedNorm = (getIntValue() - minVal) / (maxVal - minVal);
      hx = lerp(left, right, snappedNorm);
      displayValue = String.valueOf(getIntValue()); 
    } else {
      hx = lerp(left, right, norm);
      displayValue = nf(getValue(), 0, 2);          
    }

    textFont(font); textSize(22); 
    
    fill(localAccent);
    textAlign(LEFT,  TOP); text(label, x + pad, y + 8);
    textAlign(RIGHT, TOP); text(displayValue, x + w - pad, y + 8); 

    stroke(BG);          strokeWeight(2); line(left, track, right, track);
    stroke(localAccent); strokeWeight(2); line(left, track, hx, track); 

    rectMode(CENTER);
    noStroke();    fill(BG);          rect(hx, track, 16, 24, 3);
    stroke(localAccent); fill(SURFACE); rect(hx, track, 12, 20, 2); 
    rectMode(CORNER);
    popStyle();
  }

  void checkMousePressed(float mx, float my) {
    if (over(mx, my)) { dragging = true; updateFromMouse(mx); }
  }
  
  void checkMouseDragged(float mx, float my) { 
    if (dragging) updateFromMouse(mx); 
  }
  
  void release() { dragging = false; }

  private void updateFromMouse(float mx) {
    float pad = 22;
    float rawNorm = constrain((mx - x - pad) / (w - 2*pad), 0, 1);
    
    if (label.equals("WAVE TERRAIN FUNCTION") || label.equals("TYPE SELECTOR")) {
      float rawVal = minVal + rawNorm * (maxVal - minVal);
      float snappedVal = constrain(round(rawVal), minVal, maxVal);
      norm = (snappedVal - minVal) / (maxVal - minVal);
    } else {
      norm = rawNorm; 
    }
    
    // --- INTEGRATED NETWORK TRANSMISSION ---
    // Instantly fires OSC message packets whenever the mouse drags a slider knob
    if (net != null) {
      // Right Side Layout Items
      if (label.equals("SCALE"))                     net.transmit("/fader/scale", getValue());
      else if (label.equals("RADIUS"))                net.transmit("/fader/radius", getValue());
      else if (label.equals("WAVE TERRAIN FUNCTION")) net.transmit("/fader/waveNumber", getIntValue());
      
      // Left Side Layout Items
      else if (label.equals("MID DRIVE"))             net.transmit("/fader/midDrive", getValue());
      else if (label.equals("HIGH DRIVE"))            net.transmit("/fader/highDrive", getValue());
      else if (label.equals("FEEDBACK"))              net.transmit("/fader/feedback", getValue());
      else if (label.equals("DELAY (ms)"))            net.transmit("/fader/delay", getValue());
      else if (label.equals("TYPE SELECTOR"))         net.transmit("/fader/type", getIntValue());
      else if (label.equals("REVERB"))                net.transmit("/fader/reverb", getValue());
    }
  }
}
