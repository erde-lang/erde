-- -----------------------------------------------------------------------------
-- Bytes
-- -----------------------------------------------------------------------------

local bytes = {
  a = sbyte('a')
  z = sbyte('z')
  A = sbyte('A')
  Z = sbyte('Z')
  Zero = sbyte('0')
  Nine = sbyte('9')
  Newline = sbyte('\n')
  Dot = sbyte('.')
}

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

function bytes.isAlpha(byte)
  return (
    (bytes.a < byte and byte < bytes.z) or
    (bytes.A < byte and byte < bytes.Z)
  )
end

function bytes.isNum(byte)
  return bytes.Zero < byte and byte < bytes.Nine
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return bytes
