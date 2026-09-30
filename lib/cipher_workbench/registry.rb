module CipherWorkbench
  module Registry
    class << self
      def register(klass)
        @ciphers ||= []
        @ciphers << klass unless @ciphers.include?(klass)
      end

      def all
        @ciphers ||= []
        group_order = { classic26: 1, ascii256: 2, super: 3, bonus: 4 }
        @ciphers.sort_by { |c| [group_order[c.group] || 99, c.title] }
      end

      def build(id, params)
        klass = all.find { |c| c.id.to_s == id.to_s }
        raise UnsupportedCipherError, "Cipher tidak didukung: #{id}" unless klass
        klass.new(params)
      end

      def catalog
        all.map do |c|
          {
            id: c.id,
            title: c.title,
            group: c.group,
            domain: c.domain,
            summary: c.summary,
            fields: c.fields
          }
        end
      end
      
      def clear!
        @ciphers = []
      end
    end
  end
end
