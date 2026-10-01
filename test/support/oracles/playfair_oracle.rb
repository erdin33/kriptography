module PlayfairOracle
  def self.decrypt(params, symbols)
    key_str = params['key'].to_s.upcase.gsub(/[^A-Z]/, '').tr('J', 'I')
    alphabet = "ABCDEFGHIKLMNOPQRSTUVWXYZ"
    
    matrix = []
    seen = {}
    (key_str.chars + alphabet.chars).each do |c|
      unless seen[c]
        matrix << c
        seen[c] = true
      end
    end
    
    # matrix is 25 chars.
    # Convert symbols to chars
    chars = symbols.map { |s| (s + 65).chr }
    # Assume symbols are already even length and no J (J replaced by I in input, but we just use symbols as is)
    # Wait, the cipher input symbols might have J (value 9)? 
    # The production prepare function replaces J with I. We are decrypting, so input symbols shouldn't have J if they came from encrypt, but if user supplies J? The oracle operates on symbols, which are 0..25. 
    # But Playfair only uses 25 letters. Let's map J to I just in case.
    chars = chars.map { |c| c == 'J' ? 'I' : c }
    
    plain_chars = []
    
    chars.each_slice(2) do |a, b|
      # if length is odd, the last block has only 'a'. Production Playfair pad 'X' during encrypt.
      # If decrypting an odd length, it shouldn't happen, but we can pad just in case.
      b = 'X' if b.nil?
      
      idx_a = matrix.index(a)
      idx_b = matrix.index(b)
      
      row_a, col_a = idx_a / 5, idx_a % 5
      row_b, col_b = idx_b / 5, idx_b % 5
      
      if row_a == row_b
        # Same row: left
        p_a = matrix[row_a * 5 + (col_a - 1) % 5]
        p_b = matrix[row_b * 5 + (col_b - 1) % 5]
      elsif col_a == col_b
        # Same col: up
        p_a = matrix[((row_a - 1) % 5) * 5 + col_a]
        p_b = matrix[((row_b - 1) % 5) * 5 + col_b]
      else
        # Rectangle
        p_a = matrix[row_a * 5 + col_b]
        p_b = matrix[row_b * 5 + col_a]
      end
      
      plain_chars << p_a << p_b
    end
    
    plain_chars.map { |c| c.ord - 65 }
  end
end
