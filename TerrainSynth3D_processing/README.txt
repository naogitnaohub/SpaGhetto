TERRAIN VIEWER 3D — pure visualization (no audio, no libraries)

REQUIREMENTS
- Processing 3.5+ or 4.x (https://processing.org)
- No external libraries needed.

HOW TO RUN
1. Keep the folder structure — the folder name must match the main .pde:
       TerrainSynth3D/
         TerrainSynth3D.pde   (main)
         Terrain3D.pde
         Orbit3D.pde
         CameraRig.pde
         HorizontalFader.pde
         Oscilloscope.pde
         sketch.properties
2. Open TerrainSynth3D.pde in Processing.
3. Press Run.

CONTROLS
- Click (no drag) on the 3D viewport: place the orbit center on the terrain.
- Drag in the viewport: rotate the camera (auto-rotate turns off).
- Scroll: zoom in/out.
- Click "CAM . AUTO/MANUAL" toggle (top-right of viewport): toggle auto-rotate.
- Press R: reset the camera.
- Drag the faders on the right:
    SCALE  - controls the terrain function parameter "a"
    RADIUS - orbit radius
    SPEED  - rotation speed of the traveller around the orbit (Hz)
- Double-click a fader: reset to default.

NOTES
- The terrain mesh is 96x96 (~18k triangles). If it stutters,
  lower RES inside Terrain3D.pde to 64.
- The waveform panel on the right shows the function value sampled
  along one full orbit period.
