module CipherWorkbench
  module Ciphers
    class ExtendedVigenere < Base
      def self.id; 'extended_vigenere'; end
      def self.title; 'Extended Vigenere Cipher'; end
      def self.group; :ascii256; end
      def self.domain; :bytes; end
      def self.summary; 'Varian Vigenere yang beroperasi pada tingkat byte (256 nilai), bukan hanya huruf. Karena dapat mengenkripsi karakter apa pun termasuk data biner murni, cipher ini cocok digunakan untuk mengenkripsi berkas.'; end

      def self.fields
        [
          {
            name: 'key',
            type: 'text',
            label: 'Kunci',
            help: 'Kunci teks bebas, akan diubah menjadi representasi byte UTF-8.'
          }
        ]
      end

      def validate_key!
        key_str = @params[:key] || @params['key'] || ""
        @key_bytes = key_str.dup.force_encoding('UTF-8').bytes
        
        if @key_bytes.empty?
          raise InvalidKeyError.new("Kunci tidak boleh kosong", field: 'key')
        end
      end

      def encrypt(symbols)
        m = @key_bytes.length
        symbols.map.with_index do |p, i|
          (p + @key_bytes[i % m]) % 256
        end
      end

      def decrypt(symbols)
        m = @key_bytes.length
        symbols.map.with_index do |c, i|
          (c - @key_bytes[i % m]) % 256
        end
      end

      def describe_key
        {
          key_bytes_hex: Codec::Views.hex(@key_bytes.pack('C*')),
          length: @key_bytes.length
        }
      end
    end
  end
end
