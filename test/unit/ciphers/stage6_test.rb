require_relative '../../test_helper'

class Stage6Test < Minitest::Test
  def setup
    @enigma_class = CipherWorkbench::Registry.all.find { |c| c.id == 'enigma' }
  end

  def test_data_integrity
    # Rotors are 26 unique letters
    CipherWorkbench::Ciphers::EnigmaData::ROTORS.each do |name, data|
      assert_equal 26, data[:wiring].chars.uniq.length, "Rotor #{name} wiring invalid"
      assert_equal 26, data[:wiring].length
    end

    # Reflectors are involutions with no fixed points
    CipherWorkbench::Ciphers::EnigmaData::REFLECTORS.each do |name, wiring|
      chars = wiring.chars
      chars.each_with_index do |char, i|
        mapped_idx = char.ord - 65
        refute_equal i, mapped_idx, "Reflector #{name} maps #{char} to itself"
        assert_equal i, chars[mapped_idx].ord - 65, "Reflector #{name} not involution at #{i}"
      end
    end
  end

  def test_vector_aaaaa
    cipher = @enigma_class.new(
      rotors: 'I,II,III',
      reflector: 'B',
      rings: 'AAA',
      positions: 'AAA'
    )
    
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols("AAAAA")
    ct = cipher.encrypt(pt)
    assert_equal "BDZGO", CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
  end

  def test_vector_26_a
    cipher = @enigma_class.new(
      rotors: 'I,II,III',
      reflector: 'B',
      rings: 'AAA',
      positions: 'AAA'
    )
    
    pt = CipherWorkbench::Codec::LetterCodec.letters_to_symbols("A" * 26)
    ct = cipher.encrypt(pt)
    assert_equal "BDZGOWCXLTKSBTMCDLPBMUQOFX", CipherWorkbench::Codec::LetterCodec.symbols_to_letters(ct)
  end

  def test_stepping_adu
    cipher = @enigma_class.new(
      rotors: 'I,II,III',
      reflector: 'B',
      rings: 'AAA',
      positions: 'ADU'
    )
    
    states = cipher._simulate_stepping(4)
    strs = states.map { |st| st.map { |x| (x+65).chr }.join }
    
    assert_equal ["ADV", "AEW", "BFX", "BFY"], strs
  end

  def test_reciprocal_random
    srand(200)
    200.times do
      rotors = CipherWorkbench::Ciphers::EnigmaData::ROTORS.keys.sample(3).join(',')
      ref = ['B', 'C'].sample
      rings = (1..3).map { (rand(26) + 65).chr }.join
      pos = (1..3).map { (rand(26) + 65).chr }.join
      
      # Random plugboard (0..10 pairs)
      alpha = ('A'..'Z').to_a.shuffle
      pairs = []
      rand(0..10).times do
        a = alpha.pop
        b = alpha.pop
        pairs << "#{a}#{b}"
      end
      
      cipher = @enigma_class.new(
        rotors: rotors,
        reflector: ref,
        rings: rings,
        positions: pos,
        plugboard: pairs.join(' ')
      )
      
      len = rand(1..100)
      pt = (1..len).map { rand(26) }
      
      ct = cipher.encrypt(pt)
      
      # no fixed points
      pt.each_with_index do |p, i|
        refute_equal p, ct[i], "Enigma maps character to itself at index #{i}"
      end
      
      # reciprocal
      # Using a new instance with same settings to simulate independent call, though process() is pure
      cipher2 = @enigma_class.new(
        rotors: rotors,
        reflector: ref,
        rings: rings,
        positions: pos,
        plugboard: pairs.join(' ')
      )
      assert_equal pt, cipher2.decrypt(ct)
    end
  end

  def test_plugboard_ac
    c_base = @enigma_class.new(rotors: 'I,II,III', reflector: 'B')
    c_plug = @enigma_class.new(rotors: 'I,II,III', reflector: 'B', plugboard: 'AC')
    
    pt = [0] # 'A'
    ct_base = c_base.encrypt(pt)
    ct_plug = c_plug.encrypt(pt)
    
    refute_equal ct_base, ct_plug
    assert_equal pt, c_plug.decrypt(ct_plug)
  end

  def test_ring_bbb
    c_base = @enigma_class.new(rotors: 'I,II,III', reflector: 'B', rings: 'AAA')
    c_ring = @enigma_class.new(rotors: 'I,II,III', reflector: 'B', rings: 'BBB')
    
    pt = [0, 0, 0, 0, 0] # AAAAA
    ct_base = c_base.encrypt(pt)
    ct_ring = c_ring.encrypt(pt)
    
    refute_equal ct_base, ct_ring
    assert_equal pt, c_ring.decrypt(ct_ring)
  end

  def test_validation_errors
    # Duplicate rotors
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,I') }
    # Unknown rotor
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,VI') }
    # Unknown reflector
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,III', reflector: 'A') }
    # Not 3 rotors
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II') }
    # Pos not 3
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,III', reflector: 'B', positions: 'AB') }
    # Ring numbers valid
    c_num = @enigma_class.new(rotors: 'I,II,III', reflector: 'B', rings: '1 2 3')
    assert_equal "ABC", c_num.describe_key[:rings]
    # Ring numbers invalid
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,III', reflector: 'B', rings: '1 27 3') }
    # Plugboard duplicates
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,III', reflector: 'B', plugboard: 'AB AC') }
    # Plugboard self
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,III', reflector: 'B', plugboard: 'AA') }
    # Plugboard 11 pairs
    assert_raises(CipherWorkbench::InvalidKeyError) { @enigma_class.new(rotors: 'I,II,III', reflector: 'B', plugboard: 'AB CD EF GH IJ KL MN OP QR ST UV') }
  end

  def test_service_roundtrips
    # Text
    res_txt = CipherWorkbench::Service.encrypt(
      cipher_id: 'enigma',
      params: { rotors: 'I,II,III', reflector: 'B' },
      input: { kind: :text, text: "Hello World" }
    )
    assert_match(/\A[A-Z]+\z/, res_txt.payload)
    
    dec_txt = CipherWorkbench::Service.decrypt(
      cipher_id: 'enigma',
      params: { rotors: 'I,II,III', reflector: 'B' },
      source: { type: :container, bytes: res_txt.container }
    )
    assert_equal "HELLOWORLD", dec_txt.text
    
    # Binary
    srand(201)
    bytes = (1...rand(100..4096)).map { rand(256).chr }.join.b
    res_bin = CipherWorkbench::Service.encrypt(
      cipher_id: 'enigma',
      params: { rotors: 'I,II,III', reflector: 'B' },
      input: { kind: :file, filename: "x.bin", bytes: bytes }
    )
    dec_bin = CipherWorkbench::Service.decrypt(
      cipher_id: 'enigma',
      params: { rotors: 'I,II,III', reflector: 'B' },
      source: { type: :container, bytes: res_bin.container }
    )
    assert_equal bytes, dec_bin.plain_bytes
  end
end
