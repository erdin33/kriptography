require 'json'
require_relative 'oracles/vigenere_oracle'
require_relative 'oracles/autokey_oracle'
require_relative 'oracles/extended_vigenere_oracle'
require_relative 'oracles/playfair_oracle'
require_relative 'oracles/affine_oracle'
require_relative 'oracles/hill_oracle'
require_relative 'oracles/columnar_oracle'
require_relative 'oracles/super_oracle'
require_relative 'oracles/enigma_oracle'

module OracleHarness
  # Maps cipher ID to its oracle decrypt function
  def self.oracle_for(cipher_id)
    case cipher_id
    when 'vigenere' then VigenereOracle
    when 'autokey' then AutokeyOracle
    when 'extended_vigenere' then ExtendedVigenereOracle
    when 'playfair' then PlayfairOracle
    when 'affine' then AffineOracle
    when 'hill' then HillOracle
    when 'columnar_transposition' then ColumnarOracle
    when 'super_encryption' then SuperOracle
    when 'enigma' then EnigmaOracle
    else
      raise "Unknown oracle for #{cipher_id}"
    end
  end

  def self.assert_matches_oracle(cipher_id, key, input, domain)
    oracle = oracle_for(cipher_id)
    
    # 1. Oracle decrypt
    oracle_result = oracle.decrypt(key, input.dup)
    
    # 2. Production decrypt (requires loading production codebase)
    # We assume 'require cipher_workbench' has been loaded in the tests.
    cipher = CipherWorkbench::Registry.build(cipher_id, key)
    prod_result = cipher.decrypt(input.dup)
    
    if oracle_result != prod_result
      log_failure(cipher_id, key, input, oracle_result, prod_result)
      raise "Oracle mismatch for #{cipher_id}. Oracle: #{oracle_result.inspect}, Prod: #{prod_result.inspect}"
    end
    true
  end

  def self.generate_data(seed, length, domain_max)
    rng = Random.new(seed)
    Array.new(length) { rng.rand(0..domain_max) }
  end

  def self.log_failure(cipher, key, input, oracle_out, prod_out)
    dir = File.expand_path("../../docs/BUGHUNT/failures", __dir__)
    FileUtils.mkdir_p(dir)
    hash = Digest::SHA256.hexdigest(input.to_s)[0, 8]
    file = File.join(dir, "#{cipher}_#{hash}.json")
    
    data = {
      cipher: cipher,
      key: key,
      size: input.size,
      input_hash: hash,
      input_preview: input[0, 20],
      oracle_preview: oracle_out[0, 20],
      prod_preview: prod_out[0, 20]
    }
    
    File.write(file, JSON.pretty_generate(data))
  end
end
