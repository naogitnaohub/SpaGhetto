// This class generates audio waveform, it is used for testing purpose as the original sound will come from JUCE and SUperCOllider

class SynthSimulator {
  private float[] buffer;
  private float sampleRate;
  private float phase = 0;
  private float lfoPhase = 0;

  SynthSimulator(int bufferSize, float sampleRate) {
    this.buffer = new float[bufferSize];
    this.sampleRate = sampleRate;
  }

  void update() {
    // LFO to modulate pitch
    lfoPhase += 0.008;
    float lfoVal = (sin(lfoPhase) + 1.0) / 2.0; 
    
   
    float currentPitchHz = lerp(50.0, 1000.0, lfoVal);

    for (int i = 0; i < buffer.length; i++) {
      // Calculate true phase configuration index progression step coordinates
      float samplePhase = phase + (TWO_PI * currentPitchHz * i / sampleRate);
      buffer[i] = sin(samplePhase);
    }
    
    // Track global running sample phase cycles
    phase += (TWO_PI * currentPitchHz * buffer.length / sampleRate);
    phase %= TWO_PI;
  }

  float[] getAudioBuffer() { return this.buffer; }
}
