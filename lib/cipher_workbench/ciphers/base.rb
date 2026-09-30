module CipherWorkbench
  module Ciphers
    class Base
      class << self
        def inherited(subclass)
          super
          Registry.register(subclass)
        end
        
        def id; raise NotImplementedError; end
        def title; raise NotImplementedError; end
        def group; raise NotImplementedError; end
        def domain; raise NotImplementedError; end
        def summary; raise NotImplementedError; end
        def fields; raise NotImplementedError; end
      end

      def initialize(params)
        @params = params
        validate_key!
      end

      def prepare(symbols)
        symbols
      end

      def encrypt(symbols)
        raise NotImplementedError
      end

      def decrypt(symbols)
        raise NotImplementedError
      end

      def describe_key
        {}
      end

      protected

      def validate_key!
        # Di-override di subkelas
      end
    end
  end
end
