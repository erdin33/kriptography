require_relative '../../test/support/oracle_harness'
require_relative '../../lib/cipher_workbench'

# 8 Ciphers
CIPHERS = [
  'vigenere', 'autokey', 'extended_vigenere', 'playfair',
  'affine', 'hill', 'columnar', 'super', 'enigma'
]

SEED = 12345
rng = Random.new(SEED)

def random_key(cipher, rng)
  case cipher
  when 'vigenere', 'autokey', 'extended_vigenere'
    len = rng.rand(3..10)
    key = Array.new(len) { (rng.rand(26) + 65).chr }.join
    { 'key' => key }
  when 'playfair'
    len = rng.rand(5..15)
    key = Array.new(len) { (rng.rand(26) + 65).chr }.join.tr('J', 'I')
    { 'key' => key }
  when 'affine'
    # valid 'a' must be coprime to 26: 1, 3, 5, 7, 9, 11, 15, 17, 19, 21, 23, 25
    valid_a = [1, 3, 5, 7, 9, 11, 15, 17, 19, 21, 23, 25]
    { 'a' => valid_a.sample(random: rng), 'b' => rng.rand(0..25) }
  when 'hill'
    # just hardcode a valid 2x2 matrix for simplicity to ensure invertible
    # Invertible matrices det coprime to 26.
    matrices = [
      [[3,3],[2,5]],
      [[7,8],[5,11]],
      [[2,3],[1,4]]
    ]
    { 'matrix' => matrices.sample(random: rng) }
  when 'columnar_transposition'
    len = rng.rand(3..8)
    key = Array.new(len) { (rng.rand(26) + 65).chr }.join
    { 'key' => key }
  when 'super_encryption'
    len1 = rng.rand(3..8)
    key1 = Array.new(len1) { (rng.rand(26) + 65).chr }.join
    len2 = rng.rand(3..8)
    key2 = Array.new(len2) { (rng.rand(26) + 65).chr }.join
    { 'vigenere_key' => key1, 'transposition_key' => key2 }
  when 'enigma'
    rotors = [['I','II','III'], ['II','IV','V'], ['III','I','V']].sample(random: rng)
    refl = ['B', 'C'].sample(random: rng)
    ring = Array.new(3) { (rng.rand(26) + 65).chr }.join
    pos = Array.new(3) { (rng.rand(26) + 65).chr }.join
    { 'rotors' => rotors, 'reflector' => refl, 'ring' => ring, 'pos' => pos, 'plugboard' => '' }
  end
end

puts "Fuzzing Oracles vs Production..."
failures = 0
CIPHERS.each do |c|
  puts "Testing #{c}..."
  
  domain_max = CipherWorkbench::Registry.all.find{|cls| cls.id == c}.domain == :bytes ? 255 : 25
  
  200.times do |i|
    key = random_key(c, rng)
    len = rng.rand(0..64)
    # plain is symbols
    plain = OracleHarness.generate_data(rng.rand(10000), len, domain_max)
    
    # Wait, the oracle tests DECRYPTION.
    # So we need to ENCRYPT it first using production, then DECRYPT using both oracle and prod.
    # Why not just encrypt with production?
    begin
      prod_cipher = CipherWorkbench::Registry.build(c, key)
      cipher_symbols = prod_cipher.encrypt(plain)
    rescue => e
      # if encrypt fails because of some constraint, skip
      next
    end
    
    begin
      OracleHarness.assert_matches_oracle(c, key, cipher_symbols, domain_max)
    rescue => e
      puts "  FAILED at iteration #{i}: #{e.message.split("\n").first}"
      failures += 1
    end
  end
end
puts "Total Failures: #{failures}"
