class Terrain3D {
  final int   RES    = 120;
  final float SPAN   = 16.0;
  // Modified versoin of waveTerrain that allows changes between 4 functions to draw the terrain
  int waveNumber = 2;
  
  final float YSCALE = -1.7;
  final float EPS    = 0.05;

  float a = 1.5;
  float b = 1.; // added b parameter
  PShape mesh;
  boolean dirty = true;

  void  setA(float v) { if (abs(v - a) > 0.001) { a = v; dirty = true; } }
  float getA()        { return a; }

  
  // New function to generate waveterrain : switch btw 4 differents functions
  float terrain(int waveNumber, float x, float z){
    
    if (waveNumber == 1) { return sin( (z*sin(z) - x*sin(x) * log(z*z + 1)) / a ); }
    else if (waveNumber == 2) { return sin(a * (x*x + z*z) ); }
    else if (waveNumber == 3) { return sin(a * exp(b* (z*z + x*x)) ); }
    else { return sin(a*z*x) * cos(a*(z*z - x*x)) ; }
    
  }

  void render(PGraphics g) {
    if (dirty) rebuild(g);
    g.shape(mesh);
  }

  private void rebuild(PGraphics g) {
    float step = SPAN / (RES - 1);
    float half = SPAN * 0.5;

    // arrays paralleli: altezza, normale (3 comp.), colore
    float[][] hy = new float[RES][RES];
    float[][] nx = new float[RES][RES];
    float[][] ny = new float[RES][RES];
    float[][] nz = new float[RES][RES];
    int  [][] cc = new int  [RES][RES];

    for (int j = 0; j < RES; j++) {
      float z = -half + j*step;
      for (int i = 0; i < RES; i++) {
        float x = -half + i*step;
        float h = terrain(waveNumber, x, z);
        // differenze finite per le normali
        float dyx = (terrain(waveNumber, x + EPS, z) - h) / EPS * YSCALE;
        float dyz = (terrain(waveNumber, x, z + EPS) - h) / EPS * YSCALE;
        float len = sqrt(dyx*dyx + 1 + dyz*dyz);
        hy[j][i] = h * YSCALE;
        nx[j][i] = -dyx / len;
        ny[j][i] =  1.0 / len;
        nz[j][i] = -dyz / len;
        // colore dall'altezza
        float t = constrain((h + 1) * 0.5, 0.0, 1.0); 
        cc[j][i] = getGradientColor(t); 
      }
    }
    
   
    mesh = g.createShape();
    mesh.beginShape(TRIANGLES);
    mesh.noStroke();
    for (int j = 0; j < RES - 1; j++) {
      float z0 = -half + j*step, z1 = z0 + step;
      for (int i = 0; i < RES - 1; i++) {
        float x0 = -half + i*step, x1 = x0 + step;
        addV(x0, hy[j  ][i  ], z0, nx[j  ][i  ], ny[j  ][i  ], nz[j  ][i  ], cc[j  ][i  ]);
        addV(x1, hy[j  ][i+1], z0, nx[j  ][i+1], ny[j  ][i+1], nz[j  ][i+1], cc[j  ][i+1]);
        addV(x0, hy[j+1][i  ], z1, nx[j+1][i  ], ny[j+1][i  ], nz[j+1][i  ], cc[j+1][i  ]);
        addV(x1, hy[j  ][i+1], z0, nx[j  ][i+1], ny[j  ][i+1], nz[j  ][i+1], cc[j  ][i+1]);
        addV(x1, hy[j+1][i+1], z1, nx[j+1][i+1], ny[j+1][i+1], nz[j+1][i+1], cc[j+1][i+1]);
        addV(x0, hy[j+1][i  ], z1, nx[j+1][i  ], ny[j+1][i  ], nz[j+1][i  ], cc[j+1][i  ]);
      }
    }
    mesh.endShape();
    dirty = false;
  }

  private void addV(float x, float y, float z, float nx, float ny, float nz, int col) {
    mesh.normal(nx, ny, nz);
    mesh.fill(col);
    mesh.vertex(x, y, z);
  }
  
  
    //******************************** NEW ç*******************************
      // Changes wave index and flags the mesh to rebuild automatically
  void setWaveNumber(int num) {
    if (waveNumber != num) {
      waveNumber = num;
      dirty = true;
    }
  }

  // Updates parameter 'b' for the exponential wave formula
  void setB(float v) {
    if (abs(v - b) > 0.001) {
      b = v;
      dirty = true;
    }
  }
  
  private int getGradientColor(float t) {
    // Define your palette stops
    int col1 = color(12, 11, 10);     // Deep valley floor (Matches your BG black)
    int col2 = color(137, 70, 239);   // Slopes: Bright Pink/Magenta (AMBER global color)
    int col3 = color(255, 255, 0);   // Ridges: Neon Green (ACCENT global color)
    int col4 = color(74, 222, 128);  // Peaks: Pure crisp white highlight
  
    if (t < 0.33) {
      // First segment: Valleys to Slopes
      return lerpColor(col1, col2, map(t, 0, 0.33, 0, 1));
    } else if (t < 0.66) {
      // Second segment: Slopes to Ridges
      return lerpColor(col2, col3, map(t, 0.33, 0.66, 0, 1));
    } else {
      // Third segment: Ridges to Peaks
      return lerpColor(col3, col4, map(t, 0.66, 1, 0, 1));
    }
  }

}
    
    
    
   
