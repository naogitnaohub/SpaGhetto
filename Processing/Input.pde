// Gestione mouse.

float lastMx, lastMy;
boolean dragInView = false;

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
  for (HorizontalFader f : faders) f.checkMousePressed(mouseX, mouseY);
}

void mouseDragged() {
  if (dragInView) {
    cam.mouseDrag(mouseX - lastMx, mouseY - lastMy);
    lastMx = mouseX; lastMy = mouseY; return;
  }
  if (minimap.over(mouseX, mouseY)) {
    minimap.handleClick(mouseX, mouseY, orbit); return;
  }
  for (HorizontalFader f : faders) f.checkMouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  dragInView = false;
  for (HorizontalFader f : faders) f.release();
}

void mouseWheel(MouseEvent e) {
  if (overViewport(mouseX, mouseY)) cam.mouseWheel(e.getCount());
}
