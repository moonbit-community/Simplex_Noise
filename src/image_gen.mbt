///|
fn save_png(path : String, png_data : Bytes) -> Bool raise @fs.IOError {
  @fs.write_bytes_to_file(path, png_data)
  true
}

// 渐变色映射工具
// 将 H, S, L 映射为 RGB（输入：h ∈ [0,360], s ∈ [0,1], l ∈ [0,1]）

///|
fn hsl_to_rgb(h : Float, s : Float, l : Float) -> (Byte, Byte, Byte) {
  let c = (1.0 - (2.0 * l.to_double() - 1.0).abs()) * s.to_double()
  let h_ = h / 60.0
  let x = c * (1.0 - (h_.to_double() % 2.0 - 1.0).abs())
  let (r1, g1, b1) = if h_ < 1.0 {
    (c, x, 0.0)
  } else if h_ < 2.0 {
    (x, c, 0.0)
  } else if h_ < 3.0 {
    (0.0, c, x)
  } else if h_ < 4.0 {
    (0.0, x, c)
  } else if h_ < 5.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  let m = l - Float::from_double(c) * 0.5
  fn to_byte_safe(v : Float) -> Byte {
    let p = 0
    let q = 255
    let i = (v * 255.0).to_int()
    if i < 0 {
      p.to_byte()
    } else if i > 255 {
      q.to_byte()
    } else {
      i.to_byte()
    }
  }

  let r = to_byte_safe(Float::from_double(r1) + m)
  let g = to_byte_safe(Float::from_double(g1) + m)
  let b = to_byte_safe(Float::from_double(b1) + m)
  (r, g, b)
}

///|
fn noise_to_color(val : Float) -> @color.RGBA {
  let hue = val * 360.0 % 360.0 // 色相映射（让噪声值对应颜色环）
  let sat : Float = 0.6
  let light : Float = 0.5
  let c = 255
  let (r, g, b) = hsl_to_rgb(hue, sat, light)
  @color.RGBA::new(r, g, b, c.to_byte())
}

// 生成指定尺寸的 2D Simplex Noise图像

///|
fn generate_noise_png_buffer(
  width : Int,
  height : Int,
  scale : Float,
  seed : Int,
  grads : Array[Array[Float]],
  useWarp : Bool, // 添加 useWarp 参数来控制是否使用 warp2d
  isGrayScale : Bool, // 是否生成灰度图
  strength : Float, // 扰动强度
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          // 使用 warp2d（如果 useWarp 为 true）
          warp2d(
            grads,
            [Float::from_int(x), Float::from_int(y)],
            seed,
            scale,
            strength,
          )
        } else {
          // 使用 simplex2d（如果 useWarp 为 false）
          simplex2d(
            [Float::from_int(x), Float::from_int(y)],
            perm_table,
            grads,
            scale,
          )
        }
        // 将噪声值映射到灰度范围
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp2d(
            grads,
            [Float::from_int(x), Float::from_int(y)],
            seed,
            scale,
            strength,
          )
        } else {
          simplex2d(
            [Float::from_int(x), Float::from_int(y)],
            perm_table,
            grads,
            scale,
          )
        }
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 2D fBm 噪声图像

///|
fn generate_fbm_png_buffer(
  width : Int,
  height : Int,
  scale : Float,
  seed : Int,
  octaves : Int,
  persistence : Float,
  lacunarity : Float,
  grads : Array[Array[Float]],
  useWarp : Bool,
  isGrayScale : Bool,
  strength : Float,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp_fbm2d(
            grads,
            [Float::from_int(x), Float::from_int(y)],
            seed,
            scale,
            strength,
            octaves,
            persistence,
            lacunarity,
          )
        } else {
          fbm2d(
            [Float::from_int(x), Float::from_int(y)],
            octaves,
            persistence,
            lacunarity,
            perm_table,
            grads,
            scale,
          )
        }
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp_fbm2d(
            grads,
            [Float::from_int(x), Float::from_int(y)],
            seed,
            scale,
            strength,
            octaves,
            persistence,
            lacunarity,
          )
        } else {
          fbm2d(
            [Float::from_int(x), Float::from_int(y)],
            octaves,
            persistence,
            lacunarity,
            perm_table,
            grads,
            scale,
          )
        }
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 3D Simplex Noise图像

