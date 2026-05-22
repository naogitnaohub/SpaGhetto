// Plots the function value along the orbit over one full period.
// Pure visualization — no audio buffer. A cursor follows the current phase.

class Oscilloscope {
  int N;

  Oscilloscope(int n) { N = n; }

  void render(float x, float y, float w, float h,
              Terrain3D terrain, Orbit3D orbit, float currentPhase) {
    // background
    noStroke();
    fill(17, 15, 13);
    rect(x, y, w, h, 3);
    noFill();
    stroke(LINE);
    rect(x + 0.5, y + 0.5, w - 1, h - 1, 3);

    // grid
    stroke(58, 52, 44, 150);
    strokeWeight(1);
    line(x, y + h/2, x + w, y + h/2);
    stroke(42, 38, 32, 150);
    for (int i = 1; i < 8; i++) {
      float xx = x + (i / 8.0) * w;
      line(xx, y, xx, y + h);
    }

    // sample one full cycle along the orbit
    float[] s = new float[N];
    for (int i = 0; i < N; i++) {
      float t  = (i / (float)N) * TWO_PI;
      float tx = orbit.cx + orbit.r * cos(t);
      float tz = orbit.cz + orbit.r * sin(t);
      s[i] = terrain.terrain(tx, tz);
    }

    // waveform with glow
    noFill();
    stroke(74, 222, 128, 70);
    strokeWeight(3);
    drawWave(s, x, y, w, h);
    stroke(ACCENT);
    strokeWeight(1.5);
    drawWave(s, x, y, w, h);

    // current phase cursor
    float pn  = ((currentPhase % TWO_PI) + TWO_PI) % TWO_PI / TWO_PI;
    float mx  = x + pn * w;
    stroke(255, 255, 255, 140);
    strokeWeight(1);
    line(mx, y + 2, mx, y + h - 2);

    int idx = (int) constrain(pn * N, 0, N - 1);
    float my = y + h/2 - s[idx] * (h/2 - 4);
    noStroke();
    fill(74, 222, 128, 90);
    ellipse(mx, my, 14, 14);
    fill(255);
    ellipse(mx, my, 6, 6);
  }

  private void drawWave(float[] s, float x, float y, float w, float h) {
    beginShape();
    for (int i = 0; i < s.length; i++) {
      float xx = x + (i / (float)(s.length - 1)) * w;
      float yy = y + h/2 - s[i] * (h/2 - 4);
      vertex(xx, yy);
    }
    endShape();
  }
}
