require_relative '../test_helper'
require_relative '../../scripts/sample_keys'

class PropertiesTest < Minitest::Test
  def setup
    srand(12345)
  end

  def test_roundtrip_random_files
    CipherWorkbench::Registry.catalog.reject { |c| c[:group] == :internal }.each do |c|
      keys = SampleKeys.keys[c[:id]]
      next unless keys

      # 100 iterations per cipher
      100.times do
        # Random input file (0..3000 bytes)
        file_size = rand(0..3000)
        file_data = Array.new(file_size) { rand(256) }.pack('C*')
        file_name = "test_#{rand(1000)}.bin"

        # Encrypt
        enc = CipherWorkbench::Service.encrypt(
          cipher_id: c[:id],
          params: keys,
          input: { kind: :file, bytes: file_data, filename: file_name }
        )

        container_bytes = enc.container

        # Decrypt
        dec = CipherWorkbench::Service.decrypt(
          cipher_id: c[:id],
          params: keys,
          source: { type: :container, bytes: container_bytes }
        )

        dec_bytes = dec.plain_bytes

        assert_equal file_data, dec_bytes, "Roundtrip failed for #{c[:id]} on #{file_size} bytes"
        assert_equal file_name, dec.filename
        assert dec.integrity[:valid]
      end
    end
  end

  def test_roundtrip_random_text
    CipherWorkbench::Registry.catalog.reject { |c| c[:group] == :internal }.each do |c|
      keys = SampleKeys.keys[c[:id]]
      next unless keys

      instance = CipherWorkbench::Registry.build(c[:id], keys)

      100.times do
        # Random text
        text = Array.new(rand(10..100)) { rand(32..126).chr }.join
        
        syms = instance.prepare(CipherWorkbench::Codec::LetterCodec.letters_to_symbols(CipherWorkbench::Codec::LetterCodec.filter_letters(text)))
        
        if c[:domain] == :letters
          expected = CipherWorkbench::Codec::LetterCodec.symbols_to_letters(syms)
        else
          syms2 = text.b.bytes
          # bytes prep
          expected = syms2.pack('C*').force_encoding('UTF-8')
        end

        enc = CipherWorkbench::Service.encrypt(cipher_id: c[:id], params: keys, input: { kind: :text, text: text })
        b64 = [enc.payload].pack('m0')
        dec = CipherWorkbench::Service.decrypt(cipher_id: c[:id], params: keys, source: { type: :text, format: :base64, text: b64 })
        
        dec_bytes = dec.plain_bytes

        assert_equal expected.b, dec_bytes.b, "Text roundtrip failed for #{c[:id]}"
      end
    end
  end
end
