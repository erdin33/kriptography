module EnigmaOracle
  # HANYA SETELAH STRUKTUR SELESAI, KITA ISI KONSTANTA INI
  ROTORS = {
    'I'   => { wiring: "EKMFLGDQVZNTOWYHXUSPAIBRCJ", notch: "Q" },
    'II'  => { wiring: "AJDKSIRUXBLHWTMCQGZNPYFVOE", notch: "E" },
    'III' => { wiring: "BDFHJLCPRTXVZNYEIWGAKMUSQO", notch: "V" },
    'IV'  => { wiring: "ESOVPZJAYQUIRHXLNFTGKDCMWB", notch: "J" },
    'V'   => { wiring: "VZBRGITYUPSDNHLXAWMJQOFECK", notch: "Z" }
  }
  
  REFLECTORS = {
    'B' => "YRUHQSLDPXNGOKMIEBFZCWVJAT",
    'C' => "FVPJIAOYEDRZXWGCTKUQSBNMHL"
  }

  def self.decrypt(params, symbols)
    # Enigma is reciprocal
    encrypt(params, symbols)
  end
  
  def self.encrypt(params, symbols)
    # params: { rotors: ['I', 'II', 'III'], reflector: 'B', ring: 'AAA', pos: 'AAA', plugboard: 'AB CD' }
    rotor_ids = params['rotors'] || ['I', 'II', 'III']
    reflector_id = params['reflector'] || 'B'
    ring_str = (params['ring'] || 'AAA').upcase
    pos_str = (params['pos'] || 'AAA').upcase
    plugboard_str = (params['plugboard'] || '').upcase
    
    # Parse configurations
    rotors = rotor_ids.map { |id| ROTORS[id] }
    reflector = REFLECTORS[reflector_id]
    
    rings = ring_str.chars.map { |c| c.ord - 65 }
    positions = pos_str.chars.map { |c| c.ord - 65 }
    
    # Precompute wiring arrays
    rotor_fwd = rotors.map do |r|
      r[:wiring].chars.map { |c| c.ord - 65 }
    end
    rotor_bwd = rotors.map do |r|
      inv = Array.new(26)
      r[:wiring].chars.each_with_index do |c, i|
        inv[c.ord - 65] = i
      end
      inv
    end
    notches = rotors.map { |r| r[:notch].ord - 65 }
    refl_wiring = reflector.chars.map { |c| c.ord - 65 }
    
    # Plugboard
    plug_map = (0..25).to_a
    plugboard_str.scan(/[A-Z]{2}/).each do |pair|
      a = pair[0].ord - 65
      b = pair[1].ord - 65
      plug_map[a] = b
      plug_map[b] = a
    end
    
    out_symbols = []
    
    symbols.each do |sym|
      # Stepping
      # Positions: 0=Left, 1=Middle, 2=Right
      right_at_notch = (positions[2] == notches[2])
      middle_at_notch = (positions[1] == notches[1])
      
      step_left = middle_at_notch
      step_middle = middle_at_notch || right_at_notch
      step_right = true
      
      positions[0] = (positions[0] + 1) % 26 if step_left
      positions[1] = (positions[1] + 1) % 26 if step_middle
      positions[2] = (positions[2] + 1) % 26 if step_right
      
      # Signal path
      signal = sym
      
      # Plug in
      signal = plug_map[signal]
      
      # Fwd through R(2), M(1), L(0)
      [2, 1, 0].each do |i|
        offset = (positions[i] - rings[i]) % 26
        pin_in = (signal + offset) % 26
        pin_out = rotor_fwd[i][pin_in]
        signal = (pin_out - offset) % 26
      end
      
      # Reflector
      signal = refl_wiring[signal]
      
      # Bwd through L(0), M(1), R(2)
      [0, 1, 2].each do |i|
        offset = (positions[i] - rings[i]) % 26
        pin_in = (signal + offset) % 26
        pin_out = rotor_bwd[i][pin_in]
        signal = (pin_out - offset) % 26
      end
      
      # Plug out
      signal = plug_map[signal]
      
      out_symbols << signal
    end
    
    out_symbols
  end
end
