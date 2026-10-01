module VigenereOracle
  def self.decrypt(params, symbols)
    key_str = params['key'].to_s.upcase.gsub(/[^A-Z]/, '')
    key_symbols = key_str.chars.map { |c| c.ord - 65 }
    key_len = key_symbols.length
    
    symbols.map.with_index do |c, i|
      k = key_symbols[i % key_len]
      (c - k) % 26
    end
  end
end
