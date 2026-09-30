module CipherWorkbench
  module Ciphers
    class ShiftLetters < Base
      def self.id; 'shift_letters'; end
      def self.title; 'Shift Letters Test'; end
      def self.group; :classic26; end
      def self.domain; :letters; end
      def self.summary; 'Test cipher'; end
      def self.fields; []; end

      def validate_key!
      end

      def prepare(symbols)
        s = symbols.dup
        s << 23 if s.length.odd? # 'X'
        s
      end

      def encrypt(symbols)
        prepare(symbols).map { |s| (s + 1) % 26 }
      end

      def decrypt(symbols)
        symbols.map { |s| (s - 1) % 26 }
      end
    end

    class ShiftBytes < Base
      def self.id; 'shift_bytes'; end
      def self.title; 'Shift Bytes Test'; end
      def self.group; :ascii256; end
      def self.domain; :bytes; end
      def self.summary; 'Test cipher'; end
      def self.fields; []; end

      def validate_key!
      end

      def encrypt(symbols)
        symbols.map { |s| (s + 1) % 256 }
      end

      def decrypt(symbols)
        symbols.map { |s| (s - 1) % 256 }
      end
    end
  end
end

CipherWorkbench::Registry.register(CipherWorkbench::Ciphers::ShiftLetters)
CipherWorkbench::Registry.register(CipherWorkbench::Ciphers::ShiftBytes)
