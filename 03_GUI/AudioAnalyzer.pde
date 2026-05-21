// This class has functions to render the FFT and the oscilloscope
class AudioAnalyzer {
  private float sampleRate;
  
  // Tracking variables
  private float viewW, fftH;
  
  // Dynamic audio stream tracking data
  private float[] timeData;
  private float[] fftData;
  
  // Style properties with default fallbacks
  private float globalTextSize = 13;
  private color waveColor = color(151, 240, 240);
  private color spectrumColor = color(255, 100, 0);
  private color filterCurveColor = color(255, 230, 0, 180);
  
  // Benchmark calibration vectors for log spectrum plotting
  private final float[] freqGridLines = {50, 75, 100, 150, 200, 250, 500, 750, 1000, 2000, 5000, 10000, 20000};
  private final float minF = 20.0;

  // COnstructor
  AudioAnalyzer(float sampleRate) {
    this.sampleRate = sampleRate;
  }

  // --- PUBLIC STYLING SETTERS ---
  void setTextSize(float size)     { this.globalTextSize = max(8, size); }
  void setWaveColor(color c)       { this.waveColor = c; }
  void setSpectrumColor(color c)   { this.spectrumColor = c; }
  void setFilterCurveColor(color c){ this.filterCurveColor = c; }

  // --- PROCESS AND UPDATE ---
  void analyze(float[] incomingAudio) {
    this.timeData = incomingAudio;
    if (fftData == null || fftData.length != timeData.length / 2) {
      this.fftData = new float[timeData.length / 2];
    }
    computeFFT();
  }

 //************-- RENDERING FUNCITONS -----**********************************
 
 // ---  FFT PANEL RENDERING ---
  void renderFFT(float x, float y, float w, float h, float activeCutoff) {
    if (fftData == null) return;
    
    this.viewW = w;
    this.fftH = h;
    
    pushMatrix(); 
    translate(x, y);
    
    // Graph parameters
    float startX = 85; 
    float endX = w - 25; 
    float graphW = endX - startX;
    float startY = h - 65; 
    float graphH = startY - 45;
    float maxF = sampleRate / 2.0;

    // Call drawing functions
    drawFFTGridLines(startX, startY, graphW, graphH, maxF);
    drawFFTSpectrumLine(startX, startY, graphW, graphH, maxF);
    drawFilterCurveGeometry(startX, startY, graphW, graphH, maxF, activeCutoff);
    
    
    popMatrix();
  }



  // --- WAVEFORM PANEL RENDERING ------------------------
  void renderWaveform(float x, float y, float w, float h) {
    if (timeData == null) return;
    pushMatrix(); 
    translate(x - (w / 2.0), y - (h / 2.0));
    
    drawOscilloscopeHardwareFrame(w, h);
    drawWaveformGeometry(w, h);
    drawOscPanelLabel("SCOPE", w/2, 30);
    
    popMatrix();
  }

//*********************************************************************
  //****************-- BACKGROUND FUNCTIONS ---*******************
  
  private void drawBackgroundFrame(float w, float h, color col) {
    fill(col); 
    stroke(255, 255, 255, 50); 
    strokeWeight(2);
    rect(0, 0, w, h, 20);
  }

//----------------- OSCILLOASCOPE FUNCTIONS -----------------------------

// DRAW OSCILLOSCOPE BACKGROUND/FRAME
  private void drawOscilloscopeHardwareFrame(float w, float h) {
    rectMode(CORNER);
    fill(20, 100, 100); 
    noStroke();
    rect(0, 0, w, h, 20); 
  
    stroke(255, 255, 255, 50); 
    strokeWeight(1.5);
    
    int numDivisionsX = 8; 
    int numDivisionsY = 6; 
    float dotSpacing = 6;  
  
    for (int col = 1; col < numDivisionsX; col++) {
      float gx = (w / numDivisionsX) * col;
      for (float gy = 0; gy < h; gy += dotSpacing * 2) {
        line(gx, gy, gx, gy + dotSpacing);
      }
    }
  
    for (int row = 1; row < numDivisionsY; row++) {
      float gy = (h / numDivisionsY) * row;
      for (float gx = 0; gx < w; gx += dotSpacing * 2) {
        line(gx, gy, gx + dotSpacing, gy);
      }
    }
  
    noFill();
    int shadowThickness = 15; 
    for (int i = 0; i < shadowThickness; i++) {
      float alpha = map(i, 0, shadowThickness - 1, 140, 0); 
      stroke(0, alpha);
      strokeWeight(1);
      rect(i, i, w - (i * 2), h - (i * 2), max(0, 20 - i));
    }

    noFill();
    stroke(0); 
    strokeWeight(2.5);
    rect(0, 0, w, h, 20);
  }
  
