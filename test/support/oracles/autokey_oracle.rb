module AutokeyOracle
  def self.decrypt(params, symbols)
    key_str = params['key'].to_s.upcase.gsub(/[^A-Z]/, '')
    key_symbols = key_str.chars.map { |c| c.ord - 65 }
    key_len = key_symbols.length
    
    plain_symbols = []
    
    symbols.each_with_index do |c, i|
      k = i < key_len ? key_symbols[i] : plain_symbols[i - key_len]
      p = (c - k) % 26
      plain_symbols << p
    end
    
    plain_symbols
  end
end
