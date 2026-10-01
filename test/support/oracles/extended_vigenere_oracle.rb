module ExtendedVigenereOracle
  def self.decrypt(params, symbols)
    # the key is treated as bytes (UTF-8 encoding string then bytes)
    key_str = params['key'].to_s
    key_bytes = key_str.bytes
    key_len = key_bytes.length
    
    symbols.map.with_index do |c, i|
      k = key_bytes[i % key_len]
      (c - k) % 256
    end
  end
end
