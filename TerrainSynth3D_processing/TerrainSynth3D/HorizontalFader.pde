class HorizontalFader {
  float x, y, w, h;
  String label;
  float minVal, maxVal;
  private float norm = 0.5;
  private boolean dragging = false;

  HorizontalFader(float x, float y, float w, float h,
                  String label, float minVal, float maxVal) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
    this.minVal = minVal; this.maxVal = maxVal;
  }

  void  setValue(float v) { norm = (v - minVal) / (maxVal - minVal); }
  float getValue()        { return minVal + norm * (maxVal - minVal); }

  boolean over(float mx, float my) {
    return mx >= x && mx <= x+w && my >= y && my <= y+h;
  }

  void render() {
    pushStyle();
    float pad   = 22;
    float track = y + h * 0.5 + 6;
    float left  = x + pad, right = x + w - pad;
    float hx    = lerp(left, right, norm);

    textFont(font); textSize(13);
    fill(ACCENT);
    textAlign(LEFT,  TOP); text(label, x + pad, y + 8);
    textAlign(RIGHT, TOP); text(nf(getValue(), 0, 2), x + w - pad, y + 8);

    stroke(BG);     strokeWeight(2); line(left, track, right, track);
    stroke(ACCENT); strokeWeight(2); line(left, track, hx, track);

    rectMode(CENTER);
    noStroke();    fill(BG);      rect(hx, track, 16, 24, 3);
    stroke(ACCENT); fill(SURFACE); rect(hx, track, 12, 20, 2);
    rectMode(CORNER);
    popStyle();
  }

  void checkMousePressed(float mx, float my) {
    if (over(mx, my)) { dragging = true; updateFromMouse(mx); }
  }
  void checkMouseDragged(float mx) { if (dragging) updateFromMouse(mx); }
  void release() { dragging = false; }

  private void updateFromMouse(float mx) {
    float pad = 22;
    norm = constrain((mx - x - pad) / (w - 2*pad), 0, 1);
  }
}
