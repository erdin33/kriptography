require_relative '../test_helper'

class MathModularTest < Minitest::Test
  def test_egcd
    assert_equal [1, 7, -4], CipherWorkbench::Math::Modular.egcd(15, 26)
  end

  def test_mod_inverse
    assert_equal 3, CipherWorkbench::Math::Modular.mod_inverse(9, 26)
    assert_equal 9, CipherWorkbench::Math::Modular.mod_inverse(3, 26)
    
    assert_raises(CipherWorkbench::InvalidKeyError) do
      CipherWorkbench::Math::Modular.mod_inverse(2, 26)
    end
  end

  def test_normalize
    assert_equal 25, CipherWorkbench::Math::Modular.normalize(-1, 26)
  end

  def test_coprime
    assert_equal true, CipherWorkbench::Math::Modular.coprime?(15, 26)
    assert_equal false, CipherWorkbench::Math::Modular.coprime?(14, 26)
  end
end
