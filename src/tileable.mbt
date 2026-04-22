fn tileable_noise2d(
  p: Array[Float], // 原始坐标
  perm_table: Array[Int],
  grads: Array[Array[Float]],
  scale: Float,
  width: Int,
  height: Int,
  pi: Double 
) -> Float {
  let angle_x = 2.0 * pi * p[0].to_double() / width.to_double()
  let angle_y = 2.0 * pi * p[1].to_double() / height.to_double()
  let tiled_x = Float::from_double(@math.cos(angle_x))
  let tiled_y = Float::from_double(@math.sin(angle_y))
  return simplex2d([tiled_x, tiled_y ], perm_table, grads, scale)
}

// 2D fBm 平铺噪声
fn tileable_fbm2d(
  p: Array[Float],
  perm_table: Array[Int],
  grads: Array[Array[Float]],
  scale: Float,
  octaves: Int,
  persistence: Float,
  lacunarity: Float,
  width: Int,
  height: Int,
  pi: Double 
) -> Float {
  let angle_x = 2.0 * pi * p[0].to_double() / width.to_double()
  let angle_y = 2.0 * pi * p[1].to_double() / height.to_double()
  let tiled_x = Float::from_double(@math.cos(angle_x))
  let tiled_y = Float::from_double(@math.sin(angle_y))

  return fbm2d(
    [tiled_x, tiled_y],
    octaves,
    persistence,
    lacunarity,
    perm_table,
    grads,
    scale,
  )
}



// 3D 平铺噪声
fn tileable_noise3d(
  p: Array[Float],
  perm_table: Array[Int],
  grads: Array[Array[Float]],
  scale: Float,
  width: Int,
  height: Int,
  depth: Int,
  pi: Double 
) -> Float {
  let angle_x = 2.0 * pi * p[0].to_double() / width.to_double()
  let angle_y = 2.0 * pi * p[1].to_double() / height.to_double()
  let angle_z = 2.0 * pi * p[2].to_double() / depth.to_double()
  let tiled_x = Float::from_double(@math.cos(angle_x))
  let tiled_y = Float::from_double(@math.sin(angle_y))
  let tiled_z = Float::from_double(@math.cos(angle_z))
  return simplex3d([tiled_x, tiled_y, tiled_z], perm_table, grads, scale)
}

// 3D fBm 平铺噪声
fn tileable_fbm3d(
  p: Array[Float],
  perm_table: Array[Int],
  grads: Array[Array[Float]],
  scale: Float,
  octaves: Int,
  persistence: Float,
  lacunarity: Float,
  width: Int,
  height: Int,
  depth: Int,
  pi: Double 
) -> Float {
  let angle_x = 2.0 * pi * p[0].to_double() / width.to_double()
  let angle_y = 2.0 * pi * p[1].to_double() / height.to_double()
  let angle_z = 2.0 * pi * p[2].to_double() / depth.to_double()
  let tiled_x = Float::from_double(@math.cos(angle_x))
  let tiled_y = Float::from_double(@math.sin(angle_y))
  let tiled_z = Float::from_double(@math.cos(angle_z))
  return fbm3d(
    [tiled_x, tiled_y, tiled_z],
    octaves,
    persistence,
    lacunarity,
    perm_table,
    grads,
    scale,
  )
}

// 4D 平铺噪声
fn tileable_noise4d(
  p: Array[Float],
  perm_table: Array[Int],
  grads: Array[Array[Float]],
  scale: Float,
  width: Int,
  height: Int,
  depth: Int,
  time: Int,
  pi: Double 
) -> Float {
  let angle_x = 2.0 * pi * p[0].to_double() / width.to_double()
  let angle_y = 2.0 * pi * p[1].to_double() / height.to_double()
  let angle_z = 2.0 * pi * p[2].to_double() / depth.to_double()
  let angle_w = 2.0 * pi * p[3].to_double() / time.to_double()
  let tiled_x = Float::from_double(@math.cos(angle_x))
  let tiled_y = Float::from_double(@math.sin(angle_y))
  let tiled_z = Float::from_double(@math.cos(angle_z))
  let tiled_w = Float::from_double(@math.sin(angle_w))
  return simplex4d([tiled_x, tiled_y, tiled_z, tiled_w], perm_table, grads, scale)
}

// 4D fBm 平铺噪声
fn tileable_fbm4d(
  p: Array[Float],
  perm_table: Array[Int],
  grads: Array[Array[Float]],
  scale: Float,
  octaves: Int,
  persistence: Float,
  lacunarity: Float,
  width: Int,
  height: Int,
  depth: Int,
  time: Int,
  pi: Double 
) -> Float {
  let angle_x = 2.0 * pi * p[0].to_double() / width.to_double()
  let angle_y = 2.0 * pi * p[1].to_double() / height.to_double()
  let angle_z = 2.0 * pi * p[2].to_double() / depth.to_double()
  let angle_w = 2.0 * pi * p[3].to_double() / time.to_double()
  let tiled_x = Float::from_double(@math.cos(angle_x))
  let tiled_y = Float::from_double(@math.sin(angle_y))
  let tiled_z = Float::from_double(@math.cos(angle_z))
  let tiled_w = Float::from_double(@math.sin(angle_w))
  return fbm4d(
    [tiled_x, tiled_y, tiled_z, tiled_w],
    octaves,
    persistence,
    lacunarity,
    perm_table,
    grads,
    scale,
  )
}
