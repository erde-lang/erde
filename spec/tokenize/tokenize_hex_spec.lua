local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_token = spec_utils.assert_token
local assert_tokens = spec_utils.assert_tokens

describe('tokenize_hex', function()
  spec('#5.1+', function()
    assert_token('1', '0x1')
    assert_token('1', '0X1')

    assert_token('4886718345', '0x123456789')
    assert_token('11259375', '0xabcdef')
    assert_token('11259375', '0xABCDEF')
    assert_token('41394', '0xa1B2')

    assert_token('0.0625', '0x.1')
    assert_token('13.625', '0xd.a')

    assert_token('3.75', '0xfp-2')
    assert_tokens({ '15', '.' }, '0xf.')

    assert.has_error(function() tokenize('0x') end)
    assert.has_error(function() tokenize('0xg') end)
    assert.has_error(function() tokenize('0x.') end)
    assert.has_error(function() tokenize('0x.g') end)
    assert.has_error(function() tokenize('0x.p1') end)
    assert.has_error(function() tokenize('0xfp') end)
    assert.has_error(function() tokenize('0xfp+') end)
    assert.has_error(function() tokenize('0xfp-') end)
    assert.has_error(function() tokenize('0xfpa') end)
  end)

  spec('#5.1 #5.2 #jit', function()
    assert_token('30', '0xfp1')
    assert_token('30', '0xfP1')
    assert_token('60', '0xfp+2')
  end)

  spec('#5.3+', function()
    assert_token('30.0', '0xfp1')
    assert_token('30.0', '0xfP1')
    assert_token('60.0', '0xfp+2')
  end)
end)