  // Draw panel labels
  private void drawPanelLabel(String title, float lx, float ly) {
    fill(180); 
    textSize(globalTextSize); 
    textAlign(LEFT, TOP);
    text(title, lx, ly);
  }
  
  private void drawOscPanelLabel(String title, float lx, float ly) {
    fill(255, 255, 255, 150); 
    textSize(30); 
    textAlign(CENTER, TOP);
    text(title, lx, ly);
  }

//-----DRAW WAVEFORM ---------------------------------
  private void drawWaveformGeometry(float w, float h) {
    if (timeData == null || timeData.length < 2) return;

    float minW = 1.0f;  
    float maxW = 7.0f;  

    int totalSamples = timeData.length;
    float halfH = h * 0.5f;
    float scaleY = h * 0.42f;
    
    float startX = 15f;
    float xStep = (w - 30f) / (totalSamples - 1);

    float rGlow = red(waveColor);
    float gGlow = green(waveColor);
    float bGlow = blue(waveColor);

    float prevX = startX;
    float prevY = halfH + (timeData[0] * scaleY);
    float thicknessRange = maxW - minW;

    for (int i = 1; i < totalSamples; i++) {
      float nextX = startX + (i * xStep);
      float rawY = timeData[i];
      float nextY = halfH + (rawY * scaleY);

      float displacement = (rawY < 0f) ? -rawY : rawY; 
      
      float baseThickness = minW + (displacement * thicknessRange); 
      float blurThickness = baseThickness * 3.5f;               
      float phosphorAlpha = 70.0f + (displacement * 185.0f);    

      stroke(rGlow, gGlow, bGlow, phosphorAlpha * 0.15f); 
      strokeWeight(blurThickness);
      line(prevX, prevY, nextX, nextY); 

      stroke(rGlow, gGlow, bGlow, phosphorAlpha);
      strokeWeight(baseThickness);
      line(prevX, prevY, nextX, nextY);

      prevX = nextX;
      prevY = nextY;
    }
  }

  //**************************************************************************************
  //------------------ FFT FUNCTIONS ------------------------------------------------------
  
