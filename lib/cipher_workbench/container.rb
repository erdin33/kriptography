module CipherWorkbench
  module Container
    MAGIC = 'CWB1'.b.freeze
    VERSION = 1
    
    KIND_MAP = { text: 1, file: 2 }.freeze
    KIND_REVERSE_MAP = { 1 => :text, 2 => :file }.freeze
    
    ENCODING_MAP = { raw: 0, alpha_filter: 1, nibble16: 2 }.freeze
    ENCODING_REVERSE_MAP = { 0 => :raw, 1 => :alpha_filter, 2 => :nibble16 }.freeze

    HeaderData = Struct.new(:cipher_id, :kind, :encoding, :filename, :plain_length, :plain_sha256, :payload, keyword_init: true)

    class << self
      def pack(cipher_id:, kind:, encoding:, filename:, plain_length:, plain_sha256:, payload:)
        cipher_id_b = cipher_id.b
        raise InvalidInputError, "ID cipher terlalu panjang (maks 255 byte)" if cipher_id_b.bytesize > 255
        
        filename_b = filename.to_s.b
        raise InvalidInputError, "Nama berkas terlalu panjang (maks 65535 byte)" if filename_b.bytesize > 65_535

        kind_code = KIND_MAP.fetch(kind) { raise InvalidInputError, "Jenis muatan tidak dikenal: #{kind}" }
        encoding_code = ENCODING_MAP.fetch(encoding) { raise InvalidInputError, "Pengodean tidak dikenal: #{encoding}" }

        # plain_sha256 should be 32 bytes (raw bytes, not hex). If it's passed as hex string, we must ensure it's raw.
        # Assuming plain_sha256 is already 32 bytes binary string.
        raise InvalidInputError, "SHA-256 harus 32 byte" if plain_sha256.bytesize != 32

        binary = String.new(capacity: 58 + cipher_id_b.bytesize + filename_b.bytesize + payload.bytesize)
        binary << MAGIC
        binary << [VERSION, cipher_id_b.bytesize].pack('C2')
        binary << cipher_id_b
        binary << [kind_code, encoding_code].pack('C2')
        binary << [filename_b.bytesize].pack('n')
        binary << filename_b
        binary << [plain_length].pack('Q>')
        binary << plain_sha256
        binary << [payload.bytesize].pack('Q>')
        binary << payload
        binary
      end

      def unpack(binary)
        parse(binary, with_payload: true)
      end

      def inspect_header(binary)
        parse(binary, with_payload: false)
      end

      private

      def parse(binary, with_payload:)
        raise InvalidContainerError, "Data terpotong atau terlalu pendek" if binary.bytesize < 58

        offset = 0
        
        magic = binary.byteslice(offset, 4)
        raise InvalidContainerError, "Magic salah" if magic != MAGIC
        offset += 4

        version = binary.getbyte(offset)
        raise InvalidContainerError, "Versi tidak dikenal" if version != VERSION
        offset += 1

        cipher_id_len = binary.getbyte(offset)
        offset += 1
        
        raise InvalidContainerError, "Data terpotong saat membaca ID cipher" if offset + cipher_id_len > binary.bytesize
        cipher_id = binary.byteslice(offset, cipher_id_len)
        offset += cipher_id_len

        raise InvalidContainerError, "Data terpotong saat membaca jenis dan pengodean" if offset + 2 > binary.bytesize
        kind_code = binary.getbyte(offset)
        encoding_code = binary.getbyte(offset + 1)
        offset += 2

        kind = KIND_REVERSE_MAP[kind_code] || raise(InvalidContainerError, "Jenis muatan tak dikenal")
        encoding = ENCODING_REVERSE_MAP[encoding_code] || raise(InvalidContainerError, "Pengodean tak dikenal")

        raise InvalidContainerError, "Data terpotong saat membaca panjang nama berkas" if offset + 2 > binary.bytesize
        filename_len = binary.byteslice(offset, 2).unpack1('n')
        offset += 2

        raise InvalidContainerError, "Data terpotong saat membaca nama berkas" if offset + filename_len > binary.bytesize
        filename_b = binary.byteslice(offset, filename_len)
        filename_b.force_encoding('UTF-8')
        raise InvalidContainerError, "Nama berkas bukan UTF-8 valid" unless filename_b.valid_encoding?
        offset += filename_len

        raise InvalidContainerError, "Data terpotong saat membaca panjang plainteks" if offset + 8 > binary.bytesize
        plain_length = binary.byteslice(offset, 8).unpack1('Q>')
        offset += 8

        raise InvalidContainerError, "Data terpotong saat membaca SHA-256" if offset + 32 > binary.bytesize
        plain_sha256 = binary.byteslice(offset, 32)
        offset += 32

        raise InvalidContainerError, "Data terpotong saat membaca panjang muatan cipherteks" if offset + 8 > binary.bytesize
        payload_len = binary.byteslice(offset, 8).unpack1('Q>')
        offset += 8

        if with_payload
          raise InvalidContainerError, "Data terpotong saat membaca muatan cipherteks" if offset + payload_len > binary.bytesize
          raise InvalidContainerError, "Terdapat sisa byte setelah muatan cipherteks" if offset + payload_len < binary.bytesize
          payload = binary.byteslice(offset, payload_len)
        else
          payload = nil
        end

        HeaderData.new(
          cipher_id: cipher_id,
          kind: kind,
          encoding: encoding,
          filename: filename_b,
          plain_length: plain_length,
          plain_sha256: plain_sha256,
          payload: payload
        )
      end
    end
  end
end
