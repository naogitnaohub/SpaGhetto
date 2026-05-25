class Oscilloscope {
  int waveNumber = 2;
  int N;
  Oscilloscope(int n) { N = n; }

  void render(float x, float y, float w, float h,
              Terrain3D terrain, Orbit3D orbit, float currentPhase) {
    noStroke(); fill(BG); rect(x, y, w, h, 3);

    float[] s = new float[N];
    for (int i = 0; i < N; i++) {
      float t  = (i / (float)N) * TWO_PI;
      float tx = orbit.cx + orbit.r * cos(t);
      float tz = orbit.cz + orbit.r * sin(t);
      s[i] = terrain.terrain(terrain.waveNumber, tx, tz);
    }

    noFill(); stroke(ACCENT); strokeWeight(1.5);
    beginShape();
    for (int i = 0; i < N; i++) {
      float xx = x + (i / (float)(N - 1)) * w;
      float yy = y + h/2 - s[i] * (h/2 - 4);
      vertex(xx, yy);
    }
    endShape();

    float pn = ((currentPhase % TWO_PI) + TWO_PI) % TWO_PI / TWO_PI;
    float mx = x + pn * w;
    stroke(AMBER); strokeWeight(1);
    line(mx, y + 2, mx, y + h - 2);
  }
}
