///|
fn simplex3d(
  p : Array[Float],
  perm_table : Array[Int],
  grads : Array[Array[Float]],
  scale : Float,
) -> Float {
  let f3 = 1.0 / 3.0
  let g3 = 1.0 / 6.0

  let nx = p[0] * scale
  let ny = p[1] * scale
  let nz = p[2] * scale

  let s = (nx + ny + nz).to_double() * f3
  let i = @math.floor(nx.to_double() + s).to_int()
  let j = @math.floor(ny.to_double() + s).to_int()
  let k = @math.floor(nz.to_double() + s).to_int()

  let t = (Float::from_int(i) + Float::from_int(j) + Float::from_int(k)) *
    Float::from_double(g3)
  let x0 = nx - (Float::from_int(i) - t)
  let y0 = ny - (Float::from_int(j) - t)
  let z0 = nz - (Float::from_int(k) - t)

  let mut ijk1 = [0, 0, 0]
  let mut ijk2 = [0, 0, 0]

  if x0 >= y0 {
    if y0 >= z0 {
      ijk1 = [1, 0, 0]
      ijk2 = [1, 1, 0]
    } else if x0 >= z0 {
      ijk1 = [1, 0, 0]
      ijk2 = [1, 0, 1]
    } else {
      ijk1 = [0, 0, 1]
      ijk2 = [1, 0, 1]
    }
  } else if y0 < z0 {
    ijk1 = [0, 0, 1]
    ijk2 = [0, 1, 1]
  } else if x0 < z0 {
    ijk1 = [0, 1, 0]
    ijk2 = [0, 1, 1]
  } else {
    ijk1 = [0, 1, 0]
    ijk2 = [1, 1, 0]
  }

  let x1 = x0 - Float::from_double(ijk1[0].to_double() + g3)
  let y1 = y0 - Float::from_double(ijk1[1].to_double() + g3)
  let z1 = z0 - Float::from_double(ijk1[2].to_double() + g3)

  let x2 = x0 - Float::from_double(ijk2[0].to_double() + 2.0 * g3)
  let y2 = y0 - Float::from_double(ijk2[1].to_double() + 2.0 * g3)
  let z2 = z0 - Float::from_double(ijk2[2].to_double() + 2.0 * g3)

  let x3 = x0 - 1.0 + 3.0 * Float::from_double(g3)
  let y3 = y0 - 1.0 + 3.0 * Float::from_double(g3)
  let z3 = z0 - 1.0 + 3.0 * Float::from_double(g3)

  let gi0 = hash3d(i, j, k, perm_table, grads)
  let gi1 = hash3d(i + ijk1[0], j + ijk1[1], k + ijk1[2], perm_table, grads)
  let gi2 = hash3d(i + ijk2[0], j + ijk2[1], k + ijk2[2], perm_table, grads)
  let gi3 = hash3d(i + 1, j + 1, k + 1, perm_table, grads)

  let mut n0 = 0.0
  let mut n1 = 0.0
  let mut n2 = 0.0
  let mut n3 = 0.0

  let t0 = 0.6 - (x0 * x0 + y0 * y0 + z0 * z0).to_double()
  if t0 >= 0.0 {
    let t0_2 = t0 * t0
    n0 = t0_2 * t0_2 * (gi0[0] * x0 + gi0[1] * y0 + gi0[2] * z0).to_double()
  }

  let t1 = 0.6 - (x1 * x1 + y1 * y1 + z1 * z1).to_double()
  if t1 >= 0.0 {
    let t1_2 = t1 * t1
    n1 = t1_2 * t1_2 * (gi1[0] * x1 + gi1[1] * y1 + gi1[2] * z1).to_double()
  }

  let t2 = 0.6 - (x2 * x2 + y2 * y2 + z2 * z2).to_double()
  if t2 >= 0.0 {
    let t2_2 = t2 * t2
    n2 = t2_2 * t2_2 * (gi2[0] * x2 + gi2[1] * y2 + gi2[2] * z2).to_double()
  }

  let t3 = 0.6 - (x3 * x3 + y3 * y3 + z3 * z3).to_double()
  if t3 >= 0.0 {
    let t3_2 = t3 * t3
    n3 = t3_2 * t3_2 * (gi3[0] * x3 + gi3[1] * y3 + gi3[2] * z3).to_double()
  }

  32.0 * Float::from_double(n0 + n1 + n2 + n3)
}
