require_relative '../../test_helper'

class Stage4Test < Minitest::Test
  def setup
    @playfair_class = CipherWorkbench::Registry.all.find { |c| c.id == 'playfair' }
    @hill_class = CipherWorkbench::Registry.all.find { |c| c.id == 'hill' }
  end

  def test_playfair_vector
    cipher = @playfair_class.new(key: 'PLAYFAIR EXAMPLE')
    
    # Check square
    square = cipher.describe_key[:square]
    expected_square = [
      %w[P L A Y F],
      %w[I R E X M],
      %w[B C D G H],
      %w[K N O Q S],
      %w[T U V W Z]
    ]
    assert_equal expected_square, square
    
    pt_str = "HIDE THE GOLD IN THE TREE STUMP"
    pt_filtered = CipherWorkbench::Codec::LetterCodec.filter_letters(pt_str)
    pt_symbols = CipherWorkbench::Codec::LetterCodec.letters_to_symbols(pt_filtered)
    
    prepared = cipher.prepare(pt_symbols)
    prepared_str = CipherWorkbench::Codec::LetterCodec.symbols_to_letters(prepared)
    assert_equal "HIDETHEGOLDINTHETREXESTUMP", prepared_str
    
    ct = cipher.encrypt(prepared)
    ct_str = CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
    assert_equal "BMODZBXDNABEKUDMUIXMMOUVIF", ct_str
    
    dec = cipher.decrypt(ct)
    assert_equal prepared, dec
  end

  def test_hill_vector
    cipher = @hill_class.new(n: 3, key_text: 'GYBNQKURP')
    
    matrix = cipher.describe_key[:matrix]
    expected_matrix = [[6, 24, 1], [13, 16, 10], [20, 17, 15]]
    assert_equal expected_matrix, matrix
    
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols("ACT")
    prepared = cipher.prepare(pt)
    ct = cipher.encrypt(prepared)
    ct_str = CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
    assert_equal "POH", ct_str
    
    dec = cipher.decrypt(ct)
    assert_equal prepared, dec
  end

  def test_hill_inverse_vector
    matrix = [[3, 3], [2, 5]]
    det = CipherWorkbench::Math::MatrixMod.determinant(matrix)
    assert_equal 9, det
    
    inv = CipherWorkbench::Math::MatrixMod.inverse(matrix, 26)
    expected_inv = [[15, 17], [20, 9]]
    assert_equal expected_inv, inv
    
    # K * K^-1 == I
    prod = CipherWorkbench::Math::MatrixMod.multiply(matrix, inv, 26)
    identity = CipherWorkbench::Math::MatrixMod.identity(2)
    assert_equal identity, prod
  end

  def test_playfair_key_normalization
    # key with J, duplicates
    cipher = @playfair_class.new(key: 'JJJAAA')
    assert_equal 'IIIAAA', cipher.describe_key[:normalized_key]
    assert_equal 'I', cipher.describe_key[:square][0][0]
    
    assert_raises(CipherWorkbench::InvalidKeyError) { @playfair_class.new(key: '') }
  end

  def test_playfair_padding_rules
    cipher = @playfair_class.new(key: 'KEY')
    
    # Double letter BALLOON
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols("BALLOON")
    prepared = cipher.prepare(pt)
    assert_equal "BALXLOON", CipherWorkbench::Codec::LetterCodec.symbols_to_letters(prepared)
    
    # XX
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols("XX")
    prepared = cipher.prepare(pt)
    assert_equal "XQXQ", CipherWorkbench::Codec::LetterCodec.symbols_to_letters(prepared)
    
    # Odd length ending in X
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols("BOX")
    prepared = cipher.prepare(pt)
    assert_equal "BOXQ", CipherWorkbench::Codec::LetterCodec.symbols_to_letters(prepared)
  end

  def test_playfair_random_roundtrip
    srand(123)
    cipher = @playfair_class.new(key: 'RANDOM')
    300.times do
      len = rand(1..50)
      letters = (1..len).map { (rand(26) + 65).chr }.join
      pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols(letters)
      prepared = cipher.prepare(pt)
      ct = cipher.encrypt(prepared)
      dec = cipher.decrypt(ct)
      assert_equal prepared, dec
    end
  end

  def test_hill_invalid_keys
    # Det not coprime
    invalid_matrices = [
      [[2, 4], [6, 8]],
      [[1, 2], [2, 4]],
      [[0, 0], [0, 0]]
    ]
    
    invalid_matrices.each do |mat|
      err = assert_raises(CipherWorkbench::InvalidKeyError) { @hill_class.new(n: 2, matrix: mat) }
      assert_match(/determinan/, err.message)
    end
    
    assert_raises(CipherWorkbench::InvalidKeyError) { @hill_class.new(n: 3, key_text: 'SHORT') }
  end

  def test_hill_random_invertible_matrices
    srand(456)
    (2..6).each do |n|
      10.times do
        matrix = nil
        loop do
          matrix = Array.new(n) { Array.new(n) { rand(26) } }
          det = CipherWorkbench::Math::MatrixMod.determinant(matrix)
          break if CipherWorkbench::Math::Modular.coprime?(det % 26, 26)
        end
        
        cipher = @hill_class.new(n: n, matrix: matrix)
        inv = cipher.describe_key[:inverse_matrix]
        prod = CipherWorkbench::Math::MatrixMod.multiply(matrix, inv, 26)
        assert_equal CipherWorkbench::Math::MatrixMod.identity(n), prod
        
        # Round trip
        pt = (1..n*2).map { rand(26) }
        ct = cipher.encrypt(pt)
        assert_equal pt, cipher.decrypt(ct)
      end
    end
  end

  def test_hill_padding
    cipher = @hill_class.new(n: 3, key_text: 'GYBNQKURP')
    
    [1, 2, 3, 4].each do |len|
      pt = (0...len).map { 0 }
      prepared = cipher.prepare(pt)
      assert_equal 0, prepared.length % 3
      assert_equal 23, prepared.last if len % 3 != 0
    end
  end

  def test_service_file_roundtrip
    srand(789)
    bytes = (0...2048).map { rand(256).chr }.join.b
    bytes[0...100] = "\x00".b * 100
    bytes[100...200] = "\xFF".b * 100
    
    single_byte = "\x42".b
    
    ciphers = [
      ['playfair', { key: 'TEST' }],
      ['hill', { n: 2, matrix: [[3, 3], [2, 5]] }]
    ]
    
    ciphers.each do |cipher_id, params|
      [bytes, single_byte].each do |b|
        input = { kind: :file, filename: "data.bin", bytes: b }
        res = CipherWorkbench::Service.encrypt(cipher_id: cipher_id, params: params, input: input)
        
        dec_res = CipherWorkbench::Service.decrypt(cipher_id: cipher_id, params: params, source: { type: :container, bytes: res.container })
        assert_equal b, dec_res.plain_bytes
      end
    end
  end
end
