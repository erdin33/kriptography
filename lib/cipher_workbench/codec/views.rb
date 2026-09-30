module CipherWorkbench
  module Codec
    module Views
      class << self
        def base64(bytes_string)
          [bytes_string].pack('m0')
        end

        def from_base64(str)
          cleaned = str.to_s.gsub(/\s/, '')
          unless cleaned.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/) && (cleaned.length % 4 == 0)
            raise InvalidCiphertextError, "Input Base64 tidak valid"
          end
          cleaned.unpack1('m0')
        end

        def hex(bytes_string)
          bytes_string.unpack1('H*')
        end

        def from_hex(str)
          cleaned = str.to_s.gsub(/\s/, '')
          unless cleaned.match?(/\A[0-9a-fA-F]*\z/) && cleaned.length.even?
            raise InvalidCiphertextError, "Input Hexadecimal tidak valid"
          end
          [cleaned].pack('H*')
        end

        # We cannot use `case:` as a keyword arg name because `case` is a reserved word.
        # We will extract it from the options hash.
        def letters(ciphertext_letters, **opts)
          case_format = opts[:case] || :lower
          case case_format
          when :lower
            ciphertext_letters.downcase
          when :upper
            ciphertext_letters.upcase
          else
            ciphertext_letters
          end
        end

        def truncate(bytes_string, limit: 65_536)
          if bytes_string.bytesize > limit
            [bytes_string.byteslice(0, limit), true]
          else
            [bytes_string, false]
          end
        end
      end
    end
  end
end
