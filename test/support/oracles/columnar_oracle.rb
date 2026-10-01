module ColumnarOracle
  def self.decrypt(params, symbols)
    key_str = params['key'].to_s
    cols = key_str.length
    return symbols if cols == 0 || symbols.empty?
    
    # rank columns stably
    # example ZEBRAS -> Z(5) E(1) B(0) R(3) A(0) S(4)? wait A is 0, B is 1, E is 2...
    # to be stable: pair char with original index, sort by char
    indexed_key = key_str.chars.map.with_index { |c, i| [c, i] }
    sorted_key = indexed_key.sort_by { |c, i| c }
    
    # original_index => rank
    # or rank => original_index
    # We need to read ciphertext. Ciphertext consists of columns.
    # The columns are ordered by `sorted_key` (so the first chunk is the column corresponding to sorted_key[0].original_index, etc.)
    
    full_rows = symbols.length / cols
    remainder = symbols.length % cols
    
    # Determine the length of each column (in original order)
    col_lengths = Array.new(cols, full_rows)
    remainder.times { |i| col_lengths[i] += 1 }
    
    # We will reconstruct the grid (array of arrays, grid[row][col])
    # But it's easier to build it column by column.
    # grid[original_col] = array of symbols
    grid = Array.new(cols) { [] }
    
    idx = 0
    sorted_key.each do |c, orig_idx|
      len = col_lengths[orig_idx]
      grid[orig_idx] = symbols[idx, len]
      idx += len
    end
    
    # Read row by row
    plain_symbols = []
    num_rows = (symbols.length.to_f / cols).ceil
    
    num_rows.times do |r|
      cols.times do |c|
        if r < grid[c].length
          plain_symbols << grid[c][r]
        end
      end
    end
    
    plain_symbols
  end
end
