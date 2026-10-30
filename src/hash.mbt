// 初始化置换表，基于种子打乱

///|
fn init_noise(seed : Int32) -> Array[Int32] {
  let perm_table = init_permutation(seed)

  //重复一遍 0..255 填充，构建最终长度 512 的置换表
  let result = [..perm_table, ..perm_table]
  result
}

///|
fn hash(
  ix : Int32,
  iy : Int32,
  perm_table : Array[Int32],
  grads : Array[Array[Float]],
) -> Array[Float] {
  let idx = perm_table[(perm_table[ix & 511] + iy) & 511] % grads.length()
  grads[idx]
}

///|
fn hash3d(
  ix : Int32,
  iy : Int32,
  iz : Int32,
  perm_table : Array[Int32],
  grads : Array[Array[Float]],
) -> Array[Float] {
  let idx = perm_table[(perm_table[(perm_table[ix & 511] + iy) & 511] + iz) &
    511] %
    grads.length()
  grads[idx]
}

///|
fn hash4d(
  ix : Int32,
  iy : Int32,
  iz : Int32,
  iw : Int32,
  perm_table : Array[Int32],
  grads : Array[Array[Float]],
) -> Array[Float] {
  let idx = perm_table[(
      perm_table[(perm_table[(perm_table[ix & 511] + iy) & 511] + iz) & 511] +
      iw
    ) &
    511] %
    grads.length()
  grads[idx]
}