  // draw grid
    private void drawFFTGridLines(float startX, float startY, float graphW, float graphH, float maxF) {
 
    rectMode(CORNER);
    fill(20, 45, 45); 
    noStroke();
    rect(0, 0, viewW, fftH, 20); 

    pushStyle();
    
  
    float freqLabelSize = 22; 
    float dbLabelSize   = 22; 
    float labelMargin   = 15; 

    // Cache log scale pre-multipliers
    float logMin = log(minF);
    float logMax = log(maxF);
    float logRangeInv = 1.0f / (logMax - logMin);

    // LOGARITHMIC FREQUENCY X-AXIS --
    stroke(255, 255, 255, 20); 
    strokeWeight(1);
    textSize(freqLabelSize);
    
    float[] decades = {10, 100, 1000, 10000};
    for (float d : decades) {
      for (int i = 1; i <= 9; i++) {
        float f = d * i;
        if (f < minF || f > maxF) continue;
        
        float logNorm = (log(f) - logMin) * logRangeInv;
        float gx = startX + (logNorm * graphW);
        
        // Strict clipping check to keep lines from going out of the box
        if (gx > startX + graphW || gx < startX) continue;
        
        boolean isMajor = false;
        for (float majorF : freqGridLines) {
          if (abs(f - majorF) < 1.0f) { isMajor = true; break; }
        }
        
        if (isMajor) {
          stroke(200, 245, 230, 75); 
          line(gx, startY, gx, startY - graphH);
          
          String labelText = (f >= 1000) ? nfc(f/1000, 0) + "k" : nfc(f, 0);
          textAlign(CENTER, TOP);
          fill(200, 245, 230);
          text(labelText, gx, startY + labelMargin); 
        } else {
          stroke(255, 255, 255, 15); 
          line(gx, startY, gx, startY - graphH);
        }
      }
    }

    // DECIBEL (+ dB to -40 dB) AMPLITUDE Y-AXIS --
    float[] dbGridLines = { 6, 0, -6, -12, -18, -24, -30, -40 }; 
    textAlign(RIGHT, CENTER);
    textSize(dbLabelSize);
    
    for (float dbVal : dbGridLines) {
      float normY = (dbVal + 40.0f) * 0.02f; 
      float gy = startY - (normY * graphH);
      
      stroke(200, 245, 230, 40);
      strokeWeight(1);
      line(startX, gy, startX + graphW, gy);
      
      fill(200, 245, 230);
      String dbLabel = (dbVal > 0) ? "+" + nfc(dbVal, 0) + " dB" : nfc(dbVal, 0) + " dB";
      text(dbLabel, startX - labelMargin, gy); 
    }
    
    // Draw gradient contour just for style (:
    noFill();
    int shadowThickness = 15;
    for (int i = 0; i < shadowThickness; i++) {
      float alpha = map(i, 0, shadowThickness - 1, 140, 0); 
      stroke(0, alpha);
      strokeWeight(1);
      rect(i, i, viewW - (i * 2), fftH - (i * 2), max(0, 20 - i));
    }

    
    noFill();
    stroke(0);
    strokeWeight(2.5);
    rect(0, 0, viewW, fftH, 20);

    popStyle();
  }

// ----- DRAW FFT SPECTRUM ----------------------------
  private void drawFFTSpectrumLine(float startX, float startY, float graphW, float graphH, float maxF) {
    noFill(); 
    stroke(spectrumColor); 
    strokeWeight(2.5); 
    
    float logMin = log(minF);
    float logMax = log(maxF);
    float logRangeInv = 1.0f / (logMax - logMin);
    float binHzWidth = sampleRate / timeData.length;
    float log10Inv = 1.0f / log(10.0f);
    
    beginShape();
    for (int i = 1; i < fftData.length; i++) {
      float currentBinFreq = i * binHzWidth;
      if (currentBinFreq < minF || currentBinFreq > maxF) continue;
      
      float rawAmp = fftData[i];
      float dbVal = -40.0f; 
      if (rawAmp > 0.0001f) {
        dbVal = 20.0f * log(rawAmp) * log10Inv; 
      }
      
      // Update constraint ranges to sit perfectly below 6dB threshold 
      if (dbVal < -40.0f) dbVal = -40.0f;
      if (dbVal > 6.0f)  dbVal = 6.0f;
      
      float normY = (dbVal + 40.0f) * 0.02f; // Fast mapping multiplier (1/50)
      float logNorm = (log(currentBinFreq) - logMin) * logRangeInv;
      
      float vx = startX + (logNorm * graphW);
      float vy = startY - (normY * graphH); 
      
      vertex(vx, vy);
    }
    endShape();
  }

//------------ DRAW FILTER CURVES --------------------------------------------------
  private void drawFilterCurveGeometry(float startX, float startY, float graphW, float graphH, float maxF, float activeCutoff) {
    noFill();
    stroke(filterCurveColor); 
    strokeWeight(2.5); 
    
    float logMin = log(minF);
    float logMax = log(maxF);
    float logRangeInv = 1.0f / (logMax - logMin);
    float log10Inv = 1.0f / log(10.0f);
    
    beginShape();
    for (float fxVal = minF; fxVal <= maxF; fxVal *= 1.08f) {
      float logNorm = (log(fxVal) - logMin) * logRangeInv;
      float cx = startX + (logNorm * graphW);
      
      float filterMagnitude = 1.0f / sqrt(1.0f + (fxVal * fxVal) / (activeCutoff * activeCutoff));
      
      float dbVal = -40.0f;
      if (filterMagnitude > 0.0001f) {
        dbVal = 20.0f * log(filterMagnitude) * log10Inv;
      }
      
      if (dbVal < -40.0f) dbVal = -40.0f;
      if (dbVal > 10.0f)  dbVal = 10.0f;
      
      float normY = (dbVal + 40.0f) * 0.02f; // Fast mapping multiplier (1/50)
      float cy = startY - (normY * graphH); 
      
      vertex(cx, cy);
    }
    endShape();
  }
  
  
   // ---------- DRAW FISHEYE DESCORATION ------------------------------
void renderFishEye(float x, float y, float diameter, float driveValue) {
    if (timeData == null || timeData.length < 2) return;
    
    pushMatrix();
    translate(x, y); 
    
    float r = diameter * 0.5f;
    
    pushStyle();
    ellipseMode(RADIUS);
    fill(20, 45, 45); 
    stroke(55, 65, 75);
    strokeWeight(2);
    ellipse(0, 0, r, r);
    
    // inner radar target circles
    stroke(200, 245, 230, 20); strokeWeight(1); noFill();
    ellipse(0, 0, r * 0.5f, r * 0.5f);
    ellipse(0, 0, r * 0.75f, r * 0.75f);
    popStyle();

    // polar coordinates waveform warp loop
    // Converts the linear buffer arrays into a continuous circular one
    float rGlow = red(waveColor);
    float gGlow = green(waveColor);
    float bGlow = blue(waveColor);
    
    int totalPoints = min(timeData.length, 256); // Downsample for better CPU speed
    float angleStep = TWO_PI / (totalPoints - 1);
    
    // Saturation/Drive 
    float dynamicSwellFactor = map(driveValue, 1.0f, 10.0f, 0.15f, 0.55f);
    dynamicSwellFactor = constrain(dynamicSwellFactor, 0.1f, 0.7f);
    
    // First layer, glowing and soft
    noFill();
    stroke(rGlow, gGlow, bGlow, 35); 
    strokeWeight(12);
    beginShape();
    for (int i = 0; i < totalPoints; i++) {
      float angle = i * angleStep;
      // rradius + audio sample modulation scaled by drive swell intensity
      float currentRadius = r * 0.55f + (timeData[i] * r * dynamicSwellFactor);
      float cx = cos(angle) * currentRadius;
      float cy = sin(angle) * currentRadius;
      vertex(cx, cy);
    }
    endShape();

    // Layer 2, intense beam
    stroke(rGlow, gGlow, bGlow, 220);
    strokeWeight(3.5f);
    beginShape();
    for (int i = 0; i < totalPoints; i++) {
      float angle = i * angleStep;
      float currentRadius = r * 0.55f + (timeData[i] * r * dynamicSwellFactor);
      float cx = cos(angle) * currentRadius;
      float cy = sin(angle) * currentRadius;
      vertex(cx, cy);
    }
    endShape();
    
    
    popMatrix();
  }


