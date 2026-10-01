require 'minitest/autorun'
require 'json'
require_relative '../../../lib/cipher_workbench'

class Bug003JsonInvalidUtf8Test < Minitest::Test
  def test_invalid_utf8_does_not_crash_json_generator
    # Encrypt a payload that is valid bytes (0xFF).
    res_enc = CipherWorkbench::Service.encrypt(
      cipher_id: 'extended_vigenere',
      params: { 'key' => 'A' },
      input: { kind: :text, text: "\xFF".b } # This is invalid UTF-8 but valid bytes!
    )
    
    # Decrypt from container
    res_dec = CipherWorkbench::Service.decrypt(
      cipher_id: 'extended_vigenere',
      params: { 'key' => 'A' },
      source: { type: :container, bytes: res_enc.container }
    )
    
    # Simulate API response generation
    ret = {
      text: res_dec.text,
      text_valid: res_dec.text_valid
    }
    
    # Should not raise error according to I8 (always JSON serializable)
    begin
      json = JSON.generate(ret)
      assert_includes json, 'false', "Expected text_valid to be false"
    rescue => e
      flunk "Melanggar I8: JSON.generate gagal dengan #{e.class}: #{e.message}"
    end
  end
end
