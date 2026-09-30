require_relative '../test_helper'

class ViewsTest < Minitest::Test
  def test_base64
    assert_equal "TWFu", CipherWorkbench::Codec::Views.base64("Man")
    assert_equal "TWE=", CipherWorkbench::Codec::Views.base64("Ma")
    assert_equal "TQ==", CipherWorkbench::Codec::Views.base64("M")
  end

  def test_base64_roundtrip_random
    srand(12345)
    100.times do
      bytes = (1..rand(0..100)).map { rand(256).chr }.join.b
      encoded = CipherWorkbench::Codec::Views.base64(bytes)
      decoded = CipherWorkbench::Codec::Views.from_base64(encoded)
      assert_equal bytes, decoded
    end
  end

  def test_from_base64_rejects_invalid
    assert_raises(CipherWorkbench::InvalidCiphertextError) do
      CipherWorkbench::Codec::Views.from_base64("invalid!")
    end
  end

  def test_hex
    assert_equal "00ff41", CipherWorkbench::Codec::Views.hex("\x00\xffA".b)
  end

  def test_letters
    assert_equal "abc", CipherWorkbench::Codec::Views.letters("AbC", case: :lower)
    assert_equal "ABC", CipherWorkbench::Codec::Views.letters("AbC", case: :upper)
  end
end
