module CipherWorkbench
  module Ciphers
    class SuperEncryption < Base
      def self.id; 'super'; end
      def self.title; 'Super Enkripsi'; end
      def self.group; :super; end
      def self.domain; :bytes; end
      def self.summary; 'Kombinasi dari Extended Vigenere Cipher dan Columnar Transposition. Enkripsi beroperasi pada tingkat byte (0-255). Proses transposisi beroperasi pada blok kolom yang tidak beraturan tanpa padding.'; end

      def self.fields
        [
          {
            name: 'vigenere_key',
            type: 'text',
            label: 'Kunci Vigenere',
            help: 'Kunci teks untuk Extended Vigenere (diubah ke byte UTF-8).'
          },
          {
            name: 'transposition_key',
            type: 'text',
            label: 'Kunci Transposisi',
            help: 'Kunci teks untuk Transposisi Kolom (minimal 2 karakter).'
          }
        ]
      end

      def validate_key!
        vig_key = @params[:vigenere_key] || @params['vigenere_key']
        trans_key = @params[:transposition_key] || @params['transposition_key']
        
        begin
          @vigenere = ExtendedVigenere.new(key: vig_key)
        rescue InvalidKeyError => e
          raise InvalidKeyError.new(e.message, field: 'vigenere_key')
        end

        begin
          @columnar = ColumnarTransposition.new(key: trans_key)
        rescue InvalidKeyError => e
          raise InvalidKeyError.new(e.message, field: 'transposition_key')
        end
      end

      def encrypt(symbols)
        vig_encrypted = @vigenere.encrypt(symbols)
        @columnar.encrypt(vig_encrypted)
      end

      def decrypt(symbols)
        col_decrypted = @columnar.decrypt(symbols)
        @vigenere.decrypt(col_decrypted)
      end

      def describe_key
        vig_desc = @vigenere.describe_key
        col_desc = @columnar.describe_key
        
        {
          vigenere: vig_desc,
          transposition: col_desc,
          order: "Extended Vigenere kemudian transposisi kolom",
          column_order: col_desc[:order]
        }
      end
    end
  end
end
