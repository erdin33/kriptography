module CipherWorkbench
  module Ciphers
    class Playfair < Base
      def self.id; 'playfair'; end
      def self.title; 'Playfair Cipher'; end
      def self.group; :classic26; end
      def self.domain; :letters; end
      def self.summary; 'Cipher substitusi digrafik yang mengenkripsi pasangan huruf menggunakan matriks 5x5. Huruf J digabung dengan I. Tidak aman menurut standar modern karena rentan terhadap analisis frekuensi digraf.'; end

      def self.fields
        [
          {
            name: 'key',
            type: 'text',
            label: 'Kunci',
            help: 'Kata kunci (hanya A-Z, huruf J akan diganti I).'
          }
        ]
      end

      def validate_key!
        letters = Codec::LetterCodec.filter_letters(@params[:key] || @params['key'])
        raise InvalidKeyError.new("Kunci harus memuat minimal satu huruf", field: 'key') if letters.empty?
        
        # Replace J with I
        letters.gsub!('J', 'I')
        
        @square = []
        @pos_map = {}
        
        # Build square: key letters first, then remaining alphabet
        chars = letters.chars.uniq
        ('A'..'Z').each do |char|
          next if char == 'J'
          chars << char unless chars.include?(char)
        end
        
        5.times do |row|
          row_chars = chars[row*5, 5]
          @square << row_chars
          row_chars.each_with_index do |char, col|
            @pos_map[char] = [row, col]
          end
        end
        
        @normalized_key = letters
      end

      def prepare(symbols)
        letters = Codec::LetterCodec.symbols_to_letters(symbols)
        letters.gsub!('J', 'I')
        
        digraphs = []
        i = 0
        while i < letters.length
          a = letters[i]
          b = letters[i+1]
          
          if b.nil?
            # Append X, or Q if a is X
            pad = (a == 'X') ? 'Q' : 'X'
            digraphs << a << pad
            i += 1
          elsif a == b
            # Insert X, or Q if XX
            pad = (a == 'X') ? 'Q' : 'X'
            digraphs << a << pad
            i += 1
          else
            digraphs << a << b
            i += 2
          end
        end
        
        Codec::LetterCodec.letters_to_symbols(digraphs.join)
      end

      def encrypt(symbols)
        process(prepare(symbols), dir: 1)
      end

      def decrypt(symbols)
        raise InvalidCiphertextError, "Panjang cipherteks Playfair harus genap" if symbols.length.odd?
        process(symbols, dir: -1)
      end

      def describe_key
        {
          normalized_key: @normalized_key,
          square: @square,
          note: "J digabung dengan I"
        }
      end

      private

      def process(symbols, dir:)
        letters = Codec::LetterCodec.symbols_to_letters(symbols)
        res = []
        
        (0...letters.length).step(2) do |i|
          a = letters[i]
          b = letters[i+1]
          
          # This should not happen on valid prepared input or valid ciphertext
          a = 'I' if a == 'J'
          b = 'I' if b == 'J'
          
          r1, c1 = @pos_map[a]
          r2, c2 = @pos_map[b]
          
          if r1 == r2
            res << @square[r1][(c1 + dir) % 5]
            res << @square[r2][(c2 + dir) % 5]
          elsif c1 == c2
            res << @square[(r1 + dir) % 5][c1]
            res << @square[(r2 + dir) % 5][c2]
          else
            res << @square[r1][c2]
            res << @square[r2][c1]
          end
        end
        
        Codec::LetterCodec.letters_to_symbols(res.join)
      end
    end
  end
end
