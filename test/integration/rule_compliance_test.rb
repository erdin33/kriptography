require_relative '../test_helper'
require_relative '../../scripts/sample_keys'

class RuleComplianceTest < Minitest::Test
  def test_container_mutation_does_not_crash
    keys = SampleKeys.keys['vigenere']
    enc = CipherWorkbench::Service.encrypt(
      cipher_id: 'vigenere',
      params: keys,
      input: { kind: :text, text: "HELLO WORLD" }
    )

    container_bytes = enc.container

    # Mutate 1 payload byte
    mutated_payload = container_bytes.dup
    mutated_payload[32] = (mutated_payload[32].ord ^ 0xFF).chr
    
    dec = CipherWorkbench::Service.decrypt(
      cipher_id: 'vigenere',
      params: keys,
      source: { type: :container, bytes: mutated_payload }
    )

    refute dec.integrity[:valid]
    
    # Mutate header
    mutated_header = container_bytes.dup
    mutated_header[1] = (mutated_header[1].ord ^ 0xFF).chr # corrupt magic number
    
    assert_raises(CipherWorkbench::InvalidContainerError) do
      CipherWorkbench::Service.decrypt(
        cipher_id: 'vigenere',
        params: keys,
        source: { type: :container, bytes: mutated_header }
      )
    end
  end
  
  def test_rule_4_base64_has_no_newlines
    keys = SampleKeys.keys['extended_vigenere']
    enc = CipherWorkbench::Service.encrypt(
      cipher_id: 'extended_vigenere',
      params: keys,
      input: { kind: :text, text: "A" * 1000 }
    )
    
    b64 = [enc.payload].pack('m0')
    refute_match(/\n|\r/, b64)
    refute_match(/\s/, b64)
  end
  
  def test_stress_input
    # Stress input for vigenere
    keys = SampleKeys.keys['vigenere']
    text = "A" * 1_000_000
    enc = CipherWorkbench::Service.encrypt(
      cipher_id: 'vigenere',
      params: keys,
      input: { kind: :text, text: text }
    )
    
    assert_equal 1_000_000, enc.used_symbols
  end
end