///|
fn generate_noise3d_png_buffer(
  width : Int,
  height : Int,
  scale : Float,
  z : Float,
  seed : Int,
  grads : Array[Array[Float]],
  useWarp : Bool,
  isGrayScale : Bool,
  strength : Float,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp3d(
            grads,
            [Float::from_int(x), Float::from_int(y), z],
            seed,
            scale,
            strength,
          )
        } else {
          simplex3d(
            [Float::from_int(x), Float::from_int(y), z],
            perm_table,
            grads,
            scale,
          )
        }
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp3d(
            grads,
            [Float::from_int(x), Float::from_int(y), z],
            seed,
            scale,
            strength,
          )
        } else {
          simplex3d(
            [Float::from_int(x), Float::from_int(y), z],
            perm_table,
            grads,
            scale,
          )
        }
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 3D fBm 噪声图像

///|
fn generate_fbm3d_png_buffer(
  width : Int,
  height : Int,
  scale : Float,
  z : Float,
  seed : Int,
  octaves : Int,
  persistence : Float,
  lacunarity : Float,
  grads : Array[Array[Float]],
  useWarp : Bool,
  isGrayScale : Bool,
  strength : Float,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp_fbm3d(
            grads,
            [Float::from_int(x), Float::from_int(y), z],
            seed,
            scale,
            strength,
            octaves,
            persistence,
            lacunarity,
          )
        } else {
          fbm3d(
            [Float::from_int(x), Float::from_int(y), z],
            octaves,
            persistence,
            lacunarity,
            perm_table,
            grads,
            scale,
          )
        }
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp_fbm3d(
            grads,
            [Float::from_int(x), Float::from_int(y), z],
            seed,
            scale,
            strength,
            octaves,
            persistence,
            lacunarity,
          )
        } else {
          fbm3d(
            [Float::from_int(x), Float::from_int(y), z],
            octaves,
            persistence,
            lacunarity,
            perm_table,
            grads,
            scale,
          )
        }
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 4D Simplex 噪声图像

///|
fn generate_noise4d_png_buffer(
  width : Int,
  height : Int,
  scale : Float,
  z : Float,
  w : Float,
  seed : Int,
  grads : Array[Array[Float]],
  useWarp : Bool,
  isGrayScale : Bool,
  strength : Float,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp4d(
            grads,
            [Float::from_int(x), Float::from_int(y), z, w],
            seed,
            scale,
            strength,
          )
        } else {
          simplex4d(
            [Float::from_int(x), Float::from_int(y), z, w],
            perm_table,
            grads,
            scale,
          )
        }
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp4d(
            grads,
            [Float::from_int(x), Float::from_int(y), z, w],
            seed,
            scale,
            strength,
          )
        } else {
          simplex4d(
            [Float::from_int(x), Float::from_int(y), z, w],
            perm_table,
            grads,
            scale,
          )
        }
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 4D fBm 噪声图像

///|
fn generate_fbm4d_png_buffer(
  width : Int,
  height : Int,
  scale : Float,
  z : Float,
  w : Float,
  seed : Int,
  octaves : Int,
  persistence : Float,
  lacunarity : Float,
  grads : Array[Array[Float]],
  useWarp : Bool,
  isGrayScale : Bool,
  strength : Float,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp_fbm4d(
            grads,
            [Float::from_int(x), Float::from_int(y), z, w],
            seed,
            scale,
            strength,
            octaves,
            persistence,
            lacunarity,
          )
        } else {
          fbm4d(
            [Float::from_int(x), Float::from_int(y), z, w],
            octaves,
            persistence,
            lacunarity,
            perm_table,
            grads,
            scale,
          )
        }
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let val = if useWarp {
          warp_fbm4d(
            grads,
            [Float::from_int(x), Float::from_int(y), z, w],
            seed,
            scale,
            strength,
            octaves,
            persistence,
            lacunarity,
          )
        } else {
          fbm4d(
            [Float::from_int(x), Float::from_int(y), z, w],
            octaves,
            persistence,
            lacunarity,
            perm_table,
            grads,
            scale,
          )
        }
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 2D 平铺 Simplex Noise 图像

///|
fn generate_tileable_noise2d_image(
  width : Int,
  height : Int,
  scale : Float,
  seed : Int,
  grads : Array[Array[Float]],
  pi : Double,
  isGrayScale : Bool,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y)]
        let val = tileable_noise2d(
          p, perm_table, grads, scale, width, height, pi,
        )
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y)]
        let val = tileable_noise2d(
          p, perm_table, grads, scale, width, height, pi,
        )
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 2D 平铺 fBm 噪声图像（支持灰度和彩色）

