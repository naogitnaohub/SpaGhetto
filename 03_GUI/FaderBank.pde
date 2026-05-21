// Class in constructions. I tried to make a class for simplifying having lots of faders, but right now it's not so efficent.
// Don't look too much on it becasue it will cahnge a lot

class FaderBank {
  // Encapsulated layout parameters
  private float centerX, centerY, viewW, viewH;
  
  // Tracking parameters
  private int activeFaderIdx = -1;
  private int totalFaders;
  private float[] faderYPositions;
  private float trackH;
  
  // Configuration storage arrays
  private String[] labelsH, labelsL;
  private float[] minVals, maxVals;
  
  // Radar fader elements
  private float radarX, radarY, radarR;
  private float joystickX, joystickY;
  private boolean isDraggingRadar = false;

  // Constructor setups layout spaces natively
  FaderBank(float x, float y, float w, float h, int numFaders) {
    this.centerX = x;
    this.centerY = y;
    this.viewW = w;
    this.viewH = h;
    this.totalFaders = max(1, numFaders); 
    
    this.faderYPositions = new float[totalFaders];
    this.labelsH = new String[totalFaders];
    this.labelsL = new String[totalFaders];
    this.minVals = new float[totalFaders];
    this.maxVals = new float[totalFaders];
    
    // Calculate dimensions relative to panel size
    this.radarX = centerX; 
    this.radarY = centerY ; 
    this.radarR = min(viewW * 0.35f, viewH * 0.65f) * 0.6f; 
    
    this.joystickX = radarX;
    this.joystickY = radarY;
    
    this.trackH = h * 0.5f; 
    
    // Initialize arrays with clean default spaces to prevent crasshhhhes
    for(int i = 0; i < totalFaders; i++) {
      faderYPositions[i] = centerY; 
      labelsH[i] = "";
      labelsL[i] = "";
      minVals[i] = 0.0f; 
      maxVals[i] = 1.0f;
    }
  }

  void configureFader(int index, String labelH, String labelL, float minV, float maxV) {
    if (index < 0 || index >= totalFaders) return;
    labelsH[index] = (labelH == null) ? "" : labelH;
    labelsL[index] = (labelL == null) ? "" : labelL;
    minVals[index] = minV;
    maxVals[index] = maxV;
  }

  void render() {
    pushStyle();
    rectMode(CENTER);
    ellipseMode(RADIUS);
    
    // Outer Container
    fill(0,0);
    stroke(0,0);
    strokeWeight(2);
    rect(centerX, centerY, viewW, viewH, 20);

    // DRAW THE RADAR SCOPE BACKDROP
    fill(0,0); stroke(200,240,240,120); strokeWeight(4.0f);
    ellipse(radarX, radarY, radarR, radarR);
    
    // Calibration grids
    stroke(200, 245, 230, 120); strokeWeight(3); noFill();
    ellipse(radarX, radarY, radarR * 0.33f, radarR * 0.33f);
    ellipse(radarX, radarY, radarR * 0.66f, radarR * 0.66f);
    stroke(200, 245, 230, 120);
    line(radarX - radarR, radarY, radarX + radarR, radarY); 
    line(radarX, radarY - radarR, radarX, radarY + radarR); 
    
    // Yellow Handle Joystick
    fill(255, 255, 0); noStroke();
    ellipse(joystickX, joystickY, 10, 10);
    noFill(); stroke(255, 255, 0, 160); strokeWeight(3.0f);
    ellipse(joystickX, joystickY, 14, 14); 

    // FIXED ARRAY STRINGS INDEX REFERENCES:
    String text0 = (0 < totalFaders && labelsH[0] != null) ? labelsH[0] : "Drive";
    String text2 = (2 < totalFaders && labelsH[2] != null) ? labelsH[2] : "Mix";

    textSize(max(11, viewH * 0.05f)); textAlign(CENTER, BOTTOM); fill(180);
    text(text0 + " & " + text2, radarX, radarY - radarR - 10);
    textAlign(CENTER, TOP); fill(0, 255, 200);
    text("Drive: " + nf(getValue(0), 1, 1) + " | Mix: " + nfc(getValue(2) * 100, 0) + "%", radarX, radarY + radarR + 10);

    // DRAW THE VERTICAL SLIDERS
    float colSpacing = viewW / (totalFaders + 1);
    float startX = centerX - (viewW / 2.0f);
    
    for (int i = 0; i < totalFaders; i++) {
      if (i == 0 || i == 2) continue; 
      
      float faderX = startX + (colSpacing * (i + 2.2f));
      
      fill(0); noStroke();
      rect(faderX, centerY, 30, trackH);

      fill(255, 255, 0);
      rect(faderX, faderYPositions[i], 50, 20);

      String tTxt = (labelsH[i] == null) ? "" : labelsH[i];
      String bTxt = (labelsL[i] == null) ? "" : labelsL[i];

      textSize(max(12, viewH * 0.05f)); 
      textAlign(CENTER, CENTER);
      fill(180); text(tTxt, faderX, centerY - (trackH / 2.0f) - 15);
      fill(200); text(bTxt, faderX, centerY + (trackH / 2.0f) + 15);
    }
    popStyle();
  }

