module CipherWorkbench
  module Ciphers
    module EnigmaData
      ROTORS = {
        'I'   => { wiring: 'EKMFLGDQVZNTOWYHXUSPAIBRCJ', notch: 'Q' },
        'II'  => { wiring: 'AJDKSIRUXBLHWTMCQGZNPYFVOE', notch: 'E' },
        'III' => { wiring: 'BDFHJLCPRTXVZNYEIWGAKMUSQO', notch: 'V' },
        'IV'  => { wiring: 'ESOVPZJAYQUIRHXLNFTGKDCMWB', notch: 'J' },
        'V'   => { wiring: 'VZBRGITYUPSDNHLXAWMJQOFECK', notch: 'Z' }
      }.freeze

      REFLECTORS = {
        'B' => 'YRUHQSLDPXNGOKMIEBFZCWVJAT',
        'C' => 'FVPJIAOYEDRZXWGCTKUQSBNMHL'
      }.freeze

      ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.freeze
    end
  end
end
