// Gestione mouse.

float lastMx, lastMy;
boolean dragInView = false;

// Double-click local tracking parameters to prevent missing field compilation errors
long globalLastClickTime = 0;
HorizontalFader lastClickedFader = null;

boolean overViewport(float mx, float my) {
  return mx >= viewX && mx <= viewX+viewW && my >= viewY && my <= viewY+viewH;
}

void mousePressed() {
  if (overViewport(mouseX, mouseY)) {
    dragInView = true; lastMx = mouseX; lastMy = mouseY; return;
  }
  if (minimap.over(mouseX, mouseY)) {
    minimap.handleClick(mouseX, mouseY, orbit); return;
  }
  
  for (HorizontalFader f : faders) {
    f.checkMousePressed(mouseX, mouseY);
    if (f.over(mouseX, mouseY) && net != null) {
      if (f == fScale)  net.transmit("/processing/scale",  f.getValue());
      if (f == fRadius) net.transmit("/processing/radius", f.getValue());
      if (f == fSpeed)  net.transmit("/processing/speed",  f.getValue());
    }
  }
}

void mouseDragged() {
  if (dragInView) {
    cam.mouseDrag(mouseX - lastMx, mouseY - lastMy);
    lastMx = mouseX; lastMy = mouseY; return;
  }
  if (minimap.over(mouseX, mouseY)) {
    minimap.handleClick(mouseX, mouseY, orbit); return;
  }
  
  for (HorizontalFader f : faders) {
    f.checkMouseDragged(mouseX, mouseY);
    if (f.over(mouseX, mouseY) && net != null) {
      if (f == fScale)  net.transmit("/processing/scale",  f.getValue());
      if (f == fRadius) net.transmit("/processing/radius", f.getValue());
      if (f == fSpeed)  net.transmit("/processing/speed",  f.getValue());
    }
  }
}

void mouseReleased() {
  dragInView = false;
  long now = millis();
  
  for (HorizontalFader f : faders) {
    if (f.over(mouseX, mouseY)) {
      if (net != null) {
        if (f == fScale)  net.transmit("/processing/scale",  f.getValue());
        if (f == fRadius) net.transmit("/processing/radius", f.getValue());
        if (f == fSpeed)  net.transmit("/processing/speed",  f.getValue());
      }
      
      // Double-click mechanic: reset to setup values if clicked within 350ms
      if (f == lastClickedFader && (now - globalLastClickTime) < 350) {
        if (f == fScale)  f.setValue(1.5f);
        if (f == fRadius) f.setValue(2.0f);
        if (f == fSpeed)  f.setValue(1.0f);
        
        if (net != null) {
          if (f == fScale)  net.transmit("/processing/scale",  f.getValue());
          if (f == fRadius) net.transmit("/processing/radius", f.getValue());
          if (f == fSpeed)  net.transmit("/processing/speed",  f.getValue());
        }
        lastClickedFader = null; 
        globalLastClickTime = 0;
      } else {
        lastClickedFader = f;
        globalLastClickTime = now;
      }
    }
    f.release();
  }
}

void mouseWheel(MouseEvent e) {
  if (overViewport(mouseX, mouseY)) cam.mouseWheel(e.getCount());
}
