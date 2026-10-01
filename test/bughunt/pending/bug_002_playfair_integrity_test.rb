require 'minitest/autorun'
require_relative '../../../lib/cipher_workbench'

class Bug002PlayfairIntegrityTest < Minitest::Test
  def test_playfair_alpha_filter_padding_integrity
    # I4 Integritas: kunci benar -> valid true
    # I2 Round-trip teks: domain huruf -> sama dengan prepare(filter(teks))
    
    # Text with double letters requiring 'X' padding
    text = "HELLO" # 'LL' becomes 'LX' 'LO'
    input = { kind: :text, text: text }
    
    # Encrypt
    enc_res = CipherWorkbench::Service.encrypt(
      cipher_id: 'playfair',
      params: { 'key' => 'KEY' },
      input: input
    )
    
    # Decrypt from container
    dec_res = CipherWorkbench::Service.decrypt(
      cipher_id: 'playfair',
      params: { 'key' => 'KEY' },
      source: { type: :container, bytes: enc_res.container }
    )
    
    # Expected: The integrity should be true because the key is correct!
    # But because Playfair does not remove the 'X' padding, the decrypted plain_bytes is "HELXLO"
    # and the SHA256 matches "HELXLO", but the container header has the SHA256 of "HELLO" (or wait, did encrypt hash before prepare?)
    
    # Let's check Service.encrypt:
    # prepared_symbols = cipher.prepare(symbols)
    # if encoding == :alpha_filter
    #   prepared_letters = Codec::LetterCodec.symbols_to_letters(prepared_symbols)
    #   plain_length = prepared_letters.bytesize
    #   plain_sha256 = Digest::SHA256.digest(prepared_letters)
    assert dec_res.integrity[:valid], "Melanggar I4: integrity.valid bernilai false pada kunci benar (akibat padding)"
  end
end
