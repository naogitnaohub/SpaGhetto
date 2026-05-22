class Minimap {
  float x, y, w, h, plotX, plotY, plotSize;
  final int RES = 40;

  Minimap(float x, float y, float w, float h) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    plotSize = min(w - 40, h - 30);
    plotX = x + (w - plotSize) * 0.5;
    plotY = y + (h - plotSize) * 0.5;
  }

  boolean over(float mx, float my) {
    return mx >= plotX && mx <= plotX + plotSize
        && my >= plotY && my <= plotY + plotSize;
  }

  void render(Terrain3D terrain, Orbit3D orbit) {
    pushStyle();
    noStroke();
    float cell = plotSize / (float)RES;

    for (int j = 0; j < RES; j++) {
      float z = -8 + 16.0 * j / (RES - 1);
      for (int i = 0; i < RES; i++) {
        float xw = -8 + 16.0 * i / (RES - 1);
        float t = (terrain.terrain(xw, z) + 1) * 0.5;
        fill(lerp(10, 80, t), lerp(20, 240, t), lerp(18, 120, t));
        rect(plotX + i*cell, plotY + j*cell, cell + 1, cell + 1);
      }
    }

    float cx = plotX + (orbit.cx + 8) / 16.0 * plotSize;
    float cz = plotY + (orbit.cz + 8) / 16.0 * plotSize;
    float rr = orbit.r / 16.0 * plotSize;
    noFill(); stroke(AMBER); strokeWeight(2);
    ellipse(cx, cz, rr*2, rr*2);
    noStroke(); fill(AMBER); ellipse(cx, cz, 6, 6);
    popStyle();
  }

  void handleClick(float mx, float my, Orbit3D orbit) {
    float nx = constrain((mx - plotX) / plotSize, 0, 1);
    float nz = constrain((my - plotY) / plotSize, 0, 1);
    float wx = -8 + nx * 16, wz = -8 + nz * 16;
    float m = orbit.r;
    orbit.setPosition(constrain(wx, -8+m, 8-m),
                      constrain(wz, -8+m, 8-m));
  }
}
