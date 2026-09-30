module CipherWorkbench
  class Error < StandardError
    attr_reader :code, :field

    def initialize(message = nil, code: 'internal_error', field: nil)
      super(message)
      @code = code
      @field = field
    end
  end

  class InvalidParamsError < Error
    def initialize(message = "Parameter tidak valid", field: nil)
      super(message, code: 'invalid_params', field: field)
    end
  end

  class InvalidKeyError < Error
    def initialize(message = "Kunci tidak valid", field: nil)
      super(message, code: 'invalid_key', field: field)
    end
  end

  class InvalidInputError < Error
    def initialize(message = "Input tidak valid", field: nil)
      super(message, code: 'invalid_input', field: field)
    end
  end

  class InvalidContainerError < Error
    def initialize(message = "Format container tidak valid", field: nil)
      super(message, code: 'invalid_container', field: field)
    end
  end

  class CipherMismatchError < Error
    def initialize(message = "Cipher tidak cocok dengan container", field: nil)
      super(message, code: 'cipher_mismatch', field: field)
    end
  end

  class InvalidCiphertextError < Error
    def initialize(message = "Cipherteks tidak valid", field: nil)
      super(message, code: 'invalid_ciphertext', field: field)
    end
  end

  class UnsupportedCipherError < Error
    def initialize(message = "Cipher tidak didukung", field: nil)
      super(message, code: 'unsupported_cipher', field: field)
    end
  end
end
