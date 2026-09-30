require_relative '../../test_helper'

class Stage3Test < Minitest::Test
  def setup
    @vigenere_class = CipherWorkbench::Registry.all.find { |c| c.id == 'vigenere' }
    @autokey_class = CipherWorkbench::Registry.all.find { |c| c.id == 'autokey' }
    @affine_class = CipherWorkbench::Registry.all.find { |c| c.id == 'affine' }
  end

  def test_catalog_registration
    refute_nil @vigenere_class
    refute_nil @autokey_class
    refute_nil @affine_class
    
    # Check fields
    assert_equal 'key', @vigenere_class.fields.first[:name]
    assert_equal 'key', @autokey_class.fields.first[:name]
    assert_equal 'a', @affine_class.fields.first[:name]
    assert_equal 'b', @affine_class.fields[1][:name]
  end

  def test_vigenere_vector
    cipher = @vigenere_class.new(key: 'LEMON')
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols('ATTACKATDAWN')
    ct = cipher.encrypt(pt)
    assert_equal 'LXFOPVEFRNHR', CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
    assert_equal pt, cipher.decrypt(ct)
  end

  def test_autokey_vector
    cipher = @autokey_class.new(key: 'QUEENLY')
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols('ATTACKATDAWN')
    ct = cipher.encrypt(pt)
    assert_equal 'QNXEPVYTWTWP', CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
    assert_equal pt, cipher.decrypt(ct)
  end

  def test_affine_vector
    cipher = @affine_class.new(a: 5, b: 8)
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols('AFFINE')
    ct = cipher.encrypt(pt)
    assert_equal 'IHHWVC', CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
    assert_equal pt, cipher.decrypt(ct)
  end

  def test_service_vigenere_text_filter
    input = { kind: :text, text: "Attack at Dawn 2026!" }
    res = CipherWorkbench::Service.encrypt(cipher_id: 'vigenere', params: { key: 'Lemon' }, input: input)
    assert_equal "LXFOPVEFRNHR", res.payload
    
    dec_res = CipherWorkbench::Service.decrypt(cipher_id: 'vigenere', params: { key: 'Lemon' }, source: { type: :container, bytes: res.container })
    assert_equal "ATTACKATDAWN", dec_res.text
  end

  def test_invalid_keys_rejected
    assert_raises(CipherWorkbench::InvalidKeyError) { @vigenere_class.new(key: '123!!!') }
    assert_raises(CipherWorkbench::InvalidKeyError) { @vigenere_class.new(key: '') }
    assert_raises(CipherWorkbench::InvalidKeyError) { @autokey_class.new(key: '  ') }

    [0, 2, 13, 26].each do |invalid_a|
      assert_raises(CipherWorkbench::InvalidKeyError) { @affine_class.new(a: invalid_a, b: 5) }
    end
    
    assert_raises(CipherWorkbench::InvalidParamsError) { @affine_class.new(a: 'abc', b: 5) }
  end

  def test_affine_normalization
    # a=27 is a=1, b=-3 is b=23
    cipher1 = @affine_class.new(a: 27, b: -3)
    desc1 = cipher1.describe_key
    assert_equal 1, desc1[:a]
    assert_equal 23, desc1[:b]
    
    # a=-1 is a=25
    cipher2 = @affine_class.new(a: -1, b: 5)
    assert_equal 25, cipher2.describe_key[:a]
  end

  def test_vigenere_extreme_keys
    # Key length 1
    c1 = @vigenere_class.new(key: 'B') # shift 1
    assert_equal [1, 2, 3], c1.encrypt([0, 1, 2])
    
    # Very long key
    long_key = "A" * 10000
    c_long = @vigenere_class.new(key: long_key)
    assert_equal [0, 1, 2], c_long.encrypt([0, 1, 2]) # A is shift 0
  end

  def test_contract_identity
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols('HELLOWORLD')
    
    cv = @vigenere_class.new(key: 'SECRET')
    assert_equal cv.prepare(pt), cv.decrypt(cv.encrypt(pt))
    
    ca = @autokey_class.new(key: 'SECRET')
    assert_equal ca.prepare(pt), ca.decrypt(ca.encrypt(pt))
    
    cf = @affine_class.new(a: 7, b: 11)
    assert_equal cf.prepare(pt), cf.decrypt(cf.encrypt(pt))
  end

  def test_random_roundtrip
    srand(999)
    200.times do
      len = rand(1..500)
      # Random bytes for file test
      bytes = (1..len).map { rand(256).chr }.join.b
      # Random letters for text test
      letters = (1..len).map { (rand(26) + 65).chr }.join
      
      ciphers = [
        ['vigenere', { key: (1..rand(1..50)).map { (rand(26) + 65).chr }.join }],
        ['autokey', { key: (1..rand(1..50)).map { (rand(26) + 65).chr }.join }],
        ['affine', { a: CipherWorkbench::Ciphers::Affine::VALID_A_VALUES.sample, b: rand(-100..100) }]
      ]
      
      cipher_id, params = ciphers.sample
      
      # Text test
      res_txt = CipherWorkbench::Service.encrypt(cipher_id: cipher_id, params: params, input: { kind: :text, text: letters })
      dec_txt = CipherWorkbench::Service.decrypt(cipher_id: cipher_id, params: params, source: { type: :container, bytes: res_txt.container })
      assert_equal letters, dec_txt.text
      
      # File test (nibble16)
      res_file = CipherWorkbench::Service.encrypt(cipher_id: cipher_id, params: params, input: { kind: :file, filename: "test.bin", bytes: bytes })
      dec_file = CipherWorkbench::Service.decrypt(cipher_id: cipher_id, params: params, source: { type: :container, bytes: res_file.container })
      assert_equal bytes, dec_file.plain_bytes
    end
  end
end
