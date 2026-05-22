// Orbit camera: spherical coordinates around the origin.
// Mouse drag rotates, wheel zooms, auto-rotate by default.
class CameraRig {
  float azimuth   = PI * 0.25;   // around Y (up)
  float elevation = PI * 0.22;   // above horizon (0..PI/2)
  float distance  = 19;
  float fov       = radians(42);
  boolean autoRotate = true;
  float autoSpeed = 0.35;        // radians/sec

  float camX, camY, camZ;

  void update(float dt) {
    if (autoRotate) azimuth += autoSpeed * dt;
    elevation = constrain(elevation, radians(5), radians(80));
    distance  = constrain(distance, 9, 38);
    camX = distance * cos(elevation) * cos(azimuth);
    camY = -distance * sin(elevation);
    camZ = distance * cos(elevation) * sin(azimuth);
  }

  void apply(PGraphics g) {
    float aspect = (float)g.width / g.height;
    g.perspective(fov, aspect, 0.1, 200);
    g.camera(camX, camY, camZ, 0, 0, 0, 0, 1, 0);
  }

  void mouseDrag(float dx, float dy) {
    autoRotate = false;
    azimuth   -= dx * 0.008;
    elevation += dy * 0.008;
  }

  void mouseWheel(float delta) {
    distance += delta * 1.4;
  }

  // Ray from camera through (sx, sy) [0..w, 0..h], intersect plane y=0.
  // Good enough since terrain is centered around y=0.
  PVector pickPlane(float sx, float sy, float vw, float vh) {
    PVector cam = new PVector(camX, camY, camZ);
    PVector fwd = PVector.mult(cam, -1); fwd.normalize();
    PVector up  = new PVector(0, 1, 0);
    PVector right = fwd.cross(up); right.normalize();
    PVector camUp = right.cross(fwd); camUp.normalize();

    float aspect = vw / vh;
    float ndcX = (sx / vw) * 2 - 1;
    float ndcY = ((sy / vh) * 2 - 1);
    float t = tan(fov * 0.5);

    PVector dir = new PVector(
      fwd.x + ndcX * t * aspect * right.x + ndcY * t * camUp.x,
      fwd.y + ndcX * t * aspect * right.y + ndcY * t * camUp.y,
      fwd.z + ndcX * t * aspect * right.z + ndcY * t * camUp.z
    );
    dir.normalize();

    if (abs(dir.y) < 0.001) return null;
    float th = -cam.y / dir.y;
    if (th < 0) return null;
    return new PVector(cam.x + th * dir.x, 0, cam.z + th * dir.z);
  }
}
