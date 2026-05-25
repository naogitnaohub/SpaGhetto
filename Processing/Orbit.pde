class Orbit3D {
  
  float cx = 0, cz = 0, r = 2.0;
  final float LIFT = -0.07;

  void setPosition(float cx, float cz) { this.cx = cx; this.cz = cz; }
  void setRadius(float r)              { this.r = max(0.2, r); }

  void render(PGraphics g, Terrain3D terrain, float phase) {
    // --- anello ---
    int N = 128;
    g.noFill();
    g.stroke(AMBER); g.strokeWeight(2.4);
    g.beginShape();
    for (int i = 0; i <= N; i++) {
      float t = (i / (float)N) * TWO_PI;
      float x = cx + r * cos(t), z = cz + r * sin(t);
      g.vertex(x, terrain.terrain(terrain.waveNumber, x, z) * terrain.YSCALE + LIFT, z);
    }
    g.endShape();

    // --- pallino sull'orbita ---
    float tx = cx + r * cos(phase);
    float tz = cz + r * sin(phase);
    float ty = terrain.terrain(terrain.waveNumber, tx, tz) * terrain.YSCALE;
    g.pushMatrix();
    g.translate(tx, ty - 0.12, tz);
    g.noStroke(); g.fill(0); g.sphere(0.08);
    g.popMatrix();
  }
}