///|
fn generate_tileable_fbm2d_image(
  width : Int,
  height : Int,
  config : NoiseConfig,
  seed : Int,
  grads : Array[Array[Float]],
  pi : Double,
  isGrayScale : Bool,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y)]
        let val = tileable_fbm2d(
          p,
          perm_table,
          grads,
          config.scale,
          config.octaves,
          config.persistence,
          config.lacunarity,
          width,
          height,
          pi,
        )
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y)]
        let val = tileable_fbm2d(
          p,
          perm_table,
          grads,
          config.scale,
          config.octaves,
          config.persistence,
          config.lacunarity,
          width,
          height,
          pi,
        )
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 3D 平铺 Simplex Noise 图像

///|
fn generate_tileable_noise3d_image(
  width : Int,
  height : Int,
  depth : Int,
  z : Float,
  scale : Float,
  seed : Int,
  grads : Array[Array[Float]],
  pi : Double,
  isGrayScale : Bool,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z]
        let val = tileable_noise3d(
          p, perm_table, grads, scale, width, height, depth, pi,
        )
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z]
        let val = tileable_noise3d(
          p, perm_table, grads, scale, width, height, depth, pi,
        )
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 3D 平铺 fBm 噪声图像

///|
fn generate_tileable_fbm3d_image(
  width : Int,
  height : Int,
  depth : Int,
  z : Float,
  config : NoiseConfig,
  seed : Int,
  grads : Array[Array[Float]],
  pi : Double,
  isGrayScale : Bool,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z]
        let val = tileable_fbm3d(
          p,
          perm_table,
          grads,
          config.scale,
          config.octaves,
          config.persistence,
          config.lacunarity,
          width,
          height,
          depth,
          pi,
        )
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z]
        let val = tileable_fbm3d(
          p,
          perm_table,
          grads,
          config.scale,
          config.octaves,
          config.persistence,
          config.lacunarity,
          width,
          height,
          depth,
          pi,
        )
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 4D 平铺 Simplex Noise 图像

///|
fn generate_tileable_noise4d_image(
  width : Int,
  height : Int,
  depth : Int,
  time : Int,
  z : Float,
  w : Float,
  seed : Int,
  scale : Float,
  grads : Array[Array[Float]],
  pi : Double,
  isGrayScale : Bool,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z, w]
        let val = tileable_noise4d(
          p, perm_table, grads, scale, width, height, depth, time, pi,
        )
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z, w]
        let val = tileable_noise4d(
          p, perm_table, grads, scale, width, height, depth, time, pi,
        )
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}

// 生成指定尺寸的 4D 平铺 fBm 噪声图像

///|
fn generate_tileable_fbm4d_image(
  width : Int,
  height : Int,
  depth : Int,
  time : Int,
  z : Float,
  w : Float,
  seed : Int,
  config : NoiseConfig,
  grads : Array[Array[Float]],
  pi : Double,
  isGrayScale : Bool,
) -> Bytes raise @image.SizeError {
  let buf = @io.Buffer::new(size_hint=1024)
  let perm_table = init_noise(seed)
  let bounds = @image.rect(0, 0, width, height)
  if isGrayScale {
    let img = @image.Gray::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z, w]
        let val = tileable_fbm4d(
          p,
          perm_table,
          grads,
          config.scale,
          config.octaves,
          config.persistence,
          config.lacunarity,
          width,
          height,
          depth,
          time,
          pi,
        )
        let raw_val = (val + 1.0) * 0.5 * 255.0
        let gray_val = if raw_val < 0.0 {
          0
        } else if raw_val > 255.0 {
          255
        } else {
          raw_val.to_int()
        }
        img.set_gray(x, y, @color.Gray::new(gray_val.to_byte()))
      }
    }
    ignore(@png.encode(buf, img))
  } else {
    let img = @image.RGBA::new(bounds)
    for y in 0..<height {
      for x in 0..<width {
        let p = [Float::from_int(x), Float::from_int(y), z, w]
        let val = tileable_fbm4d(
          p,
          perm_table,
          grads,
          config.scale,
          config.octaves,
          config.persistence,
          config.lacunarity,
          width,
          height,
          depth,
          time,
          pi,
        )
        let normalized_val = (val + 1.0) * 0.5
        let color = noise_to_color(normalized_val)
        img.set_rgba(x, y, color)
      }
    }
    ignore(@png.encode(buf, img))
  }
  return buf.to_bytes()
}
