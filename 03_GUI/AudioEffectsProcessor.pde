// This class is to simulate the effects that will comefrom JUCE. Use it for testing purpose on Processing, made by AI
class AudioEffectsProcessor {
  private float sampleRate;
 
  private FaderBank faderUI;
  
  // DSP parameters
  private float drive = 1.0;       
  private float cutoff = 5000.0;   
  private float dryWet = 1.0;       
  private float lpfState = 0;

  AudioEffectsProcessor(float sampleRate) {
    this.sampleRate = sampleRate;
  }

  void process(float[] buffer) {
    // Initali faders postion
    if (faderUI != null) {
      drive  = faderUI.getValue(0);
      cutoff = faderUI.getValue(1);
      dryWet = faderUI.getValue(2);
    }

    // AUdio streaming algo
    float rc = 1.0 / (TWO_PI * cutoff);
    float dt = 1.0 / sampleRate;
    float alpha = dt / (rc + dt);
    alpha = constrain(alpha, 0.0, 1.0);

    for (int i = 0; i < buffer.length; i++) {
      float drySample = buffer[i];
      float wetSample = drySample * drive;
      
      wetSample = constrain(wetSample, -1.5, 1.5);
      wetSample = wetSample - (pow(wetSample, 3) / 3.0); 
      
      lpfState = lpfState + alpha * (wetSample - lpfState);
      wetSample = lpfState;
      
      buffer[i] = lerp(drySample, wetSample, dryWet);
    }
  }

  // Add publig getter fcts
  float getFilterCutoff() { return this.cutoff; }
  float getDrive()        { return this.drive; } 

  // --- RENDERING INTERFACE LAYER ---
  void drawControlPanel(float x, float y, float w, float h) {
    // Initialization check
    if (faderUI == null) {
      
      faderUI = new FaderBank(x, y, w, h, 3);
      
      // configureFader(index, labelTop, labelBottom, minVal, maxVal)
      faderUI.configureFader(0, "Drive",  "",    1.0,  10.0);
      faderUI.configureFader(1, "Cutoff", "",    5.0,  15000.0);
      faderUI.configureFader(2, "Wet",    "Dry", 0.0,  1.0);
    }
    
    
    faderUI.render();
  }

  // --- RESPONSIVE USER INTERACTION ROUTER ---
  void checkMouseInteraction(float mx, float my) {
    if (faderUI == null) return;
    
    
    faderUI.checkMousePressed(mx, my);
    faderUI.checkMouseDragged(mx, my);
  }
}
