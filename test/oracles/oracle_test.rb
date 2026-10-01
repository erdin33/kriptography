require 'minitest/autorun'
require_relative '../support/oracle_harness'

class OracleTest < Minitest::Test
  def chars_to_syms(str)
    str.upcase.gsub(/[^A-Z]/, '').chars.map { |c| c.ord - 65 }
  end

  def syms_to_chars(syms)
    syms.map { |s| (s + 65).chr }.join
  end

  def test_vigenere_oracle
    # Vigenere LEMON/ATTACKATDAWN -> LXFOPVEFRNHR
    # Decrypt: LXFOPVEFRNHR -> ATTACKATDAWN
    cipher = chars_to_syms("LXFOPVEFRNHR")
    plain = VigenereOracle.decrypt({ 'key' => 'LEMON' }, cipher)
    assert_equal "ATTACKATDAWN", syms_to_chars(plain)
  end

  def test_autokey_oracle
    # Auto-Key QUEENLY/ATTACKATDAWN -> QNXEPVYTWTWP
    # Note: wait, QUEENLY is the key. Is ATTACKATDAWN -> QNXEPVYTWTWP?
    # Let's check:
    # A + Q = Q
    # T + U = N
    # T + E = X
    # A + E = E
    # C + N = P
    # K + L = V
    # A + Y = Y
    # T + A = T
    # D + T = W
    # A + T = T
    # W + A = W
    # N + C = P
    cipher = chars_to_syms("QNXEPVYTWTWP")
    plain = AutokeyOracle.decrypt({ 'key' => 'QUEENLY' }, cipher)
    assert_equal "ATTACKATDAWN", syms_to_chars(plain)
  end

  def test_affine_oracle
    # Affine a=5 b=8 AFFINE -> IHHWVC
    cipher = chars_to_syms("IHHWVC")
    plain = AffineOracle.decrypt({ 'a' => 5, 'b' => 8 }, cipher)
    assert_equal "AFFINE", syms_to_chars(plain)
  end

  def test_playfair_oracle
    # Playfair PLAYFAIR EXAMPLE HIDETHEGOLDINTHETREESTUMP -> BMODZBXDNABEKUDMUIXMMOUVIF
    # (assuming J->I)
    cipher = chars_to_syms("BMODZBXDNABEKUDMUIXMMOUVIF")
    plain = PlayfairOracle.decrypt({ 'key' => 'PLAYFAIREXAMPLE' }, cipher)
    # The plaintext is HIDETHEGOLDINTHETREESTUMP. Wait, Playfair encrypts in pairs.
    # HIDETHEGOLDINTHETREESTUMP -> HI DE TH EG OL DI NT HE TR EE ST UM P? 
    # Usually EE is split by X, so TR EX ES...
    # Let's see what oracle outputs. It should match the reversed process exactly.
    # The source says PLAYFAIR EXAMPLE HIDETHEGOLDINTHETREESTUMP -> BMODZBXDNABEKUDMUIXMMOUVIF
    # Let's just test if decrypting BMODZBXDNABEKUDMUIXMMOUVIF gives HI DE TH EG OL DI NT HE TR EX ES TU MP
    plain_chars = syms_to_chars(plain)
    assert_equal "HIDETHEGOLDINTHETREXESTUMP", plain_chars
  end

  def test_hill_oracle
    # Hill GYBNQKURP ACT -> POH
    # Key matrix GYBNQKURP -> G(6) Y(24) B(1) / N(13) Q(16) K(10) / U(20) R(17) P(15)
    # POH = 15, 14, 7
    cipher = chars_to_syms("POH")
    matrix = [
      [6, 24, 1],
      [13, 16, 10],
      [20, 17, 15]
    ]
    plain = HillOracle.decrypt({ 'matrix' => matrix }, cipher)
    assert_equal "ACT", syms_to_chars(plain)
  end

  def test_columnar_oracle
    # ZEBRAS WEAREDISCOVEREDFLEEATONCE -> EVLNACDTESEAROFODEECWIREE
    cipher = chars_to_syms("EVLNACDTESEAROFODEECWIREE")
    plain = ColumnarOracle.decrypt({ 'key' => 'ZEBRAS' }, cipher)
    assert_equal "WEAREDISCOVEREDFLEEATONCE", syms_to_chars(plain)
  end

  def test_enigma_oracle
    # I-II-III/B/AAA/AAA AAAAA -> BDZGO
    cipher = chars_to_syms("BDZGO")
    plain = EnigmaOracle.decrypt({
      'rotors' => ['I', 'II', 'III'],
      'reflector' => 'B',
      'ring' => 'AAA',
      'pos' => 'AAA',
      'plugboard' => ''
    }, cipher)
    assert_equal "AAAAA", syms_to_chars(plain)
    
    # 26 huruf A -> BDZGOWCXLTKSBTMCDLPBMUQOFX
    cipher26 = chars_to_syms("BDZGOWCXLTKSBTMCDLPBMUQOFX")
    plain26 = EnigmaOracle.decrypt({
      'rotors' => ['I', 'II', 'III'],
      'reflector' => 'B',
      'ring' => 'AAA',
      'pos' => 'AAA',
      'plugboard' => ''
    }, cipher26)
    assert_equal "A" * 26, syms_to_chars(plain26)
  end
end
