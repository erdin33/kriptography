require_relative '../test_helper'

class ContainerTest < Minitest::Test
  def test_roundtrip_all_combinations
    kinds = [:text, :file]
    encodings = [:raw, :alpha_filter, :nibble16]
    
    kinds.each do |kind|
      encodings.each do |enc|
        payload = "A" * 100
        sha = Digest::SHA256.digest(payload)
        binary = CipherWorkbench::Container.pack(
          cipher_id: "test",
          kind: kind,
          encoding: enc,
          filename: kind == :file ? "测试.txt" : "",
          plain_length: payload.length,
          plain_sha256: sha,
          payload: payload
        )
        
        header = CipherWorkbench::Container.unpack(binary)
        assert_equal "test", header.cipher_id
        assert_equal kind, header.kind
        assert_equal enc, header.encoding
        assert_equal kind == :file ? "测试.txt".b : "".b, header.filename.b
        assert_equal payload.length, header.plain_length
        assert_equal sha, header.plain_sha256
        assert_equal payload, header.payload
      end
    end
  end

  def test_empty_file
    sha = Digest::SHA256.digest("")
    binary = CipherWorkbench::Container.pack(
      cipher_id: "test",
      kind: :file,
      encoding: :raw,
      filename: "empty.bin",
      plain_length: 0,
      plain_sha256: sha,
      payload: ""
    )
    
    header = CipherWorkbench::Container.unpack(binary)
    assert_equal "", header.payload
  end

  def test_rejects_invalid_magic
    valid = CipherWorkbench::Container.pack(cipher_id: "test", kind: :text, encoding: :raw, filename: "", plain_length: 1, plain_sha256: Digest::SHA256.digest("A"), payload: "A")
    invalid = valid.dup
    invalid[0] = 'X'
    assert_raises(CipherWorkbench::InvalidContainerError) { CipherWorkbench::Container.unpack(invalid) }
  end

  def test_rejects_invalid_version
    valid = CipherWorkbench::Container.pack(cipher_id: "test", kind: :text, encoding: :raw, filename: "", plain_length: 1, plain_sha256: Digest::SHA256.digest("A"), payload: "A")
    invalid = valid.dup
    invalid[4] = "\x02"
    assert_raises(CipherWorkbench::InvalidContainerError) { CipherWorkbench::Container.unpack(invalid) }
  end

  def test_rejects_truncated
    valid = CipherWorkbench::Container.pack(cipher_id: "test", kind: :text, encoding: :raw, filename: "", plain_length: 1, plain_sha256: Digest::SHA256.digest("A"), payload: "A")
    (1...valid.bytesize).each do |len|
      assert_raises(CipherWorkbench::InvalidContainerError) { CipherWorkbench::Container.unpack(valid.byteslice(0, len)) }
    end
  end

  def test_rejects_trailing_bytes
    valid = CipherWorkbench::Container.pack(cipher_id: "test", kind: :text, encoding: :raw, filename: "", plain_length: 1, plain_sha256: Digest::SHA256.digest("A"), payload: "A")
    assert_raises(CipherWorkbench::InvalidContainerError) { CipherWorkbench::Container.unpack(valid + "X") }
  end
end
