module CipherWorkbench
  module Ciphers
    class Enigma < Base
      def self.id; 'enigma'; end
      def self.title; 'Enigma M3'; end
      def self.group; :bonus; end
      def self.domain; :letters; end
      def self.summary; 'Simulasi mesin Enigma M3 yang digunakan oleh Wehrmacht dan Luftwaffe. Kunci untuk cipher ini berupa serangkaian pengaturan mekanis mesin, bukan string teks bebas. Merupakan cipher polyalphabetic elektromekanis canggih di zamannya, dengan karakteristik unik bahwa huruf tidak pernah dipetakan ke dirinya sendiri.'; end

      def self.fields
        [
          {
            name: 'rotors',
            type: 'text',
            label: 'Rotor (Kiri, Tengah, Kanan)',
            help: 'Pilih tiga rotor unik dari I, II, III, IV, V (contoh: I,II,III).'
          },
          {
            name: 'reflector',
            type: 'text',
            label: 'Reflektor',
            help: 'Pilih reflektor: B atau C.'
          },
          {
            name: 'rings',
            type: 'text',
            label: 'Ringstellung',
            help: 'Tiga huruf pengaturan ring (contoh: AAA).'
          },
          {
            name: 'positions',
            type: 'text',
            label: 'Posisi Awal',
            help: 'Tiga huruf posisi awal rotor (contoh: AAA).'
          },
          {
            name: 'plugboard',
            type: 'text',
            label: 'Plugboard',
            help: 'Pasangan huruf, maks 10 pasang dipisah spasi (contoh: AB CD).'
          }
        ]
      end

      def validate_key!
        # Rotors
        rot_raw = (@params[:rotors] || @params['rotors'] || "").to_s.upcase.split(/[\s,]+/)
        if rot_raw.length != 3
          raise InvalidKeyError.new("Harus memasukkan tepat 3 rotor", field: 'rotors')
        end
        unless rot_raw.all? { |r| EnigmaData::ROTORS.key?(r) }
          raise InvalidKeyError.new("Rotor tidak dikenal. Pilih dari I, II, III, IV, V", field: 'rotors')
        end
        if rot_raw.uniq.length != 3
          raise InvalidKeyError.new("Tidak boleh ada rotor yang berulang", field: 'rotors')
        end
        @rotors = rot_raw

        # Reflector
        ref_raw = (@params[:reflector] || @params['reflector'] || "").to_s.upcase.strip
        unless EnigmaData::REFLECTORS.key?(ref_raw)
          raise InvalidKeyError.new("Reflektor harus B atau C", field: 'reflector')
        end
        @reflector = ref_raw

        # Rings
        @rings = parse_three_setting((@params[:rings] || @params['rings']), 'rings', 'AAA')

        # Positions
        @positions = parse_three_setting((@params[:positions] || @params['positions']), 'positions', 'AAA')

        # Plugboard
        pb_raw = (@params[:plugboard] || @params['plugboard'] || "").to_s.upcase
        pairs = pb_raw.scan(/[A-Z]{2}/)
        if pairs.length > 10
          raise InvalidKeyError.new("Plugboard maksimal 10 pasang", field: 'plugboard')
        end
        
        @plugboard_map = {}
        seen = {}
        pairs.each do |pair|
          a, b = pair[0], pair[1]
          if a == b
            raise InvalidKeyError.new("Pasangan huruf plugboard tidak boleh sama (#{pair})", field: 'plugboard')
          end
          if seen[a] || seen[b]
            raise InvalidKeyError.new("Huruf pada plugboard tidak boleh muncul lebih dari sekali", field: 'plugboard')
          end
          seen[a] = true
          seen[b] = true
          @plugboard_map[a.ord - 65] = b.ord - 65
          @plugboard_map[b.ord - 65] = a.ord - 65
        end
      end

      def encrypt(symbols)
        process(symbols)
      end

      def decrypt(symbols)
        process(symbols)
      end

      def describe_key
        pairs = @plugboard_map.select { |k, v| k < v }.map { |k, v| "#{(k+65).chr}#{(v+65).chr}" }
        
        {
          rotors: @rotors,
          reflector: @reflector,
          rings: @rings.map { |r| (r + 65).chr }.join,
          positions: @positions.map { |p| (p + 65).chr }.join,
          plugboard_pairs: pairs,
          final_positions_after_message: nil,
          note: "Enigma resiprokal: dekripsi memakai pengaturan awal yang sama"
        }
      end

      # Expose for testing stepping logic internally
      def _simulate_stepping(num_steps)
        state = @positions.dup
        res = []
        num_steps.times do
          step_rotors!(state)
          res << state.dup
        end
        res
      end

      private

      def parse_three_setting(val, field, default_val)
        val = val.to_s.upcase.strip
        val = default_val if val.empty?
        
        if val.match?(/\A\d+\s+\d+\s+\d+\z/) || val.match?(/\A\d+,\d+,\d+\z/)
          nums = val.split(/[\s,]+/).map(&:to_i)
          unless nums.all? { |n| n >= 1 && n <= 26 }
            raise InvalidKeyError.new("Angka pengaturan harus antara 1-26", field: field)
          end
          nums.map { |n| n - 1 }
        else
          val = Codec::LetterCodec.filter_letters(val)
          if val.length != 3
            raise InvalidKeyError.new("Pengaturan harus persis 3 huruf atau angka", field: field)
          end
          Codec::LetterCodec.letters_to_symbols(val)
        end
      end

      def process(symbols)
        state = @positions.dup
        
        # Wiring pre-computations (0..25 mapping)
        r_wires_fwd = []
        r_wires_rev = []
        r_notches = []
        
        @rotors.each do |r|
          data = EnigmaData::ROTORS[r]
          w = Codec::LetterCodec.letters_to_symbols(data[:wiring])
          r_wires_fwd << w
          
          w_rev = Array.new(26)
          w.each_with_index { |v, i| w_rev[v] = i }
          r_wires_rev << w_rev
          
          r_notches << (data[:notch].ord - 65)
        end

        ref_wire = Codec::LetterCodec.letters_to_symbols(EnigmaData::REFLECTORS[@reflector])

        out = Array.new(symbols.length)

        symbols.each_with_index do |sym, idx|
          # 1. Stepping
          step_rotors!(state, r_notches)

          # 2. Path: Plugboard -> Forward Rotors -> Reflector -> Reverse Rotors -> Plugboard
          c = @plugboard_map[sym] || sym
          
          # Right to left (Forward)
          # state and rings index: 0=Left, 1=Middle, 2=Right
          # Rotors order: Right=2, Middle=1, Left=0
          3.times do |i|
            r_idx = 2 - i
            p = state[r_idx]
            r = @rings[r_idx]
            o = (p - r) % 26
            
            c = (r_wires_fwd[r_idx][(c + o) % 26] - o) % 26
          end
          
          # Reflector
          c = ref_wire[c]
          
          # Left to right (Reverse)
          3.times do |i|
            r_idx = i
            p = state[r_idx]
            r = @rings[r_idx]
            o = (p - r) % 26
            
            c = (r_wires_rev[r_idx][(c + o) % 26] - o) % 26
          end
          
          c = @plugboard_map[c] || c
          out[idx] = c
        end
        out
      end

      def step_rotors!(state, notches = nil)
        unless notches
          notches = @rotors.map { |r| EnigmaData::ROTORS[r][:notch].ord - 65 }
        end
        
        at_notch_m = (state[1] == notches[1])
        at_notch_r = (state[2] == notches[2])
        
        middle_steps = at_notch_r || at_notch_m
        left_steps = at_notch_m
        
        state[2] = (state[2] + 1) % 26
        state[1] = (state[1] + 1) % 26 if middle_steps
        state[0] = (state[0] + 1) % 26 if left_steps
      end
    end
  end
end
