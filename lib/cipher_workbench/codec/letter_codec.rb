module CipherWorkbench
  module Codec
    module LetterCodec
      ALPHABET_26 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.freeze
      NIBBLE_ALPHABET = 'ABCDEFGHIKLMNOPQ'.freeze

      class << self
        def filter_letters(string)
          string.to_s.force_encoding('UTF-8').scrub.upcase.gsub(/[^A-Z]/, '')
        end

        def letters_to_symbols(string)
          string.each_byte.map { |b| b - 65 }
        end

        def symbols_to_letters(array)
          array.map { |s| (s + 65).chr }.join
        end

        def nibble_encode(bytes_string)
          result = String.new(capacity: bytes_string.bytesize * 2)
          bytes_string.each_byte do |b|
            result << NIBBLE_ALPHABET[b >> 4]
            result << NIBBLE_ALPHABET[b & 15]
          end
          result
        end

        def nibble_decode(letters, byte_length:)
          filtered = letters.gsub(/[^ABCDEFGHIKLMNOPQ]/, '')
          if filtered.length < 2 * byte_length
            raise InvalidCiphertextError, "Huruf cipherteks tidak cukup untuk mengembalikan panjang byte yang diminta"
          end

          result = String.new(capacity: byte_length)
          byte_length.times do |i|
            high = NIBBLE_ALPHABET.index(filtered[i * 2])
            low = NIBBLE_ALPHABET.index(filtered[i * 2 + 1])
            result << ((high << 4) | low).chr
          end
          result
        end
      end
    end
  end
end
