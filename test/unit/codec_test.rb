require_relative '../test_helper'

class CodecTest < Minitest::Test
  def test_filter_letters
    assert_equal "DIBAWAHSINAR", CipherWorkbench::Codec::LetterCodec.filter_letters("Di bawah sinar, 2026!")
  end

  def test_nibble_alphabet
    assert_equal 16, CipherWorkbench::Codec::LetterCodec::NIBBLE_ALPHABET.length
    assert_equal 16, CipherWorkbench::Codec::LetterCodec::NIBBLE_ALPHABET.chars.uniq.length
    refute_includes CipherWorkbench::Codec::LetterCodec::NIBBLE_ALPHABET, 'J'
  end

  def test_nibble_roundtrip_all_bytes
    all_bytes = (0..255).map(&:chr).join.b
    encoded = CipherWorkbench::Codec::LetterCodec.nibble_encode(all_bytes)
    decoded = CipherWorkbench::Codec::LetterCodec.nibble_decode(encoded, byte_length: 256)
    assert_equal all_bytes, decoded
  end

  def test_nibble_roundtrip_random
    srand(12345)
    100.times do
      len = rand(0..1000)
      bytes = (1..len).map { rand(256).chr }.join.b
      encoded = CipherWorkbench::Codec::LetterCodec.nibble_encode(bytes)
      decoded = CipherWorkbench::Codec::LetterCodec.nibble_decode(encoded, byte_length: len)
      assert_equal bytes, decoded
    end
  end

  def test_nibble_decode_filters_x
    encoded = "ABCD"
    encoded_with_x = "ABXCDX"
    decoded = CipherWorkbench::Codec::LetterCodec.nibble_decode(encoded_with_x, byte_length: 2)
    assert_equal CipherWorkbench::Codec::LetterCodec.nibble_decode(encoded, byte_length: 2), decoded
  end

  def test_nibble_decode_too_short
    assert_raises(CipherWorkbench::InvalidCiphertextError) do
      CipherWorkbench::Codec::LetterCodec.nibble_decode("ABC", byte_length: 2)
    end
  end
end
