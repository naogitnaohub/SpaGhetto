class Terrain3D {
  final int   RES          = 96;       // 96x96 grid (lower than web for Processing perf)
  final float SPAN         = 16.0;     // domain [-8, +8]
  final float HEIGHT_SCALE = -1.7;

  float a = 1.5;
  private PShape mesh;
  private boolean dirty = true;

  void setA(float newA) {
    if (abs(newA - a) > 0.001) { a = newA; dirty = true; }
  }
  float getA() { return a; }

  // analytical terrain function (matches web port)
  float terrain(float x, float z) {
  return sin((z * sin(z) - x * sin(x) * log(z*z + 1)) / a);
}

  void render(PGraphics g) {
    if (dirty) rebuild(g);
    g.shape(mesh);
  }

  private void rebuild(PGraphics g) {
    float step = SPAN / (RES - 1);
    float half = SPAN * 0.5;

    // precompute heights, normals, colors
    float[][] hy = new float[RES][RES];
    float[][] nx = new float[RES][RES];
    float[][] ny = new float[RES][RES];
    float[][] nz = new float[RES][RES];
    int[][]   cc = new int[RES][RES];

    for (int j = 0; j < RES; j++) {
      float z = -half + j * step;
      float sinZ = sin(z), cosZ = cos(z);
      for (int i = 0; i < RES; i++) {
        float x = -half + i * step;
        float sinX = sin(x), cosX = cos(x);
        float logArg = log(z*z + 1);
        float arg = (z*sinZ - x*sinX*logArg) / a;
        float h = sin(arg);
        hy[j][i] = h * HEIGHT_SCALE;

        float cosArg  = cos(arg);
        float dArg_dx = (-(sinX + x*cosX) * logArg) / a;
        float dArg_dz = (sinZ + z*cosZ - x*sinX * (2*z / (z*z + 1))) / a;
        float dyx = cosArg * dArg_dx * HEIGHT_SCALE;
        float dyz = cosArg * dArg_dz * HEIGHT_SCALE;
        float len = sqrt(dyx*dyx + 1 + dyz*dyz);
        nx[j][i] = -dyx / len;
        ny[j][i] =  1.0 / len;
        nz[j][i] = -dyz / len;
  



        float t = (h + 1) * 0.5;
        int r = (int)lerp(10,   80, t);
int gr= (int)lerp(20,  240, t);
int b = (int)lerp(18,  120, t);

        cc[j][i] = 0xFF000000 | (r << 16) | (gr << 8) | b;
      }
    }

    mesh = g.createShape();
    mesh.beginShape(TRIANGLES);
    mesh.noStroke();

    for (int j = 0; j < RES - 1; j++) {
      float z0 = -half + j * step;
      float z1 = z0 + step;
      for (int i = 0; i < RES - 1; i++) {
        float x0 = -half + i * step;
        float x1 = x0 + step;

        // tri 1
        addV(mesh, x0, hy[j  ][i  ], z0, nx[j  ][i  ], ny[j  ][i  ], nz[j  ][i  ], cc[j  ][i  ]);
        addV(mesh, x1, hy[j  ][i+1], z0, nx[j  ][i+1], ny[j  ][i+1], nz[j  ][i+1], cc[j  ][i+1]);
        addV(mesh, x0, hy[j+1][i  ], z1, nx[j+1][i  ], ny[j+1][i  ], nz[j+1][i  ], cc[j+1][i  ]);
        // tri 2
        addV(mesh, x1, hy[j  ][i+1], z0, nx[j  ][i+1], ny[j  ][i+1], nz[j  ][i+1], cc[j  ][i+1]);
        addV(mesh, x1, hy[j+1][i+1], z1, nx[j+1][i+1], ny[j+1][i+1], nz[j+1][i+1], cc[j+1][i+1]);
        addV(mesh, x0, hy[j+1][i  ], z1, nx[j+1][i  ], ny[j+1][i  ], nz[j+1][i  ], cc[j+1][i  ]);
      }
    }
    mesh.endShape();
    dirty = false;
  }

  private void addV(PShape sh, float x, float y, float z,
                    float nx_, float ny_, float nz_, int col) {
    sh.normal(nx_, ny_, nz_);
    sh.fill(col);
    sh.vertex(x, y, z);
  }
}
