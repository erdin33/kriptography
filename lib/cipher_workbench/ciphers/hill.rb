module CipherWorkbench
  module Ciphers
    class Hill < Base
      def self.id; 'hill'; end
      def self.title; 'Hill Cipher'; end
      def self.group; :classic26; end
      def self.domain; :letters; end
      def self.summary; 'Cipher substitusi poligrafik berbasis aljabar linier yang mengenkripsi blok huruf (berukuran n) menggunakan perkalian matriks n x n. Rentan terhadap serangan known-plaintext.'; end

      def self.fields
        [
          {
            name: 'n',
            type: 'integer',
            label: 'Ukuran Matriks (n)',
            help: 'Pilih antara 2 sampai 6.',
            options: (2..6).map { |v| { value: v, label: v.to_s } }
          },
          {
            name: 'key_text',
            type: 'text',
            label: 'Kunci Teks',
            help: 'Teks dengan panjang tepat n*n huruf. Akan diubah menjadi matriks n x n.'
          },
          {
            name: 'matrix',
            type: 'matrix',
            label: 'Kunci Matriks',
            help: 'Matriks n x n (prioritas lebih tinggi dari teks).'
          }
        ]
      end

      def validate_key!
        @n = (@params[:n] || @params['n'] || 2).to_i
        raise InvalidKeyError.new("Ukuran n harus 2 sampai 6", field: 'n') unless (2..6).include?(@n)

        raw_matrix = @params[:matrix] || @params['matrix']
        key_text = @params[:key_text] || @params['key_text']

        if raw_matrix.is_a?(Array) && raw_matrix.length == @n && raw_matrix.all? { |r| r.is_a?(Array) && r.length == @n }
          # Using matrix
          @matrix = Array.new(@n) { Array.new(@n, 0) }
          @n.times do |i|
            @n.times do |j|
              @matrix[i][j] = Math::Modular.normalize(raw_matrix[i][j].to_i, 26)
            end
          end
        elsif key_text.is_a?(String) && !key_text.strip.empty?
          letters = Codec::LetterCodec.filter_letters(key_text)
          unless letters.length == @n * @n
            raise InvalidKeyError.new("Panjang kunci teks harus tepat #{@n * @n} huruf untuk n=#{@n}", field: 'key_text')
          end
          symbols = Codec::LetterCodec.letters_to_symbols(letters)
          
          @matrix = Array.new(@n) { Array.new(@n, 0) }
          @n.times do |i|
            @n.times do |j|
              @matrix[i][j] = Math::Modular.normalize(symbols[i * @n + j], 26)
            end
          end
        else
          raise InvalidKeyError.new("Harus menyediakan matrix atau key_text yang valid untuk n=#{@n}", field: 'matrix')
        end

        # Validate invertibility
        # MatrixMod.inverse will raise InvalidKeyError if det is not coprime with 26
        @inverse = Math::MatrixMod.inverse(@matrix, 26)
        @det_mod = Math::Modular.normalize(Math::MatrixMod.determinant(@matrix), 26)
      end

      def prepare(symbols)
        s = symbols.dup
        while s.length % @n != 0
          s << 23 # 'X'
        end
        s
      end

      def encrypt(symbols)
        process(prepare(symbols), @matrix)
      end

      def decrypt(symbols)
        raise InvalidCiphertextError, "Panjang cipherteks harus kelipatan #{@n}" unless symbols.length % @n == 0
        process(symbols, @inverse)
      end

      def describe_key
        {
          n: @n,
          matrix: @matrix,
          determinant_mod_26: @det_mod,
          inverse_matrix: @inverse
        }
      end

      private

      def process(symbols, matrix)
        res = []
        (0...symbols.length).step(@n) do |i|
          v = symbols[i, @n]
          out = Math::MatrixMod.mat_vec(matrix, v, 26)
          res.concat(out)
        end
        res
      end
    end
  end
end
