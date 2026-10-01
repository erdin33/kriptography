module HillOracle
  def self.decrypt(params, symbols)
    matrix = params['matrix']
    if matrix.is_a?(String)
      matrix = matrix.split("\n").map { |row| row.split(",").map(&:to_i) }
    end
    
    n = matrix.size
    
    # Calculate determinant mod 26
    det = determinant(matrix) % 26
    
    # Calculate modular inverse of det
    det_inv = nil
    (1..25).each do |i|
      if (det * i) % 26 == 1
        det_inv = i
        break
      end
    end
    
    raise "Matrix is not invertible mod 26 (det=#{det})" unless det_inv
    
    # Calculate adjugate matrix
    adj = adjugate(matrix).map { |row| row.map { |x| x % 26 } }
    
    # Calculate inverse matrix
    inv_matrix = adj.map do |row|
      row.map { |x| (x * det_inv) % 26 }
    end
    
    # Decrypt
    plain_symbols = []
    
    symbols.each_slice(n) do |block|
      # if block is smaller than n, Hill usually pads with 'X' (23)
      block = block + Array.new(n - block.size, 23) if block.size < n
      
      decrypted_block = Array.new(n, 0)
      n.times do |i|
        n.times do |j|
          decrypted_block[i] = (decrypted_block[i] + inv_matrix[i][j] * block[j]) % 26
        end
      end
      
      plain_symbols.concat(decrypted_block)
    end
    
    plain_symbols
  end
  
  def self.determinant(m)
    n = m.size
    return m[0][0] if n == 1
    return m[0][0] * m[1][1] - m[0][1] * m[1][0] if n == 2
    
    det = 0
    n.times do |c|
      sub = m[1..-1].map { |row| row[0...c] + row[(c+1)..-1] }
      sign = (c % 2 == 0) ? 1 : -1
      det += sign * m[0][c] * determinant(sub)
    end
    det
  end
  
  def self.adjugate(m)
    n = m.size
    return [[1]] if n == 1
    
    adj = Array.new(n) { Array.new(n, 0) }
    n.times do |i|
      n.times do |j|
        sub = m.reject.with_index { |_, r| r == i }.map do |row|
          row.reject.with_index { |_, c| c == j }
        end
        sign = ((i + j) % 2 == 0) ? 1 : -1
        adj[j][i] = sign * determinant(sub)
      end
    end
    adj
  end
end
