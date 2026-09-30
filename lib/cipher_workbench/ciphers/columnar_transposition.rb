module CipherWorkbench
  module Ciphers
    class ColumnarTransposition < Base
      def self.id; 'columnar'; end
      def self.title; 'Columnar Transposition'; end
      def self.group; :internal; end # Not shown in main catalog
      def self.domain; :bytes; end
      def self.summary; 'Cipher transposisi kolom. Diimplementasikan untuk keperluan komposisi dalam Super Enkripsi.'; end

      def self.fields
        [
          {
            name: 'key',
            type: 'text',
            label: 'Kunci Transposisi',
            help: 'Kunci untuk transposisi kolom (minimal 2 karakter).'
          }
        ]
      end

      def validate_key!
        key_str = @params[:key] || @params['key'] || ""
        @key_bytes = key_str.dup.force_encoding('UTF-8').bytes
        
        if @key_bytes.length < 2
          raise InvalidKeyError.new("Kunci transposisi harus memuat minimal 2 byte", field: 'key')
        end
        
        @c = @key_bytes.length
        
        # Rank the columns stably
        # Create array of [byte_value, original_index]
        indexed = @key_bytes.map.with_index { |b, i| [b, i] }
        # Sort by byte_value, then original_index to ensure stability
        sorted = indexed.sort_by { |b, i| [b, i] }
        
        @column_order = sorted.map { |_, i| i }
      end

      def encrypt(symbols)
        return [] if symbols.empty?
        
        n = symbols.length
        res = []
        
        @column_order.each do |col_idx|
          i = col_idx
          while i < n
            res << symbols[i]
            i += @c
          end
        end
        
        res
      end

      def decrypt(symbols)
        return [] if symbols.empty?
        
        n = symbols.length
        full_rows = n / @c
        remainder = n % @c
        
        col_lengths = Array.new(@c, full_rows)
        remainder.times { |i| col_lengths[i] += 1 }
        
        # We need to fill columns based on @column_order
        cols = Array.new(@c) { [] }
        idx = 0
        
        @column_order.each do |col_idx|
          len = col_lengths[col_idx]
          cols[col_idx] = symbols[idx, len]
          idx += len
        end
        
        # Reconstruct the original string row by row
        res = []
        row = 0
        while res.length < n
          @c.times do |col_idx|
            if row < cols[col_idx].length
              res << cols[col_idx][row]
            end
          end
          row += 1
        end
        
        res
      end

      def describe_key
        {
          columns: @c,
          order: @column_order.map { |i| i + 1 } # 1-based for UI
        }
      end
    end
  end
end
