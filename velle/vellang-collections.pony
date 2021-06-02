
class VList
  let inner: Array[AtomValue]val
  new val create(v': Array[AtomValue]val) =>
    inner = v'
  new val concat(total: Array[VList val]val) =>
    var size': USize = 0
    for subarr in total.values() do size' = size' + subarr.inner.size() end

    let temp = recover Array[AtomValue](size') end
    for subarr in total.values() do
      for v in subarr.inner.values() do
        temp.push(v)
      end
    end
    inner = consume temp

  fun apply(idx: USize): AtomValue =>
    try inner(idx)? else Error("Can't find index " + idx.string()) end

  fun slice(start: USize, iend: USize): VList val =>
    VList(recover inner.slice(start, iend) end)

  fun string(): String iso^ =>
    "(: " + " ".join(inner.values()) + " )"

  fun eq(other: VList val): Bool =>
    if inner.size() != other.inner.size() then return false end
    var i: USize = 0
    while true do
      try
        let v1 = inner(i)?
        let v2 = other.inner(i)?
        if not VellangStd.compare(v1, v2) then return false end
      else break end
    i = i + 1 end
    true