  float getValue(int index) {
    float topLimit = centerY - (trackH / 2.0f);
    float bottomLimit = centerY + (trackH / 2.0f);
    
    float minVal0 = (0 < totalFaders) ? minVals[0] : 1.0f;
    float maxVal0 = (0 < totalFaders) ? maxVals[0] : 10.0f;
    float minVal2 = (2 < totalFaders) ? minVals[2] : 0.0f;
    float maxVal2 = (2 < totalFaders) ? maxVals[2] : 1.0f;

    if (index == 0) { 
      return map(joystickY, radarY + radarR, radarY - radarR, minVal0, maxVal0);
    }
    if (index == 2) { 
      return map(joystickX, radarX - radarR, radarX + radarR, minVal2, maxVal2);
    }
    
    if (index < 0 || index >= totalFaders) return 0;
    return map(faderYPositions[index], bottomLimit, topLimit, minVals[index], maxVals[index]);
  }

  void checkMousePressed(float mx, float my) {
    activeFaderIdx = -1;
    isDraggingRadar = false;

    if (dist(mx, my, radarX, radarY) <= radarR + 15) {
      isDraggingRadar = true;
      handleRadarDrag(mx, my);
      return; 
    }

    float colSpacing = viewW / (totalFaders + 1);
    float startX = centerX - (viewW / 2.0f);
    float topLimit = centerY - (trackH / 2.0f);
    float bottomLimit = centerY + (trackH / 2.0f);

    for (int i = 0; i < totalFaders; i++) {
      if (i == 0 || i == 2) continue;
      float faderX = startX + (colSpacing * (i + 2.2f));
      if (abs(mx - faderX) < 25 && my >= topLimit - 15 && my <= bottomLimit + 15) {
        activeFaderIdx = i;
        faderYPositions[i] = constrain(my, topLimit, bottomLimit);
        break;
      }
    }
  }

  void checkMouseDragged(float mx, float my) {
    if (isDraggingRadar) {
      handleRadarDrag(mx, my);
    } else if (activeFaderIdx != -1) {
      float topLimit = centerY - (trackH / 2.0f);
      float bottomLimit = centerY + (trackH / 2.0f);
      faderYPositions[activeFaderIdx] = constrain(my, topLimit, bottomLimit);
    }
  }

  private void handleRadarDrag(float mx, float my) {
    float dx = mx - radarX;
    float dy = my - radarY;
    float currentDist = sqrt(dx*dx + dy*dy);
    
    if (currentDist <= radarR) {
      joystickX = mx;
      joystickY = my;
    } else {
      joystickX = radarX + (dx / currentDist) * radarR;
      joystickY = radarY + (dy / currentDist) * radarR;
    }
  }
  
  void releaseInteraction() {
    isDraggingRadar = false;
    activeFaderIdx = -1;
  }
}
