module CipherWorkbench
  module Ciphers
    class Autokey < Base
      def self.id; 'autokey'; end
      def self.title; 'Auto-Key Vigenere Cipher'; end
      def self.group; :classic26; end
      def self.domain; :letters; end
      def self.summary; 'Varian dari Vigenere yang menggunakan plainteks sebagai bagian dari aliran kunci setelah kunci utama habis. Tidak aman untuk standar modern namun lebih sulit dipecahkan daripada Vigenere standar.'; end

      def self.fields
        [
          {
            name: 'key',
            type: 'text',
            label: 'Kunci',
            help: 'Kata kunci awal (hanya karakter A-Z akan digunakan, panjang bebas).'
          }
        ]
      end

      def validate_key!
        @key_letters = Codec::LetterCodec.filter_letters(@params[:key] || @params['key'])
        if @key_letters.empty?
          raise InvalidKeyError.new("Kunci harus memuat minimal satu huruf A-Z", field: 'key')
        end
        @key_symbols = Codec::LetterCodec.letters_to_symbols(@key_letters)
      end

      def encrypt(symbols)
        # Keystream is key_symbols + symbols
        k_stream = @key_symbols + symbols

        symbols.map.with_index do |p, i|
          k = k_stream[i]
          (p + k) % 26
        end
      end

      def decrypt(symbols)
        m = @key_symbols.length
        plain_symbols = Array.new(symbols.length)
        
        symbols.each_with_index do |c, i|
          k = i < m ? @key_symbols[i] : plain_symbols[i - m]
          p = (c - k) % 26
          plain_symbols[i] = p
        end
        
        plain_symbols
      end

      def describe_key
        {
          normalized_key: @key_letters,
          length: @key_letters.length,
          note: "aliran kunci = kunci + plainteks"
        }
      end
    end
  end
end
