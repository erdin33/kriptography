module CipherWorkbench
  module Ciphers
    class Vigenere < Base
      def self.id; 'vigenere'; end
      def self.title; 'Vigenere Cipher'; end
      def self.group; :classic26; end
      def self.domain; :letters; end
      def self.summary; 'Cipher substitusi polialfabetik klasik yang menggunakan tabel huruf (bujur sangkar Vigenere). Walaupun klasik dan terkenal, cipher ini tidak aman untuk standar modern.'; end

      def self.fields
        [
          {
            name: 'key',
            type: 'text',
            label: 'Kunci',
            help: 'Kata kunci (hanya karakter A-Z akan digunakan, panjang bebas).'
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
        m = @key_symbols.length
        symbols.map.with_index do |p, i|
          k = @key_symbols[i % m]
          (p + k) % 26
        end
      end

      def decrypt(symbols)
        m = @key_symbols.length
        symbols.map.with_index do |c, i|
          k = @key_symbols[i % m]
          (c - k) % 26
        end
      end

      def describe_key
        preview_length = [@key_letters.length, 30].min
        preview = @key_letters[0...preview_length]
        # if the key is short, repeat it to preview
        if @key_letters.length < 30
          preview = (@key_letters * ((30.0 / @key_letters.length).ceil))[0...30]
        end

        {
          normalized_key: @key_letters,
          length: @key_letters.length,
          keystream_preview: preview
        }
      end
    end
  end
end
