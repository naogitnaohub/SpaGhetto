class CameraRig {
  float azimuth   = PI * 0.25;
  float elevation = PI * 0.22;
  float distance  = 19;
  float fov       = radians(42);
  float camX, camY, camZ;

  void update() {
    elevation = constrain(elevation, radians(5), radians(80));
    distance  = constrain(distance, 9, 38);
    camX =  distance * cos(elevation) * cos(azimuth);
    camY = -distance * sin(elevation);
    camZ =  distance * cos(elevation) * sin(azimuth);
  }

  void apply(PGraphics g) {
    g.perspective(fov, (float)g.width / g.height, 0.1, 200);
    g.camera(camX, camY, camZ, 0, 0, 0, 0, 1, 0);
  }

  void mouseDrag(float dx, float dy) {
    azimuth   -= dx * 0.008;
    elevation += dy * 0.008;
  }

  void mouseWheel(float delta) {
    distance += delta * 1.4;
  }
}
