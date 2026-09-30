require_relative '../../test_helper'

class Stage5Test < Minitest::Test
  def setup
    @ext_vigenere_class = CipherWorkbench::Registry.all.find { |c| c.id == 'extended_vigenere' }
    @columnar_class = CipherWorkbench::Registry.all.find { |c| c.id == 'columnar' }
    @super_class = CipherWorkbench::Registry.all.find { |c| c.id == 'super' }
  end

  def test_columnar_vector
    cipher = @columnar_class.new(key: 'ZEBRAS')
    pt_bytes = "WEAREDISCOVEREDFLEEATONCE".bytes
    ct = cipher.encrypt(pt_bytes)
    assert_equal "EVLNACDTESEAROFODEECWIREE", ct.pack('C*')
    
    # rank check
    order = cipher.describe_key[:order]
    # order gives the original column indices (1-based) in ranked order:
    # A(5), B(3), E(2), R(4), S(6), Z(1)
    assert_equal [5, 3, 2, 4, 6, 1], order
  end

  def test_ext_vigenere_vector
    c1 = @ext_vigenere_class.new(key: 1.chr)
    assert_equal [1, 2, 0], c1.encrypt([0, 1, 255])
    
    c2 = @ext_vigenere_class.new(key: 'AB')
    assert_equal [65, 66, 65], c2.encrypt([0, 0, 0])
  end

  def test_super_composition_vector
    srand(101)
    100.times do
      len = rand(10..200)
      pt = (0...len).map { rand(256) }
      vig_key = (0...rand(5..15)).map { rand(256).chr }.join
      col_key = (0...rand(3..10)).map { rand(256).chr }.join
      
      c_super = @super_class.new(vigenere_key: vig_key, transposition_key: col_key)
      c_vig = @ext_vigenere_class.new(key: vig_key)
      c_col = @columnar_class.new(key: col_key)
      
      res_super = c_super.encrypt(pt)
      res_comp = c_col.encrypt(c_vig.encrypt(pt))
      
      assert_equal res_comp, res_super
      
      # Decrypt check
      dec_super = c_super.decrypt(res_super)
      assert_equal pt, dec_super
    end
  end

  def test_ext_vigenere_roundtrip
    # All 256 byte values
    pt = (0..255).to_a
    c = @ext_vigenere_class.new(key: 'SECRET')
    assert_equal pt, c.decrypt(c.encrypt(pt))
    
    # Random lengths
    srand(102)
    10.times do
      key_len = rand(1..300)
      key = (0...key_len).map { rand(256).chr }.join
      c_rand = @ext_vigenere_class.new(key: key)
      assert_equal pt, c_rand.decrypt(c_rand.encrypt(pt))
    end
    
    # Non-ASCII key
    c_unicode = @ext_vigenere_class.new(key: 'kunci-ñ')
    assert_equal pt, c_unicode.decrypt(c_unicode.encrypt(pt))
  end

  def test_columnar_roundtrip
    srand(103)
    10.times do
      col_num = rand(2..20)
      key = (0...col_num).map { rand(256).chr }.join
      c = @columnar_class.new(key: key)
      
      len = rand(0..300)
      pt = (0...len).map { rand(256) }
      
      ct = c.encrypt(pt)
      assert_equal len, ct.length
      assert_equal pt, c.decrypt(ct)
    end
    
    # Dup key test (stable sort)
    c_dup = @columnar_class.new(key: 'AABBA')
    pt_dup = "HELLO".bytes
    ct_dup = c_dup.encrypt(pt_dup)
    assert_equal "HELLO".length, ct_dup.length
    assert_equal pt_dup, c_dup.decrypt(ct_dup)
  end

  def test_service_super_roundtrip
    srand(104)
    # File test
    bytes = (0...rand(100..4096)).map { rand(256).chr }.join.b
    res_file = CipherWorkbench::Service.encrypt(
      cipher_id: 'super',
      params: { vigenere_key: 'vig', transposition_key: 'col' },
      input: { kind: :file, filename: "random.bin", bytes: bytes }
    )
    
    dec_file = CipherWorkbench::Service.decrypt(
      cipher_id: 'super',
      params: { vigenere_key: 'vig', transposition_key: 'col' },
      source: { type: :container, bytes: res_file.container }
    )
    assert_equal bytes, dec_file.plain_bytes
    assert_equal true, dec_file.integrity[:valid]
    
    # Different key -> different ciphertext
    res_file_2 = CipherWorkbench::Service.encrypt(
      cipher_id: 'super',
      params: { vigenere_key: 'vig2', transposition_key: 'col2' },
      input: { kind: :file, filename: "random.bin", bytes: bytes }
    )
    refute_equal res_file.payload, res_file_2.payload
    
    # Unicode text test
    unicode_txt = "Halo, dünya! 你好"
    res_txt = CipherWorkbench::Service.encrypt(
      cipher_id: 'super',
      params: { vigenere_key: 'vig', transposition_key: 'col' },
      input: { kind: :text, text: unicode_txt }
    )
    dec_txt = CipherWorkbench::Service.decrypt(
      cipher_id: 'super',
      params: { vigenere_key: 'vig', transposition_key: 'col' },
      source: { type: :container, bytes: res_txt.container }
    )
    assert_equal unicode_txt, dec_txt.text
    assert_equal true, dec_txt.text_valid
  end

  def test_file_header_changed
    png_header = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A".b
    jpeg_header = "\xFF\xD8\xFF".b
    
    cipher = @ext_vigenere_class.new(key: 'kunci')
    
    png_ct = cipher.encrypt(png_header.bytes).pack('C*')
    jpeg_ct = cipher.encrypt(jpeg_header.bytes).pack('C*')
    
    refute_equal png_header, png_ct
    refute_equal jpeg_header, jpeg_ct
  end

  def test_invalid_keys
    # Ext Vigenere empty
    assert_raises(CipherWorkbench::InvalidKeyError) { @ext_vigenere_class.new(key: '') }
    
    # Columnar 1 char
    assert_raises(CipherWorkbench::InvalidKeyError) { @columnar_class.new(key: 'A') }
    
    # Super with invalid vig
    assert_raises(CipherWorkbench::InvalidKeyError) do
      @super_class.new(vigenere_key: '', transposition_key: 'COL')
    end
    
    # Super with invalid col
    assert_raises(CipherWorkbench::InvalidKeyError) do
      @super_class.new(vigenere_key: 'VIG', transposition_key: 'C')
    end
  end
end
