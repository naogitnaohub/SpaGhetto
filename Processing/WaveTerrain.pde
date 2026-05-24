class Terrain3D {
  final int   RES    = 96;
  final float SPAN   = 16.0;
  final float YSCALE = -1.7;
  final float EPS    = 0.05;

  float a = 1.5;
  PShape mesh;
  boolean dirty = true;

  void  setA(float v) { if (abs(v - a) > 0.001) { a = v; dirty = true; } }
  float getA()        { return a; }

  float terrain(float x, float z) {
    return sin( (z*sin(z) - x*sin(x) * log(z*z + 1)) / a );
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
        float h = terrain(x, z);
        // differenze finite per le normali
        float dyx = (terrain(x + EPS, z) - h) / EPS * YSCALE;
        float dyz = (terrain(x, z + EPS) - h) / EPS * YSCALE;
        float len = sqrt(dyx*dyx + 1 + dyz*dyz);
        hy[j][i] = h * YSCALE;
        nx[j][i] = -dyx / len;
        ny[j][i] =  1.0 / len;
        nz[j][i] = -dyz / len;
        // colore dall'altezza
        float t = (h + 1) * 0.5;
        cc[j][i] = color(lerp(10, 80, t), lerp(20, 240, t), lerp(18, 120, t));
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
}
