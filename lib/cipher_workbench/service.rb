require 'digest/sha2'

module CipherWorkbench
  module Service
    EncryptResult = Struct.new(:container, :payload, :encoding, :kind, :filename, :plain_bytes, :cipher_letters, :key_info, :used_symbols, keyword_init: true)
    DecryptResult = Struct.new(:kind, :encoding, :filename, :plain_bytes, :text, :text_valid, :integrity, :key_info, keyword_init: true)

    class << self
      def encrypt(cipher_id:, params:, input:)
        cipher = Registry.build(cipher_id, params)
        kind = input[:kind]

        if cipher.class.domain == :letters
          if kind == :text
            letters = Codec::LetterCodec.filter_letters(input[:text])
            raise InvalidInputError, "Plainteks tidak memuat huruf A-Z" if letters.empty?
            encoding = :alpha_filter
          else
            bytes = input[:bytes].b
            letters = Codec::LetterCodec.nibble_encode(bytes)
            encoding = :nibble16
          end

          symbols = Codec::LetterCodec.letters_to_symbols(letters)
          prepared_symbols = cipher.prepare(symbols)
          cipher_symbols = cipher.encrypt(symbols)
          
          if encoding == :alpha_filter
            prepared_letters = Codec::LetterCodec.symbols_to_letters(prepared_symbols)
            plain_length = prepared_letters.bytesize
            plain_sha256 = Digest::SHA256.digest(prepared_letters)
            plain_bytes = prepared_letters # for base64 view
          else
            # nibble16
            orig_bytes = input[:bytes].b
            plain_length = orig_bytes.bytesize
            plain_sha256 = Digest::SHA256.digest(orig_bytes)
            plain_bytes = orig_bytes
          end

          payload = Codec::LetterCodec.symbols_to_letters(cipher_symbols)
          cipher_letters = payload

        elsif cipher.class.domain == :bytes
          if kind == :text
            bytes = input[:text].dup.force_encoding('UTF-8').b
            raise InvalidInputError, "Teks kosong tidak diizinkan" if bytes.empty?
          else
            bytes = input[:bytes].b
          end
          encoding = :raw
          symbols = bytes.bytes
          # prepared_symbols = cipher.prepare(symbols) ? Wait, not explicitly required by prompt for bytes plain_length, but let's see. 
          # Prompt: "plain_length dan sha256 atas byte plainteks" meaning original bytes.
          plain_length = bytes.bytesize
          plain_sha256 = Digest::SHA256.digest(bytes)
          plain_bytes = bytes
          
          cipher_symbols = cipher.encrypt(symbols)
          payload = cipher_symbols.pack('C*')
          cipher_letters = nil
        else
          raise UnsupportedCipherError, "Domain cipher tidak dikenal: #{cipher.domain}"
        end

        filename = kind == :file ? input[:filename] : ""
        
        container = Container.pack(
          cipher_id: cipher_id,
          kind: kind,
          encoding: encoding,
          filename: filename,
          plain_length: plain_length,
          plain_sha256: plain_sha256,
          payload: payload
        )

        EncryptResult.new(
          container: container,
          payload: payload,
          encoding: encoding,
          kind: kind,
          filename: filename,
          plain_bytes: plain_bytes,
          cipher_letters: cipher_letters,
          key_info: cipher.describe_key,
          used_symbols: cipher_symbols.length
        )
      end

      def decrypt(cipher_id:, params:, source:)
        cipher = Registry.build(cipher_id, params)
        
        if source[:type] == :container
          header = Container.unpack(source[:bytes])
          
          if header.cipher_id != cipher_id.to_s
            raise CipherMismatchError, "Cipher mismatch: expected #{header.cipher_id}, got #{cipher_id}"
          end

          kind = header.kind
          encoding = header.encoding
          filename = header.filename
          payload = header.payload
          
          valid = true

          if cipher.class.domain == :letters
            unless encoding == :alpha_filter || encoding == :nibble16
              raise InvalidContainerError, "Pengodean #{encoding} tidak cocok dengan domain letters"
            end
            
            # payload is ascii letters
            cipher_symbols = Codec::LetterCodec.letters_to_symbols(payload)
            plain_symbols = cipher.decrypt(cipher_symbols)
            plain_letters = Codec::LetterCodec.symbols_to_letters(plain_symbols)

            if encoding == :alpha_filter
              text = plain_letters
              text_valid = true
              plain_bytes = text.b
              
              calc_sha = Digest::SHA256.digest(plain_bytes)
              if calc_sha != header.plain_sha256 || plain_bytes.bytesize != header.plain_length
                valid = false
              end
            else
              # nibble16
              plain_bytes = Codec::LetterCodec.nibble_decode(plain_letters, byte_length: header.plain_length)
              text = nil
              text_valid = false
              
              calc_sha = Digest::SHA256.digest(plain_bytes)
              if calc_sha != header.plain_sha256
                valid = false
              end
            end
          else
            # domain :bytes
            unless encoding == :raw
              raise InvalidContainerError, "Pengodean #{encoding} tidak cocok dengan domain bytes"
            end
            
            cipher_symbols = payload.bytes
            plain_symbols = cipher.decrypt(cipher_symbols)
            plain_bytes = plain_symbols.pack('C*')
            
            calc_sha = Digest::SHA256.digest(plain_bytes)
            if calc_sha != header.plain_sha256 || plain_bytes.bytesize != header.plain_length
              valid = false
            end
            
            if kind == :text
              text = plain_bytes.dup.force_encoding('UTF-8')
              text_valid = text.valid_encoding?
              text = text.scrub unless text_valid
            else
              text = nil
              text_valid = false
            end
          end

          integrity = { checked: true, valid: valid }

          DecryptResult.new(
            kind: kind,
            encoding: encoding,
            filename: filename,
            plain_bytes: plain_bytes,
            text: text,
            text_valid: text_valid,
            integrity: integrity,
            key_info: cipher.describe_key
          )

        elsif source[:type] == :text
          payload_text = source[:text]
          format = source[:format]

          integrity = { checked: false, valid: false }

          if cipher.class.domain == :letters
            if format == :letters
              payload = Codec::LetterCodec.filter_letters(payload_text)
              raise InvalidInputError, "Teks kosong setelah difilter" if payload.empty?
            elsif format == :base64
              payload_bytes = Codec::Views.from_base64(payload_text)
              payload = payload_bytes.force_encoding('UTF-8')
              raise InvalidCiphertextError, "Bukan ASCII" unless payload.ascii_only? && payload.match?(/\A[A-Za-z]+\z/)
              payload = payload.upcase
            elsif format == :hex
              payload_bytes = Codec::Views.from_hex(payload_text)
              payload = payload_bytes.force_encoding('UTF-8')
              raise InvalidCiphertextError, "Bukan ASCII" unless payload.ascii_only? && payload.match?(/\A[A-Za-z]+\z/)
              payload = payload.upcase
            else
              raise InvalidInputError, "Format #{format} tidak dikenal"
            end

            cipher_symbols = Codec::LetterCodec.letters_to_symbols(payload)
            plain_symbols = cipher.decrypt(cipher_symbols)
            text = Codec::LetterCodec.symbols_to_letters(plain_symbols)
            
            DecryptResult.new(
              kind: :text,
              encoding: :alpha_filter,
              filename: "",
              plain_bytes: text.b,
              text: text,
              text_valid: true,
              integrity: integrity,
              key_info: cipher.describe_key
            )
          else
            # bytes
            if format == :letters
              raise InvalidInputError, "Format letters tidak didukung untuk domain bytes"
            elsif format == :base64
              payload_bytes = Codec::Views.from_base64(payload_text)
            elsif format == :hex
              payload_bytes = Codec::Views.from_hex(payload_text)
            else
              raise InvalidInputError, "Format #{format} tidak dikenal"
            end

            cipher_symbols = payload_bytes.bytes
            plain_symbols = cipher.decrypt(cipher_symbols)
            plain_bytes = plain_symbols.pack('C*')
            
            text = plain_bytes.dup.force_encoding('UTF-8')
            text_valid = text.valid_encoding?

            DecryptResult.new(
              kind: :text,
              encoding: :raw,
              filename: "",
              plain_bytes: plain_bytes,
              text: text,
              text_valid: text_valid,
              integrity: integrity,
              key_info: cipher.describe_key
            )
          end
        else
          raise InvalidInputError, "Sumber dekripsi tidak dikenal"
        end
      end
    end
  end
end
