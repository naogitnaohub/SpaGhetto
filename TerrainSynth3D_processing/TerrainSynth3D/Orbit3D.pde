// Orbit + traveller + trail, drawn on top of the terrain surface.
class Orbit3D {
  float cx = 0, cz = 0, r = 2.0;
  ArrayList<PVector> trail = new ArrayList<PVector>();
  final int TRAIL_MAX = 90;
  final float LIFT = -0.07;       // sit slightly above the surface

  void setPosition(float cx, float cz) { this.cx = cx; this.cz = cz; }
  void setRadius(float r) { this.r = max(0.2, r); }

  void renderOrbit(PGraphics g, Terrain3D terrain) {
  int N = 128;
  g.noFill();
  g.stroke(0, 0, 0, 230);
  g.strokeWeight(2.4);
  g.beginShape();
  for (int i = 0; i <= N; i++) {
    float t = (i / (float)N) * TWO_PI;
    float x = cx + r * cos(t);
    float z = cz + r * sin(t);
    float y = terrain.terrain(x, z) * terrain.HEIGHT_SCALE + LIFT;
    g.vertex(x, y, z);
  }
  g.endShape();

  // soft glow under-line
  g.stroke(0, 0, 0, 120);
  g.strokeWeight(3);
  g.beginShape();
  for (int i = 0; i <= N; i++) {
    float t = (i / (float)N) * TWO_PI;
    float x = cx + r * cos(t);
    float z = cz + r * sin(t);
    float y = terrain.terrain(x, z) * terrain.HEIGHT_SCALE + LIFT;
    g.vertex(x, y, z);
  }
  g.endShape();
}

  void renderTraveller(PGraphics g, Terrain3D terrain, float phase, float rms) {
    float tx = cx + r * cos(phase);
    float tz = cz + r * sin(phase);
    float ty = terrain.terrain(tx, tz) * terrain.HEIGHT_SCALE;

    // record trail
    trail.add(new PVector(tx, ty + LIFT, tz));
    while (trail.size() > TRAIL_MAX) trail.remove(0);

    // trail with per-vertex alpha fade
    g.noFill();
    g.strokeWeight(0.8);
    g.beginShape();
    int n = trail.size();
    for (int i = 0; i < n; i++) {
      float a = (float)i / max(1, n - 1);
      g.stroke(0, 0, 0, 240 * a * 0.9);
      PVector p = trail.get(i);
      g.vertex(p.x, p.y, p.z);
    }
    g.endShape();

    // glow halos
    float reactive = 1.0 + rms * 4;
    g.pushMatrix();
    g.translate(tx, ty - 0.18, tz);
    g.noStroke();
for (int i = 5; i >= 1; i--) {
  g.fill(74, 222, 128, (32 - i*4));
  g.sphere(i * 0.085 * reactive);
}
g.fill(0);
g.sphere(0.06);

    g.popMatrix();

    // dynamic point light at traveller
    float intens = 0.7 + rms * 4;
    g.pointLight(255 * intens, 170 * intens, 90 * intens, tx, ty - 0.3, tz);
  }
}
