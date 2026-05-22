class HorizontalFader {
  float x, y, w, h;
  String label;
  float minVal, maxVal, defaultVal;
  String curve;    // "linear" or "log"
  String fmtStr;   // printf format, or null
  boolean kilo = false;
  boolean percent = false;

  private float norm = 0.5;
  private boolean dragging = false;
  long lastClick = 0;

  HorizontalFader(float x, float y, float w, float h,
                  String label, float minVal, float maxVal,
                  String curve, String fmtStr) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
    this.minVal = minVal; this.maxVal = maxVal;
    this.curve = curve; this.fmtStr = fmtStr;
    this.defaultVal = (minVal + maxVal) * 0.5;
  }

  void setValue(float v) { defaultVal = v; norm = toNorm(v); }
  float getValue() { return fromNorm(norm); }
  void reset() { norm = toNorm(defaultVal); }

  private float toNorm(float v) {
    if (curve.equals("log")) return (log(v) - log(minVal)) / (log(maxVal) - log(minVal));
    return (v - minVal) / (maxVal - minVal);
  }
  private float fromNorm(float n) {
    n = constrain(n, 0, 1);
    if (curve.equals("log")) return exp(log(minVal) + n * (log(maxVal) - log(minVal)));
    return minVal + n * (maxVal - minVal);
  }

  boolean over(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void render() {
    pushStyle();
    float padLR = 22;
    float trackY = y + h * 0.5 + 6;
    float left   = x + padLR;
    float right  = x + w - padLR;
    float hx     = lerp(left, right, norm);

    // label
    textFont(fontMono); textSize(11);
    fill(TEXT);
    textAlign(LEFT, TOP);
    text(label, x + padLR, y + 8);

    // value
    textAlign(RIGHT, TOP);
    fill(ACCENT);
    text(formatValue(), x + w - padLR, y + 8);

    // ticks
    stroke(LINE);
    strokeWeight(1);
    for (int i = 0; i <= 10; i++) {
      float tx = lerp(left, right, i / 10.0);
      float th = (i % 5 == 0) ? 5 : 2;
      line(tx, trackY - th, tx, trackY + th);
    }

    // track
    stroke(LINE_STRONG);
    strokeWeight(2);
    line(left, trackY, right, trackY);

    // fill
    stroke(ACCENT_SOFT);
    strokeWeight(2);
    line(left, trackY, hx, trackY);

    // handle
    rectMode(CENTER);
    noStroke();
    fill(BG);
    rect(hx, trackY, 16, 24, 3);
    fill(TEXT);
    stroke(ACCENT_SOFT);
    strokeWeight(1);
    rect(hx, trackY, 12, 20, 2);
    rectMode(CORNER);
    popStyle();
  }

  String formatValue() {
    float v = getValue();
    if (percent) return Math.round(v * 100) + "%";
    if (kilo) {
      if (v >= 1000) return nf(v/1000, 0, 2) + " kHz";
      return nf(v, 0, 0) + " Hz";
    }
    if (fmtStr != null) return String.format(fmtStr, v);
    if (abs(v) >= 10) return nf(v, 0, 1);
    return nf(v, 1, 2);
  }

  void checkMousePressed(float mx, float my) {
    if (over(mx, my)) { dragging = true; updateFromMouse(mx); }
  }
  void checkMouseDragged(float mx, float my) { if (dragging) updateFromMouse(mx); }
  void release() { dragging = false; }

  private void updateFromMouse(float mx) {
    float padLR = 22;
    float left  = x + padLR;
    float right = x + w - padLR;
    norm = constrain((mx - left) / (right - left), 0, 1);
  }
}