 //*****************************************************************3
  // ---  FFT ALGORITHM (radix2) ---
  private void computeFFT() {
    int n = timeData.length;
    float[] real = new float[n];
    float[] imag = new float[n];
    System.arraycopy(timeData, 0, real, 0, n);
    
    int j = 0;
    for (int i = 0; i < n; i++) {
      if (i < j) { float temp = real[i]; real[i] = real[j]; real[j] = temp; }
      int m = n >> 1;
      while (m >= 2 && j >= m) { j -= m; m >>= 1; }
      j += m;
    }
    for (int size = 2; size <= n; size <<= 1) {
      float deltaTheta = -TWO_PI / size;
      float wpr = cos(deltaTheta); float wpi = sin(deltaTheta);
      for (int step = 0; step < n; step += size) {
        float wr = 1.0; float wi = 0.0;
        for (int i = 0; i < size / 2; i++) {
          int indexA = step + i; int indexB = indexA + size / 2;
          float tReal = wr * real[indexB] - wi * imag[indexB];
          float tImag = wr * imag[indexB] + wi * real[indexB];
          real[indexB] = real[indexA] - tReal; imag[indexB] = imag[indexA] - tImag;
          real[indexA] += tReal; imag[indexA] += tImag;
          float nextWr = wr * wpr - wi * wpi; wi = wr * wpi + wi * wpr; wr = nextWr;
        }
      }
    }
    for (int i = 0; i < n / 2; i++) {
      float m = sqrt(real[i] * real[i] + imag[i] * imag[i]) / n;
      fftData[i] = lerp(fftData[i], m * 3.5, 0.4); 
    }
  }
}


 
