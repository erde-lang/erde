local bytes = {
  a = sbyte('a')
  z = sbyte('z')
  A = sbyte('A')
  Z = sbyte('Z')
  Newline = sbyte('\n')
  Dot = sbyte('.')
}

function bytes.isAlpha(byte)
  return (
    (bytes.a < byte and byte < bytes.z) or
    (bytes.A < byte and byte < bytes.Z)
  )
end

return bytes
