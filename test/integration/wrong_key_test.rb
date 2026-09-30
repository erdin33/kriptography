require_relative '../test_helper'
require_relative '../../scripts/sample_keys'

class WrongKeyTest < Minitest::Test
  def setup
    srand(54321)
  end

  def test_wrong_key_integrity
    CipherWorkbench::Registry.catalog.reject { |c| c[:group] == :internal }.each do |c|
      keys1 = SampleKeys.keys[c[:id]]
      next unless keys1
      
      # Corrupt the key slightly
      keys2 = keys1.dup
      
      # Affine requires coprime 'a'. It's tricky to automatically corrupt 'a' without breaking validation,
      # so we will just corrupt 'b' for Affine. For Matrix we corrupt one cell.
      if c[:id] == 'affine'
        keys2['b'] = ((keys1['b'].to_i + 1) % 26).to_s
      elsif c[:id] == 'hill'
        # duplicate array to avoid mutating original
        keys2['matrix'] = keys1['matrix'].map(&:dup)
        keys2['matrix'][1][1] = '7' # Det = 3*7 - 2*3 = 21-6 = 15. Coprime with 26.
      elsif c[:id] == 'enigma'
        keys2['rings'] = 'BBB'
      elsif c[:id] == 'super'
        keys2['vigenere_key'] = keys1['vigenere_key'] + 'X'
      else
        keys2['key'] = keys1['key'] + 'X'
      end

      # Encrypt with keys1
      file_data = "TEST MESSAGE WRONG KEY"
      enc = CipherWorkbench::Service.encrypt(
        cipher_id: c[:id],
        params: keys1,
        input: { kind: :text, text: file_data }
      )

      # Decrypt with keys2
      b64 = [enc.payload].pack('m0')
      dec = CipherWorkbench::Service.decrypt(
        cipher_id: c[:id],
        params: keys2,
        source: { type: :text, format: :base64, text: b64 }
      )
      
      # Should be invalid integrity
      refute dec.integrity[:valid], "Integrity should be invalid for wrong key on #{c[:id]}"
    end
  end
end
