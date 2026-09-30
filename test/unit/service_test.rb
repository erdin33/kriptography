require_relative '../test_helper'
require_relative '../support/test_ciphers'

class ServiceTest < Minitest::Test
  def test_letters_text
    # text = "ABC" => prepare adds 'X' => "ABCX" => shift 1 => "BCDY"
    input = { kind: :text, text: "A B C!" }
    res = CipherWorkbench::Service.encrypt(cipher_id: "shift_letters", params: {}, input: input)
    
    assert_equal :alpha_filter, res.encoding
    assert_equal "BCDY", res.payload
    
    dec_res = CipherWorkbench::Service.decrypt(cipher_id: "shift_letters", params: {}, source: { type: :container, bytes: res.container })
    assert_equal true, dec_res.text_valid
    assert_equal "ABCX", dec_res.text
  end

  def test_letters_file
    bytes = (0..2048).map { rand(256).chr }.join.b
    input = { kind: :file, filename: "test.bin", bytes: bytes }
    res = CipherWorkbench::Service.encrypt(cipher_id: "shift_letters", params: {}, input: input)
    
    assert_equal :nibble16, res.encoding
    
    dec_res = CipherWorkbench::Service.decrypt(cipher_id: "shift_letters", params: {}, source: { type: :container, bytes: res.container })
    assert_equal false, dec_res.text_valid
    assert_nil dec_res.text
    assert_equal bytes, dec_res.plain_bytes
    assert_equal true, dec_res.integrity[:valid]
  end

  def test_bytes_file
    bytes = (0..2048).map { rand(256).chr }.join.b
    input = { kind: :file, filename: "test.bin", bytes: bytes }
    res = CipherWorkbench::Service.encrypt(cipher_id: "shift_bytes", params: {}, input: input)
    
    assert_equal :raw, res.encoding
    
    dec_res = CipherWorkbench::Service.decrypt(cipher_id: "shift_bytes", params: {}, source: { type: :container, bytes: res.container })
    assert_equal false, dec_res.text_valid
    assert_equal bytes, dec_res.plain_bytes
    assert_equal true, dec_res.integrity[:valid]
  end

  def test_cipher_mismatch
    input = { kind: :text, text: "ABC" }
    res = CipherWorkbench::Service.encrypt(cipher_id: "shift_letters", params: {}, input: input)
    
    assert_raises(CipherWorkbench::CipherMismatchError) do
      CipherWorkbench::Service.decrypt(cipher_id: "shift_bytes", params: {}, source: { type: :container, bytes: res.container })
    end
  end

  def test_paste_base64
    input = { kind: :text, text: "ABC" }
    res = CipherWorkbench::Service.encrypt(cipher_id: "shift_letters", params: {}, input: input)
    
    b64 = CipherWorkbench::Codec::Views.base64(res.payload)
    dec_res = CipherWorkbench::Service.decrypt(cipher_id: "shift_letters", params: {}, source: { type: :text, text: b64, format: :base64 })
    
    assert_equal "ABCX", dec_res.text
  end

  def test_empty_text_rejected
    input = { kind: :text, text: "123!" } # no letters
    assert_raises(CipherWorkbench::InvalidInputError) do
      CipherWorkbench::Service.encrypt(cipher_id: "shift_letters", params: {}, input: input)
    end
  end
  
  def test_empty_file_bytes_accepted
    input = { kind: :file, filename: "empty.bin", bytes: "".b }
    res = CipherWorkbench::Service.encrypt(cipher_id: "shift_bytes", params: {}, input: input)
    dec_res = CipherWorkbench::Service.decrypt(cipher_id: "shift_bytes", params: {}, source: { type: :container, bytes: res.container })
    assert_equal "".b, dec_res.plain_bytes
  end
end
