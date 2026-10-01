module AffineOracle
  def self.decrypt(params, symbols)
    a = params['a'].to_i % 26
    b = params['b'].to_i % 26
    
    # find modular inverse of a mod 26
    a_inv = nil
    (1..25).each do |i|
      if (a * i) % 26 == 1
        a_inv = i
        break
      end
    end
    
    raise "a=#{a} is not coprime to 26" unless a_inv
    
    symbols.map do |c|
      (a_inv * (c - b)) % 26
    end
  end
end
