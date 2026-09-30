module CipherWorkbench
  module Ciphers
    class Affine < Base
      def self.id; 'affine'; end
      def self.title; 'Affine Cipher'; end
      def self.group; :classic26; end
      def self.domain; :letters; end
      def self.summary; 'Cipher substitusi monoalfabetik yang menggunakan fungsi matematika linear C = (aP + b) mod 26. Tidak aman karena rentan terhadap serangan analisis frekuensi dan hanya memiliki sedikit kunci yang mungkin.'; end

      VALID_A_VALUES = [1, 3, 5, 7, 9, 11, 15, 17, 19, 21, 23, 25].freeze

      def self.fields
        [
          {
            name: 'a',
            type: 'integer',
            label: 'Pengali (a)',
            help: 'Harus bernilai yang relatif prima dengan 26.',
            options: VALID_A_VALUES.map { |v| { value: v, label: v.to_s } }
          },
          {
            name: 'b',
            type: 'integer',
            label: 'Pergeseran (b)',
            help: 'Nilai pergeseran (sembarang bilangan bulat).'
          }
        ]
      end

      def validate_key!
        a_param = @params[:a] || @params['a']
        b_param = @params[:b] || @params['b']
        
        unless a_param.to_s.match?(/\A-?\d+\z/) && b_param.to_s.match?(/\A-?\d+\z/)
          raise InvalidParamsError.new("Parameter a dan b harus bernilai angka (integer)", field: 'a')
        end
        
        a_val = a_param.to_i
        b_val = b_param.to_i
        
        @a = Math::Modular.normalize(a_val, 26)
        @b = Math::Modular.normalize(b_val, 26)
        
        unless VALID_A_VALUES.include?(@a)
          raise InvalidKeyError.new("Nilai 'a' (setelah mod 26) harus koprima dengan 26. Nilai yang sah: #{VALID_A_VALUES.join(', ')}", field: 'a')
        end
        
        @a_inv = Math::Modular.mod_inverse(@a, 26)
      end

      def encrypt(symbols)
        symbols.map { |p| (@a * p + @b) % 26 }
      end

      def decrypt(symbols)
        symbols.map { |c| (@a_inv * (c - @b)) % 26 }
      end

      def describe_key
        {
          a: @a,
          b: @b,
          a_inverse: @a_inv,
          valid_a_values: VALID_A_VALUES
        }
      end
    end
  end
end
